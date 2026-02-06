# Dotfiles

我的个人配置文件，按照操作系统分为不同的分支。

## 选择你的系统

### Linux 系统
```bash
# Clone仓库
git clone git@github.com:White-Brick/dotfiles.git

# 切换到Linux分支
git checkout linux
```

Linux分支包含：
- Neovim 配置
- Tmux 配置
- Htop 配置
- Lazygit 配置

### macOS 系统
```bash
# Clone仓库
git clone git@github.com:White-Brick/dotfiles.git

# 切换到macOS分支
git checkout mac
```

macOS分支包含：
- Neovim 配置
- Tmux 配置
- Kitty 终端配置
- Vim 配置
- Zsh 配置
- Zim 框架配置

## 目录说明

- **linux分支**: Linux系统特定配置
- **mac分支**: macOS系统特定配置
- **main分支**: 本分支，仅包含此README说明

## 安装

### 配置文件安装
各分支的配置文件位于 `~/.config/` 目录下。

你可以：
1. 直接将配置文件复制到对应目录
2. 使用软链接指向这些配置文件

### 常用工具
- **Neovim**: 现代化的Vim编辑器
- **Tmux**: 终端复用器
- **Lazygit**: Git的TUI界面
- **Htop**: 交互式进程监控器
- **Kitty**: macOS终端模拟器
- **Zim**: Zsh配置框架

## 跨分支配置同步

某些工具的配置可能在多个分支间共享（如Tmux）：

```bash
# 在mac分支上同步Linux的tmux配置
git checkout mac
git checkout linux -- tmux/tmux.conf
git commit -m "同步tmux配置"
```

## 注意事项

- 各分支独立管理各自系统的配置
- 不要随意merge不同系统的分支
- 只同步通用工具的配置文件（如tmux）
- 保留系统特定的配置差异

## License

MIT License
