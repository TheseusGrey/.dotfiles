-- Config for LSPs

return {
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        pyright = {},
        tsserver = {},
        jsonls = {},
        bashls = {},
        jdtls = {},
        rust_analyzer = {},
        html = {},
      },
    },
  },
  -- { "mfussenegger/nvim-jdtls" },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        lua = { "stylua" },
        python = { "black" },
        typescript = { "prettier" },
      },
    },
  },
}
