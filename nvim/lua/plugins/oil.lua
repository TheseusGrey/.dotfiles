return {
  {
    "stevearc/oil.nvim",
    event = "VeryLazy",
    opts = {
      default_file_explorer = true,
      view_options = {
        show_hidden = true,
      },
      keymaps = {
        ["q"] = { "actions.close", mode = "n" },
      },
    },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      {
        "<leader>e",
        "<CMD>Oil<CR>",
        desc = "file Explorer",
      },
    },
  },
  {
    "benomahony/oil-git.nvim",
    event = "VeryLazy",
    dependencies = {},
  },
}
