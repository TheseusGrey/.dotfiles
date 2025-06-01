return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    dim = { enabled = true },
    git = { enabled = true },
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
      sections = {
        { section = "header" },
        { icon = " ", title = "Keymaps", section = "keys", indent = 2, padding = 1 },
        { icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
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
        { section = "startup" },
      },
    },
  },
  keys = {
    { "<leader>g", "", desc = "+goto/git" },
    { "<leader>f", "", desc = "+find/focus" },
    {
      "<leader>gg",
      function()
        Snacks.lazygit.open()
      end,
      desc = "Goto (lazy)Git",
    },
    {
      "<leader>gw",
      function()
        Snacks.gitbrowse.open()
      end,
      desc = "Git Webbrowse",
    },
    {
      "<leader>gd",
      function()
        Snacks.picker.lsp_definitions()
      end,
      desc = "Goto Definition",
    },
    {
      "<leader>gD",
      function()
        Snacks.picker.lsp_declarations()
      end,
      desc = "Goto Declaration",
    },
    {
      "<leader>gr",
      function()
        Snacks.picker.lsp_references()
      end,
      nowait = true,
      desc = "References",
    },
    {
      "<leader>gI",
      function()
        Snacks.picker.lsp_implementations()
      end,
      desc = "Goto Implementation",
    },
    {
      "<leader>gt",
      function()
        Snacks.picker.lsp_type_definitions()
      end,
      desc = "Goto T[y]pe Definition",
    },
    {
      "<leader>fb",
      function()
        Snacks.picker.buffers()
      end,
      desc = "Buffers",
    },
    {
      "<leader>fc",
      function()
        Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
      end,
      desc = "Find Config File",
    },
    {
      "<leader><leader>",
      function()
        Snacks.picker.files()
      end,
      desc = "Find Files",
    },
    {
      "<leader>fg",
      function()
        Snacks.picker.grep()
      end,
      desc = "Grep",
    },
    {
      "<leader>fw",
      function()
        Snacks.picker.grep_word()
      end,
      desc = "Visual selection or word",
      mode = { "n", "x" },
    },
    -- { "<leader>fg", function() Snacks.picker.git_files() end, desc = "Find Git Files" },
    {
      "<leader>fp",
      function()
        Snacks.picker.projects()
      end,
      desc = "Projects",
    },
    {
      "<leader>fr",
      function()
        Snacks.picker.recent()
      end,
      desc = "Recent",
    },
    {
      "<leader>fm",
      function()
        Snacks.picker.marks()
      end,
      desc = "Marks",
    },
    {
      "<leader>fk",
      function()
        Snacks.picker.keymaps()
      end,
      desc = "Keymaps",
    },
    {
      "<leader>n",
      function()
        Snacks.notifier.show_history()
      end,
      desc = "Notification History",
    },
    {
      "<leader>gb",
      function()
        Snacks.git.blame_line()
      end,
      desc = "Git Blame Line",
    },
    {
      "<leader>gh",
      function()
        Snacks.picker.git_diff()
      end,
      desc = "Git Diff (Hunks)",
    },
    {
      "<leader>fo",
      function()
        Snacks.zen.zen()
      end,
      desc = "Toggle focus editing",
    },
  },
}
