return {
  {
    "TheseusGrey/present.nvim",
    dev = true,
    dir = "~/projects/present.nvim",
    dependencies = {
      "OXY2DEV/markview.nvim",
    },
    ft = "markdown",
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
        preview = {
          enable = false,
        },
        markdown = {
          horizontal_rules = presets.horizontal_rules.thin,
          headings = presets.headings.marker,
        },
      })
    end,

    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<leader>Ps", "<cmd>PresentStart<cr>", desc = "Start Presentation" },
      { "<leader>Pr", "<cmd>PresentResume<cr>", desc = "Resume Presentation" },
    },
  },
}
