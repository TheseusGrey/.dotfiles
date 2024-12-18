local vault_location = vim.fn.expand("~") .. "/Documents/Lore Store"

return {
  {
    "epwalsh/obsidian.nvim",
    version = "*", -- recommended, use latest release instead of latest commit
    lazy = true,
    disable_frontmatter = true,
    event = {
      "BufReadPre " .. vault_location .. "/**.md",
      "BufNewFile " .. vault_location .. "/**.md",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      workspaces = {
        {
          name = "personal",
          path = vault_location,
        },
      },
      new_notes_location = "current_dir",
      daily_notes = {
        folder = "Notes/Dailies",
        date_format = "%y-%m-%d",
        template = "Templates/Daily Note.md",
      },
      templates = {
        folder = "Templates",
      },
    },
  },
}
