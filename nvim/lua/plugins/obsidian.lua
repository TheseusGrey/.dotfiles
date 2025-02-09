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
      picker = {
        name = "fzf-lua",
      },
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
    keys = {
      { "<leader>ot", "<cmd>ObsidianTags<cr>", desc = "Open the Tag picker to for note finding" },
      { "<leader>oi", "<cmd>ObsidianTemplate<cr>", desc = "Insert the given Obsidian template" },
      { "<leader>oc", "<cmd>ObsidianTOC<cr>", desc = "Open the Table Of Contents for the current buffer" },
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
