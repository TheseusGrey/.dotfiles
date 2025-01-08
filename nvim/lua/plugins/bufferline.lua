return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = "nvim-tree/nvim-web-devicons",
  config = function()
    local map = vim.keymap.set

    map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
    map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
    map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
    map("n", "<leader>bd", "<cmd>bd<CR>", { desc = "Delete Buffer" })
    map("n", "<leader>bo", "<cmd>BufferLineCloseOthers<CR>", { desc = "Delete Other Buffers" })
    map("n", "<leader>bh", "<cmd>BufferLineCloseLeft<CR>", { desc = "Delete Buffers to the Left" })
    map("n", "<leader>bl", "<cmd>BufferLineCloseRight<CR>", { desc = "Delete Buffers to the right" })
    map("n", "<leader>bp", "<cmd>BufferLinePick<CR>", { desc = "Pick from list of open buffers" })
    require("bufferline").setup({
      options = {
        diagnostics = "nvim_lsp",
        show_buffer_close_icons = false,
      },
    })
  end,
}
