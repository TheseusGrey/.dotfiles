return {
  "saghen/blink.cmp",
  dependencies = {
    "rafamadriz/friendly-snippets",
    {
      "L3MON4D3/LuaSnip",
      config = function()
        -- Load custom snippets from ~/.config/nvim/lua/snippets
        require("luasnip.loaders.from_lua").load({
          paths = vim.fn.stdpath("config") .. "/lua/snippets",
        })
      end,
    },
    "archie-judd/blink-cmp-words",
    "moyiz/blink-emoji.nvim",
  },
  version = "*",
  opts = {
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
      },
      providers = {

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
            return vim.tbl_contains(
              -- Enable emoji completion only for git commits and markdown.
              -- By default, enabled for all file-types.
              { "gitcommit", "markdown" },
              vim.o.filetype
            )
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

    -- Signature help configuration
    signature = {
      enabled = true,
    },

    -- Snippet configuration for LuaSnip
    snippets = {
      preset = "luasnip",
    },
  },
  opts_extend = { "sources.default" },
}
