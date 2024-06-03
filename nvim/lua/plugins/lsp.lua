-- Config for LSPs
local html_capabilities = vim.lsp.protocol.make_client_capabilities()
html_capabilities.textDocument.completion.completionItem.snippetSupport = true

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
        glsl_analyzer = {},
        gdscript = {},
        gdshader_lsp = {},
        nixd = {},
        html = {
          capabilities = html_capabilities,
        },
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
