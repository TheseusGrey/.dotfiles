return {
  "saghen/blink.cmp",
  version = "1.*",
  dependencies = { "L3MON4D3/LuaSnip", version = "v2.*" },
  opts_extend = { "sources.default" },
  opts = {
    signature = { enabled = true },
    completion = {
      trigger = {
        show_on_blocked_trigger_characters = function(ctx)
          if vim.bo.filetype == "markdown" then
            return { "[[" }
          end
          return { " ", "\n", "\t" } -- Default blocked triggers
        end,
      },
      documentation = { auto_show = true, auto_show_delay_ms = 250 },
      menu = {
        draw = {
          columns = { { "kind_icon", "label", "label_description", gap = 1 }, { "kind" } },
        },
      },
    },
    keymap = {
      -- set to 'none' to disable the 'default' preset
      preset = "default",
      ["<CR>"] = { "select_and_accept", "fallback" },
    },
    snippets = { preset = "luasnip" },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },
  },
}
