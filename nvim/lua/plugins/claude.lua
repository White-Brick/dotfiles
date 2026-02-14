return {
	"coder/claudecode.nvim",
	dependencies = { "folke/snacks.nvim" },
	opts = {
		terminal = {
			provider = "snacks",
			snacks_win_opts = {
				-- position = "float",
				border = "rounded",
				style = "minimal",
				-- width = 0.8,
				-- height = 0.7,
				-- wo = {
				-- 	winblend = 10,
				-- },
			},
		},
	},
	cmd = "ClaudeCode",
	keys = {
		-- 在普通模式和可视模式下打开 Claude Code
		-- { "<c-/>", "<cmd>ClaudeCode<cr>", mode = { "n", "v" }, desc = "Claude Code" },
		-- 在终端模式下，<c-,> 也触发 toggle
		-- { "<c-,>", "<cmd>ClaudeCode<cr>", mode = "t", desc = "Toggle Claude" },
		-- 终端模式下按 <Esc> 退出到普通模式
		-- { "<esc>", [[<C-\><C-n>]], mode = "t", desc = "Exit terminal mode", expr = true },
		-- 或者用 <leader>q 关闭
		-- { "<leader>aq", "<cmd>ClaudeCodeClose<cr>", mode = "n", desc = "Close Claude" },
	},
}
