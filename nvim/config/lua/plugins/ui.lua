return {
  { "nvim-neo-tree/neo-tree.nvim", enabled = false },
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
  { "junegunn/goyo.vim" },
  { "junegunn/limelight.vim" },
  --[=[{
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
