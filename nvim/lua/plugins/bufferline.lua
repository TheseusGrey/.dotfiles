return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = "nvim-tree/nvim-web-devicons",
  config = function(_, opts)
    local map = vim.keymap.set

    map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
    map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
    map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
    map("n", "<leader>bd", "<cmd>bd<CR>", { desc = "Delete Buffer" })
    map("n", "<leader>bo", "<cmd>BufferLineCloseOthers<CR>", { desc = "Delete Other Buffers" })
    map("n", "<leader>bh", "<cmd>BufferLineCloseLeft<CR>", { desc = "Delete Buffers to the Left" })
    map("n", "<leader>bl", "<cmd>BufferLineCloseRight<CR>", { desc = "Delete Buffers to the right" })
    require("bufferline").setup(opts)
  end,
}
