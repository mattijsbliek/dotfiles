-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- Restore the launch directory after persistence.nvim restores a session.
-- Without this, session restore sets cwd to the previous project's directory.
autocmd("VimEnter", {
  group = augroup("restore_launch_cwd", { clear = true }),
  callback = function()
    if vim.g._launch_cwd then
      vim.cmd.cd(vim.g._launch_cwd)
    end
  end,
  nested = true,
})

-- Git commit textwidth
autocmd("FileType", {
  group = augroup("git_textwidth", { clear = true }),
  pattern = "gitcommit",
  callback = function()
    vim.opt_local.textwidth = 72
  end,
})

-- Disable textwidth for certain filetypes
autocmd({ "BufRead" }, {
  group = augroup("no_textwidth", { clear = true }),
  pattern = { "*.html" },
  callback = function()
    vim.opt_local.textwidth = 0
  end,
})

-- Set markdown filetype
autocmd({ "BufRead", "BufNewFile" }, {
  group = augroup("markdown_ft", { clear = true }),
  pattern = "*.md",
  callback = function()
    vim.bo.filetype = "markdown"
  end,
})

-- Set scss filetype
autocmd({ "BufRead", "BufNewFile" }, {
  group = augroup("scss_ft", { clear = true }),
  pattern = "*.scss",
  callback = function()
    vim.bo.filetype = "scss.css"
  end,
})
