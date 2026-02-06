-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Disable mouse
-- vim.opt.mouse = ""

-- no number
-- vim.opt.number = false

vim.opt.backup = false
vim.opt.wrap = false
-- vim.opt.tabstop = 4
-- vim.opt.shiftwidth = 4
vim.opt.listchars = { tab = "→ ", trail = "·" }
-- Disable lsp.log output
vim.lsp.set_log_level("off")

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.autoindent = true -- 自动缩进
vim.opt.smartindent = true -- 智能缩进（特别适合 C 语言）
vim.opt.expandtab = true -- 将 Tab 转为空格
vim.opt.smarttab = true -- Tab 键行为受 `shiftwidth` 控制
vim.opt.shiftwidth = 2 -- 每一级缩进占用 2 个空格
vim.opt.tabstop = 2 -- Tab 键显示宽度为 2 空格
vim.opt.breakindent = true -- 换行时保留缩进
vim.opt.backspace = { "start", "eol", "indent" } -- 回退键行为：允许删除缩进、换行等

-- vim.g.lazyvim_picker = "telescope" -- 设置 fuzzy picker 为 telescope（也支持 fzf-lua）
vim.g.lazyvim_cmp = "blink.cmp" -- 设置自动补全引擎（自定义插件名）

-- File types
vim.filetype.add({
  extension = {
    tpp = "cpp",
    hpp = "cpp",
  },
})
