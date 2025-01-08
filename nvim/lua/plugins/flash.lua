return {
  "folke/flash.nvim",
  enabled = true,
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
}
