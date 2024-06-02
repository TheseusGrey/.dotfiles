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
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
  {
    "alexghergh/nvim-tmux-navigation",
    config = function()
      local nvim_tmux_nav = require("nvim-tmux-navigation")

      nvim_tmux_nav.setup({
        disable_when_zoomed = true, -- defaults to false
      })
    end,
  },
  --[=[{ // Requred nvim 0.10.0 so we're leaving it out for now
    "Bekaboo/dropbar.nvim",
    -- optional, but required for fuzzy finder support
    dependencies = {
      "nvim-telescope/telescope-fzf-native.nvim",
    },
  },--]=]
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
