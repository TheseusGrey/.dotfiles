local helpers = require("util.helpers")
local vault_location = vim.fn.expand("~") .. "/Documents/Lore Store"

return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*", -- recommended, use latest release instead of latest commit
    event = {
      "BufReadPre " .. vault_location .. "/*.md",
      "BufNewFile " .. vault_location .. "/*.md",
    },
    opts = {
      legacy_commands = false,
      workspaces = {
        {
          name = "personal",
          path = vault_location,
        },
      },

      daily_notes = {
        folder = "Notes/Dailies",
        default_tags = { "daily" },
        -- Optional, if you want to automatically insert a template from your template directory like 'daily.md'
        template = "Daily Note.md",
        workdays_only = false,
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
    },
  },

  {
    "oflisback/obsidian-bridge.nvim",
    opts = {
      obsidian_server_address = "https://127.0.0.1:27124",
      cert_path = "~/Documents/obsidian.crt",
    },
    event = {
      "BufReadPre " .. vault_location .. "/**.md",
      "BufNewFile " .. vault_location .. "/**.md",
    },
    lazy = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
  },
}
