return {
  {
    "crag666/code_runner.nvim",
    keys = {
      { "<leader>rr", "<cmd>w<CR><cmd>RunCode<CR>", desc = "[R]un Code" },
      { "<leader>rf", "<cmd>w<CR><cmd>RunFile<CR>", desc = "[R]un [F]ile" },
    },
    -- config = true,
    config = function()
      local CXX_FLAGS = "-std=c++20 -Wall -Wextra"
      local C_FLAGS = "-std=c17 -Wall -Wextra"
      require("code_runner").setup({
        filetype = {
          cpp = string.format("clang++ %s $fileName -o $fileNameWithoutExt && ./$fileNameWithoutExt", CXX_FLAGS),
          c = string.format("gcc %s $fileName -o $fileNameWithoutExt && ./$fileNameWithoutExt", C_FLAGS),
          -- cpp = "clang++ -std=c++20 $fileName -o $fileNameWithoutExt && ./$fileNameWithoutExt",
          -- c = "gcc $fileName -o $fileNameWithoutExt && ./$fileNameWithoutExt",
        },
      })
      -- vim.keymap.set("n", "<leader>rr", ":RunCode<CR>", { noremap = true, silent = false })
      -- vim.keymap.set("n", "<leader>rf", ":RunFile<CR>", { noremap = true, silent = false })

      -- local wk = require("which-key")
      -- wk.add({
      --   { "<leader>r", group = "codeRunner" }, -- group
      --   { "<leader>rr", "<cmd>RunCode<CR>", desc = "Run Code" },
      --   { "<leader>rf", "<cmd>RunFile<CR>", desc = "Run File" },
      -- })
    end,
  },
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "cancel", "fallback" },
        -- ["<C-e>"] = { "cancel" },
        -- ["<Esc>"] = { "hide", "fallback" },
        ["<Enter>"] = { "fallback" },

        ["<Tab>"] = {
          function(cmp)
            if cmp.snippet_active() then
              return cmp.accept()
            else
              return cmp.select_and_accept()
            end
          end,
          "snippet_forward",
          "fallback",
        },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },

        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback_to_mappings" },
        ["<C-n>"] = { "select_next", "fallback_to_mappings" },

        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },

        ["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
      },
    },
  },
}
