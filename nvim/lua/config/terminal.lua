local state = {
  buf = -1,
  win = -1,
}

local function create_terminal(opts)
  opts = opts or {}

  -- Calculate dimensions
  local width = math.min(vim.o.columns * 0.8, 122)
  local height = math.floor(vim.o.lines * 0.8)

  -- Calculate starting position
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  local win_opts = {
    title = vim.o.shell:gsub("/usr/bin/", " ") .. " ",
    relative = "editor",
    width = math.floor(width),
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
  }

  local buf = nil
  if vim.api.nvim_buf_is_valid(state.buf) then
    buf = state.buf
  else
    buf = vim.api.nvim_create_buf(false, true)
  end

  local win = vim.api.nvim_open_win(buf, true, win_opts)

  return { buf = buf, win = win }
end

vim.api.nvim_create_user_command("ToggleTerm", function()
  if not vim.api.nvim_win_is_valid(state.win) then
    state = create_terminal({ buf = state.buf })
    if vim.bo[state.buf].buftype ~= "terminal" then
      vim.cmd.term()
    end
    vim.api.nvim_set_option_value("buflisted", false, { buf = state.buf })
  else
    vim.api.nvim_win_hide(state.win)
  end
end, {})

vim.keymap.set("t", "<esc><esc>", "<c-\\><c-n>")
vim.keymap.set({ "n" }, "<leader>tt", "<cmd>ToggleTerm<cr>", { noremap = true, silent = true })
