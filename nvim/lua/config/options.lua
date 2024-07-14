
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.o.laststatus = 3
vim.o.termguicolors = true

local opt = vim.opt
opt.clipboard = "unnamedplus"
opt.cursorline = true
opt.linebreak = true
opt.list = true
opt.scrolloff = 999
opt.splitbelow = true
opt.splitkeep = "screen"
opt.splitright = true
opt.statuscolumn = [[%!v:lua.require'util.ui'.statuscolumn()]]
opt.tabstop = 2
opt.undofile = true
opt.undolevels = 10000
opt.conceallevel = 2
opt.shiftround = true
opt.shiftwidth = 2
opt.ignorecase = true
opt.smartcase = true
opt.relativenumber = true
opt.number = true
opt.showmode = true
opt.expandtab = true

vim.wo.relativenumber = true
