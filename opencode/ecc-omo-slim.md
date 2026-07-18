# ECC + OMO 瘦身结果（2026-07-18）

跨设备可同步的策略快照。控制面：**OMO 独家编排**；ECC 仅作语言专项 + 按需 skill/command 库。  
**不改** `~/.claude`（Claude Code ECC 继续用）。

## 原则

1. 编排不与 OMO 双控（无 `orchestrate` / loop-operator / harness-optimizer 注册）
2. `api-design` / `frontend-patterns` / `backend-patterns` 等 skill **按需**（不进 `instructions[]`）
3. 孤儿 `commands/*.md` 可留磁盘，不注册则不进上下文
4. 主力语言：go / ts / js / python；C++ 降为冷资产

## 同步文件（本目录 git）

| 文件 | 内容 |
| --- | --- |
| `opencode.json` | 全局 OpenCode：provider、默认 model、OMO plugin、3 个 ECC 语言 agent 模型覆盖 |
| `oh-my-openagent.jsonc` | OMO agents/categories；`claude_code.* = false` |
| `ecc-model-overlay.json` | 仅 go/python agent 模型表（merge 用） |
| `ecc-opencode.json` | 瘦身后的 `~/.opencode/opencode.json` 完整副本 |
| `scripts/apply-ecc-slim.sh` | 新机：覆盖 ECC 注册表 + 合并模型 + 禁用 tmux-reminder |
| `AGENTS.md` / `plugins/*` | 全局规则与本地插件 |

## ECC 注册面（`ecc-opencode.json`）

### agents（DAILY，仅 3）

- `go-reviewer`
- `go-build-resolver`
- `python-reviewer`

### agents（LIBRARY，不注册；prompt 仍在 `~/.opencode/prompts/agents/`）

- `doc-updater`、`refactor-cleaner`（已确认 LIBRARY）
- `e2e-runner`、`database-reviewer`、`build-error-resolver`、`cpp-*` 等

### agents（OpenCode 注销，防双控/非主力）

- `build`、`planner`、`architect`、`code-reviewer`、`security-reviewer`、`tdd-guide`
- `harness-optimizer`、`loop-operator`、`docs-lookup`
- `java-*`、`kotlin-*`、`php-reviewer`、`rust-*`

### commands

- **已注册 22**：plan/tdd/code-review/security/build-fix/e2e/refactor-clean/learn/checkpoint/verify/eval/update-docs/update-codemaps/test-coverage/setup-pm/skill-create/instinct-*/evolve/promote/projects
- **全部为纯模板**（无 `agent`/`subtask`，避免拉起已注销 ECC agent）
- **已注销**：`orchestrate`
- **孤儿 md**：磁盘可保留，不进 git

### instructions

- 仅 `instructions/INSTRUCTIONS.md`
- 原 11 个 always-on skill 全文已移除 → `skills/` 按需 `skill()`

### hooks

- `pre:bash:tmux-reminder`：OpenCode 侧禁用（名实不符；OMO 管后台）
- 可用环境变量持久化：`ECC_DISABLED_HOOKS=pre:bash:tmux-reminder`

## 明确不入 git

- `~/.opencode/skills|commands|dist|node_modules|prompts` 安装树
- `~/.opencode/ecc-install-state.json`
- `*.bak*`
- `~/.claude/settings.json`（密钥 + Claude 独立面）

## 回滚（本机）

```bash
cp ~/.opencode/opencode.json.bak.20260718184123 ~/.opencode/opencode.json
cp ~/.config/opencode/opencode.json.bak.20260718-ecc-trim ~/.config/opencode/opencode.json
cp ~/.config/opencode/ecc-model-overlay.json.bak.20260718-ecc-trim ~/.config/opencode/ecc-model-overlay.json
```
