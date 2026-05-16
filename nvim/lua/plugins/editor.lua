-- flash, blink, snippets?, pairs, emoji, surround, basically anything not lsp specific

require("nvim-treesitter").setup()

require("flash").setup()
require("mini.pairs").setup()
require("mini.ai").setup()
require("mini.surround").setup({
  mappings = {
    add = "<leader>sa", -- Add surrounding in Normal and Visual modes
    delete = "<leader>sd", -- Delete surrounding
    find = "<leader>sf", -- Find surrounding (to the right)
    find_left = "<leader>sF", -- Find surrounding (to the left)
    highlight = "<leader>sh", -- Highlight surrounding
    replace = "<leader>sr", -- Replace surrounding
    update_n_lines = "<leader>sn", -- Update `n_lines`
  },
})

require("conform").setup({
  default_format_opts = {
    timeout_ms = 3000,
    async = false, -- not recommended to change
    quiet = false, -- not recommended to change
    lsp_format = "fallback", -- not recommended to change
  },
  formatters_by_ft = {
    lua = { "stylua" },
    fish = { "fish_indent" },
    sh = { "shfmt" },
    python = { "isort", "black" },
    rust = { "rustfmt", lsp_format = "fallback" },
    javascript = { "prettierd", "prettier", stop_after_first = true },
    css = { "prettier", "cssls", stop_after_first = true },
    scss = { "prettier", "cssls", stop_after_first = true },
  },
  formatters = {
    injected = { options = { ignore_errors = true } },
  },
})

require("luasnip.loaders.from_vscode").lazy_load()
require("luasnip").setup()

local cmp = require("blink.cmp")
cmp.setup({
  -- Keymap configuration
  keymap = {
    preset = "default",
    ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
    ["<C-e>"] = { "hide", "fallback" },
    ["<CR>"] = { "accept", "fallback" },
    ["<Tab>"] = { "snippet_forward", "select_next", "fallback" },
    ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },
    ["<Up>"] = { "select_prev", "fallback" },
    ["<Down>"] = { "select_next", "fallback" },
    ["<C-p>"] = { "select_prev", "fallback" },
    ["<C-n>"] = { "select_next", "fallback" },
    ["<C-u>"] = { "scroll_documentation_up", "fallback" },
    ["<C-d>"] = { "scroll_documentation_down", "fallback" },
  },

  sources = {
    default = { "snippets", "lsp", "path", "buffer", "emoji" },
    -- Setup completion by filetype
    per_filetype = {
      markdown = { "thesaurus", "emoji" },
      text = { "thesaurus", "emoji" },
      lua = { inherit_defaults = true, "lazydev" },
    },
    providers = {
      lazydev = {
        name = "LazyDev",
        module = "lazydev.integrations.blink",
        -- make lazydev completions top priority (see `:h blink.cmp`)
        score_offset = 100,
      },

      emoji = {
        module = "blink-emoji",
        name = "Emoji",
        score_offset = 15, -- Tune by preference
        opts = {
          insert = true, -- Insert emoji (default) or complete its name
          ---@type string|table|fun():table
          trigger = function()
            return { ":" }
          end,
        },
        should_show_items = function()
          return vim.tbl_contains({ "gitcommit", "markdown" }, vim.o.filetype)
        end,
      },

      thesaurus = {
        name = "blink-cmp-words",
        module = "blink-cmp-words.thesaurus",
        opts = {
          score_offset = 0,
          definition_pointers = { "!", "&", "^" },
          similarity_pointers = { "&", "^" },
          similarity_depth = 2,
        },
      },

      dictionary = {
        name = "blink-cmp-words",
        module = "blink-cmp-words.dictionary",
        opts = {
          dictionary_search_threshold = 3,
          score_offset = 0,
          definition_pointers = { "!", "&", "^" },
        },
      },
    },
  },

  completion = {
    trigger = {
      show_on_blocked_trigger_characters = function()
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
  signature = {
    enabled = true,
  },
  snippets = {
    preset = "luasnip",
  },
})
