local palette = {
  none = "NONE",

  black0 = "#191D24",
  black1 = "#1E222A",
  black2 = "#222630",

  gray0 = "#242933",
  gray1 = "#2E3440",
  gray2 = "#3B4252",
  gray3 = "#434C5E",
  gray4 = "#4C566A",
  gray5 = "#60728A",

  white0_normal = "#BBC3D4",
  white0_reduce_blue = "#C0C8D8",

  white1 = "#D8DEE9",
  white2 = "#E5E9F0",
  white3 = "#ECEFF4",

  blue0 = "#5E81AC",
  blue1 = "#81A1C1",
  blue2 = "#88C0D0",

  cyan = {
    base = "#8FBCBB",
    bright = "#9FC6C5",
    dim = "#80B3B2",
  },

  red = {
    base = "#BF616A",
    bright = "#C5727A",
    dim = "#B74E58",
  },
  orange = {
    base = "#D08770",
    bright = "#D79784",
    dim = "#CB775D",
  },
  yellow = {
    base = "#EBCB8B",
    bright = "#EFD49F",
    dim = "#E7C173",
  },
  green = {
    base = "#A3BE8C",
    bright = "#B1C89D",
    dim = "#97B67C",
  },
  magenta = {
    base = "#B48EAD",
    bright = "#BE9DB8",
    dim = "#A97EA1",
  },
}

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
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = {},
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
      colorscheme = "catppuccin",
    },
  },
}
