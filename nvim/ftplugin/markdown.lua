local gh = require("util.helpers").gh
local is_obsidian_vault = require("util.helpers").is_obsidian_vault
local keymaps = require("util.keymaps")
local map = vim.keymap.set

-- PLUGINS --
vim.pack.add({
  { src = gh("OXY2DEV/markview.nvim") },
})

local local_plugin = vim.fn.expand("~/projects/present.nvim")
if vim.fn.isdirectory(local_plugin) == 1 then
  vim.opt.runtimepath:prepend(local_plugin)
else
  vim.pack.add({
    { src = gh("TheseusGrey/present.nvim") },
  })
end

local presets = require("markview.presets")
vim.g.markview_blink_loaded = true

require("markview").setup({
  preview = {
    enable = false,
    filetypes = { "codecompanion", "avante" },
    ignore_buftypes = { "markdown" },
  },
  markdown = {
    horizontal_rules = presets.horizontal_rules.thin,
    headings = presets.headings.marker,
  },
})

require("present").setup({
  integrations = {
    markview = true,
  },
})

map("n", keymaps.present("s"), "<CMD>PresentStart<CR>", { desc = "Presentation Start" })
map("n", keymaps.present("r"), "<CMD>PresentResume<CR>", { desc = "Presentation Resume" })

if is_obsidian_vault() then
  vim.pack.add({
    { src = gh("obsidian-nvim/obsidian.nvim"), version = vim.version.range("*") },
    { src = gh("oflisback/obsidian-bridge.nvim") },
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

-- MARKDOWN SPECIFIC CONFIG --
vim.opt_local.textwidth = 85
vim.opt_local.colorcolumn = "85"
