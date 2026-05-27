local M = {}

M.icons = {
  [vim.diagnostic.severity.ERROR] = "",
  [vim.diagnostic.severity.WARN] = "",
  [vim.diagnostic.severity.HINT] = "",
  [vim.diagnostic.severity.INFO] = "",
}

---A table of border elements, can provide a highlight name to make sure the text is colored appropriately.
---@param hl_name any
---@return table
function M.border(hl_name)
  return {
    { "╭", hl_name },
    { "─", hl_name },
    { "╮", hl_name },
    { "│", hl_name },
    { "╯", hl_name },
    { "─", hl_name },
    { "╰", hl_name },
    { "│", hl_name },
  }
end

---Returns the width & Height of the given window
---@return table
function M.screen()
  local window = vim.api.nvim_get_current_win()
  local window_info = vim.fn.getwininfo(window)[1] -- First entry
  local real_width = window_info.width - window_info.textoff
  return {
    width = real_width,
    height = window_info.height,
  }
end

return M
