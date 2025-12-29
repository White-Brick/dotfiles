return {
  -- animations
  {
    "nvim-mini/mini.animate",
    event = "VeryLazy",
    opts = function(_, opts)
      opts.scroll = {
        enable = false,
      }
    end,
  },
  {
    "rcarriga/nvim-notify",
    opts = {
      timeout = 5000,
    },
  },
}
