return {
  -- Disable tokyonight
  {
    enabled = false,
    "tokyonight.nvim",
  },
  -- Disable cappuccin
  {
    enabled = false,
    "catppuccin",
  },
  -- Enable gruvbox
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      terminal_colors = true,
      transparent_mode = false,
      contrast = "",
      overrides = {
        -- 让浮窗背景和普通缓冲区背景一致
        -- NormalFloat = { link = "Normal" },
        -- FloatBorder = { link = "Normal" },
        -- 针对 snacks 终端可能用到的特定高亮组
        SnacksNormal = { link = "Normal" },
        SnacksTerminal = { link = "Normal" },
      },
    },
    config = function(_, opts)
      require("gruvbox").setup(opts)
      vim.cmd.colorscheme("gruvbox")
    end,
  },
  -- Configure Lualine theme
  {
    "nvim-lualine/lualine.nvim",
    -- lazy = true,
    -- priority = 1000,
    opts = {
      -- theme = custom_gruvbox,
      theme = (function()
        local gruvbox_theme = require("lualine.themes.gruvbox_dark")
        gruvbox_theme.insert.a.bg = "#F0E68C" -- "#005f87"
        gruvbox_theme.visual.a.bg = "#808000" -- "#3CB371"
        gruvbox_theme.command.a.bg = "#6495ED"
        return gruvbox_theme
      end)(),
    },
  },
}
