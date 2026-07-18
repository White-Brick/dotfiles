#!/usr/bin/env bash
# apply-ecc-slim: copy tracked ecc-opencode.json onto ~/.opencode/opencode.json
# usage: bash scripts/apply-ecc-slim.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export ROOT
ECC_HOME="${HOME}/.opencode"
ECC_CFG="${ECC_HOME}/opencode.json"
SLIM_CFG="${ROOT}/ecc-opencode.json"
OVERLAY="${ROOT}/ecc-model-overlay.json"

if [[ ! -f "${SLIM_CFG}" ]]; then
  echo "missing ${SLIM_CFG}" >&2
  exit 1
fi

if [[ ! -d "${ECC_HOME}" ]]; then
  echo "ECC not installed: ${ECC_HOME} missing. Run ecc-install first." >&2
  exit 1
fi

ts="$(date +%Y%m%d%H%M%S)"
if [[ -f "${ECC_CFG}" ]]; then
  cp "${ECC_CFG}" "${ECC_CFG}.bak.apply-slim.${ts}"
  echo "backup: ${ECC_CFG}.bak.apply-slim.${ts}"
fi

cp "${SLIM_CFG}" "${ECC_CFG}"
echo "wrote ${ECC_CFG} from ecc-opencode.json"

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

echo "optional shell rc: export ECC_DISABLED_HOOKS=pre:bash:tmux-reminder"
echo "done. open a new OpenCode session."
