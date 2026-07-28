-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here
local formatoptions_group = vim.api.nvim_create_augroup("user_formatoptions", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = formatoptions_group,
  pattern = "*",
  callback = function()
    vim.opt_local.formatoptions:remove({ "r", "o" })
  end,
})
