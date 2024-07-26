local default_config = require("config.lsp")

return {
  on_attach = default_config.on_attach,
  capabilities = default_config.capabilities,
  on_init = default_config.on_init,

  cmd = { "tsserver" },
  filetypes = { "js", "ts", "jsx", "tsx", "mjs", "typescript", "javascript" },
}
