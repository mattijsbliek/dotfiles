-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Leader key to ,
vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- Capture the target project directory: use the argument passed to nvim if it's a directory,
-- otherwise fall back to the directory Neovim was launched from.
local arg = vim.fn.argv(0)
if arg ~= "" and vim.fn.isdirectory(vim.fn.fnamemodify(arg, ":p")) == 1 then
  vim.g._launch_cwd = vim.fn.fnamemodify(arg, ":p")
else
  vim.g._launch_cwd = vim.fn.getcwd()
end

vim.g.lazyvim_php_lsp = "intelephense"

local opt = vim.opt

-- Hide buffers instead of closing them
opt.hidden = true

-- Visual autocomplete for command menu
opt.wildmenu = true

-- Set terminal to 256 colors
opt.termguicolors = true

-- Enable line highlight
opt.cursorline = true

-- Column width indicator
opt.textwidth = 0
opt.colorcolumn = "+1"

-- Show relative line numbers with absolute for current line
opt.relativenumber = true
opt.number = true

-- Do not wrap lines
opt.wrap = false
opt.wrapmargin = 0

-- Disable backups and swap files
opt.backup = false
opt.swapfile = false

-- Make Vim autoread changed files
opt.autoread = true

-- Word boundary settings
opt.iskeyword:remove("_")
opt.iskeyword:append("#")
opt.iskeyword:append("$")

-- Share clipboard with the OS
opt.clipboard = "unnamedplus"

-- Set encoding to UTF-8
opt.encoding = "utf-8"

-- Scroll when reaching the top or bottom x lines
opt.scrolloff = 5

-- File format
opt.fileformat = "unix"

-- Line break
opt.linebreak = true

-- Status line (LazyVim handles this via lualine)
opt.laststatus = 2
opt.ttimeoutlen = 50

-- Prevent zero leading numbers to be interpreted as octal
opt.nrformats = "hex"

-- Autosave when losing focus
opt.autowriteall = true

-- Search settings
opt.ignorecase = true
opt.smartcase = true
opt.gdefault = true
opt.hlsearch = true
opt.incsearch = true
opt.showmatch = true

-- Remember more commands and search history
opt.history = 1000

-- Use many levels of undo
opt.undolevels = 1000

-- Don't beep
opt.errorbells = false
