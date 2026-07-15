# Codex 配置

## RunCat Neo 指标

本目录跟踪 [RunCat Neo 官方 Codex 示例](https://github.com/runcat-dev/RunCatNeo/tree/main/docs/samples/codex)及其 hook 配置。Codex 每轮结束后会生成本机文件 `~/.codex/runcat-usage.json`。

安装文件级符号链接：

```bash
ln -s ~/.config/codex/runcat-hook.py ~/.codex/runcat-hook.py
ln -s ~/.config/codex/hooks.json ~/.codex/hooks.json
```

重启 Codex 后，通过 `/hooks` 检查并信任该 hook。完成一轮对话后，在 RunCat Neo 中打开 Settings → Metrics → Custom Metrics，点击 Add JSON Source，并选择 `~/.codex/runcat-usage.json`。

不要链接整个 `~/.codex`：该目录还包含会话、缓存及其他本机状态。生成的 `runcat-usage.json` 也不纳入版本控制。
