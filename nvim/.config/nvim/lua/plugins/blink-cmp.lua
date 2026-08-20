return {
  {
    "saghen/blink.cmp",
    branch = "v1",
    opts = {
      keymap = {
        ["<Tab>"] = { "accept", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
      },
    },
  },
}
