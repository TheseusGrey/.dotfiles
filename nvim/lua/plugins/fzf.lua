local find = function()
  if not require("fzf-lua").git_files() then
    require("fzf-lua").find()
  end
end

return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    fzf_colors = true,
  },
  keys = {
    { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find Files" },
    { "<leader><leader>", find, desc = "Find Git Files, fallback to find all files" },
    { "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Grep files" },
    { "<leader>gd", "<cmd>FzfLua lsp_definitions", mode = { "n", "v" }, desc = "Goto Definition" },
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
