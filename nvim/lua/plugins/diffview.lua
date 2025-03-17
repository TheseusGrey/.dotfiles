local diff_view_open = false
local function toggle_diff_view()
  if not diff_view_open then
    vim.cmd("DiffviewOpen")
    diff_view_open = true
  else
    vim.cmd("DiffviewClose")
    diff_view_open = false
  end
end

return {
  "sindrets/diffview.nvim",
  keys = {
    { "<leader>gg", toggle_diff_view, desc = "Goto Git diffview" },
  },
}
