# ECC + OMO 瘦身结果（2026-07-18）

跨设备可同步的策略快照。控制面：**OMO 独家编排**；ECC 仅提供语言专项注册与非技能 command/runtime 面。
**不改** `~/.claude`（Claude Code ECC 继续用）。

## 原则

1. 编排不与 OMO 双控（无 `orchestrate` / loop-operator / harness-optimizer 注册）
2. CC Switch 独占 OpenCode 技能所有权；SSOT 只能是 `~/.config/cc-switch/skills`
3. OpenCode 技能入口只能是 `~/.config/opencode/skills/<skill>` 的逐技能链接
4. `~/.opencode/skills` 必须不存在且不能是符号链接；工具发现冲突时 fail closed，绝不自动删除或移动
5. ECC 只能安装显式模块 `commands-core,platform-configs`，不得使用默认 profile 或 `--profile opencode`
6. 孤儿 `commands/*.md` 可留磁盘，不注册则不进上下文
7. 主力语言：go / ts / js / python；C++ 降为冷资产

## 所有权边界

| 表面 | 唯一所有者 | 不变量 |
| --- | --- | --- |
| `~/.config/cc-switch/skills` | CC Switch | 50 个 SSOT 技能目录 |
| `~/.config/opencode/skills/<skill>` | CC Switch | 49 个已启用 OpenCode 技能逐项链接到 SSOT |
| `~/.opencode/skills` | 无 | 路径完全不存在 |
| `~/.opencode/commands|prompts|instructions|plugins|dist|scripts` | ECC | 仅由两个显式非技能模块维护 |

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
- 原 11 个 always-on ECC skill 全文已移除；OpenCode 技能只从 CC Switch 逐技能链接发现

### hooks

- `pre:bash:tmux-reminder`：OpenCode 侧禁用（名实不符；OMO 管后台）
- 可用环境变量持久化：`ECC_DISABLED_HOOKS=pre:bash:tmux-reminder`

## 明确不入 git

- `~/.opencode/commands|dist|node_modules|prompts` 非技能安装树
- `~/.opencode/ecc-install-state.json`
- `*.bak*`
- `~/.claude/settings.json`（密钥 + Claude 独立面）

`~/.opencode/skills` 不是“不入 git 的可保留安装树”，而是**必须不存在**的所有权禁区。

## 固定安装方式

```bash
cd ~/.local/share/ECC
node scripts/install-apply.js --target opencode --modules commands-core,platform-configs --dry-run --json > /tmp/ecc-opencode-plan.json
node scripts/install-apply.js --target opencode --modules commands-core,platform-configs --json > /tmp/ecc-opencode-install.json

# 只能在安装成功后运行
~/.config/opencode/scripts/apply-ecc-slim.sh
```

当前 ECC 源版本的 dry-run 是 203 个操作、零 skills 源、零 `~/.opencode/skills` 目标、零 warning。操作数随上游版本改变时必须先解释差异；其余零技能不变量不可放宽。

## 升级验证清单

- [ ] 安装前后 `~/.opencode/skills` 都不存在且不是符号链接
- [ ] dry-run 的 selected modules 集合恰好是 `commands-core,platform-configs`
- [ ] install-state：schema v1、legacyMode=false、profile=null，request/resolution 模块集合均恰好为上述两个
- [ ] 全部 operation 无 `skills/` 源，无等于或位于 `~/.opencode/skills` 下的目标
- [ ] `node scripts/repair.js --target opencode --dry-run --json` 仍计划零技能操作
- [ ] auto-update 仅检查从 state 重建的参数等价于 `--target opencode --modules commands-core,platform-configs`，不实际执行更新
- [ ] 安装后已运行 `apply-ecc-slim.sh`，tracked 与 runtime 配置语义相等，时间戳备份保留
- [ ] CC Switch DB 50/启用 OpenCode 49/quick_check ok；逐技能链接 49、哈希匹配 49、runtime 各出现一次且无技能错误

## 回滚（本机）

```bash
cp ~/.opencode/opencode.json.bak.20260718184123 ~/.opencode/opencode.json
cp ~/.config/opencode/opencode.json.bak.20260718-ecc-trim ~/.config/opencode/opencode.json
cp ~/.config/opencode/ecc-model-overlay.json.bak.20260718-ecc-trim ~/.config/opencode/ecc-model-overlay.json
```
