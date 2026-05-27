--- AST analysis and LSP-based auto-tagging
local shared = require("util.snippet-creator.state")

local M = {}

--- Parse union/enum type choices from LSP hover markdown
---@param hover_text string
---@return string[]|nil choices if a union/enum type was detected
function M.parse_type_choices(hover_text)
  if not hover_text then
    return nil
  end

  local choices = {}

  for line in hover_text:gmatch("[^\n]+") do
    local found = false
    for choice in line:gmatch('["\']([^"\']+)["\']') do
      table.insert(choices, choice)
      found = true
    end
    if found and line:find("|") and #choices >= 2 then
      return choices
    end
    if found and not line:find("|") then
      choices = {}
    end
  end

  local enum_choices = {}
  for member in hover_text:gmatch("([%w_]+)%s*[=,}]") do
    table.insert(enum_choices, member)
  end
  if #enum_choices >= 2 then
    return enum_choices
  end

  return nil
end

--- Query LSP for type information at a position (async)
---@param source_buf number
---@param row number 0-indexed
---@param col number 0-indexed
---@param callback fun(choices: string[]|nil)
function M.query_lsp_type(source_buf, row, col, callback)
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(source_buf),
    position = { line = row, character = col },
  }

  local clients = vim.lsp.get_clients({ bufnr = source_buf })
  if #clients == 0 then
    callback(nil)
    return
  end

  local responded = false
  for _, client in ipairs(clients) do
    if client.supports_method("textDocument/hover") then
      client:request("textDocument/hover", params, function(err, result)
        if responded then
          return
        end
        responded = true

        if err or not result or not result.contents then
          callback(nil)
          return
        end

        local hover_text
        if type(result.contents) == "string" then
          hover_text = result.contents
        elseif result.contents.value then
          hover_text = result.contents.value
        elseif type(result.contents) == "table" then
          local parts = {}
          for _, item in ipairs(result.contents) do
            if type(item) == "string" then
              table.insert(parts, item)
            elseif item.value then
              table.insert(parts, item.value)
            end
          end
          hover_text = table.concat(parts, "\n")
        end

        callback(M.parse_type_choices(hover_text))
      end, source_buf)
      return
    end
  end

  callback(nil)
end

--- Analyze AST of the selection using Treesitter
---@param source_buf number
---@param lines string[]
---@param start_row number 0-indexed start row in the source buffer
---@return table identifiers, table[] string_literals
function M.analyze_ast(source_buf, lines, start_row)
  local ft = vim.bo[source_buf].filetype
  local ok, parser = pcall(vim.treesitter.get_parser, source_buf, ft)
  if not ok or not parser then
    return {}, {}
  end

  local tree = parser:parse()[1]
  if not tree then
    return {}, {}
  end

  local root = tree:root()
  local end_row = start_row + #lines - 1

  local identifiers = {}
  local string_literals = {}

  local identifier_set = {
    identifier = true,
    property_identifier = true,
    shorthand_property_identifier = true,
    shorthand_property_identifier_pattern = true,
    type_identifier = true,
    field_identifier = true,
    variable_name = true,
    name = true,
  }

  local member_set = {
    member_expression = true,
    field_expression = true,
    attribute = true,
    method_call = true,
    dot_index_expression = true,
    method_index_expression = true,
  }

  local string_set = {
    string = true,
    string_literal = true,
    template_string = true,
    string_content = true,
  }

  local processed_members = {}

  local function get_member_ancestor(node)
    local current = node:parent()
    local top_member = nil
    while current do
      if member_set[current:type()] then
        top_member = current
      else
        break
      end
      current = current:parent()
    end
    return top_member
  end

  local function walk(node)
    local ntype = node:type()
    local sr, sc, er, ec = node:range()

    if er < start_row or sr > end_row then
      return
    end

    if identifier_set[ntype] then
      local member = get_member_ancestor(node)
      if member then
        local mr, mc, mer, mec = member:range()
        local member_key = string.format("%d:%d:%d:%d", mr, mc, mer, mec)
        if not processed_members[member_key] then
          processed_members[member_key] = true
          if mr >= start_row and mer <= end_row then
            local text = vim.treesitter.get_node_text(member, source_buf)
            if not identifiers[text] then
              identifiers[text] = {}
            end
            table.insert(identifiers[text], {
              start_row = mr - start_row,
              start_col = mc,
              end_row = mer - start_row,
              end_col = mec,
            })
          end
        end
      else
        if sr >= start_row and er <= end_row then
          local text = vim.treesitter.get_node_text(node, source_buf)
          if not identifiers[text] then
            identifiers[text] = {}
          end
          table.insert(identifiers[text], {
            start_row = sr - start_row,
            start_col = sc,
            end_row = er - start_row,
            end_col = ec,
          })
        end
      end
    end

    if string_set[ntype] then
      if sr >= start_row and er <= end_row then
        local text = vim.treesitter.get_node_text(node, source_buf)
        table.insert(string_literals, {
          start_row = sr - start_row,
          start_col = sc,
          end_row = er - start_row,
          end_col = ec,
          text = text,
          source_row = sr,
          source_col = sc,
        })
      end
      return
    end

    for child in node:iter_children() do
      walk(child)
    end
  end

  walk(root)

  return identifiers, string_literals
end

--- Build auto-tags from AST analysis results
---@param source_buf number
---@param lines string[]
---@param start_row number 0-indexed
---@param callback fun(nodes: table[])
function M.build_auto_tags(source_buf, lines, start_row, callback)
  local identifiers, string_literals = M.analyze_ast(source_buf, lines, start_row)

  local nodes = {}
  local node_counter = 0

  -- Sort identifier groups by first occurrence
  local groups = {}
  for name, positions in pairs(identifiers) do
    table.sort(positions, function(a, b)
      if a.start_row == b.start_row then
        return a.start_col < b.start_col
      end
      return a.start_row < b.start_row
    end)
    table.insert(groups, { name = name, positions = positions })
  end

  table.sort(groups, function(a, b)
    local ap = a.positions[1]
    local bp = b.positions[1]
    if ap.start_row == bp.start_row then
      return ap.start_col < bp.start_col
    end
    return ap.start_row < bp.start_row
  end)

  -- Build nodes: first occurrence = insert_node, rest = rep
  local name_to_first_index = {}
  for _, group in ipairs(groups) do
    node_counter = node_counter + 1
    local first_pos = group.positions[1]
    name_to_first_index[group.name] = node_counter

    table.insert(nodes, {
      type = "insert_node",
      start_row = first_pos.start_row,
      start_col = first_pos.start_col,
      end_row = first_pos.end_row,
      end_col = first_pos.end_col,
      text = group.name,
      index = node_counter,
      config = {},
      auto_tagged = true,
    })

    for idx = 2, #group.positions do
      node_counter = node_counter + 1
      local pos = group.positions[idx]
      table.insert(nodes, {
        type = "rep",
        start_row = pos.start_row,
        start_col = pos.start_col,
        end_row = pos.end_row,
        end_col = pos.end_col,
        text = group.name,
        index = node_counter,
        config = {
          target = name_to_first_index[group.name],
          summary = string.format("rep(%d)", name_to_first_index[group.name]),
        },
        auto_tagged = true,
      })
    end
  end

  -- Handle string literals via LSP
  if #string_literals == 0 then
    callback(nodes)
    return
  end

  local pending = #string_literals
  local string_nodes = {}

  for _, lit in ipairs(string_literals) do
    M.query_lsp_type(source_buf, lit.source_row, lit.source_col + 1, function(choices)
      if choices and #choices >= 2 then
        node_counter = node_counter + 1
        table.insert(string_nodes, {
          type = "choice_node",
          start_row = lit.start_row,
          start_col = lit.start_col,
          end_row = lit.end_row,
          end_col = lit.end_col,
          text = lit.text,
          index = node_counter,
          config = {
            choices = choices,
            summary = table.concat(choices, "|"),
          },
          auto_tagged = true,
        })
      end

      pending = pending - 1
      if pending == 0 then
        for _, sn in ipairs(string_nodes) do
          table.insert(nodes, sn)
        end
        -- Re-sort and re-index
        table.sort(nodes, function(a, b)
          if a.start_row == b.start_row then
            return a.start_col < b.start_col
          end
          return a.start_row < b.start_row
        end)
        local new_name_to_idx = {}
        for i, n in ipairs(nodes) do
          n.index = i
          if n.type == "insert_node" then
            new_name_to_idx[n.text] = i
          end
        end
        for _, n in ipairs(nodes) do
          if n.type == "rep" then
            local target_idx = new_name_to_idx[n.text]
            if target_idx then
              n.config.target = target_idx
              n.config.summary = string.format("rep(%d)", target_idx)
            end
          end
        end

        vim.schedule(function()
          callback(nodes)
        end)
      end
    end)
  end
end

return M
