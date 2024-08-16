return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "c",
        "cpp",
        "cmake",
        "gitignore",
        "lua",
        "python",
      },
      highlight = { enable = true },
      indent = { enable = true },
    },
  },
}
