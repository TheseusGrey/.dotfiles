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

    keys = {
      { "<leader>Ps", "<cmd>PresentStart<cr>", desc = "Start Presentation" },
      { "<leader>Pr", "<cmd>PresentResume<cr>", desc = "Resume Presentation" },
    },
  },
  { -- for pretty markdown styling
    "OXY2DEV/markview.nvim",
    dependencies = {
      "saghen/blink.cmp",
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    lazy = true,
    ft = "markdown",
    priority = 49,
    config = function()
      local presets = require("markview.presets")
      vim.g.markview_blink_loaded = true

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
  },
}
