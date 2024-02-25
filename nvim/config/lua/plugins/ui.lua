local function default_config_function(PluginSpec)
  local options = nil

  if type(PluginSpec.opts) == "function" then
    options = PluginSpec.opts(PluginSpec)
  elseif type(PluginSpec.opts) ~= "nil" then
    options = PluginSpec.opts
  end

  require(PluginSpec.main).setup(options)
end

return {
  { "nvim-neo-tree/neo-tree.nvim", enabled = false },
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
  {
    "junegunn/goyo.vim",
    opts = {
      goyo_width = 120,
    },
    config = default_config_function,
    keys = {
      { "<leader>fo", "<cmd>Goyo<CR>", desc = "Toggle focus editing" },
    },
  },
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
