return {
  { "nvim-neo-tree/neo-tree.nvim", enabled = false },
  {
    "snacks.nvim",
    opts = {
      picker = {
        sources = {
          files = {
            hidden = true,
            follow = false,
          },
          grep = {
            follow = false,
          },
          grep_word = {
            follow = false,
          },
          explorer = {
            hidden = true,
            ignored = true,
            actions = {
              explorer_yank_rel = function(picker, item)
                if item then
                  local abs = require("snacks.picker.util").path(item)
                  local rel = vim.fn.fnamemodify(abs, ":~:.")
                  vim.fn.setreg("+", rel)
                  require("snacks").notify.info("Copied: " .. rel)
                end
              end,
            },
            win = {
              list = {
                keys = {
                  ["o"] = "confirm",
                  ["gy"] = "explorer_yank_rel",
                },
              },
            },
          },
        },
      },
    },
  },
}
