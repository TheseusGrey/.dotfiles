--- Snippet creator: create LuaSnip snippets interactively from visual selections
--- Entry points for the snippet creation workflow
local ui = require("util.snippet-creator.ui")
local ast = require("util.snippet-creator.ast")

local M = {}

--- Manual snippet creation from visual selection (<leader>es)
function M.create_from_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_row = start_pos[2]
  local end_row = end_pos[2]

  local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
  local source_ft = vim.bo.filetype

  if #lines == 0 or source_ft == "" then
    vim.notify("No text selected or no filetype detected", vim.log.levels.WARN)
    return
  end

  ui.prompt_metadata(source_ft, function(meta)
    vim.schedule(function()
      ui.open_scratch_pad(lines, meta, source_ft)
    end)
  end)
end

--- Auto-tagged snippet creation from visual selection (<leader>eS)
function M.create_from_selection_auto()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_row = start_pos[2]
  local end_row = end_pos[2]

  local source_buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(source_buf, start_row - 1, end_row, false)
  local source_ft = vim.bo.filetype

  if #lines == 0 or source_ft == "" then
    vim.notify("No text selected or no filetype detected", vim.log.levels.WARN)
    return
  end

  ui.prompt_metadata(source_ft, function(meta)
    vim.schedule(function()
      vim.notify("Analyzing AST and querying types...", vim.log.levels.INFO)
      ast.build_auto_tags(source_buf, lines, start_row - 1, function(auto_nodes)
        ui.open_scratch_pad_with_tags(lines, meta, source_ft, auto_nodes)
      end)
    end)
  end)
end

return M
