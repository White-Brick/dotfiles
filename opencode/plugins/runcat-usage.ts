import type { Plugin } from "@opencode-ai/plugin"
import { spawn } from "node:child_process"
import { existsSync, realpathSync, statSync } from "node:fs"
import { mkdir, open, rename, rm } from "node:fs/promises"
import { homedir } from "node:os"
import { dirname, isAbsolute, join } from "node:path"
import { randomUUID } from "node:crypto"

type RateLimitWindow = {
  usedPercent?: number
  windowDurationMins?: number
}

type RateLimits = {
  primary?: RateLimitWindow | null
  secondary?: RateLimitWindow | null
}

function getCodexPath() {
  const validateExecutable = (path: string) => {
    if (!isAbsolute(path) || !existsSync(path)) throw new Error("Codex executable path is invalid")
    const resolvedPath = realpathSync(path)
    const stats = statSync(resolvedPath)
    const currentUser = process.getuid?.()
    if (!stats.isFile() || (stats.uid !== 0 && currentUser !== undefined && stats.uid !== currentUser)) {
      throw new Error("Codex executable ownership is invalid")
    }
    if ((stats.mode & 0o002) !== 0) throw new Error("Codex executable must not be world-writable")
    return resolvedPath
  }

  if (process.env.CODEX_CLI_PATH) {
    return validateExecutable(process.env.CODEX_CLI_PATH)
  }

  const candidates = [
    "/Applications/ChatGPT.app/Contents/Resources/codex",
    "/opt/homebrew/bin/codex",
    "/usr/local/bin/codex",
  ]
  const executable = candidates.find(existsSync)
  if (!executable) throw new Error("Codex executable not found")
  return validateExecutable(executable)
}

function getNumericSetting(name: string, fallback: number, minimum: number, maximum: number) {
  const value = Number(process.env[name] ?? fallback)
  return Number.isFinite(value) && value >= minimum && value <= maximum ? value : fallback
}

function getSafeErrorMessage(error: unknown) {
  const message = error instanceof Error ? error.message : "unknown error"
  return message
    .replace(/Bearer\s+\S+/gi, "Bearer [redacted]")
    .replace(/\bsk-[A-Za-z0-9_-]+/g, "[redacted]")
    .slice(0, 300)
}

function getWindowTitle(windowMinutes: number) {
  if (windowMinutes % 1440 === 0) return `${windowMinutes / 1440}d`
  if (windowMinutes % 60 === 0) return `${windowMinutes / 60}h`
  return `${windowMinutes}m`
}

function getPercentageMetric(window: RateLimitWindow | null | undefined) {
  if (typeof window?.usedPercent !== "number" || typeof window.windowDurationMins !== "number") {
    return null
  }

  const usedPercent = Math.max(0, Math.min(window.usedPercent, 100))
  const formattedPercent = usedPercent.toFixed(1).replace(/\.0$/, "")
  return {
    title: getWindowTitle(window.windowDurationMins),
    formattedValue: `${formattedPercent}%`,
    normalizedValue: Math.round((usedPercent / 100) * 10000) / 10000,
  }
}

function getUpdatedMetric(now: Date) {
  const pad = (value: number) => String(value).padStart(2, "0")
  return {
    title: "Updated",
    formattedValue: `${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}`,
  }
}

function stopChild(child: ReturnType<typeof spawn>) {
  if (child.exitCode !== null || child.signalCode !== null) return Promise.resolve()

  return new Promise<void>((resolve) => {
    let completed = false
    const complete = () => {
      if (completed) return
      completed = true
      clearTimeout(killTimer)
      resolve()
    }
    const killTimer = setTimeout(() => {
      if (child.exitCode === null && child.signalCode === null) child.kill("SIGKILL")
    }, 500)

    child.once("close", complete)
    child.kill("SIGTERM")
    if (child.exitCode !== null || child.signalCode !== null) complete()
  })
}

function startRateLimitRequest() {
  let cancelRequest = async () => {}
  const promise = new Promise<RateLimits>((resolve, reject) => {
    const timeoutMilliseconds = getNumericSetting("RUNCAT_CODEX_TIMEOUT_MS", 15000, 100, 60000)
    const child = spawn(getCodexPath(), ["app-server", "--stdio"], {
      stdio: ["pipe", "pipe", "ignore"],
    })
    let buffer = ""
    let outputBytes = 0
    let settled = false
    let finishPromise: Promise<void> | null = null

    const finish = (error?: Error, rateLimits?: RateLimits) => {
      if (settled) return finishPromise ?? Promise.resolve()
      settled = true
      clearTimeout(timer)
      child.stdin.end()
      child.stdout.destroy()
      finishPromise = stopChild(child).then(() => {
        if (error) reject(error)
        else resolve(rateLimits ?? {})
      })
      return finishPromise
    }

    const timer = setTimeout(() => finish(new Error("Codex app-server request timed out")), timeoutMilliseconds)
    cancelRequest = () => finish(new Error("Codex app-server request cancelled"))

    child.on("error", (error) => finish(error))
    child.on("exit", (code) => {
      if (!settled) finish(new Error(`Codex app-server exited before responding (${code ?? "unknown"})`))
    })
    child.stdout.on("data", (chunk) => {
      outputBytes += chunk.length
      if (outputBytes > 1024 * 1024) {
        void finish(new Error("Codex app-server response exceeded 1 MB"))
        return
      }
      buffer += String(chunk)
      let newlineIndex
      while ((newlineIndex = buffer.indexOf("\n")) >= 0) {
        const line = buffer.slice(0, newlineIndex)
        buffer = buffer.slice(newlineIndex + 1)
        if (!line) continue

        let message
        try {
          message = JSON.parse(line)
        } catch {
          continue
        }

        if (message.id === 1) {
          child.stdin.write(`${JSON.stringify({ method: "initialized", params: {} })}\n`)
          child.stdin.write(`${JSON.stringify({ method: "account/rateLimits/read", id: 2 })}\n`)
        }
        if (message.id === 2) {
          if (message.error) finish(new Error(message.error.message ?? "Codex rate-limit query failed"))
          else finish(undefined, message.result?.rateLimits)
        }
      }
    })

    child.stdin.write(
      `${JSON.stringify({
        method: "initialize",
        id: 1,
        params: { clientInfo: { name: "opencode-runcat", version: "1.0.0" } },
      })}\n`,
    )
  })

  return {
    promise,
    stop: async () => {
      await cancelRequest()
      await promise.catch(() => {})
    },
  }
}

async function writeSnapshot(rateLimits: RateLimits) {
  const quotaMetrics = [rateLimits.primary, rateLimits.secondary]
    .map(getPercentageMetric)
    .filter((metric) => metric !== null)
    .filter((metric, index, metrics) => metrics.findIndex((item) => item.title === metric.title) === index)

  if (quotaMetrics.length === 0) throw new Error("Codex app-server returned no rate-limit windows")

  const now = new Date()
  const outputFile = process.env.RUNCAT_CODEX_OUT_FILE ?? join(homedir(), ".runcat", "codex.json")
  if (!isAbsolute(outputFile)) throw new Error("RunCat output path must be absolute")
  const temporaryFile = join(dirname(outputFile), `.runcat-${process.pid}-${randomUUID()}`)
  const snapshot = {
    title: "Codex",
    symbol: "camera.aperture",
    metricsBarValue: quotaMetrics[0].formattedValue,
    metrics: [...quotaMetrics, getUpdatedMetric(now)],
    lastUpdatedDate: now.toISOString().replace(/\.\d{3}Z$/, "Z"),
  }

  await mkdir(dirname(outputFile), { recursive: true })
  let temporaryHandle
  try {
    temporaryHandle = await open(temporaryFile, "wx", 0o600)
    await temporaryHandle.writeFile(JSON.stringify(snapshot))
    await temporaryHandle.close()
    temporaryHandle = undefined
    await rename(temporaryFile, outputFile)
  } catch (error) {
    await temporaryHandle?.close()
    await rm(temporaryFile, { force: true })
    throw error
  }
}

export const RunCatUsagePlugin: Plugin = async () => {
  let inFlight: Promise<void> | null = null
  let activeRequest: ReturnType<typeof startRateLimitRequest> | null = null
  let lastRefresh = 0

  const hooks = {
    event: async ({ event }: { event: { type: string } }) => {
      if (event.type !== "session.idle") return

      const debounceMilliseconds = getNumericSetting("RUNCAT_REFRESH_DEBOUNCE_MS", 30000, 0, 300000)
      const now = Date.now()
      if (inFlight || now - lastRefresh < debounceMilliseconds) return
      lastRefresh = now

      const request = startRateLimitRequest()
      activeRequest = request
      inFlight = request.promise
        .then(writeSnapshot)
        .catch((error) => console.warn(`[runcat] Codex quota refresh failed: ${getSafeErrorMessage(error)}`))
        .finally(() => {
          if (activeRequest === request) activeRequest = null
          inFlight = null
        })
      await inFlight
    },
    dispose: async () => {
      const pendingRefresh = inFlight
      if (!pendingRefresh) return

      const graceMilliseconds = getNumericSetting("RUNCAT_DISPOSE_GRACE_MS", 10000, 0, 15000)
      await new Promise<void>((resolve) => {
        const timer = setTimeout(resolve, graceMilliseconds)
        pendingRefresh.finally(() => {
          clearTimeout(timer)
          resolve()
        })
      })
      if (inFlight === pendingRefresh) await activeRequest?.stop()
      await pendingRefresh
    },
  }
  return hooks
}
