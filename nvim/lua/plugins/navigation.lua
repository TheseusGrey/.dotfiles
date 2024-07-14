return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
		config = function()
			require("telescope").load_extension("fzf")
		end,
		keys = {
			{ "<leader>ff", require("telescope.builtin").find_files, desc = "Find Files" },
			{ "<leader><leader>", require("telescope.builtin").git_files, desc = "Find Git Files" },
			{ "<leader>fg", require("telescope.builtin").live_grep, desc = "Grep files" },
		},
	},
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		keys = {
			{
				"s",
				function()
					require("flash").jump()
				end,
				mode = { "n", "x", "o" },
				desc = "Search text",
			},
			{
				"S",
				function()
					require("flash").treesitter()
				end,
				mode = { "n", "x", "o" },
				desc = "Search Treesitter textobjects",
			},
		},
	},
	{
		"echasnovski/mini.ai",
		event = "VeryLazy",
		version = false,
	},
	{
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
	},
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
		},
		config = function()
			local harpoon = require("harpoon")
			harpoon:setup({})

			-- basic telescope configuration
			local conf = require("telescope.config").values
			local function toggle_telescope(harpoon_files)
				local file_paths = {}
				for _, item in ipairs(harpoon_files.items) do
					table.insert(file_paths, item.value)
				end

				require("telescope.pickers")
					.new({}, {
						prompt_title = "Harpoon",
						previewer = conf.file_previewer({}),
						sorter = conf.generic_sorter({}),
						finder = require("telescope.finders").new_table({
							results = file_paths,
						}),
					})
					:find()
			end
			vim.keymap.set("n", "<leader>ha", function()
				harpoon:list():add()
			end)
			vim.keymap.set("n", "<leader>hl", function()
				toggle_telescope(harpoon:list())
			end, { desc = "Open harpoon window" })
			vim.keymap.set("n", "<leader>hq", function()
				harpoon:list():select(1)
			end)
			vim.keymap.set("n", "<leader>hw", function()
				harpoon:list():select(2)
			end)
			vim.keymap.set("n", "<leader>he", function()
				harpoon:list():select(3)
			end)
			vim.keymap.set("n", "<leader>hr", function()
				harpoon:list():select(4)
			end)
		end,
	},
  {
    "yuramoto/w3m.vim",
    event = "VeryLazy",
    url = "git@github.com:yuratomo/w3m.vim.git",
    keys = {
      { "<leader>wo", function()
        local url = vim.fn.expand('<cfile>')
        vim.cmd("W3m " .. url)
      end, desc = "Open URL in buffer" },
    },
  },
}
