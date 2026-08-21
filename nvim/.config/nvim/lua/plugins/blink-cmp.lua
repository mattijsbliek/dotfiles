return {
  {
    "saghen/blink.cmp",
    version = "1.*",
    opts = {
      keymap = {
        ["<Tab>"] = { "accept", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
      },
    },
  },
}
