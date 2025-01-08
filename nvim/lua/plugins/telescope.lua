local find = function()
  if not pcall(require("telescope.builtin").git_files) then
    require("telescope.builtin").find_files()
  end
end

return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8",
  enabled = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },
  config = function()
    local t = require("telescope")

    t.load_extension("fzf")
    t.setup({
      defaults = {
        path_display = function(_, path)
          local tail = require("telescope.utils").path_tail(path)
          return string.format("%s (%s)", tail, path)
        end,
      },
    })
  end,
  keys = {
    { "<leader>ff", require("telescope.builtin").find_files, desc = "Find Files" },
    { "<leader><leader>", find, desc = "Find Git Files, fallback to find all files" },
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
