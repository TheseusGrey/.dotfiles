local keymaps = require("util.keymaps")
local map = vim.keymap.set

-- Clear search with <esc>
map({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and Clear hlsearch" })

-- Move to window using the <ctrl> hjkl keys
map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })

-- Don't yank empty lines
vim.keymap.set("n", "dd", function()
  if vim.fn.getline("."):match("^%s*$") then
    return '"_dd'
  end
  return "dd"
end, { expr = true })

map("n", "]d", function()
  vim.diagnostic.jump({ count = 1 })
end, { desc = "Next Diagnostic" })
map("n", "[d", function()
  vim.diagnostic.jump({ count = -1 })
end, { desc = "Prev Diagnostic" })
map("n", "]e", function()
  vim.diagnostic.jump({ count = 1, severity = 1 })
end, { desc = "Next Error" })
map("n", "[e", function()
  vim.diagnostic.jump({ count = -1, severity = 1 })
end, { desc = "Prev Error" })
map("n", "]w", function()
  vim.diagnostic.jump({ count = 1, severity = 2 })
end, { desc = "Next Warning" })
map("n", "[w", function()
  vim.diagnostic.jump({ count = -1, severity = 2 })
end, { desc = "Prev Warning" })

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

map("t", "<esc><esc>", "<c-\\><c-n>", { desc = "Exit Terminal mode" })

map({ "n", "x", "o" }, "s", require("flash").jump, { desc = "Search viewport" })
map({ "n", "x", "o" }, "S", require("flash").treesitter, { desc = "Search Treesitter" })

map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })

map("n", keymaps.buffer("b"), "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", keymaps.buffer("d"), "<cmd>bd<CR>", { desc = "Delete Buffers" })
map("n", keymaps.buffer("o"), "<cmd>BufferLineCloseOthers<CR>", { desc = "Close other Buffers" })
map("n", keymaps.buffer("h"), "<cmd>BufferLineCloseLeft<CR>", { desc = "Delete Buffers to the Left" })
map("n", keymaps.buffer("l"), "<cmd>BufferLineCloseRight<CR>", { desc = "Delete Buffers to the Right" })
map("n", keymaps.buffer("p"), "<cmd>BufferLinePick<CR>", { desc = "Pick from visible buffers" })

map({ "n", "v" }, keymaps.edit("r"), vim.lsp.buf.rename, { desc = "Rename Symbol" })
map({ "n", "v" },keymaps.edit("l"), vim.lsp.codelens.run, { desc = "codeLense" })
map({"n", "v" }, keymaps.edit("A"), source_action, { desc = "Source Action" })
map({"n", "v" }, keymaps.edit("a"), vim.lsp.buf.code_action, { desc = "Code Action" })

map("n", "<leader><leader>", Snacks.picker.files, { desc = "Find Files" })
map("n", keymaps.find("b"), Snacks.picker.buffers, { desc = "Find Buffers" })
map("n", keymaps.find("g"), Snacks.picker.grep, { desc = "Find (Grep)" })
map("n", keymaps.find("k"), Snacks.picker.keymaps, { desc = "Find Keymaps" })
map("n", keymaps.find("m"), Snacks.picker.marks, { desc = "Find Marks" })
map("n", keymaps.find("w"), Snacks.picker.grep_word, { desc = "Find Word" })

map("n", keymaps.git("B"), Snacks.git.blame_line, { desc = "Git Blame" })

map("n", keymaps.goto("D"), Snacks.picker.lsp_declarations, { desc = "Goto Declaration" })
map("n", keymaps.goto("I"), Snacks.picker.lsp_implementations, { desc = "Goto Implementation"  })
map("n", keymaps.goto("d"), Snacks.picker.lsp_definitions, { desc = "Goto Definition" })
map("n", keymaps.goto("r"), Snacks.picker.lsp_references, { desc = "Goto References", nowait = true })
map("n", keymaps.goto("t"), Snacks.picker.lsp_type_definitions, { desc = "Goto Type definition"  })
map("n", keymaps.goto("w"), Snacks.gitbrowse.open, { desc = "Git Webbrowse" })

map("n", keymaps.toggle("d"), vim.diagnostic.open_float, { desc = "line Diagnostics" })
map("n", keymaps.toggle("e"), "<CMD>Oil<CR>", { desc = "Explorer" })
map("n", keymaps.toggle("f"), Snacks.zen.zen, { desc = "Focus mode" })
map("n", keymaps.toggle("g"), Snacks.lazygit.open, { desc = "(lazy)Git" })
map("n", keymaps.toggle("n"), Snacks.notifier.show_history, { desc = "Notification history" })
map("n", keymaps.toggle("s"), vim.treesitter.inspect_tree, { desc = "TreeSitter tree" })
map("n", keymaps.toggle("t"), "<cmd>ToggleTerm<cr>", { desc = "Terminal", noremap = true, silent = true })

