return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    keymap = {
      fzf = {
        ["ctrl-q"] = "select-all+accept",
      },
    },
    defaults = {
      formatter = "path.filename_first",
    },
    fzf_colors = true,
    fzf_opts = {
      ["-1"] = true,
    },
  },
  keys = {
    { "<leader>ff", "<cmd>FzfLua git_files<cr>", desc = "Find Git files" },
    { "<leader><leader>", "<cmd>FzfLua files", desc = "Find Files" },
    { "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Grep files" },
    { "<leader>gd", "<cmd>FzfLua lsp_definitions<cr>", mode = { "n", "v" }, desc = "Goto Definition" },
    { "<leader>gr", "<cmd>FzfLua lsp_references<cr>", mode = { "n", "v" }, desc = "Goto references" },
    {
      "<leader>gI",
      "<cmd>FzfLua lsp_implementations<cr>",
      mode = { "n", "v" },
      desc = "Goto Implementation",
    },
    {
      "<leader>gy",
      "<cmd>FzfLua lsp_typedefs<cr>",
      mode = { "n", "v" },
      desc = "Goto Type Definition",
    },
  },
}
