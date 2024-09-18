local palette = {
    none = 'NONE',
    -- Blacks. Not in base Nord.
    black0 = '#191D24',
    black1 = '#1E222A',
    black2 = '#222630',
    -- Grays
    gray0 = '#242933', -- bg
    gray1 = '#2E3440',
    gray2 = '#3B4252',
    gray3 = '#434C5E',
    gray4 = '#4C566A',
    -- A light blue/gray.
    gray5 = '#60728A',
    -- Dim white.
    white0_normal = '#BBC3D4',
    white0_reduce_blue = '#C0C8D8',
    -- Snow storm.
    white1 = '#D8DEE9',
    white2 = '#E5E9F0',
    white3 = '#ECEFF4',
    -- Frost.
    blue0 = '#5E81AC',
    blue1 = '#81A1C1',
    blue2 = '#88C0D0',

    cyan = {
        base = '#8FBCBB',
        bright = '#9FC6C5',
        dim = '#80B3B2',
    },

    -- Aurora.
    red = {
        base = '#BF616A',
        bright = '#C5727A',
        dim = '#B74E58',
    },
    orange = {
        base = '#D08770',
        bright = '#D79784',
        dim = '#CB775D',
    },
    yellow = {
        base = '#EBCB8B',
        bright = '#EFD49F',
        dim = '#E7C173',
    },
    green = {
        base = '#A3BE8C',
        bright = '#B1C89D',
        dim = '#97B67C',
    },
    magenta = {
        base = '#B48EAD',
        bright = '#BE9DB8',
        dim = '#A97EA1',
    },
}

return {
	{
		"AlexvZyl/nordic.nvim",
		lazy = false,
    enabled = false,
		priority = 1000,
		config = function()
			require("nordic").setup({
				bold_keywords = true,
			})
			require("nordic").load()
		end,
	},
	{
		"catppuccin/nvim",
		lazy = false,
    enabled = true,
		name = "catppuccin",
		priority = 1000,
    config = function()
      require("catppuccin").setup {
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
		}

    require("catppuccin").load()
    end,
	},
}
