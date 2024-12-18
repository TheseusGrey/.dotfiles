return {
  "folke/snacks.nvim",
  opts = {
    gitbrowse = { enabled = true },
    input = { enabled = true },
    lazygit = { enabled = true },
    quickfile = { enabled = true },
    dim = { enabled = true },
    statuscolumn = { enabled = true },
    zen = { enabled = true },
    dashboard = {
      enabled = true,
      sections = {
        { section = "header" },
        { icon = " ", title = "Keymaps", section = "keys", indent = 2, padding = 1 },
        { icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
        { section = "startup" },
      },
    },
  },
  keys = {
    {
      "<leader>fo",
      function()
        local s = require("snacks")
        s.zen()
        s.dim()
      end,
      desc = "Toggle focus editing",
    },
  },
}
