# Codex 配置

## RunCat Neo 指标

本目录基于 [RunCat Neo 官方 Codex 示例](https://github.com/runcat-dev/RunCatNeo/tree/main/docs/samples/codex)跟踪 hook 配置，并定制为只显示账号额度、不显示 Context。菜单栏优先显示第一个可用额度窗口。Codex 每轮结束后会生成统一管理的本机文件 `~/.runcat/codex.json`。

安装文件级符号链接：

```bash
ln -s ~/.config/codex/runcat-hook.py ~/.codex/runcat-hook.py
ln -s ~/.config/codex/hooks.json ~/.codex/hooks.json
```

重启 Codex 后，通过 `/hooks` 检查并信任该 hook。完成一轮对话后，在 RunCat Neo 中打开 Settings → Metrics → Custom Metrics，点击 Add JSON Source，并选择 `~/.runcat/codex.json`。

不要链接整个 `~/.codex`：该目录还包含会话、缓存及其他本机状态。生成的 `~/.runcat/codex.json` 也不纳入版本控制。
