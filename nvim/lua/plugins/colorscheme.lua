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
  -- Add gruvbox
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      terminal_colors = true,
      transparent_mode = false,
      contrast = "soft",
      palette_overrides = {},
      overrides = {},
    },
    config = function()
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
