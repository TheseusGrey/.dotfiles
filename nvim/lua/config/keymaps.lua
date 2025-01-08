local map = vim.keymap.set

-- Clear search with <esc>
map({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and Clear hlsearch" })

-- Don't yank empty lines
vim.keymap.set("n", "dd", function()
  if vim.fn.getline("."):match("^%s*$") then
    return '"_dd'
  end
  return "dd"
end, { expr = true })

-- diagnostic
local diagnostic_goto = function(next, severity)
  local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    go({ severity = severity })
  end
end
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
map("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
map("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
map("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
map("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
map("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })

-- lsp
local source_action = function(_, action)
  vim.lsp.buf.code_action({
    apply = true,
    context = {
      only = { action },
      diagnostics = {},
    },
  })
end
map({ "n", "v" }, "<leader>gD", vim.lsp.buf.declaration, { desc = "Goto Declaration" })
map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })
map({ "n", "v" }, "<leader>cA", source_action, { desc = "Source Action" })
map({ "n", "v" }, "<leader>cl", vim.lsp.codelens.run, { desc = "Codelense" })
map({ "n", "v" }, "<leader>cL", vim.lsp.codelens.refresh, { desc = "Codelense Refresh" })
map({ "n", "v" }, "<leader>cr", vim.lsp.buf.rename, { desc = "Rename Symbol" })

-- Treesitter
map("n", "<leader>ti", vim.treesitter.inspect_tree, { desc = "Inspect Treesitter tree" })
