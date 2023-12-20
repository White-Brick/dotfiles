return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "c",
        "cpp",
        "cmake",
      },
      highlight = { enable = true },
      indent = { enable = true },
    },
  },
}
