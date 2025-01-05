return {
  {
    dir = "~/projects/present.nvim",
    opts = {
      integrations = {
        markview = true,
      },
    },
  },
  { -- for pretty markdown styling
    "OXY2DEV/markview.nvim",
    lazy = true,
    ft = "markdown",
    opts = {
      initial_state = false,
    },

    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
  },
}
