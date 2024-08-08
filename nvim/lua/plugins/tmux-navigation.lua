return {
	"alexghergh/nvim-tmux-navigation",
	config = function()
		local nvim_tmux_nav = require("nvim-tmux-navigation")

		nvim_tmux_nav.setup({
			disable_when_zoomed = true, -- defaults to false
		})
	end,
	keys = {
		{
			"<C-h>",
			function()
				require("nvim-tmux-navigation").NvimTmuxNavigateLeft()
			end,
		},
		{
			"<C-j>",
			function()
				require("nvim-tmux-navigation").NvimTmuxNavigateDown()
			end,
		},
		{
			"<C-k>",
			function()
				require("nvim-tmux-navigation").NvimTmuxNavigateUp()
			end,
		},
		{
			"<C-l>",
			function()
				require("nvim-tmux-navigation").NvimTmuxNavigateRight()
			end,
		},
		{
			"<C-\\>",
			function()
				require("nvim-tmux-navigation").NvimTmuxNavigateLastActive()
			end,
		},
		{
			"<C-Space>",
			function()
				require("nvim-tmux-navigation").NvimTmuxNavigateNext()
			end,
		},
	},
}
