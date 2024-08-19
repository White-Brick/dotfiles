return {
  -- tools
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "clangd",
        "clang-format",
        "black",
        "pyright",
        -- "gopls",
      })
    end,
  },
  -- lsp servers
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- inlay_hints = { enabled = true },
      -- ---@type lspconfig.options
      servers = {
        clangd = {
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=google",
          },
          -- cmd = { "clangd", "--background-index", "--clang-tidy", "--log=verbose" },
          --
          initialization_options = {
            fallback_flags = { "-std=c++20" },
          },
          -- keys = {
          --   { "<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>", desc = "Switch Source/Header (C/C++)" },
          -- },
        },
        pyright = {},
        -- gopls = {},
      },
    },
  },
}
