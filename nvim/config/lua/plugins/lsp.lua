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
        bashls = {},
        jdtls = {},
        rust_analyzer = {},
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
