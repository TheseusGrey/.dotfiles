vault_location = "~/Documents/loreStore"

return {
  {
    "epwalsh/obsidian.nvim",
    version = "*", -- recommended, use latest release instead of latest commit
    lazy = true,
    ft = "markdown",
    -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
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
    },
  },
  {
    "folke/zen-mode.nvim",
    opts = {
      on_open = function()
        require("lualine").hide()
      end,
      on_close = function()
        require("lualine").hide({ unhide = true })
      end,
      plugins = {
        -- disable some global vim options (vim.o...)
        options = {
          enabled = true,
          ruler = false, -- disables the ruler text in the cmd line area
          showcmd = false, -- disables the command in the last line of the screen
          -- you may turn on/off statusline in zen mode by setting 'laststatus'
          -- statusline will be shown only if 'laststatus' == 3
          laststatus = 0, -- turn off the statusline in zen mode
        },
        twilight = { enabled = true }, -- enable to start Twilight when zen mode opens
        gitsigns = { enabled = false }, -- disables git signs
        tmux = { enabled = true }, -- disables the tmux statusline
        alacritty = {
          enabled = false,
          font = "14", -- font size
        },
      },
    },
    keys = {
      { "<leader>fo", "<cmd>ZenMode<CR>", desc = "Toggle focus editing" },
    },
  },
  { "folke/twilight.nvim" },
}
