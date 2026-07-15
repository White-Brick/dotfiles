# RunCat Neo 指标

所有 RunCat Neo 运行 JSON 统一存放在 `~/.runcat/`：

- `~/.runcat/codex.json`：由 Codex Stop hook 更新的账号额度。
- `~/.runcat/bitcoin.json`：优先使用 CoinGecko 的 BTC/USD；CoinGecko 限流或不可用时使用 XAUS 的 `btc_usd`。
- `~/.runcat/gold.json`：XAUS 的 XAU/USD 现货价，单位为美元/金衡盎司。

本目录的市场更新器基于 [RunCat Neo 官方 Bitcoin 示例](https://github.com/runcat-dev/RunCatNeo/tree/main/docs/samples/bitcoin)，每 10 分钟更新 Bitcoin 和黄金两个 Custom Metrics 数据源。

## Codex 额度

Codex hook 基于 [RunCat Neo 官方 Codex 示例](https://github.com/runcat-dev/RunCatNeo/tree/main/docs/samples/codex)，定制为只显示账号额度、不显示 Context。菜单栏优先显示第一个可用额度窗口。

安装文件级符号链接：

```bash
ln -s ~/.config/codex/runcat-hook.py ~/.codex/runcat-hook.py
ln -s ~/.config/codex/hooks.json ~/.codex/hooks.json
```

重启 Codex 后，通过 `/hooks` 检查并信任该 hook。完成一轮对话后会生成 `~/.runcat/codex.json`。

不要链接整个 `~/.codex`：该目录还包含会话、缓存及其他本机状态。

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

在 RunCat Neo 中打开 Settings → Metrics → Custom Metrics，分别添加：

- `~/.runcat/codex.json`
- `~/.runcat/bitcoin.json`
- `~/.runcat/gold.json`

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

脚本独立更新两个数据源。单个接口失败不会阻止另一个更新；失败的数据源保留最后一次成功快照。XAUS 报价不是 `fresh` 时不会覆盖现有黄金价格。
