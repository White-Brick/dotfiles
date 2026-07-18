# opencode 配置同步

跨设备同步：模型路由、provider、**OMO 主控**、ECC 瘦身注册表、本地插件。  
**不同步**：ECC 安装树（`~/.opencode/skills|commands|dist|node_modules`）、密钥明文、`~/.claude`。

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
  ├── instructions → 仅 INSTRUCTIONS.md（skill 按需）
  └── skills/commands 磁盘全文可留，不进 git
```

## 新机步骤

```bash
# 1. 装 opencode CLI

# 2. 同步本目录到 ~/.config/opencode/（stow/symlink/git pull）

# 3. 装 ECC 到 ~/.opencode（按你平时的方式）
#    npx ecc-install ... 或 ECC install.sh

# 4. 应用本仓库追踪的瘦身结果
cd ~/.config/opencode
bash scripts/apply-ecc-slim.sh

# 5. （建议）shell rc 持久禁用误导 hook
# export ECC_DISABLED_HOOKS=pre:bash:tmux-reminder

# 6. 密钥：本地配 provider / 登录，勿写入 json
```

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
- 策略细节见 `ecc-omo-slim.md`
