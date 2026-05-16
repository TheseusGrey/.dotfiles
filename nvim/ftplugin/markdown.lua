local gh = require("util.helpers").gh
local is_obsidian_vault = require("util.helpers").is_obsidian_vault
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

require("present").setup({
  integrations = {
    markview = true,
  },
})

map("n", "<leader>ps", "<CMD>presentstart<CR>", { desc = "Presentation Start" })
map("n", "<leader>pr", "<CMD>presentresume<CR>", { desc = "Presentation Resume" })

if is_obsidian_vault() then
  vim.pack.add({
    { src = gh("obsidian-nvim/obsidian.nvim"), version = vim.version.range("*") },
    { src = gh("oflisback/obsidian-bridge.nvim") },
  })
end

-- MARKDOWN SPECIFIC CONFIG --
vim.opt_local.textwidth = 85
vim.opt_local.colorcolumn = "85"
