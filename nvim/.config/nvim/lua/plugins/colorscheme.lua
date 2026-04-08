return {
  {
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    lazy = false, -- load at startup
    priority = 1000, -- load before other plugins
    config = function()
      require("github-theme").setup({
        -- add any options here, or leave empty for defaults
      })
    end,
  },

  -- Tell LazyVim to use this as the colorscheme
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "github_dark_dimmed",
    },
  },
}
