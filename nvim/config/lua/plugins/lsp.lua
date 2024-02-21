-- Config for LSPs

return {
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        -- pyright will be automatically installed with mason and loaded with lspconfig
        pyright = {},
        tsserver = {},
        bashls = {},
      },
    },
  },
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
