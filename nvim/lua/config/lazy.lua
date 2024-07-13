-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.o.laststatus = 3
vim.o.termguicolors = true
vim.opt.clipboard = "unnamedplus"
vim.opt.cursorline = true
vim.opt.linebreak = true
vim.opt.list = true
vim.opt.scrolloff = 999
vim.opt.splitbelow = true
vim.opt.splitkeep = "screen"
vim.opt.splitright = true
vim.opt.statuscolumn = [[%!v:lua.require'util.ui'.statuscolumn()]]
vim.opt.tabstop = 2
vim.opt.undofile = true
vim.opt.undolevels = 10000
vim.opt.conceallevel = 2
vim.opt.shiftround = true
vim.opt.shiftwidth = 2
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.showmode = true
vim.opt.expandtab = true

vim.wo.relativenumber = true

-- Setup lazy.nvim
require("lazy").setup({
	spec = {
		-- import your plugins
		{ import = "plugins" },
	},
	-- Configure any other settings here. See the documentation for more details.
	-- colorscheme that will be used when installing plugins.
	install = { colorscheme = { "nordic" } },
	-- automatically check for plugin updates
	checker = { enabled = true },
})
