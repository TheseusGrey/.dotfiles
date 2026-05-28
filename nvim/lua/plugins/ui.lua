require("vim._core.ui2").enable()

local snippet_picker = {
  supports_live = false,
  preview = "preview",
  format = function(item, picker)
    local name = Snacks.picker.util.align(item.name, picker.align_1 + 5)
    return {
      { name, item.ft == "" and "Conceal" or "DiagnosticWarn" },
      { item.description },
    }
  end,
  finder = function(_, ctx)
    local snippets = {}
    for _, snip in ipairs(require("luasnip").get_snippets().all) do
      snip.ft = ""
      table.insert(snippets, snip)
    end
    for _, snip in ipairs(require("luasnip").get_snippets(vim.bo.ft)) do
      snip.ft = vim.bo.ft
      table.insert(snippets, snip)
    end
    local align_1 = 0
    for _, snip in pairs(snippets) do
      align_1 = math.max(align_1, #snip.name)
    end
    ctx.picker.align_1 = align_1
    local items = {}
    for _, snip in pairs(snippets) do
      local docstring = snip:get_docstring()
      if type(docstring) == "table" then
        docstring = table.concat(docstring)
      end
      local name = snip.name
      local description = table.concat(snip.description)
      description = name == description and "" or description
      table.insert(items, {
        text = name .. " " .. description, -- search string
        name = name,
        description = description,
        trigger = snip.trigger,
        ft = snip.ft,
        preview = {
          ft = snip.ft,
          text = docstring,
        },
      })
    end
    return items
  end,
  confirm = function(picker, item)
    picker:close()
    --
    local expand = {}
    require("luasnip").available(function(snippet)
      if snippet.trigger == item.trigger then
        table.insert(expand, snippet)
      end
      return snippet
    end)
    if #expand > 0 then
      vim.cmd(":startinsert!")
      vim.defer_fn(function()
        require("luasnip").snip_expand(expand[1])
      end, 50)
    else
      Snacks.notify.warn("No snippet to expand")
    end
  end,
}

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
    sources = {
      snippet = snippet_picker,
    },
  },
  styles = {
    zen = {
      enter = true,
      fixbuf = false,
      minimal = false,
      width = 85,
      height = 0,
      backdrop = { transparent = true, blend = 40 },
      keys = { q = "close" },
      zindex = 40,
      wo = {
        winhighlight = "NormalFloat:Normal",
      },
      w = {
        snacks_main = true,
      },
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
    lualine_y = { "diagnostics", "lsp_status" },
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
  { "<leader>b", group = "+buffer", desc = "" },
  { "<leader>d", group = "+debug", icon = "", desc = "" },
  { "<leader>e", group = "+edit", icon = "", desc = "" },
  { "<leader>f", group = "+find/files/focus", icon = "󰈞", desc = "" },
  { "<leader>g", group = "+goto/git", icon = "", desc = "" },
  { "<leader>p", group = "+Plugins/Presentations", icon = "", desc = "" },
  { "<leader>s", group = "+surround", icon = "󰅩", desc = "" },
  { "<leader>t", group = "+toggle (ui elements)", icon = "", desc = "" },
})
