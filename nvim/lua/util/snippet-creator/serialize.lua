--- Serialization and saving of snippets
local shared = require("util.snippet-creator.state")

local M = {}

--- Format a text node, handling multiline text
---@param text string
---@return string
function M.format_text_node(text)
  local lines = vim.split(text, "\n", { plain = true })
  if #lines == 1 then
    return string.format("    t(%q),", lines[1])
  else
    local formatted = {}
    for _, line in ipairs(lines) do
      table.insert(formatted, string.format("%q", line))
    end
    return string.format("    t({ %s }),", table.concat(formatted, ", "))
  end
end

--- Format a snippet node
---@param node table
---@param position number
---@return string
function M.format_node(node, position)
  local config = node.config or {}

  if node.type == "insert_node" then
    return string.format("    i(%d, %q),", position, node.text)
  elseif node.type == "choice_node" then
    local choices = config.choices or { node.text }
    local choice_parts = {}
    for _, ch in ipairs(choices) do
      table.insert(choice_parts, string.format("t(%q)", ch))
    end
    return string.format("    c(%d, { %s }),", position, table.concat(choice_parts, ", "))
  elseif node.type == "function_node" then
    local body = config.body or "return args[1][1]"
    local deps = config.deps or { 1 }
    local deps_str = table.concat(vim.tbl_map(tostring, deps), ", ")
    return string.format("    f(function(args) %s end, { %s }),", body, deps_str)
  elseif node.type == "rep" then
    local target = config.target or 1
    return string.format("    rep(%d),", target)
  elseif node.type == "dynamic_node" then
    local deps = config.deps or {}
    local deps_str = table.concat(vim.tbl_map(tostring, deps), ", ")
    local inner = config.inner_text or node.text
    return string.format("    d(%d, function(args) return sn(nil, { i(1, %q) }) end, { %s }),", position, inner, deps_str)
  elseif node.type == "text_node" then
    return M.format_text_node(node.text)
  else
    return string.format("    i(%d, %q),", position, node.text)
  end
end

--- Serialize the snippet to LuaSnip Lua API format
---@return string
function M.serialize_snippet()
  if not shared.state then
    return ""
  end

  local sorted_nodes = vim.deepcopy(shared.state.nodes)
  table.sort(sorted_nodes, function(a, b)
    if a.start_row == b.start_row then
      return a.start_col < b.start_col
    end
    return a.start_row < b.start_row
  end)

  local result_parts = {}
  local full_text = table.concat(shared.state.lines, "\n")

  local function to_offset(row, col)
    local offset = 0
    for r = 0, row - 1 do
      offset = offset + #shared.state.lines[r + 1] + 1
    end
    return offset + col
  end

  local pos = 0
  local node_counter = 0

  for _, node in ipairs(sorted_nodes) do
    local node_start = to_offset(node.start_row, node.start_col)
    local node_end = to_offset(node.end_row, node.end_col)

    if node_start > pos then
      local text_between = full_text:sub(pos + 1, node_start)
      if text_between ~= "" then
        table.insert(result_parts, M.format_text_node(text_between))
      end
    end

    node_counter = node_counter + 1
    table.insert(result_parts, M.format_node(node, node_counter))
    pos = node_end
  end

  if pos < #full_text then
    local trailing = full_text:sub(pos + 1)
    if trailing ~= "" then
      table.insert(result_parts, M.format_text_node(trailing))
    end
  end

  table.insert(result_parts, "    i(0),")

  local snippet_lines = {
    string.format("  s({"),
    string.format("    trig = %q,", shared.state.meta.trigger),
    string.format("    name = %q,", shared.state.meta.name),
  }
  if shared.state.meta.description ~= "" then
    table.insert(snippet_lines, string.format("    dscr = %q,", shared.state.meta.description))
  end
  table.insert(snippet_lines, "  }, {")
  for _, part in ipairs(result_parts) do
    table.insert(snippet_lines, part)
  end
  table.insert(snippet_lines, "  }),")

  return table.concat(snippet_lines, "\n")
end

--- Save the snippet to the appropriate filetype file
function M.save_snippet()
  if not shared.state then
    return
  end

  local snippet_code = M.serialize_snippet()
  local ft = shared.state.source_ft
  local snippet_dir = vim.fn.stdpath("config") .. "/lua/snippets"
  local filepath = snippet_dir .. "/" .. ft .. ".lua"

  vim.fn.mkdir(snippet_dir, "p")

  if vim.fn.filereadable(filepath) == 1 then
    local existing = vim.fn.readfile(filepath)
    local insert_at = nil
    for idx = #existing, 1, -1 do
      if existing[idx]:match("^}") then
        insert_at = idx
        break
      end
    end

    if insert_at then
      local new_lines = { "" }
      for _, line in ipairs(vim.split(snippet_code, "\n")) do
        table.insert(new_lines, line)
      end

      for idx, line in ipairs(new_lines) do
        table.insert(existing, insert_at + idx - 1, line)
      end

      vim.fn.writefile(existing, filepath)
    else
      vim.notify("Could not find insertion point in " .. filepath, vim.log.levels.ERROR)
      return
    end
  else
    local file_content = {
      'local ls = require("luasnip")',
      "local s = ls.snippet",
      "local t = ls.text_node",
      "local i = ls.insert_node",
      "local f = ls.function_node",
      "local c = ls.choice_node",
      "local d = ls.dynamic_node",
      "local sn = ls.snippet_node",
      'local rep = require("luasnip.extras").rep',
      "",
      "return {",
    }
    for _, line in ipairs(vim.split(snippet_code, "\n")) do
      table.insert(file_content, line)
    end
    table.insert(file_content, "}")

    vim.fn.writefile(file_content, filepath)
  end

  if shared.state.win and vim.api.nvim_win_is_valid(shared.state.win) then
    vim.api.nvim_win_close(shared.state.win, true)
  end

  vim.notify(
    string.format("Snippet '%s' saved to %s", shared.state.meta.trigger, filepath),
    vim.log.levels.INFO
  )

  require("luasnip.loaders.from_lua").lazy_load({ paths = snippet_dir })
  shared.state = nil
end

return M
