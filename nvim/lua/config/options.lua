-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

vim.opt.backup = false
vim.opt.wrap = false
vim.opt.listchars = { tab = "→ ", trail = "·" }
vim.lsp.set_log_level("off")

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.breakindent = true
vim.opt.backspace = { "start", "eol", "indent" }

vim.g.lazyvim_cmp = "blink.cmp"

-- File types
vim.filetype.add({
	extension = {
		tpp = "cpp",
		hpp = "cpp",
	},
})

-- 禁用 LazyVim 默认剪切板管理，使用自定义 OSC 52
vim.g.lazyvim_clipboard = false
vim.opt.clipboard = "unnamedplus"

-- OSC 52 剪切板配置（兼容 SSH + tmux 环境）
-- 注意：nvim 内置 osc52 在 clipboard=unnamedplus 时不会自动启用，需要自定义实现
local function base64_encode(data)
	local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	return (
		(data:gsub(".", function(x)
			local r, b64 = "", x:byte()
			for i = 8, 1, -1 do
				r = r .. (b64 % 2 ^ i - b64 % 2 ^ (i - 1) > 0 and "1" or "0")
			end
			return r
		end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
			if #x < 6 then
				return ""
			end
			local c = 0
			for i = 1, 6 do
				c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
			end
			return b:sub(c + 1, c + 1)
		end) .. ({ "", "==", "=" })[#data % 3 + 1]
	)
end

local function osc52_copy(lines, _)
	local text = table.concat(lines, "\n")
	local encoded = base64_encode(text)
	local osc52 = string.format("\27]52;c;%s\7", encoded)

	-- tmux 环境下需要包装序列（passthrough）
	if vim.env.TMUX then
		osc52 = string.format("\27Ptmux;\27%s\27\\", osc52)
	end

	-- 写入 stderr 发送给终端
	vim.fn.chansend(vim.v.stderr, osc52)
end

vim.g.clipboard = {
	name = "OSC 52",
	copy = {
		["+"] = osc52_copy,
		["*"] = osc52_copy,
	},
	paste = {
		["+"] = function()
			return { vim.fn.split(vim.fn.getreg('"'), "\n") }
		end,
		["*"] = function()
			return { vim.fn.split(vim.fn.getreg('"'), "\n") }
		end,
	},
}
