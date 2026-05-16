local ui = require("util.ui")

---@type table<string, table<vim.lsp.Client, table<number, boolean>>>
local _supports_method = {}

---@param method string
---@param fn fun(client:vim.lsp.Client, buffer)
function on_supports_method(method, fn)
  _supports_method[method] = _supports_method[method] or setmetatable({}, { __mode = "k" })

  return vim.api.nvim_create_autocmd("User", {
    pattern = "LspSupportsMethod",
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      local buffer = args.data.buffer ---@type number

      if client and method == args.data.method then
        return fn(client, buffer)
      end
    end,
  })
end

require("mason").setup()
require("mason-lspconfig").setup()

-- Set up some QOL stuff around LSPs

-- Highlights for line diagnostics
for severity, icon in pairs(ui.icons) do
  local name = vim.diagnostic.severity[severity]:lower():gsub("^%l", string.upper)
  name = "DiagnosticSign" .. name
  vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
end

vim.diagnostic.config({
  signs = {
    text = ui.icons,
  },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  virtual_text = {
    spacing = 4,
    source = "if_many",

    prefix = function(diagnostic)
      for d, icon in pairs(ui.icons) do
        if diagnostic.severity == vim.diagnostic.severity[d] then
          return icon
        end
        return "●"
      end
    end,
  },
})

-- Inlay hints when supported
local exclude = { "vue" }
on_supports_method("textDocument/inlayHint", function(_, buffer)
  if
    vim.api.nvim_buf_is_valid(buffer)
    and vim.bo[buffer].buftype == ""
    and not vim.tbl_contains(exclude, vim.bo[buffer].filetype)
  then
    vim.lsp.inlay_hint.enable(true, { bufnr = buffer })
  end
end)

-- Codelens when supported
on_supports_method("textDocument/codeLens", function(_, buffer)
  vim.lsp.codelens.enable(true, { bufnr = buffer })
end)

local servers = {}
local capabilities = require("blink.cmp").get_lsp_capabilities(vim.lsp.protocol.make_client_capabilities())

local function setup(server)
  local server_opts = vim.tbl_deep_extend("force", {
    capabilities = vim.deepcopy(capabilities),
  }, servers[server] or {})

  if server_opts.enabled == false then
    return
  end
  require("lspconfig")[server].setup(server_opts)
end

-- get all the servers that are available through mason-lspconfig
local have_mason, mlsp = pcall(require, "mason-lspconfig")

local ensure_installed = {} ---@type string[]

for server, server_opts in pairs(servers) do
  if server_opts then
    server_opts = server_opts == true and {} or server_opts

    if server_opts.enabled ~= false then
      -- run manual setup if mason=false or if this is a server that cannot be installed with mason-lspconfig

      if server_opts.mason == false then
        setup(server)
      else
        ensure_installed[#ensure_installed + 1] = server
      end
    end
  end
end

if have_mason then
  mlsp.setup({
    ensure_installed = ensure_installed,
    handlers = { setup },
  })
end
