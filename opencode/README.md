# opencode 配置同步

跨设备同步：模型路由、provider、oh-my 与本地插件。  
**不同步**：ECC 安装树（`~/.opencode/skills|commands|dist`）、密钥明文。

## 目录

| 文件 | 作用 |
| --- | --- |
| `opencode.json` | 全局：provider、默认 model、ECC agent 模型覆盖 |
| `ecc-model-overlay.json` | 纯 ECC agent 模型表；`ecc-install` 后可 merge 回 `~/.opencode/opencode.json` |
| `oh-my-opencode.json` | oh-my-opencode agent/category 模型 |
| `oh-my-openagent.jsonc` | oh-my-openagent 配置 |
| `AGENTS.md` | 全局规则 |
| `plugins/rtk.ts` | RTK 命令重写插件 |

## 新机步骤

```bash
# 1. 装 opencode CLI，导出密钥（勿写入 json）
export ZHIPUAI_CODING_PLAN_API_KEY='...'

# 2. 装 ECC 到 ~/.opencode（按你平时的方式）
# npx ecc-install ... 或 ECC install.sh

# 3. 同步本目录到 ~/.config/opencode/
# 若用 stow/symlink，确保 opencode/ 链到此处

# 4. （可选）把 ECC 模型写回安装树，防止 home 配置覆盖全局
node -e '
const fs=require("fs");
const path=require("path");
const home=path.join(process.env.HOME,".opencode/opencode.json");
const overlay=JSON.parse(fs.readFileSync("ecc-model-overlay.json","utf8"));
const cfg=JSON.parse(fs.readFileSync(home,"utf8"));
cfg.model=overlay.model;
cfg.small_model=overlay.small_model;
if(overlay.default_agent) cfg.default_agent=overlay.default_agent;
cfg.agent=cfg.agent||{};
for (const [k,v] of Object.entries(overlay.agent||{})) {
  cfg.agent[k]={...(cfg.agent[k]||{}), ...v};
}
fs.writeFileSync(home, JSON.stringify(cfg,null,2)+"\n");
console.log("merged ecc models into", home);
'
```

## 密钥

`opencode.json` 使用 `{env:ZHIPUAI_CODING_PLAN_API_KEY}`，在 shell 或私密 env 文件中设置。
