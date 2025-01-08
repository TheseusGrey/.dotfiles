return {
  {
    "AlexvZyl/nordic.nvim",
    lazy = true,
    config = function() end,
  },
  {
    "catppuccin/nvim",
    lazy = false,
    enabled = true,
    name = "catppuccin",
    priority = 1000,
    config = function()
      local palette = require("nordic.colors.nordic")

      require("catppuccin").setup({
        flavour = "mocha",
        color_overrides = {
          mocha = {
            text = palette.white0_reduce_blue,
            surface0 = palette.gray3,
            surface1 = palette.gray4,
            surface2 = palette.gray5,
            base = palette.black2,
            mantle = palette.black1,
            crust = palette.black0,
            red = palette.red.base,
            yellow = palette.yellow.base,
            sapphire = palette.blue0,
            blue = palette.blue1,
            lavender = palette.magenta.bright,
            teal = palette.blue2,
            green = palette.green.base,
          },
        },

        integrations = {
          cmp = true,
          dashboard = true,
          flash = true,
          gitsigns = true,
          headlines = true,
          indent_blankline = { enabled = true },
          leap = true,
          lsp_trouble = true,
          mason = true,
          markdown = true,
          mini = true,
          native_lsp = {
            enabled = true,
            underlines = {
              errors = { "undercurl" },
              hints = { "undercurl" },
              warnings = { "undercurl" },
              information = { "undercurl" },
            },
          },
          noice = true,
          notify = true,
          semantic_tokens = true,
          telescope = true,
          treesitter = true,
          treesitter_context = true,
          which_key = true,
        },
      })

      require("catppuccin").load()
    end,
  },
}
