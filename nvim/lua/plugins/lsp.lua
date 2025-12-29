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
          cmd = {
            "clangd",
            -- "/usr/bin/clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders=true",
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
