local custom_gruvbox = require("lualine.themes.gruvbox_dark")
-- Change the background of lualine_c section for normal mode
-- custom_gruvbox.normal.a.bg = "#005f87"
custom_gruvbox.insert.a.bg = "#F0E68C"
-- custom_gruvbox.visual.a.bg = "#3CB371"
custom_gruvbox.visual.a.bg = "#808000"
custom_gruvbox.command.a.bg = "#6495ED"

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
    lazy = true,
    priority = 1000,
    opts = function()
      return {
        terminal_colors = true,
        transparent_mode = false,
        contrast = "soft",
        palette_overrides = {},
      }
    end,
  },

  -- Configure LazyVim to load gruvbox
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },

  -- Configure Lualine theme
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      theme = custom_gruvbox,
    },
  },
}
