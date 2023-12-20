return {
  -- tools
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "clangd",
        "clang-format",
      })
    end,
  },
  -- -- Set up lspconfig.
  -- local capabilities = require("cmp_nvim_lsp").default_capabilities()
  -- -- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
  -- require("lspconfig")["clangd"].setup({
  --   capabilities = capabilities,
  -- })

  -- {
  --   "neovim/nvim-lspconfig",
  --   opts = function(_, opts)
  --     -- Add additional capabilities supported by nvim-cmp
  --     -- local on_attach = require("plugins.configs.lspconfig").on_attach
  --     -- local capabilities = require("cmp_nvim_lsp").default_capabilities()
  --     local base = require("cmp_nvim_lsp")
  --     local on_attach = base.on_attach
  --     local capabilities = base.capabilities

  --     local lspconfig = require("lspconfig")

  --     -- Enable some language servers with the additional completion capabilities offered by nvim-cmp
  --     local servers = {
  --       "clangd",
  --       -- 'rust_analyzer',
  --       -- 'pyright',
  --       -- 'tsserver'
  --     }

  --     for _, lsp in ipairs(servers) do
  --       lspconfig[lsp].setup({
  --         -- on_attach = my_custom_on_attach,
  --         on_attach = function(client, bufnr)
  --           client.server_capabilities.signatureHelpProvider = true
  --           on_attach(client, bufnr)
  --         end,
  --         capabilities = capabilities,
  --       })
  --     end
  --   end,
  -- },

  -- lsp servers
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- inlay_hints = { enabled = true },
      -- ---@type lspconfig.options
      servers = {
        clangd = {},
      },
    },
  },
}
