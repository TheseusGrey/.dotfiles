return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    keys = {
      { "<leader>E", false },
      {
        "<leader>e",
        function()
          local neotree = require("neo-tree.command")
          local state = require("neo-tree.sources.manager").get_state("filesystem")
          local reveal_file = vim.fn.expand("%:p")
          if reveal_file == "" then
            reveal_file = vim.fn.getcwd()
          else
            local f = io.open(reveal_file, "r")
            if f then
              f.close(f)
            else
              reveal_file = vim.fn.getcwd()
            end
          end
          require("neo-tree.sources.filesystem.commands").clear_filter(state)
          neotree.execute({
            position = "float",
            reveal_file = reveal_file,
          })
        end,
        desc = "Neotree File explorer",
      },
    },
    event_handlers = {
      {
        event = "file_opened",
        handler = function()
          require("neo-tree.command").execute({ action = "close" })
        end,
      },
    },
  },
  {
    'AlexvZyl/nordic.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      require("nordic").setup({
        bold_keywords = true,
      })
      require("nordic").load()
    end
  },
  {
    "alexghergh/nvim-tmux-navigation",
    config = function()
      local nvim_tmux_nav = require("nvim-tmux-navigation")

      nvim_tmux_nav.setup({
        disable_when_zoomed = true, -- defaults to false
      })
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      sections = {
        lualine_c = {},
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "nordic",
    },
  },
}
