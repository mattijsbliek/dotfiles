-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
--

local map = vim.keymap.set

-- Remap : to ; and ; to :
map("n", ";", ":", { desc = "Command mode" })
map("n", ":", ";", { desc = "Repeat f/t" })

-- Swap jump list navigation (Ctrl+I = back, Ctrl+O = forward)
map("n", "<C-i>", "<C-o>", { desc = "Jump list backward" })
map("n", "<C-o>", "<C-i>", { desc = "Jump list forward" })

-- Move up and down half screens
map("n", "<C-j>", "<C-d>", { desc = "Half page down" })
map("n", "<C-k>", "<C-u>", { desc = "Half page up" })

-- Move in visual lines instead of actual lines
map("n", "j", "gj", { desc = "Move down (visual line)" })
map("n", "k", "gk", { desc = "Move up (visual line)" })
map("n", "gj", "j", { desc = "Move down (actual line)" })
map("n", "gk", "k", { desc = "Move up (actual line)" })

-- Move to beginning and end of line with H and L
map({ "n", "o", "v" }, "H", "^", { desc = "Beginning of line" })
map({ "n", "o", "v" }, "L", "$", { desc = "End of line" })

-- Clear search highlights with ,<space>
map("n", "<leader><space>", ":noh<CR>", { silent = true, desc = "Clear search highlights" })

-- Save current buffer
map("n", "<leader>w", ":w!<CR>", { desc = "Save file" })

-- Edit config files
map("n", "<leader>ev", function()
  vim.cmd("vsplit")
  vim.cmd("edit $MYVIMRC")
end, { desc = "Edit init.lua" })

-- Split line (inverse of J)
map("n", "S", "i<CR><Esc>^mwgk:silent! s/\\v +$//<CR>:noh<CR>`w", { desc = "Split line" })

-- Open new split window with <leader>s and focus on it
map("n", "<leader>s", "<C-w>v<C-w>l", { desc = "Vertical split and focus" })

-- Go to previous/next buffer
map("n", "<D-[>", ":bp<CR>", { silent = true, desc = "Previous buffer" })
map("n", "<D-]>", ":bn<CR>", { silent = true, desc = "Next buffer" })

-- Recent files
map("n", "<leader>o", function()
  require("telescope.builtin").oldfiles()
end, { desc = "Recent files" })

-- Buffer picker (replaces CtrlPBuffer)
map("n", "<leader>j", function()
  require("telescope.builtin").buffers()
end, { desc = "Find buffers" })

-- Search with grep (replaces Ag)
map("n", "<leader>f", function()
  require("telescope.builtin").live_grep()
end, { desc = "Live grep" })

-- Override LazyVim's <leader>fg (git files) with live grep
map("n", "<leader>fg", function()
  require("telescope.builtin").live_grep()
end, { desc = "Live grep" })

-- Quickly switch buffer with <leader>#
for i = 1, 99 do
  map("n", "<leader>" .. i, ":" .. i .. "b<CR>", { silent = true, desc = "Go to buffer " .. i })
end

-- Quickly delete buffers with <leader>d#
for i = 1, 99 do
  map("n", "<leader>d" .. i, function()
    vim.cmd("bdelete " .. i)
  end, { silent = true, desc = "Delete buffer " .. i })
end

-- Rename file
map("n", "<leader>r", function()
  local old_name = vim.fn.expand("%")
  local new_name = vim.fn.input("New file name: ", old_name, "file")
  if new_name ~= "" and new_name ~= old_name then
    vim.cmd("saveas " .. new_name)
    vim.fn.delete(old_name)
    vim.cmd("redraw!")
  end
end, { desc = "Rename file" })

-- Yank entire line regardless of cursor position (overrides LazyVim's y$ default)
map("n", "Y", "yy", { desc = "Yank entire line" })

-- Tab navigation
map("n", "<M-Left>", ":tabprevious<CR>", { silent = true, desc = "Previous tab" })
map("n", "<M-Right>", ":tabnext<CR>", { silent = true, desc = "Next tab" })

-- Find the enclosing method name using Treesitter
local function get_enclosing_method()
  local node = vim.treesitter.get_node()
  while node do
    local type = node:type()
    if type == "method_declaration" or type == "function_definition" then
      -- Find the "name" child node
      for child in node:iter_children() do
        if child:type() == "name" then
          return vim.treesitter.get_node_text(child, 0)
        end
      end
    end
    node = node:parent()
  end
  return nil
end

-- Copy fully qualified class name, optionally with method (PHP + Java)
map("n", "<leader>cp", function()
  local ft = vim.bo.filetype
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local ns, class

  if ft == "java" then
    for _, line in ipairs(lines) do
      local trimmed = line:match("^%s*(.-)%s*$")
      if not ns then ns = trimmed:match("^package%s+([%w%.]+)") end
      if not class and not trimmed:match("^[/%*]") and not trimmed:match("^import%s") then
        for _, keyword in ipairs({ "class", "interface", "enum", "record" }) do
          class = trimmed:match("%f[%a]" .. keyword .. "%s+(%w+)")
          if class then break end
        end
      end
      if ns and class then break end
    end
    if ns and class then
      local fqn = ns .. "." .. class
      local method = get_enclosing_method()
      if method then fqn = fqn .. "::" .. method end
      vim.fn.setreg("+", fqn)
      vim.notify("Copied: " .. fqn)
    else
      vim.notify("Could not determine FQN", vim.log.levels.WARN)
    end
  else
    for _, line in ipairs(lines) do
      if not ns then ns = line:match("^namespace%s+([%w\\]+)") end
      if not class then class = line:match("^class%s+(%w+)") end
      if not class then class = line:match("^abstract%s+class%s+(%w+)") end
      if not class then class = line:match("^final%s+class%s+(%w+)") end
      if not class then class = line:match("^interface%s+(%w+)") end
      if not class then class = line:match("^enum%s+(%w+)") end
      if not class then class = line:match("^trait%s+(%w+)") end
      if ns and class then break end
    end
    if ns and class then
      local fqn = ns .. "\\" .. class
      local method = get_enclosing_method()
      if method then fqn = fqn .. "::" .. method end
      vim.fn.setreg("+", fqn)
      vim.notify("Copied: " .. fqn)
    else
      vim.notify("Could not determine FQN", vim.log.levels.WARN)
    end
  end
end, { desc = "Copy FQN (PHP/Java)" })

-- Save file with sudo
vim.api.nvim_create_user_command("W", "w !sudo tee % >/dev/null", {})
