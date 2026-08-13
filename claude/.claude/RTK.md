# RTK

A PreToolUse hook rewrites Bash commands through [`rtk`](https://github.com/rtk-ai/rtk),
which filters verbose CLI output down to what a model actually needs. This is
transparent — write normal commands.

Meta commands, which are *not* rewritten and must be typed as-is:

```bash
rtk gain              # token savings so far
rtk discover          # commands that could be filtered but aren't
rtk proxy <cmd>       # run <cmd> unfiltered
```

Two things the rewrite breaks:

- **Piping JSON to `jq`/`python3`** — rtk replaces a JSON response with a
  schema summary, so the parse fails. Use `rtk proxy curl ...` for those.
- **Multi-line Bash blocks** — if the first line isn't rewritable, rtk silently
  skips the *whole* block. One command per Bash call, or join with `&&`/`;`.
