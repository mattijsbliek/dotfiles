return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      textobjects = {
        move = {
          enable = true,
          set_jumps = true, -- adds jumps to the jumplist
          goto_next_start = {
            ["]c"] = { query = "@class.outer", desc = "Next class start" },
          },
          goto_next_end = {
            ["]C"] = { query = "@class.outer", desc = "Next class end" },
          },
          goto_previous_start = {
            ["[c"] = { query = "@class.outer", desc = "Previous class start" },
          },
          goto_previous_end = {
            ["[C"] = { query = "@class.outer", desc = "Previous class end" },
          },
        },
      },
    },
  },
}
