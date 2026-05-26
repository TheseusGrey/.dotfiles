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
    filetypes = { "codecompanion", "avante" },
    ignore_buftypes = { "markdown" },
  },
  markdown = {
    enable = false,
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

  local cwd = vim.fn.getcwd()
  local name = vim.fn.fnamemodify(cwd, ":t")

  require("obsidian").setup({
    legacy_commands = false,
    workspaces = { { name = name, path = cwd } },

    daily_notes = {
      enabled = false,
    },

    completion = {
      nvim_cmp = false,
      blink = true,
      min_chars = 2,
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
