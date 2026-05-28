--- Shared state and constants for snippet-creator
local M = {}

-- Namespace for extmarks (highlights)
M.ns = vim.api.nvim_create_namespace("snippet_creator")

-- State for the current snippet creation session
---@class SnippetCreatorState
---@field source_ft string
---@field lines string[]
---@field nodes table[]
---@field buf number|nil
---@field win number|nil
---@field meta {name: string, description: string, trigger: string}
M.state = nil

-- LuaSnip node types available for completion
M.node_types = {
  {
    label = "insert_node",
    kind = 15,
    detail = "Tabstop with optional placeholder text",
    documentation = "i(position, \"placeholder\")",
  },
  {
    label = "choice_node",
    kind = 15,
    detail = "Multiple choices at a tabstop",
    documentation = "c(position, { t(\"option1\"), t(\"option2\") })",
  },
  {
    label = "function_node",
    kind = 15,
    detail = "Dynamically computed text from other nodes",
    documentation = "f(function(args) return args[1][1] end, {1})",
  },
  {
    label = "rep",
    kind = 15,
    detail = "Repeat the content of another node",
    documentation = "rep(1) -- repeats node at position 1",
  },
  {
    label = "dynamic_node",
    kind = 15,
    detail = "Dynamically generated snippet node",
    documentation = "d(position, function(args) ... end, {dependencies})",
  },
  {
    label = "text_node",
    kind = 15,
    detail = "Static text (no tabstop)",
    documentation = "t(\"static text\")",
  },
}

return M
