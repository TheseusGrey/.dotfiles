local function macro_state()
  local reg = vim.fn.reg_recording()
  if reg == "" then
    return ""
  end
  return "@" .. reg
end

return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      theme = "auto",
      globalstatus = vim.o.laststatus == 3,
      disabled_filetypes = { statusline = { "dashboard", "alpha", "ministarter" } },
      section_separators = "",
      component_separators = "",
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "diagnostics" },
      lualine_c = { macro_state },
      lualine_y = {},
      lualine_z = { "location" },
    },
  },
}
