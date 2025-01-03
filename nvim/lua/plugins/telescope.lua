return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },
  config = function()
    local t = require("telescope")

    t.load_extension("fzf")
    t.setup({
      defaults = {
        path_display = function(opts, path)
          local tail = require("telescope.utils").path_tail(path)
          return string.format("%s (%s)", tail, path)
        end,
      },
    })
  end,
  keys = {
    { "<leader>ff", require("telescope.builtin").find_files, desc = "Find Files" },
    { "<leader><leader>", require("telescope.builtin").git_files, desc = "Find Git Files" },
    { "<leader>fg", require("telescope.builtin").live_grep, desc = "Grep files" },
    { "<leader>gd", require("telescope.builtin").lsp_definitions, mode = { "n", "v" }, desc = "Goto Definition" },
    { "<leader>gr", require("telescope.builtin").lsp_references, mode = { "n", "v" }, desc = "Goto references" },
    {
      "<leader>gI",
      require("telescope.builtin").lsp_implementations,
      mode = { "n", "v" },
      desc = "Goto Implementation",
    },
    {
      "<leader>gy",
      require("telescope.builtin").lsp_type_definitions,
      mode = { "n", "v" },
      desc = "Goto Type Definition",
    },
  },
}
