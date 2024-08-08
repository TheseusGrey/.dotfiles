return {
	"akinsho/bufferline.nvim",
	event = "VeryLazy",
	version = "*",
	dependencies = "nvim-tree/nvim-web-devicons",
	config = function(_, opts)
		local map = vim.keymap.set

		map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
		map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
		map("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
		map("n", "]b", "<cmd>bnext<cr>", { desc = "Next Buffer" })
		map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
		map("n", "<leader>`", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
		map("n", "<leader>bd", "<cmd>bd<CR>", { desc = "Delete Buffer" })
		map("n", "<leader>bD", "<cmd>:bd<cr>", { desc = "Delete Buffer and Window" })
		require("bufferline").setup(opts)
	end,
}
