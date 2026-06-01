local gh = require("util.helpers").gh
local helpers = require("util.helpers")
local is_git_repo = require("util.helpers").is_git_repo

require("config.options")
require("config.terminal")

-- Core Plugin List
vim.pack.add({
  { src = gh("AlexvZyl/nordic.nvim") },
  { src = gh("L3MON4D3/LuaSnip") },
  { src = gh("akinsho/bufferline.nvim") },
  { src = gh("archie-judd/blink-cmp-words") },
  { src = gh("catppuccin/nvim") },
  { src = gh("echasnovski/mini.ai") },
  { src = gh("echasnovski/mini.surround") },
  { src = gh("j-hui/fidget.nvim") },
  { src = gh("folke/flash.nvim") },
  { src = gh("folke/lazydev.nvim") },
  { src = gh("folke/persistence.nvim") },
  { src = gh("folke/snacks.nvim") },
  { src = gh("folke/which-key.nvim") },
  { src = gh("mason-org/mason.nvim") },
  { src = gh("moyiz/blink-emoji.nvim") },
  { src = gh("mfussenegger/nvim-dap") },
  { src = gh("mfussenegger/nvim-jdtls") },
  { src = gh("igorlfs/nvim-dap-view") },
  { src = gh("neovim/nvim-lspconfig") },
  { src = gh("numToStr/FTerm.nvim") },
  { src = gh("nvim-lua/plenary.nvim") },
  { src = gh("nvim-lualine/lualine.nvim") },
  { src = gh("oribarilan/lensline.nvim") },
  { src = gh("nvim-mini/mini.pairs"), version = "stable" },
  { src = gh("nvim-tree/nvim-web-devicons") },
  { src = gh("nvim-treesitter/nvim-treesitter"), version = "main" },
  { src = gh("nvim-treesitter/nvim-treesitter-textobjects"), version = "main" },
  { src = gh("rafamadriz/friendly-snippets") },
  { src = gh("saghen/blink.cmp"), version = vim.version.range("1.*") },
  { src = gh("stevearc/conform.nvim") },
  { src = gh("stevearc/oil.nvim") },
  { src = gh("williamboman/mason-lspconfig.nvim") },
  { src = gh("obsidian-nvim/obsidian.nvim"), version = vim.version.range("*") },
  { src = gh("oflisback/obsidian-bridge.nvim") },
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
require("plugins.debug")

require("config.keymaps")
require("config.autocmds")

if helpers.is_obsidian_vault() then
  local map = vim.keymap.set
  local ui = require("util.ui")

  local keymaps = require("util.keymaps")

  local cwd = vim.fn.getcwd()
  local name = vim.fn.fnamemodify(cwd, ":t")

  require("obsidian").setup({
    legacy_commands = false,
    workspaces = {
      { name = name, path = cwd },
      {
        name = "personal",
        path = "~/projects/LoreStore", -- Ensure this points exactly to your vault
      },
    },

    completion = {
      nvim_cmp = false,
      blink = true,
      min_chars = 2,
    },

    daily_notes = {
      enabled = false,
    },

    link = {
      auto_update = true,
    },

    footer = {
      enabled = true,
      format = "{{properties}} properties  {{words}} words  {{chars}} chars",
      hl_group = "Comment",
      separator = string.rep("─", ui.screen().width),
    },

    new_notes_location = "current_dir",
    templates = {
      folder = "_templates",
    },

    frontmatter = {
      enabled = true,
      sort = { "id", "key", "aliases", "tags" },
      func = function(note)
        local key = note.key
        if key == nil then
          key = helpers.generate_uuid()
        end

        if note.title then
          note:add_alias(note.title)
        end

        local out = { key = key, aliases = note.aliases, tags = note.tags }

        -- `note.metadata` contains any manually added fields in the frontmatter.
        -- So here we just make sure those fields are kept in the frontmatter.
        if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
          for k, v in pairs(note.metadata) do
            out[k] = v
          end
        end

        return out
      end,
    },

    picker = {
      name = "snacks.pick",
    },
  })

  require("obsidian-bridge").setup()

  local wk = require("which-key")

  wk.add({
    { "<leader>o", group = "+obsidian", desc = "" },
  })

  map("n", keymaps.obsidian("t"), "<CMD>Obsidian template<CR>", { desc = "Obsidian: insert Template" })
  map(
    "n",
    keymaps.obsidian("T"),
    "<CMD>Obsidian new_note_from_template<CR>",
    { desc = "Obsidian: new note from Template" }
  )
  map("n", keymaps.obsidian("s"), "<CMD>Obsidian tags<CR>", { desc = "Obsidian: Search tags" })
end
