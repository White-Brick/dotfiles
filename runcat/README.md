# RunCat Neo 指标

所有 RunCat Neo 运行 JSON 统一存放在 `~/.runcat/`：

- `~/.runcat/codex.json`：由 Codex Stop hook 更新的账号额度。
- `~/.runcat/markets.json`：在同一张卡片中显示 Bitcoin 和 Gold（XAU）。

本目录的市场更新器基于 [RunCat Neo 官方 Bitcoin 示例](https://github.com/runcat-dev/RunCatNeo/tree/main/docs/samples/bitcoin)，每 10 分钟更新组合市场卡片。BTC 与 XAU 均以美元显示，使用千分位并保留两位小数。Bitcoin 优先使用 CoinGecko 的 BTC/USD，接口不可用时使用 XAUS 的 `btc_usd`；Gold 使用 XAUS 的 XAU/USD 现货价。

## Codex 额度

Codex hook 基于 [RunCat Neo 官方 Codex 示例](https://github.com/runcat-dev/RunCatNeo/tree/main/docs/samples/codex)，定制为显示账号额度及其下一次刷新时间、不显示 Context。菜单栏优先显示第一个可用额度窗口。

安装文件级符号链接与本机 hooks（`hooks.json` 含绝对路径，不进 Git）：

```bash
mkdir -p ~/.codex ~/.runcat
ln -sf ~/.config/runcat/codex-hook.py ~/.codex/runcat-hook.py

# 每台机器各自创建 hooks.json（绝对路径，勿写 $HOME）
cat > ~/.config/codex/hooks.json <<EOF
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.codex/runcat-hook.py",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
EOF
ln -sf ~/.config/codex/hooks.json ~/.codex/hooks.json
```

Codex 不经 shell 直接 exec hook 命令，因此必须用绝对路径（官方示例同样如此）。

重启 Codex 后，通过 `/hooks` 检查并信任该 hook。完成一轮对话后会生成 `~/.runcat/codex.json`。若 `/hooks` 不可用，在 `~/.codex/config.toml` 加 `hooks = true` 后重启。

不要链接整个 `~/.codex`：该目录还包含会话、缓存及其他本机状态。

## OpenCode 额度

`opencode/plugins/runcat-usage.ts` 监听 OpenCode 的 `session.idle` 事件，在每轮对话结束后通过本机 Codex app-server 查询账号额度，并原子更新同一个 `~/.runcat/codex.json`。插件不读取 OAuth 文件；查询失败时保留上一次快照。

OpenCode 退出时默认最多等待额度查询 10 秒；慢机器可通过 `RUNCAT_DISPOSE_GRACE_MS` 调整为 `0` 到 `15000` 毫秒。

安装或更新插件后需要完全退出并重启 OpenCode。可运行确定性测试：

```bash
node --disable-warning=MODULE_TYPELESS_PACKAGE_JSON --test \
  ~/.config/opencode/tests/runcat-usage.test.mjs
```

## 市场价格

```bash
chmod +x ~/.config/runcat/update-markets.sh
~/.config/runcat/update-markets.sh

mkdir -p ~/Library/LaunchAgents
ln -s ~/.config/runcat/dev.runcat.market-prices.plist \
  ~/Library/LaunchAgents/dev.runcat.market-prices.plist
launchctl bootstrap gui/$(id -u) \
  ~/Library/LaunchAgents/dev.runcat.market-prices.plist
```

## RunCat Neo 数据源

在 RunCat Neo 中打开 Settings → Metrics → Custom Metrics，添加：

- `~/.runcat/codex.json`
- `~/.runcat/markets.json`

隐藏目录可通过 `⌘⇧G` 输入完整路径。需要显示菜单栏价格时，在 Metrics Bar 中打开对应数据源的开关。

## 管理市场更新任务

查看任务：

```bash
launchctl print gui/$(id -u)/dev.runcat.market-prices
```

停止任务：

```bash
launchctl bootout gui/$(id -u)/dev.runcat.market-prices
```

只有 Bitcoin 与 Gold 本轮均成功时才原子更新 `markets.json`；任一接口失败或 XAUS 报价不是 `fresh` 时，保留上一次组合快照。
