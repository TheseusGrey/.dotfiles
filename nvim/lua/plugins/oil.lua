return {
	"stevearc/oil.nvim",
	event = "VeryLazy",
	opts = {
		default_file_explorer = true,
		view_options = {
			show_hidden = true,
		},
	},
	dependencies = { "nvim-tree/nvim-web-devicons" },
	keys = {
		{
			"<leader>e",
			function()
				require("oil").open()
			end,
			desc = "file Explorer",
		},
		{
			"q",
			function()
				require("oil").close()
			end,
			desc = "close Explorer",
		},
	},
}
