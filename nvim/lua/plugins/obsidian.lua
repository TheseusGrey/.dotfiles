local helpers = require("util.helpers")

---@return boolean
local function in_obsidian_vault()
  return vim.fn.isdirectory(vim.fn.getcwd() .. "/.obsidian") == 1
end

return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*", -- recommended, use latest release instead of latest commit
    event = "BufReadPre *.md",
    cond = in_obsidian_vault,
    opts = function()
      local cwd = vim.fn.getcwd()
      local name = vim.fn.fnamemodify(cwd, ":t")
      return {
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
      }
    end,
  },

  {
    "oflisback/obsidian-bridge.nvim",
    event = "BufReadPre *.md",
    cond = function()
      return in_obsidian_vault() and vim.env.OBSIDIAN_REST_API_KEY ~= nil
    end,
    opts = {
      obsidian_server_address = "https://127.0.0.1:27124",
      cert_path = "~/Documents/obsidian.crt",
    },
    lazy = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
  },
}
