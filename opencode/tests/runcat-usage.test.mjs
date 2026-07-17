import assert from "node:assert/strict"
import { chmod, mkdtemp, readFile, rm, writeFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"
import test from "node:test"

import { RunCatUsagePlugin } from "../plugins/runcat-usage.ts"

async function createFakeCodex(directory) {
  const executable = join(directory, "codex")
  await writeFile(
    executable,
    `#!/usr/bin/env node
import { appendFileSync } from "node:fs"
if (process.env.FAKE_COUNT_FILE) appendFileSync(process.env.FAKE_COUNT_FILE, "started\\n")
if (process.env.FAKE_PID_FILE) appendFileSync(process.env.FAKE_PID_FILE, String(process.pid))
process.on("SIGTERM", () => {
  if (process.env.FAKE_TERMINATED_FILE) appendFileSync(process.env.FAKE_TERMINATED_FILE, "terminated\\n")
  if (process.env.FAKE_CODEX_MODE === "ignore-term") return
  process.exit(0)
})
if (process.env.FAKE_READY_FILE) appendFileSync(process.env.FAKE_READY_FILE, "ready\\n")
let buffer = ""
let initialized = false
process.stdin.on("data", (chunk) => {
  buffer += chunk
  let newline
  while ((newline = buffer.indexOf("\\n")) >= 0) {
    const line = buffer.slice(0, newline)
    buffer = buffer.slice(newline + 1)
    if (!line) continue
    const message = JSON.parse(line)
    if (message.method === "initialize") {
      console.log(JSON.stringify({ id: message.id, result: { userAgent: "test" } }))
    }
    if (message.method === "initialized") initialized = true
    if (message.method === "account/rateLimits/read") {
      if (!initialized) {
        console.log(JSON.stringify({ id: message.id, error: { code: -32600, message: "not initialized" } }))
      } else if (process.env.FAKE_CODEX_MODE === "hang" || process.env.FAKE_CODEX_MODE === "ignore-term") {
        continue
      } else if (process.env.FAKE_CODEX_MODE === "error") {
        console.log(JSON.stringify({ id: message.id, error: { code: -32603, message: "unavailable" } }))
      } else {
        console.log(JSON.stringify({
          id: message.id,
          result: {
            rateLimits: {
              primary: { usedPercent: 52, windowDurationMins: 10080, resetsAt: 1784682509 },
              secondary: null
            }
          }
        }))
      }
    }
  }
})
`,
  )
  await chmod(executable, 0o755)
  return executable
}

async function createFixture() {
  const directory = await mkdtemp(join(tmpdir(), "opencode-runcat-"))
  const output = join(directory, "codex.json")
  const codex = await createFakeCodex(directory)
  process.env.CODEX_CLI_PATH = codex
  process.env.RUNCAT_CODEX_OUT_FILE = output
  process.env.RUNCAT_REFRESH_DEBOUNCE_MS = "0"
  delete process.env.FAKE_CODEX_MODE
  return { directory, output }
}

async function waitForFile(path) {
  for (let attempt = 0; attempt < 100; attempt += 1) {
    try {
      await readFile(path)
      return
    } catch {
      await new Promise((resolve) => setTimeout(resolve, 20))
    }
  }
  throw new Error(`Timed out waiting for ${path}`)
}

test("session.idle 查询额度并写入 RunCat JSON", async () => {
  const fixture = await createFixture()
  try {
    const hooks = await RunCatUsagePlugin({})
    await hooks.event({ event: { type: "session.idle", properties: { sessionID: "session-1" } } })

    const snapshot = JSON.parse(await readFile(fixture.output, "utf8"))
    assert.equal(snapshot.title, "Codex")
    assert.equal(snapshot.metricsBarValue, "52%")
    assert.deepEqual(snapshot.metrics[0], {
      title: "7d",
      formattedValue: "52%",
      normalizedValue: 0.52,
    })
    const resetDate = new Date(1784682509 * 1000)
    const pad = (value) => String(value).padStart(2, "0")
    assert.deepEqual(snapshot.metrics[1], {
      title: "7d Reset",
      formattedValue: `${pad(resetDate.getMonth() + 1)}-${pad(resetDate.getDate())} ${pad(resetDate.getHours())}:${pad(resetDate.getMinutes())}`,
    })
  } finally {
    await rm(fixture.directory, { recursive: true, force: true })
  }
})

test("非 session.idle 事件不查询额度", async () => {
  const fixture = await createFixture()
  try {
    const hooks = await RunCatUsagePlugin({})
    await hooks.event({ event: { type: "session.status", properties: {} } })
    await assert.rejects(readFile(fixture.output, "utf8"), { code: "ENOENT" })
  } finally {
    await rm(fixture.directory, { recursive: true, force: true })
  }
})

test("额度查询失败时保留旧快照", async () => {
  const fixture = await createFixture()
  const previous = '{"title":"Existing"}'
  try {
    await writeFile(fixture.output, previous)
    process.env.FAKE_CODEX_MODE = "error"
    const originalWarn = console.warn
    console.warn = () => {}
    const hooks = await RunCatUsagePlugin({})
    try {
      await hooks.event({ event: { type: "session.idle", properties: { sessionID: "session-2" } } })
      assert.equal(await readFile(fixture.output, "utf8"), previous)
    } finally {
      console.warn = originalWarn
    }
  } finally {
    delete process.env.FAKE_CODEX_MODE
    await rm(fixture.directory, { recursive: true, force: true })
  }
})

test("并发 idle 事件只启动一个 app-server", async () => {
  const fixture = await createFixture()
  const countFile = join(fixture.directory, "count.log")
  try {
    process.env.FAKE_COUNT_FILE = countFile
    const hooks = await RunCatUsagePlugin({})
    await Promise.all([
      hooks.event({ event: { type: "session.idle", properties: { sessionID: "session-3" } } }),
      hooks.event({ event: { type: "session.idle", properties: { sessionID: "session-4" } } }),
    ])
    assert.equal((await readFile(countFile, "utf8")).trim().split("\n").length, 1)
  } finally {
    delete process.env.FAKE_COUNT_FILE
    await rm(fixture.directory, { recursive: true, force: true })
  }
})

test("查询超时会终止 app-server 并保留旧快照", async () => {
  const fixture = await createFixture()
  const terminatedFile = join(fixture.directory, "terminated.log")
  const readyFile = join(fixture.directory, "ready.log")
  const previous = '{"title":"Existing"}'
  try {
    await writeFile(fixture.output, previous)
    process.env.FAKE_CODEX_MODE = "hang"
    process.env.FAKE_TERMINATED_FILE = terminatedFile
    process.env.FAKE_READY_FILE = readyFile
    process.env.RUNCAT_CODEX_TIMEOUT_MS = "1000"
    const originalWarn = console.warn
    console.warn = () => {}
    const hooks = await RunCatUsagePlugin({})
    try {
      await hooks.event({ event: { type: "session.idle", properties: { sessionID: "session-5" } } })
    } finally {
      console.warn = originalWarn
    }
    assert.equal(await readFile(fixture.output, "utf8"), previous)
    assert.match(await readFile(terminatedFile, "utf8"), /terminated/)
  } finally {
    delete process.env.FAKE_CODEX_MODE
    delete process.env.FAKE_TERMINATED_FILE
    delete process.env.FAKE_READY_FILE
    delete process.env.RUNCAT_CODEX_TIMEOUT_MS
    await rm(fixture.directory, { recursive: true, force: true })
  }
})

test("dispose 会终止活动 app-server", async () => {
  const fixture = await createFixture()
  const terminatedFile = join(fixture.directory, "terminated.log")
  const readyFile = join(fixture.directory, "ready.log")
  try {
    process.env.FAKE_CODEX_MODE = "hang"
    process.env.FAKE_TERMINATED_FILE = terminatedFile
    process.env.FAKE_READY_FILE = readyFile
    process.env.RUNCAT_CODEX_TIMEOUT_MS = "10000"
    process.env.RUNCAT_DISPOSE_GRACE_MS = "0"
    const originalWarn = console.warn
    console.warn = () => {}
    const hooks = await RunCatUsagePlugin({})
    try {
      const refresh = hooks.event({ event: { type: "session.idle", properties: { sessionID: "session-6" } } })
      await waitForFile(readyFile)
      assert.equal(typeof hooks.dispose, "function")
      await hooks.dispose()
      await refresh
    } finally {
      console.warn = originalWarn
    }
    assert.match(await readFile(terminatedFile, "utf8"), /terminated/)
  } finally {
    delete process.env.FAKE_CODEX_MODE
    delete process.env.FAKE_TERMINATED_FILE
    delete process.env.FAKE_READY_FILE
    delete process.env.RUNCAT_CODEX_TIMEOUT_MS
    delete process.env.RUNCAT_DISPOSE_GRACE_MS
    await rm(fixture.directory, { recursive: true, force: true })
  }
})

test("dispose 会等待正在完成的额度刷新", async () => {
  const fixture = await createFixture()
  try {
    process.env.RUNCAT_DISPOSE_GRACE_MS = "5000"
    const hooks = await RunCatUsagePlugin({})
    const refresh = hooks.event({ event: { type: "session.idle", properties: { sessionID: "session-10" } } })
    await hooks.dispose()
    await refresh
    const snapshot = JSON.parse(await readFile(fixture.output, "utf8"))
    assert.equal(snapshot.metricsBarValue, "52%")
  } finally {
    delete process.env.RUNCAT_DISPOSE_GRACE_MS
    await rm(fixture.directory, { recursive: true, force: true })
  }
})

test("拒绝相对 CODEX_CLI_PATH 并保留旧快照", async () => {
  const fixture = await createFixture()
  const previous = '{"title":"Existing"}'
  try {
    await writeFile(fixture.output, previous)
    process.env.CODEX_CLI_PATH = "codex"
    const originalWarn = console.warn
    console.warn = () => {}
    const hooks = await RunCatUsagePlugin({})
    try {
      await hooks.event({ event: { type: "session.idle", properties: { sessionID: "session-7" } } })
    } finally {
      console.warn = originalWarn
    }
    assert.equal(await readFile(fixture.output, "utf8"), previous)
  } finally {
    await rm(fixture.directory, { recursive: true, force: true })
  }
})

test("拒绝 world-writable Codex 可执行文件", async () => {
  const fixture = await createFixture()
  const previous = '{"title":"Existing"}'
  try {
    await writeFile(fixture.output, previous)
    await chmod(process.env.CODEX_CLI_PATH, 0o777)
    const originalWarn = console.warn
    console.warn = () => {}
    const hooks = await RunCatUsagePlugin({})
    try {
      await hooks.event({ event: { type: "session.idle", properties: { sessionID: "session-8" } } })
    } finally {
      console.warn = originalWarn
    }
    assert.equal(await readFile(fixture.output, "utf8"), previous)
  } finally {
    await rm(fixture.directory, { recursive: true, force: true })
  }
})

test("app-server 忽略 SIGTERM 时升级为 SIGKILL", async () => {
  const fixture = await createFixture()
  const pidFile = join(fixture.directory, "pid.log")
  try {
    process.env.FAKE_CODEX_MODE = "ignore-term"
    process.env.FAKE_PID_FILE = pidFile
    process.env.RUNCAT_CODEX_TIMEOUT_MS = "500"
    const originalWarn = console.warn
    console.warn = () => {}
    const hooks = await RunCatUsagePlugin({})
    try {
      await hooks.event({ event: { type: "session.idle", properties: { sessionID: "session-9" } } })
    } finally {
      console.warn = originalWarn
    }
    const pid = Number(await readFile(pidFile, "utf8"))
    assert.throws(() => process.kill(pid, 0), { code: "ESRCH" })
  } finally {
    delete process.env.FAKE_CODEX_MODE
    delete process.env.FAKE_PID_FILE
    delete process.env.RUNCAT_CODEX_TIMEOUT_MS
    await rm(fixture.directory, { recursive: true, force: true })
  }
})
