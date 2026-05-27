--- Node assignment, configuration, and management
local shared = require("util.snippet-creator.state")
local ns = shared.ns

local M = {}

--- Get the visual selection range (0-indexed)
---@return number start_row, number start_col, number end_row, number end_col
local function get_visual_range()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  return start_pos[2] - 1, start_pos[3] - 1, end_pos[2] - 1, end_pos[3]
end

--- Check if a new range overlaps with existing nodes
---@param sr number
---@param sc number
---@param er number
---@param ec number
---@return boolean
local function overlaps_existing(sr, sc, er, ec)
  if not shared.state then
    return false
  end
  for _, node in ipairs(shared.state.nodes) do
    local nr, nc, ner, nec = node.start_row, node.start_col, node.end_row, node.end_col
    local before = (er < nr) or (er == nr and ec <= nc)
    local after = (sr > ner) or (sr == ner and sc >= nec)
    if not (before or after) then
      return true
    end
  end
  return false
end

--- Finalize adding a node to state with highlight
---@param choice string
---@param text string
---@param sr number
---@param sc number
---@param er number
---@param ec number
---@param config? table
local function finalize_node(choice, text, sr, sc, er, ec, config)
  if not shared.state then
    return
  end

  local node_index = #shared.state.nodes + 1
  local node = {
    type = choice,
    start_row = sr,
    start_col = sc,
    end_row = er,
    end_col = ec,
    text = text,
    index = node_index,
    config = config or {},
  }

  table.insert(shared.state.nodes, node)

  local label = choice
  if config and config.summary then
    label = label .. ": " .. config.summary
  end
  vim.api.nvim_set_option_value("modifiable", true, { buf = shared.state.buf })
  vim.api.nvim_buf_set_extmark(shared.state.buf, ns, sr, sc, {
    end_row = er,
    end_col = ec,
    hl_group = "DiagnosticVirtualTextInfo",
    virt_text = { { string.format(" [%d: %s]", node_index, label), "DiagnosticInfo" } },
    virt_text_pos = "eol",
  })
  vim.api.nvim_set_option_value("modifiable", false, { buf = shared.state.buf })

  vim.notify(
    string.format("Node %d (%s) assigned to: \"%s\"", node_index, choice, text:sub(1, 30)),
    vim.log.levels.INFO
  )
end

--- Configure complex nodes that need additional input
---@param choice string
---@param text string
---@param sr number
---@param sc number
---@param er number
---@param ec number
function M.configure_node(choice, text, sr, sc, er, ec)
  if choice == "choice_node" then
    M._configure_choice_node(text, sr, sc, er, ec)
  elseif choice == "function_node" then
    M._configure_function_node(text, sr, sc, er, ec)
  elseif choice == "rep" then
    M._configure_rep_node(text, sr, sc, er, ec)
  elseif choice == "dynamic_node" then
    M._configure_dynamic_node(text, sr, sc, er, ec)
  else
    finalize_node(choice, text, sr, sc, er, ec)
  end
end

function M._configure_choice_node(text, sr, sc, er, ec)
  vim.ui.input({
    prompt = "Choices (comma-separated, selected text is first choice): ",
    default = text,
  }, function(input)
    if not input or not shared.state then
      return
    end
    local choices = {}
    for choice in input:gmatch("([^,]+)") do
      table.insert(choices, vim.trim(choice))
    end
    if #choices == 0 then
      choices = { text }
    end
    finalize_node("choice_node", text, sr, sc, er, ec, {
      choices = choices,
      summary = table.concat(choices, "|"),
    })
  end)
end

function M._configure_function_node(text, sr, sc, er, ec)
  if not shared.state or #shared.state.nodes == 0 then
    vim.ui.input({
      prompt = "Function body (args available as `args`): ",
      default = "return args[1][1]",
    }, function(body)
      if not body or not shared.state then
        return
      end
      vim.ui.input({
        prompt = "Dependent node positions (comma-separated, e.g. 1,2): ",
        default = "1",
      }, function(deps_str)
        if not deps_str or not shared.state then
          return
        end
        local deps = {}
        for d in deps_str:gmatch("%d+") do
          table.insert(deps, tonumber(d))
        end
        finalize_node("function_node", text, sr, sc, er, ec, {
          body = body,
          deps = deps,
          summary = string.format("f({%s})", deps_str),
        })
      end)
    end)
    return
  end

  local node_labels = {}
  for _, n in ipairs(shared.state.nodes) do
    table.insert(node_labels, string.format("[%d] %s: \"%s\"", n.index, n.type, n.text:sub(1, 20)))
  end

  vim.ui.input({
    prompt = string.format("Dependent node positions (%s): ", table.concat(node_labels, ", ")),
    default = "1",
  }, function(deps_str)
    if not deps_str or not shared.state then
      return
    end
    local deps = {}
    for d in deps_str:gmatch("%d+") do
      table.insert(deps, tonumber(d))
    end
    vim.ui.input({
      prompt = "Function body (use `args[N][1]` for Nth dependency): ",
      default = "return args[1][1]",
    }, function(body)
      if not body or not shared.state then
        return
      end
      finalize_node("function_node", text, sr, sc, er, ec, {
        body = body,
        deps = deps,
        summary = string.format("f({%s})", deps_str),
      })
    end)
  end)
end

function M._configure_rep_node(text, sr, sc, er, ec)
  if not shared.state or #shared.state.nodes == 0 then
    vim.ui.input({
      prompt = "Repeat which node position? ",
      default = "1",
    }, function(input)
      if not input or not shared.state then
        return
      end
      local target = tonumber(input) or 1
      finalize_node("rep", text, sr, sc, er, ec, {
        target = target,
        summary = string.format("rep(%d)", target),
      })
    end)
    return
  end

  local items = {}
  for _, n in ipairs(shared.state.nodes) do
    table.insert(items, string.format("[%d] %s: \"%s\"", n.index, n.type, n.text:sub(1, 30)))
  end

  vim.ui.select(items, {
    prompt = "Repeat which node?",
  }, function(choice)
    if not choice or not shared.state then
      return
    end
    local target = tonumber(choice:match("^%[(%d+)%]")) or 1
    finalize_node("rep", text, sr, sc, er, ec, {
      target = target,
      summary = string.format("rep(%d)", target),
    })
  end)
end

function M._configure_dynamic_node(text, sr, sc, er, ec)
  vim.ui.input({
    prompt = "Dependent node positions (comma-separated, empty for none): ",
    default = "",
  }, function(deps_str)
    if not shared.state then
      return
    end
    deps_str = deps_str or ""
    local deps = {}
    for d in deps_str:gmatch("%d+") do
      table.insert(deps, tonumber(d))
    end
    vim.ui.input({
      prompt = "Default inner text: ",
      default = text,
    }, function(inner)
      if not shared.state then
        return
      end
      inner = inner or text
      finalize_node("dynamic_node", text, sr, sc, er, ec, {
        deps = deps,
        inner_text = inner,
        summary = string.format("d({%s})", deps_str),
      })
    end)
  end)
end

--- Show node type selection via vim.ui.select
function M.assign_node()
  if not shared.state then
    return
  end

  vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<Esc>", true, false, true))

  vim.schedule(function()
    local sr, sc, er, ec = get_visual_range()

    if overlaps_existing(sr, sc, er, ec) then
      vim.notify("Selection overlaps with an existing node!", vim.log.levels.ERROR)
      return
    end

    local selected_lines = vim.api.nvim_buf_get_text(shared.state.buf, sr, sc, er, ec, {})
    local selected_text = table.concat(selected_lines, "\n")

    local items = vim.tbl_map(function(n)
      return n.label
    end, shared.node_types)

    vim.ui.select(items, {
      prompt = string.format("Node type for: \"%s\"", selected_text:sub(1, 40)),
      format_item = function(item)
        for _, n in ipairs(shared.node_types) do
          if n.label == item then
            return item .. " - " .. n.detail
          end
        end
        return item
      end,
    }, function(choice)
      if not choice or not shared.state then
        return
      end
      M.configure_node(choice, selected_text, sr, sc, er, ec)
    end)
  end)
end

--- Undo the last node assignment
function M.undo_last_node()
  if not shared.state or #shared.state.nodes == 0 then
    vim.notify("No nodes to undo", vim.log.levels.WARN)
    return
  end

  table.remove(shared.state.nodes)
  M.refresh_extmarks()
  vim.notify("Undid last node assignment", vim.log.levels.INFO)
end

--- Find the node at the current cursor position
---@return table|nil node, number|nil index
function M.find_node_at_cursor()
  if not shared.state then
    return nil, nil
  end

  local cursor = vim.api.nvim_win_get_cursor(shared.state.win)
  local row = cursor[1] - 1
  local col = cursor[2]

  for idx, node in ipairs(shared.state.nodes) do
    local in_range = false
    if row > node.start_row and row < node.end_row then
      in_range = true
    elseif row == node.start_row and row == node.end_row then
      in_range = col >= node.start_col and col < node.end_col
    elseif row == node.start_row then
      in_range = col >= node.start_col
    elseif row == node.end_row then
      in_range = col < node.end_col
    end

    if in_range then
      return node, idx
    end
  end

  return nil, nil
end

--- Delete the node at cursor position
function M.delete_node_at_cursor()
  if not shared.state then
    return
  end

  local node, idx = M.find_node_at_cursor()
  if not node then
    vim.notify("No node at cursor position", vim.log.levels.WARN)
    return
  end

  table.remove(shared.state.nodes, idx)
  M.reindex_nodes()
  M.refresh_extmarks()
  vim.notify(string.format("Deleted node %d (%s)", idx, node.type), vim.log.levels.INFO)
end

--- Replace/reconfigure the node at cursor position
function M.replace_node_at_cursor()
  if not shared.state then
    return
  end

  local node, idx = M.find_node_at_cursor()
  if not node then
    vim.notify("No node at cursor position", vim.log.levels.WARN)
    return
  end

  local items = vim.tbl_map(function(n)
    return n.label
  end, shared.node_types)

  vim.ui.select(items, {
    prompt = string.format("Replace node %d (%s) with:", idx, node.type),
    format_item = function(item)
      for _, n in ipairs(shared.node_types) do
        if n.label == item then
          return item .. " - " .. n.detail
        end
      end
      return item
    end,
  }, function(choice)
    if not choice or not shared.state then
      return
    end
    table.remove(shared.state.nodes, idx)
    M.configure_node(choice, node.text, node.start_row, node.start_col, node.end_row, node.end_col)
  end)
end

--- Re-index all nodes and fix rep targets
function M.reindex_nodes()
  if not shared.state then
    return
  end

  local name_to_new_index = {}
  for i, node in ipairs(shared.state.nodes) do
    node.index = i
    if node.type == "insert_node" then
      name_to_new_index[node.text] = i
    end
  end

  for _, node in ipairs(shared.state.nodes) do
    if node.type == "rep" then
      local target_idx = name_to_new_index[node.text]
      if target_idx then
        node.config.target = target_idx
        node.config.summary = string.format("rep(%d)", target_idx)
      end
    end
  end
end

--- Refresh all extmarks to match current node state
function M.refresh_extmarks()
  if not shared.state then
    return
  end

  vim.api.nvim_buf_clear_namespace(shared.state.buf, ns, 0, -1)
  vim.api.nvim_set_option_value("modifiable", true, { buf = shared.state.buf })
  for _, node in ipairs(shared.state.nodes) do
    local label = node.type
    if node.config and node.config.summary then
      label = label .. ": " .. node.config.summary
    end
    vim.api.nvim_buf_set_extmark(shared.state.buf, ns, node.start_row, node.start_col, {
      end_row = node.end_row,
      end_col = node.end_col,
      hl_group = "DiagnosticVirtualTextInfo",
      virt_text = { { string.format(" [%d: %s]", node.index, label), "DiagnosticInfo" } },
      virt_text_pos = "eol",
    })
  end
  vim.api.nvim_set_option_value("modifiable", false, { buf = shared.state.buf })
end

return M
