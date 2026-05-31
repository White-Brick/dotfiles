return {
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {},
      -- automatic_installation = false,
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          mason = false,
          cmd = {
            "/opt/homebrew/opt/llvm/bin/clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders=true",  -- 修复：clangd 22.1.5 需要明确的布尔值
            "--query-driver=/opt/homebrew/opt/llvm/bin/clang++",
            "--fallback-style=llvm",
          },
          init_options = {
            completion = { includeComments = false },
            -- fallbackFlags = { "-std=c++20" },
          },
        },
      },
    },
  },
}
