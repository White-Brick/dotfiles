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
        transparent_mode = false,
        contrast = "soft",
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
}
