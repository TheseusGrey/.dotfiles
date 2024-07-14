local M = {}
local map = vim.keymap.set

-- export on_attach & capabilities
M.on_attach = function(_, bufnr)
  local function opts(desc)
    return { buffer = bufnr, desc = "LSP " .. desc }
  end

  map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action (current line)" })
  map({ "n", "v" }, "<leader>cs", vim.lsp.buf.hover, { desc = "Code Symbol view" })
  map({ "n", "v" }, "<leader>rs", vim.lsp.buf.rename, { desc = "Rename Symbol" })
  map({ "n", "v" }, "<leader>cr", vim.lsp.buf.references, { desc = "Code References" })
  map({ "n", "v" }, "<leader>gd", vim.lsp.buf.definition, { desc = "Goto Definition" })
  map("n", "gD", vim.lsp.buf.declaration, opts "Go to declaration")
end

-- disable semanticTokens
M.on_init = function(client, _)
  if client.supports_method "textDocument/semanticTokens" then
    client.server_capabilities.semanticTokensProvider = nil
  end
end


local cmp_lsp = require("cmp_nvim_lsp")
local capabilities = vim.tbl_deep_extend(
  "force",
  {},
  vim.lsp.protocol.make_client_capabilities(),
  cmp_lsp.default_capabilities()
)

M.capabilities = capabilities
M.capabilities.textDocument.completion.completionItem = {
  documentationFormat = { "markdown", "plaintext" },
  snippetSupport = true,
  preselectSupport = true,
  insertReplaceSupport = true,
  labelDetailsSupport = true,
  deprecatedSupport = true,
  commitCharactersSupport = true,
  tagSupport = { valueSet = { 1 } },
  resolveSupport = {
    properties = {
      "documentation",
      "detail",
      "additionalTextEdits",
    },
  },
}

return M
