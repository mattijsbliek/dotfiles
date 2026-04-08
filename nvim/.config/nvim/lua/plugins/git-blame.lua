return {
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true,
      current_line_blame_opts = {
        delay = 300,
        virt_text_pos = "eol",
      },
    },
    keys = {
      { "<leader>gB", "<cmd>Gitsigns blame<cr>", desc = "Blame (full file)" },
      {
        "<leader>gb",
        function()
          require("gitsigns").blame_line({ full = true })
        end,
        desc = "Blame line (full commit)",
      },
      {
        "<leader>gt",
        "<cmd>Gitsigns toggle_current_line_blame<cr>",
        desc = "Toggle inline blame",
      },
    },
  },
}
