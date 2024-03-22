return {
  { "nvim-neo-tree/neo-tree.nvim", enabled = false },
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
  {
    "alexghergh/nvim-tmux-navigation",
    config = function()
      local nvim_tmux_nav = require("nvim-tmux-navigation")

      nvim_tmux_nav.setup({
        disable_when_zoomed = true, -- defaults to false
      })
    end,
  },
  --[=[{ // Requred nvim 0.10.0 so we're leaving it out for now
    "Bekaboo/dropbar.nvim",
    -- optional, but required for fuzzy finder support
    dependencies = {
      "nvim-telescope/telescope-fzf-native.nvim",
    },
  },--]=]
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
