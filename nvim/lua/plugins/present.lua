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
    config = function()
      local presets = require("markview.presets")

      require("markview").setup({
        horizontal_rules = presets.horizontal_rules.thin,
        headings = presets.headings.marker,
        initial_state = false,
      })
    end,

    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
  },
}
