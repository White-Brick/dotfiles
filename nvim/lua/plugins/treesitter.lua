return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "c",
        "cpp",
        "cmake",
        "gitignore",
        "lua",
        "python",
      },
      highlight = { enable = true },
      indent = { enable = true },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-mini/mini.icons",
    },
    keys = {
      { "<leader>mp", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle Markdown Render" },
      { "<leader>mb", "<cmd>RenderMarkdown buf_toggle<cr>", desc = "Toggle Markdown Render-buf" },
      { "<leader>ms", "<cmd>RenderMarkdown preview<cr>", desc = "Markdown Preview Side Buffer" },
      { "<leader>me", "<cmd>RenderMarkdown expand<cr>", desc = "Expand Markdown Margin" },
      { "<leader>mc", "<cmd>RenderMarkdown contract<cr>", desc = "Contract Markdown Margin" },
    },
  },
}
