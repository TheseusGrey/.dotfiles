local function augroup(name)
  return vim.api.nvim_create_augroup("dotfiles_" .. name, { clear = true })
end

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Check if we need to reload the file when it changed
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup("checktime"),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

-- resize splits if window got resized
vim.api.nvim_create_autocmd({ "VimResized" }, {
  group = augroup("resize_splits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})

-- close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    "PlenaryTestPopup",
    "help",
    "lspinfo",
    "notify",
    "checkhealth",
    "dbout",
    "gitsigns.blame",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", {
      buffer = event.buf,
      silent = true,
      desc = "Quit buffer",
    })
  end,
})

-- wrap and check for spell in text filetypes
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("wrap_spell"),
  pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

vim.api.nvim_create_autocmd("TermOpen", {
  group = augroup("terminal_insert"),
  pattern = "term://*",
  callback = function()
    vim.cmd.startinsert()
  end,
})

-- Refresh Lualine for macro status
vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
  callback = function()
    -- small delay needed on RecordingLeave as reg_recording()
    -- clears before the event fully fires
    vim.schedule(function()
      require("lualine").refresh()
    end)
  end,
})

-- Format on "save"
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function(args)
    require("conform").format({ bufnr = args.buf })
  end,
})

-- Post-install steps for a few plugins
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == "blink.cmp" and (kind == "install" or kind == "update") then
      vim.system({ "cargo", "build", "--release" }, {
        cwd = ev.data.spec.path,
      })

      -- Used once blink.cmp has been upgraded to v2
      -- if not ev.data.active then
      --   vim.cmd.packadd("blink.cmp")
      --   vim.cmd.packadd("blink.lib")
      -- end
      -- require("blink.cmp").build():wait(60000)
    end

    if name == "LuaSnip" and (kind == "install" or kind == "update") then
      vim.system({ "make", "install_jsregexp" }, {
        cwd = ev.data.spec.path,
      })
    end

    if name == "Mason" and (kind == "install" or kind == "update") then
      vim.cmd("MasonUpdate")
    end

    if name == "Mason" and (kind == "install" or kind == "update") then
      vim.cmd("TSUpdate")
    end
  end,
})
