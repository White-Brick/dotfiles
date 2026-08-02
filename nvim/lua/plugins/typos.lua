-- Markdown 不跑 typos_lsp（不 attach），避免中文粘贴增量 didChange 切碎 UTF-8
-- 其它 filetype 保持默认增量同步；typos.toml 的 [type.md] 作双保险
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        typos_lsp = {
          init_options = {
            config = vim.fn.expand("~/.config/typos.toml"),
          },
        },
      },
    },
    init = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("typos_lsp_skip_markdown", { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client or client.name ~= "typos_lsp" then
            return
          end
          if vim.bo[args.buf].filetype ~= "markdown" then
            return
          end
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(args.buf) then
              pcall(vim.lsp.buf_detach_client, args.buf, client.id)
            end
          end)
        end,
      })
    end,
  },
}
