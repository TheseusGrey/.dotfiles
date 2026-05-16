local gh = require("util.helpers").gh
local is_git_repo = require("util.helpers").is_git_repo

require("config.options")
require("config.terminal")

-- Core Plugin List
vim.pack.add({
  -- { src = gh("saghen/blink.lib") }, -- Enable when migrating over to blink.cmp v2
  { src = gh("AlexvZyl/nordic.nvim") },
  { src = gh("L3MON4D3/LuaSnip") },
  { src = gh("akinsho/bufferline.nvim") },
  { src = gh("archie-judd/blink-cmp-words") },
  { src = gh("catppuccin/nvim") },
  { src = gh("echasnovski/mini.ai") },
  { src = gh("echasnovski/mini.surround") },
  { src = gh("folke/flash.nvim") },
  { src = gh("folke/lazydev.nvim") },
  { src = gh("folke/persistence.nvim") },
  { src = gh("folke/snacks.nvim") },
  { src = gh("folke/which-key.nvim") },
  { src = gh("mason-org/mason.nvim") },
  { src = gh("moyiz/blink-emoji.nvim") },
  { src = gh("neovim/nvim-lspconfig") },
  { src = gh("nvim-lua/plenary.nvim") },
  { src = gh("nvim-lualine/lualine.nvim") },
  { src = gh("nvim-mini/mini.pairs"), version = "stable" },
  { src = gh("nvim-tree/nvim-web-devicons") },
  { src = gh("nvim-treesitter/nvim-treesitter"), version = "main" },
  { src = gh("nvim-treesitter/nvim-treesitter-textobjects"), version = "main" },
  { src = gh("rafamadriz/friendly-snippets") },
  { src = gh("saghen/blink.cmp"), version = vim.version.range("1.*") },
  { src = gh("stevearc/conform.nvim") },
  { src = gh("stevearc/oil.nvim") },
  { src = gh("williamboman/mason-lspconfig.nvim") },
})

if is_git_repo() then
  vim.pack.add({
    { src = gh("benomahony/oil-git.nvim") },
  })
end

require("plugins.colorscheme")
require("plugins.ui")
require("plugins.editor")
require("plugins.lsp")

require("config.keymaps")
require("config.autocmds")
