--- UI utilities: floating windows, scratch pad, keymaps
local shared = require("util.snippet-creator.state")

local M = {}

--- Create a centered floating window
---@param buf number
---@param opts? {title?: string, footer?: string, footer_pos?: string, width_ratio?: number, height_ratio?: number}
---@return number win
function M.open_float(buf, opts)
  opts = opts or {}
  local width_ratio = opts.width_ratio or 0.6
  local height_ratio = opts.height_ratio or 0.6

  local editor_width = vim.api.nvim_get_option_value("columns", {})
  local editor_height = vim.api.nvim_get_option_value("lines", {})

  local win_width = math.floor(editor_width * width_ratio)
  local win_height = math.floor(editor_height * height_ratio)
  local row = math.floor((editor_height - win_height) / 2)
  local col = math.floor((editor_width - win_width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = opts.title and (" " .. opts.title .. " ") or nil,
    title_pos = opts.title and "center" or nil,
    footer = opts.footer and { { opts.footer, "FloatFooter" } } or nil,
    footer_pos = opts.footer_pos or nil,
  })

  return win
end

--- Prompt for snippet metadata using a floating form window
---@param callback fun(meta: {name: string, description: string, trigger: string})
function M.prompt_metadata(callback)
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = {
    "# Snippet Metadata (press <CR> on last field or <C-s> to confirm, <Esc> to cancel)",
    "",
    "Trigger:     ",
    "Name:        ",
    "Description: ",
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })

  local win = M.open_float(buf, { title = "New Snippet", width_ratio = 0.5, height_ratio = 0.25 })

  -- Place cursor at end of Trigger line
  vim.api.nvim_win_set_cursor(win, { 3, #"Trigger:     " })

  local function close_and_submit()
    local buf_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local trigger = (buf_lines[3] or ""):match("^Trigger:%s*(.*)$") or ""
    local name = (buf_lines[4] or ""):match("^Name:%s*(.*)$") or ""
    local description = (buf_lines[5] or ""):match("^Description:%s*(.*)$") or ""

    trigger = vim.trim(trigger)
    name = vim.trim(name)
    description = vim.trim(description)

    vim.api.nvim_win_close(win, true)

    if trigger == "" then
      vim.notify("Snippet creation cancelled: trigger is required", vim.log.levels.WARN)
      return
    end

    if name == "" then
      name = trigger
    end

    callback({ name = name, description = description, trigger = trigger })
  end

  -- Keymaps for the form
  vim.keymap.set("n", "<Esc>", function()
    vim.api.nvim_win_close(win, true)
    vim.notify("Snippet creation cancelled", vim.log.levels.INFO)
  end, { buffer = buf })

  vim.keymap.set("n", "<C-s>", close_and_submit, { buffer = buf })
  vim.keymap.set("i", "<C-s>", close_and_submit, { buffer = buf })

  -- Enter on the last field submits
  vim.keymap.set("i", "<CR>", function()
    local cursor = vim.api.nvim_win_get_cursor(win)
    if cursor[1] >= 5 then
      close_and_submit()
    else
      -- Move to next field
      local next_row = cursor[1] + 1
      if next_row > 5 then
        next_row = 5
      end
      local line = vim.api.nvim_buf_get_lines(buf, next_row - 1, next_row, false)[1] or ""
      vim.api.nvim_win_set_cursor(win, { next_row, #line })
    end
  end, { buffer = buf })

  vim.cmd("startinsert!")
end

--- Set up all scratch pad keymaps (shared between manual and auto-tagged)
---@param buf number
---@param win number
function M.setup_scratch_pad_keymaps(buf, win)
  local nodes = require("util.snippet-creator.nodes")
  local serialize = require("util.snippet-creator.serialize")

  vim.keymap.set("x", "<CR>", function()
    nodes.assign_node()
  end, { buffer = buf, noremap = true, desc = "Assign snippet node to selection" })

  vim.keymap.set("n", "<C-s>", function()
    serialize.save_snippet()
  end, { buffer = buf, desc = "Save snippet" })

  vim.keymap.set("n", "<Esc>", function()
    vim.api.nvim_win_close(win, true)
    shared.state = nil
    vim.notify("Snippet creation cancelled", vim.log.levels.INFO)
  end, { buffer = buf, desc = "Cancel snippet creation" })

  vim.keymap.set("n", "u", function()
    nodes.undo_last_node()
  end, { buffer = buf, desc = "Undo last node assignment" })

  vim.keymap.set("n", "d", function()
    nodes.delete_node_at_cursor()
  end, { buffer = buf, desc = "Delete node at cursor" })

  vim.keymap.set("n", "r", function()
    nodes.replace_node_at_cursor()
  end, { buffer = buf, desc = "Replace node at cursor" })
end

--- Open the scratch pad with the selected text for node assignment
---@param lines string[]
---@param meta {name: string, description: string, trigger: string}
---@param source_ft string
function M.open_scratch_pad(lines, meta, source_ft)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  vim.api.nvim_set_option_value("filetype", source_ft, { buf = buf })

  local win = M.open_float(buf, {
    title = string.format("Snippet: %s [%s]", meta.name, meta.trigger),
    footer = " v+<CR>: assign │ d: delete │ r: replace │ <C-s>: save │ u: undo │ <Esc>: cancel ",
    footer_pos = "center",
    width_ratio = 0.7,
    height_ratio = 0.6,
  })

  shared.state = {
    source_ft = source_ft,
    lines = lines,
    nodes = {},
    buf = buf,
    win = win,
    meta = meta,
  }

  M.setup_scratch_pad_keymaps(buf, win)

  vim.notify(
    "Select text in visual mode and press <CR> to assign a node.\n<C-s> to save, <Esc> to cancel, u to undo last.",
    vim.log.levels.INFO
  )
end

--- Open scratch pad with pre-applied auto-tags
---@param lines string[]
---@param meta {name: string, description: string, trigger: string}
---@param source_ft string
---@param auto_nodes table[]
function M.open_scratch_pad_with_tags(lines, meta, source_ft, auto_nodes)
  local nodes_mod = require("util.snippet-creator.nodes")
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  vim.api.nvim_set_option_value("filetype", source_ft, { buf = buf })

  local win = M.open_float(buf, {
    title = string.format("Snippet: %s [%s] (auto-tagged)", meta.name, meta.trigger),
    footer = " v+<CR>: assign │ d: delete │ r: replace │ <C-s>: save │ u: undo │ <Esc>: cancel ",
    footer_pos = "center",
    width_ratio = 0.7,
    height_ratio = 0.6,
  })

  shared.state = {
    source_ft = source_ft,
    lines = lines,
    nodes = auto_nodes,
    buf = buf,
    win = win,
    meta = meta,
  }

  nodes_mod.refresh_extmarks()
  M.setup_scratch_pad_keymaps(buf, win)

  vim.notify(
    string.format("Auto-tagged %d nodes. Review and edit as needed.", #auto_nodes),
    vim.log.levels.INFO
  )
end

return M
