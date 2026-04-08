return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        ["<Tab>"] = { "accept", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
      },
    },
  },
}
