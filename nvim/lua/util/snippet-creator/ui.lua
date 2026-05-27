--- UI utilities: floating windows, scratch pad, keymaps
local shared = require("util.snippet-creator.state")

local M = {}

--- Get existing triggers for a filetype by reading the snippet file
---@param ft string
---@return table<string, boolean>
function M.get_existing_triggers(ft)
  local triggers = {}
  local snippet_dir = vim.fn.stdpath("config") .. "/lua/snippets"
  local filepath = snippet_dir .. "/" .. ft .. ".lua"

  if vim.fn.filereadable(filepath) == 1 then
    local content = table.concat(vim.fn.readfile(filepath), "\n")
    for trig in content:gmatch('trig%s*=%s*"([^"]+)"') do
      triggers[trig] = true
    end
  end

  return triggers
end

--- Create a centered floating window
---@param buf number
---@param opts? {title?: string|table, footer?: string|table, footer_pos?: string, width_ratio?: number, height_ratio?: number}
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

  -- Support title as string or pre-built table of {text, hl} pairs
  local title = opts.title
  if type(title) == "string" then
    title = { { " " .. title .. " ", "FloatTitle" } }
  end

  local footer = opts.footer
  if type(footer) == "string" then
    footer = { { footer, "FloatFooter" } }
  end

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = title,
    title_pos = title and "center" or nil,
    footer = footer,
    footer_pos = opts.footer_pos or nil,
  })

  return win
end

--- Prompt for snippet metadata using a floating form window
---@param source_ft string
---@param callback fun(meta: {name: string, description: string, trigger: string})
function M.prompt_metadata(source_ft, callback)
  local existing_triggers = M.get_existing_triggers(source_ft)

  local buf = vim.api.nvim_create_buf(false, true)
  -- Layout: label on one line, input on the next (indented)
  local lines = {
    "  Trigger *",  -- 1 (label)
    "  ",           -- 2 (input)
    "",             -- 3 (spacer)
    "  Name",       -- 4 (label)
    "  ",           -- 5 (input)
    "",             -- 6 (spacer)
    "  Description", -- 7 (label)
    "  ",           -- 8 (input)
    "",             -- 9 (spacer)
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })

  local ns = vim.api.nvim_create_namespace("snippet_form")

  local win = M.open_float(buf, {
    title = {
      { " ", "FloatBorder" },
      { " New Snippet ", "Title" },
      { " ", "FloatBorder" },
      { " " .. source_ft .. " ", "DiagnosticInfo" },
      { " ", "FloatBorder" },
    },
    footer = {
      { " <C-n>/<C-p> ", "DiagnosticHint" },
      { "navigate", "Comment" },
      { " │ ", "FloatBorder" },
      { " <C-s> ", "DiagnosticOk" },
      { "confirm", "Comment" },
      { " │ ", "FloatBorder" },
      { " <Esc> ", "DiagnosticError" },
      { "cancel", "Comment" },
      { " ", "FloatBorder" },
    },
    footer_pos = "center",
    width_ratio = 0.45,
    height_ratio = 0.35,
  })

  -- Input line numbers (1-indexed)
  local input_lines = { 2, 5, 8 }

  -- Highlight labels
  vim.api.nvim_buf_set_extmark(buf, ns, 0, 2, { end_col = 9, hl_group = "Keyword" })   -- "Trigger"
  vim.api.nvim_buf_set_extmark(buf, ns, 0, 10, { end_col = 11, hl_group = "DiagnosticError" }) -- "*"
  vim.api.nvim_buf_set_extmark(buf, ns, 3, 2, { end_col = 6, hl_group = "Keyword" })   -- "Name"
  vim.api.nvim_buf_set_extmark(buf, ns, 6, 2, { end_col = 13, hl_group = "Keyword" })  -- "Description"

  -- Highlight input lines with a different background
  for _, lnum in ipairs(input_lines) do
    vim.api.nvim_buf_set_extmark(buf, ns, lnum - 1, 0, {
      end_row = lnum - 1,
      end_col = 0,
      hl_eol = true,
      line_hl_group = "CursorLine",
    })
  end

  -- Place cursor at end of first input line
  vim.api.nvim_win_set_cursor(win, { 2, #"  " })

  local validation_extmark = nil

  local function show_validation_error(msg)
    if validation_extmark then
      vim.api.nvim_buf_del_extmark(buf, ns, validation_extmark)
    end
    validation_extmark = vim.api.nvim_buf_set_extmark(buf, ns, 1, 0, {
      virt_lines = { { { "  ⚠ " .. msg, "DiagnosticWarn" } } },
      virt_lines_above = false,
    })
  end

  local function clear_validation()
    if validation_extmark then
      vim.api.nvim_buf_del_extmark(buf, ns, validation_extmark)
      validation_extmark = nil
    end
  end

  local function goto_field(idx)
    clear_validation()
    local lnum = input_lines[idx]
    if lnum then
      local line = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1] or ""
      vim.api.nvim_win_set_cursor(win, { lnum, #line })
    end
  end

  local function current_field_index()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local row = cursor[1]
    for i, lnum in ipairs(input_lines) do
      if row <= lnum then
        return i
      end
    end
    return #input_lines
  end

  local function close_and_submit()
    local buf_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local trigger = vim.trim((buf_lines[2] or ""):sub(3))  -- strip leading "  "
    local name = vim.trim((buf_lines[5] or ""):sub(3))
    local description = vim.trim((buf_lines[8] or ""):sub(3))

    if trigger == "" then
      show_validation_error("Trigger is required")
      goto_field(1)
      return
    end

    if existing_triggers[trigger] then
      show_validation_error("Trigger '" .. trigger .. "' already exists for " .. source_ft)
      goto_field(1)
      return
    end

    if trigger:match("%s") then
      show_validation_error("Trigger cannot contain spaces")
      goto_field(1)
      return
    end

    vim.api.nvim_win_close(win, true)

    if name == "" then
      name = trigger
    end

    callback({ name = name, description = description, trigger = trigger })
  end

  -- Keymaps
  local map_opts = { buffer = buf, noremap = true }

  vim.keymap.set("n", "<Esc>", function()
    vim.api.nvim_win_close(win, true)
    vim.notify("Snippet creation cancelled", vim.log.levels.INFO)
  end, map_opts)

  vim.keymap.set({ "n", "i" }, "<C-s>", close_and_submit, map_opts)

  -- Field navigation
  vim.keymap.set({ "n", "i" }, "<C-n>", function()
    local idx = current_field_index()
    if idx < #input_lines then
      goto_field(idx + 1)
      vim.cmd("startinsert!")
    else
      close_and_submit()
    end
  end, map_opts)

  vim.keymap.set({ "n", "i" }, "<C-p>", function()
    local idx = current_field_index()
    if idx > 1 then
      goto_field(idx - 1)
      vim.cmd("startinsert!")
    end
  end, map_opts)

  -- Prevent <CR> from inserting newlines; use it as next-field too
  vim.keymap.set("i", "<CR>", function()
    local idx = current_field_index()
    if idx < #input_lines then
      goto_field(idx + 1)
      vim.cmd("startinsert!")
    else
      close_and_submit()
    end
  end, map_opts)

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
    title = {
      { " ", "FloatBorder" },
      { " " .. meta.name .. " ", "Title" },
      { " ", "FloatBorder" },
      { " " .. meta.trigger .. " ", "DiagnosticOk" },
      { " ", "FloatBorder" },
    },
    footer = M._scratch_pad_footer(),
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
    title = {
      { " ", "FloatBorder" },
      { " " .. meta.name .. " ", "Title" },
      { " ", "FloatBorder" },
      { " " .. meta.trigger .. " ", "DiagnosticOk" },
      { " ", "FloatBorder" },
      { " auto ", "DiagnosticHint" },
      { " ", "FloatBorder" },
    },
    footer = M._scratch_pad_footer(),
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

--- Build the colored footer for scratch pad windows
---@return table
function M._scratch_pad_footer()
  return {
    { " v+<CR> ", "DiagnosticHint" },
    { "assign", "Comment" },
    { " │ ", "FloatBorder" },
    { "d ", "DiagnosticWarn" },
    { "delete", "Comment" },
    { " │ ", "FloatBorder" },
    { "r ", "DiagnosticWarn" },
    { "replace", "Comment" },
    { " │ ", "FloatBorder" },
    { "<C-s> ", "DiagnosticOk" },
    { "save", "Comment" },
    { " │ ", "FloatBorder" },
    { "u ", "DiagnosticInfo" },
    { "undo", "Comment" },
    { " │ ", "FloatBorder" },
    { "<Esc> ", "DiagnosticError" },
    { "cancel", "Comment" },
    { " ", "FloatBorder" },
  }
end

return M
