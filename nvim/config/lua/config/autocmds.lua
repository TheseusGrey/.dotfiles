-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

vim.api.nvim_create_augroup("user_focus", { clear = true })

vim.api.nvim_create_autocmd("User", {
  group = "user_focus",
  pattern = "GoyoEnter",
  callback = function()
    vim.api.nvim_command(":Limelight")
    require("lualine").hide()
  end,
})

vim.api.nvim_create_autocmd("User", {
  group = "user_focus",
  pattern = "GoyoLeave",
  callback = function()
    vim.api.nvim_command(":Limelight!")
    require("lualine").hide({ unhide = true })
  end,
})
