# opencode 配置同步

跨设备同步：模型路由、provider、**OMO 主控**、ECC 瘦身注册表、本地插件。  
**不同步**：ECC 非技能安装树（`~/.opencode/commands|dist|node_modules`）、密钥明文、`~/.claude`。

## 技能所有权（强制不变量）

- CC Switch 是 OpenCode 技能的唯一所有者；唯一事实源（SSOT）是 `~/.config/cc-switch/skills`。
- OpenCode 只通过 `~/.config/opencode/skills/<skill>` 的逐技能符号链接使用已启用技能。
- ECC 只拥有 commands、prompts、instructions、plugins、dist、scripts 等**非技能面**。
- `~/.opencode/skills` 必须始终不存在（包括断链符号链接）。发现该路径时禁止自动删除、移动、修复或继续安装，应先人工排查所有权冲突。

## 目录

| 文件 | 作用 |
| --- | --- |
| `opencode.json` | 全局：provider、默认 model、OMO plugin、ECC 语言 agent 模型覆盖 |
| `oh-my-openagent.jsonc` | oh-my-openagent（编排主控；`claude_code.* = false`） |
| `ecc-opencode.json` | **瘦身后的** `~/.opencode/opencode.json` 完整副本（可 git 同步） |
| `ecc-model-overlay.json` | ECC agent 模型表（go/python only） |
| `ecc-omo-slim.md` | 本次 ECC+OMO 瘦身策略与清单 |
| `scripts/apply-ecc-slim.sh` | 新机应用瘦身注册表 |
| `AGENTS.md` | 全局规则 |
| `plugins/rtk.ts` | RTK 命令重写插件 |
| `plugins/runcat-usage.ts` | RunCat 用量插件 |

## 架构（瘦身后）

```text
OpenCode 全局 (~/.config/opencode)
  ├── OMO          → 编排 / 规划 / 审查 / loop（唯一控制面）
  └── ECC overlay  → 仅 go-reviewer / go-build-resolver / python-reviewer 模型

ECC 安装树 (~/.opencode)  ← 用 ecc-install 装，再用 ecc-opencode.json 覆盖注册表
  ├── agents 注册  → 仅上述 3 个语言 agent
  ├── commands     → 22 个纯模板（无 orchestrate，无 agent 双控）
  ├── instructions → 仅 INSTRUCTIONS.md
  └── skills       → 必须不存在；ECC 不拥有 OpenCode 技能

CC Switch 技能面
  ├── SSOT         → ~/.config/cc-switch/skills
  └── OpenCode     → ~/.config/opencode/skills/<skill> 逐技能链接
```

## 新机步骤

```bash
# 1. 装 opencode CLI

# 2. 同步本目录到 ~/.config/opencode/（stow/symlink/git pull）

# 3. 先由 CC Switch 同步技能，确认 SSOT 与逐技能链接健康

# 4. 确认 ECC 技能路径完全不存在（-L 同时捕获断链）
[[ ! -e ~/.opencode/skills && ! -L ~/.opencode/skills ]]

# 5. 只安装 ECC 非技能模块；先审 dry-run，再实际安装
cd ~/.local/share/ECC
node scripts/install-apply.js --target opencode --modules commands-core,platform-configs --dry-run --json > /tmp/ecc-opencode-plan.json
node scripts/install-apply.js --target opencode --modules commands-core,platform-configs --json > /tmp/ecc-opencode-install.json

# 6. 仅在安装成功后恢复本仓库追踪的 slim runtime 配置
cd ~/.config/opencode
bash scripts/apply-ecc-slim.sh

# 7. （建议）shell rc 持久禁用误导 hook
# export ECC_DISABLED_HOOKS=pre:bash:tmux-reminder

# 8. 密钥：本地配 provider / 登录，勿写入 json
```

严禁使用默认 profile，尤其不得运行 `--profile opencode`。默认 profile 会把 ECC skills 写回 `~/.opencode/skills`，并使 repair/auto-update 在以后重复该行为。

## ECC 升级、repair 与 auto-update 检查

每次 ECC 源码升级、repair、auto-update 参数变更或新机恢复都必须检查：

1. 安装前 `~/.opencode/skills` 不存在且不是符号链接；否则 fail closed。
2. 上述 dry-run 的 `selectedModuleIds` 集合恰好是 `commands-core,platform-configs`。当前 ECC 源版本应有 203 个操作；若上游版本改变数量，必须解释差异后再继续。
3. dry-run 中没有 `sourceRelativePath` 位于任何 `skills/` 下，也没有 `destinationPath` 等于或位于 `~/.opencode/skills` 下，且无使计划失效的 warning。
4. 安装后运行 `scripts/apply-ecc-slim.sh`。脚本会在任何备份/复制前校验 install-state 并拒绝技能所有权漂移。
5. install-state 必须满足：`schemaVersion=ecc.install.v1`、`request.profile=null`、`request.legacyMode=false`，且 request/resolution 的模块集合都恰好是上述两个模块。
6. `node scripts/repair.js --target opencode --dry-run --json` 也必须保持零技能操作；auto-update 从 install-state 重建的参数必须仍为 `--target opencode --modules commands-core,platform-configs`。不要用检查流程实际执行 auto-update。
7. 最后复验 CC Switch：DB 为 50 项、OpenCode 启用 49 项、49 个逐技能链接及内容哈希匹配，OpenCode runtime 中 49 个迁移技能各出现一次且无技能错误。

### 仅 merge 模型（不覆盖完整注册表）

```bash
cd ~/.config/opencode
node -e '
const fs=require("fs");
const path=require("path");
const home=path.join(process.env.HOME,".opencode/opencode.json");
const overlay=JSON.parse(fs.readFileSync("ecc-model-overlay.json","utf8"));
const cfg=JSON.parse(fs.readFileSync(home,"utf8"));
cfg.model=overlay.model;
cfg.small_model=overlay.small_model;
cfg.agent=cfg.agent||{};
for (const [k,v] of Object.entries(overlay.agent||{})) {
  cfg.agent[k]={...(cfg.agent[k]||{}), ...v};
}
fs.writeFileSync(home, JSON.stringify(cfg,null,2)+"\n");
console.log("merged ecc models into", home);
'
```

## 说明

- 自定义 provider 仅保留可同步的结构；**无明文 apiKey**
- oh-my 里的模型 id 需本机已配置对应 provider
- Claude Code ECC 独立：`~/.claude` 不在本目录同步范围
- ECC 的 repair/auto-update 会从 `~/.opencode/ecc-install-state.json` 的 request 重算计划，因此显式模块状态是长期安全边界，不得手改成 profile
- 策略细节见 `ecc-omo-slim.md`
