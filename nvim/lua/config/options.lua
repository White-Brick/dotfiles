-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Disable mouse
-- vim.opt.mouse = ""

-- no number
-- vim.opt.number = false

vim.opt.backup = false
vim.opt.wrap = false
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.listchars = { tab = "→ ", trail = "·" }
-- Disable log output
vim.lsp.set_log_level("off")
