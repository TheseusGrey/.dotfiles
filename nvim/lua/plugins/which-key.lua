return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "helix",
    delay = 140,
    triggers = {
      { "<leader>", mode = { "n", "v" } },
    },
  },
}
