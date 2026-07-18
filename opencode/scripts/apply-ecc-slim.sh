#!/usr/bin/env bash
# apply-ecc-slim：用已追踪的 ecc-opencode.json 覆盖 ~/.opencode/opencode.json
# 用法：bash scripts/apply-ecc-slim.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export ROOT
ECC_HOME="${HOME}/.opencode"
ECC_CFG="${ECC_HOME}/opencode.json"
ECC_STATE="${ECC_HOME}/ecc-install-state.json"
ECC_SKILLS="${ECC_HOME}/skills"
SLIM_CFG="${ROOT}/ecc-opencode.json"
OVERLAY="${ROOT}/ecc-model-overlay.json"

if [[ -e "${ECC_SKILLS}" || -L "${ECC_SKILLS}" ]]; then
  echo "拒绝应用 slim 配置：${ECC_SKILLS} 已存在或是符号链接。请先人工确认所有权冲突；脚本不会删除或移动任何内容。" >&2
  exit 1
fi

if [[ ! -f "${SLIM_CFG}" ]]; then
  echo "缺少已追踪的 slim 配置：${SLIM_CFG}" >&2
  exit 1
fi

if [[ ! -d "${ECC_HOME}" ]]; then
  echo "ECC 尚未安装：缺少 ${ECC_HOME}。请先用显式模块运行 ECC 安装器。" >&2
  exit 1
fi

node - "${ECC_STATE}" "${ECC_SKILLS}" <<'NODE'
const fs = require("fs");
const path = require("path");

const statePath = process.argv[2];
const skillsRoot = path.resolve(process.argv[3]);
const allowedModules = ["commands-core", "platform-configs"];

function fail(message) {
  throw new Error(message);
}

function hasExactModules(value) {
  return Array.isArray(value)
    && value.length === allowedModules.length
    && allowedModules.every((moduleId) => value.includes(moduleId));
}

function isSkillsSource(sourceRelativePath) {
  if (typeof sourceRelativePath !== "string" || sourceRelativePath.length === 0) {
    fail("install-state 含无效的 sourceRelativePath");
  }
  return sourceRelativePath.split(/[\\/]+/).filter(Boolean).includes("skills");
}

function isAtOrInside(candidatePath, rootPath) {
  if (typeof candidatePath !== "string" || candidatePath.length === 0) {
    fail("install-state 含无效的 destinationPath");
  }
  const resolvedCandidate = path.resolve(candidatePath);
  const relative = path.relative(rootPath, resolvedCandidate);
  const firstSegment = relative.split(path.sep)[0];
  return relative === "" || (firstSegment !== ".." && !path.isAbsolute(relative));
}

try {
  if (!fs.existsSync(statePath)) {
    fail(`缺少 ECC install-state：${statePath}`);
  }
  const state = JSON.parse(fs.readFileSync(statePath, "utf8"));
  if (state.schemaVersion !== "ecc.install.v1") {
    fail("install-state schemaVersion 必须是 ecc.install.v1");
  }
  if (state.request?.legacyMode !== false) {
    fail("install-state request.legacyMode 必须是 false");
  }
  if (state.request?.profile !== null) {
    fail("install-state request.profile 必须是 null；禁止使用默认 profile");
  }
  if (!hasExactModules(state.request?.modules)) {
    fail(`install-state request.modules 必须且只能包含 ${allowedModules.join(",")}`);
  }
  if (!hasExactModules(state.resolution?.selectedModules)) {
    fail(`install-state resolution.selectedModules 必须且只能包含 ${allowedModules.join(",")}`);
  }
  if (!Array.isArray(state.operations)) {
    fail("install-state operations 必须是数组");
  }
  for (const [index, operation] of state.operations.entries()) {
    if (!operation || typeof operation !== "object") {
      fail(`install-state operations[${index}] 不是有效对象`);
    }
    if (isSkillsSource(operation.sourceRelativePath)) {
      fail(`install-state operations[${index}] 的源路径位于 skills/ 下`);
    }
    if (isAtOrInside(operation.destinationPath, skillsRoot)) {
      fail(`install-state operations[${index}] 的目标位于 ${skillsRoot} 内`);
    }
  }
  console.log("已验证 ECC install-state：仅 commands-core,platform-configs，且无技能操作");
} catch (error) {
  console.error(`拒绝应用 slim 配置：${error.message}`);
  process.exit(1);
}
NODE

ts="$(date +%Y%m%d%H%M%S)"
if [[ -f "${ECC_CFG}" ]]; then
  BACKUP_CFG="${ECC_CFG}.bak.apply-slim.${ts}"
  if [[ -e "${BACKUP_CFG}" || -L "${BACKUP_CFG}" ]]; then
    echo "拒绝覆盖既有备份：${BACKUP_CFG}" >&2
    exit 1
  fi
  cp "${ECC_CFG}" "${BACKUP_CFG}"
  chmod 600 "${BACKUP_CFG}"
  echo "backup: ${BACKUP_CFG}"
fi

cp "${SLIM_CFG}" "${ECC_CFG}"
chmod 600 "${ECC_CFG}"
echo "已从 ecc-opencode.json 写入 ${ECC_CFG}"

if [[ -f "${OVERLAY}" ]]; then
  node <<'NODE'
const fs = require("fs");
const path = require("path");
const root = process.env.ROOT;
if (!root) throw new Error("ROOT env missing");
const home = path.join(process.env.HOME, ".opencode/opencode.json");
const overlay = JSON.parse(fs.readFileSync(path.join(root, "ecc-model-overlay.json"), "utf8"));
const cfg = JSON.parse(fs.readFileSync(home, "utf8"));
if (overlay.model) cfg.model = overlay.model;
if (overlay.small_model) cfg.small_model = overlay.small_model;
cfg.agent = cfg.agent || {};
for (const [k, v] of Object.entries(overlay.agent || {})) {
  cfg.agent[k] = { ...(cfg.agent[k] || {}), ...v };
}
fs.writeFileSync(home, JSON.stringify(cfg, null, 2) + "\n");
console.log("merged ecc-model-overlay.json into", home);
NODE
fi

echo "可选 shell rc：export ECC_DISABLED_HOOKS=pre:bash:tmux-reminder"
echo "完成。请开启新的 OpenCode 会话。"
