-- require("vim._core.ui2").enable()

if vim.o.filetype == "lazy" then
  vim.cmd([[messages clear]])
end

require("persistence").setup()

require("snacks").setup({
  dim = { enabled = true },
  git = { enabled = true },
  indent = { enabled = true },
  gitbrowse = { enabled = true },
  image = {
    enabled = true,
    doc = {
      inline = false,
      float = true,
    },
  },
  input = { enabled = true },
  lazygit = { enabled = true },
  notifier = { enabled = true },
  quickfile = { enabled = true },
  statuscolumn = { enabled = true },
  zen = { enabled = true },
  picker = {
    enabled = true,
    preset = "ivy",
    layout = { position = "right" },
    formatters = {
      file = {
        filename_first = true,
      },
    },
  },
  styles = {
    zen = {
      keys = { q = "close" },
    },
  },
  dashboard = {
    enabled = true,
    preset = {
      keys = {
        {
          icon = " ",
          key = "s",
          desc = "Restore Session",
          action = function()
            require("persistence").load()
          end,
        },
        { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
        { icon = " ", key = "g", desc = "Lazygit", action = ":lua Snacks.lazygit.open()" },
        { icon = " ", key = "q", desc = "Quit", action = ":qa" },
      },
    },
    sections = {
      { section = "header" },
      { icon = " ", title = "Keymaps", section = "keys", indent = 2, padding = 1 },
      {
        icon = " ",
        title = "Git Status",
        section = "terminal",
        enabled = function()
          return Snacks.git.get_root() ~= nil
        end,
        cmd = "git status --short --branch --renames",
        height = 5,
        padding = 1,
        ttl = 5 * 60,
        indent = 3,
      },
    },
  },
})

require("lualine").setup({
  options = {
    theme = "auto",
    globalstatus = vim.opt.laststatus == 3,
    disabled_filetypes = { statusline = { "dashboard", "alpha", "ministarter" } },
    section_separators = "",
    component_separators = "",
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = {
      {
        function()
          local reg = vim.fn.reg_recording()
          if reg ~= "" then
            return "Recording  @" .. reg -- or whatever icon/format you like
          end
          return ""
        end,
        color = { fg = "#ff9e64" }, -- optional, highlights it when active
      },
    },
    lualine_c = {},
    lualine_x = { "searchcount" },
    lualine_y = { "diagnostics" },
    lualine_z = { "location" },
  },
})

require("bufferline").setup({
  options = {
    diagnostics = "nvim_lsp",
    show_buffer_close_icons = false,
  },
})

require("oil").setup({
  default_file_explorer = true,
  view_options = {
    show_hidden = true,
  },
  keymaps = {
    ["q"] = { "actions.close", mode = "n" },
  },
})

local wk = require("which-key")

wk.setup({
  preset = "helix",
  delay = 140,
  triggers = {
    { "<leader>", mode = { "n", "v" } },
  },
})

wk.add({
  { "<leader>f", group = "+find/files/focus", desc = "" },
  { "<leader>t", group = "+toggle (ui elements)", desc = "" },
  { "<leader>g", group = "+goto/git", desc = "" },
  { "<leader>b", group = "+buffer", desc = "" },
  { "<leader>e", group = "+edit", icon = "", desc = "" },
  { "<leader>s", group = "+surround", icon = "󰅩", desc = "" },
})
