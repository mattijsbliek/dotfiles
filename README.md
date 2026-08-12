# Dotfiles

Development configuration managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Quick Start

```bash
git clone git@github.com:mattijsbliek/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The bootstrap script installs dependencies (fish, neovim, stow, starship, the `gh`/`glab` CLIs, tmux, worktrunk, `fd`, `rtk`, language servers, etc.), backs up existing configs, and creates symlinks via stow.

## Structure

Eleven stow packages, each mirroring the target directory structure under `$HOME`:

```
bash/      → ~/.bash_profile, ~/.bashrc   Sources secrets, execs fish for interactive sessions
fish/      → ~/.config/fish/              Shell config, aliases, functions
nvim/      → ~/.config/nvim/              LazyVim-based Neovim config
git/       → ~/.gitconfig, etc.           Git aliases, diff-so-fancy, SSH signing
claude/    → ~/.claude/                   Claude Code settings, hooks, skills, rules
opencode/  → ~/.config/opencode/          opencode config, LiteLLM provider + plugins
starship/  → ~/.config/starship.toml      Prompt configuration
ghostty/   → ~/.config/ghostty/           Terminal emulator config (macOS)
tmux/      → ~/.tmux.conf                 Status bar, mouse mode
worktrunk/ → ~/.config/worktrunk/         wt aliases + env-copy/window-rename hooks
herdr/     → ~/.config/herdr/config.toml  Herdr terminal manager config
```

## Worktree Workflow

The `m` fish function (`fish/.config/fish/functions/m.fish`) wraps worktrunk +
tmux/herdr + Claude Code into three verbs:

```
m start my-feature             # wt switch --create -x claude:
                                #   creates worktree + branch, cds in,
                                #   renames the tmux window/herdr tab, launches claude
m start my-feature -- "prompt" # same, but starts claude with an initial prompt
m start <github-issue-url>     # worktree name derived from the issue title
                                #   (e.g. https://github.com/OWNER/REPO/issues/2)
m cleanup                      # wt remove (branch deleted if merged), then
                                #   kills the tmux window/herdr tab. Refuses a dirty tree.
m cleanup --force              # remove even with uncommitted changes
m cleanup --reap               # also kill leftover dev servers in the worktree
m prune                        # wt step prune: bulk-remove worktrees/branches
                                #   already merged into the default branch
m prune --dry-run              # preview what prune would remove
```

`m cleanup` runs `wt remove` first and only kills the window/tab if it
succeeds, so uncommitted work can't be silently destroyed. It detects tmux via
`$TMUX` and herdr via `$HERDR_ENV`. On herdr, if the tab is the last one in its
workspace, herdr refuses to close it, so `m cleanup` closes the workspace
instead. The window/tab rename comes from the
worktrunk `post-start`/`post-switch` hooks in `worktrunk/`, which use the same
detection. `m prune` skips the main worktree, locked worktrees, and anything
younger than a day; it's for tidying up worktrees left behind after a manual
merge or a forgotten `m cleanup` — it doesn't kill windows/tabs for the
worktrees it removes.

A fresh worktree only contains tracked files, so gitignored files are missing.
Two worktrunk `pre-start` hooks in `worktrunk/` seed them from the primary
worktree:

- `copy-env` copies every top-level `.env*` file — a glob because repos differ
  (`.env.development` in some, `.env` in others). The app won't boot without
  them.
- `copy-claude-settings` copies `.claude/settings.local.json`, which
  `.gitignore_global` ignores. Mainly the permission allowlist — `m cleanup`
  deletes the worktree, so approvals never accumulate and would otherwise be
  re-granted every time. It also carries `enabledMcpjsonServers`, which matters
  for any *project*-scoped MCP server: unlike a permission, a server that isn't
  enabled produces no prompt, it's just silently absent. User-scoped servers
  (see below) need no such entry and work in worktrees regardless.

Neither overwrites an existing file, so a tracked `.env.example` is left alone.
Both are `pre-start` (blocking) rather than `post-start` (background) so the
files are in place before `-x claude` starts.

`m` also has a `paste-image` verb, unrelated to worktrees: it grabs the
clipboard image (via `pngpaste`, macOS only), scps it to `hl-claude:/tmp/`,
copies the remote path back onto the clipboard (via `pbcopy`), and prints it.

```
m paste-image                  # paste clipboard image, scp to hl-claude:/tmp,
                                #   copy + print the remote path
```

## Claude Code Skills

`claude/.claude/skills/` holds every skill, hand-written or vendored, all stowed
straight into `~/.claude/skills/`. Skills originally installed via `npx skills`
(https://skills.sh) are vendored here rather than left under `~/.agents/skills`,
since that CLI deletes and recreates its managed directories on every update and
can't coexist with a symlink into this repo. See `claude/.claude/skills/VENDORED.md`
for each vendored skill's upstream source, to pull updates manually.

One directory there isn't a skill: `tsgo-lsp/` is a local Claude Code *plugin*
declaring a language server. `~/.claude/skills/` doubles as the discovery path
for local plugins — see [Agent Tooling](#agent-tooling).

## Agent Tooling

Three things exist purely to make coding agents cheaper and more accurate. All
three are installed by `install.sh` on both macOS and Linux.

### Language servers (LSP)

`ENABLE_LSP_TOOL=1` in `claude/.claude/settings.json` gives Claude an LSP tool —
`hover`, `goToDefinition`, `findReferences` — which is exact and cheap compared
to grepping for a symbol. Two halves have to line up:

| Language | Server binary | Installed by | Claude Code plugin |
|----------|---------------|--------------|--------------------|
| TypeScript/JavaScript | `tsgo` (`@typescript/native-preview`) | `npm -g` | `tsgo-lsp@skills-dir` (local, in this repo) |
| PHP | `intelephense` | `npm -g` | `php-lsp@claude-plugins-official` |
| Java | `jdtls` | brew (macOS) / Eclipse tarball into `~/.local/share/jdtls` (Linux) | `jdtls-lsp@claude-plugins-official` |

The plugins carry no binaries — they only register a server that must already be
on `PATH`. `install.sh` installs the binaries (`install_lsp_servers`) and then
installs + enables the marketplace plugins (`setup_claude`).

#### Why tsgo rather than typescript-language-server

The official `typescript-lsp` plugin runs `typescript-language-server`, which
loads `node_modules/typescript/lib/tsserver.js` **from the workspace**. That
fails in two common cases: a TypeScript 7 project (the native port ships no
`tsserver.js`) and a loose `.ts` file with no `node_modules` at all — both exit
with *"Could not find a valid TypeScript installation"*.

`tsgo` is a self-contained Go binary that reads `tsconfig.json` and the sources
directly, so it needs no `typescript` dependency and serves TypeScript 5 and 7
workspaces alike. Verified against all three: TS 5, TS 7, and a bare `.ts` file.

It's declared by `claude/.claude/skills/tsgo-lsp/.claude-plugin/plugin.json`.
Local plugins live under `~/.claude/skills/` — that's where `claude plugin init`
puts them and where Claude Code discovers them as `<name>@skills-dir`. The
directory holds no `SKILL.md`, so it contributes an LSP server and nothing else,
and it loads without any `enabledPlugins` entry, which keeps it working on a
machine whose `settings.json` this repo doesn't own.

Only one server can own an extension — when two enabled servers both claim
`.ts`, the first registered wins and the other never starts — so `setup_claude`
disables `typescript-lsp` if a machine has it on. To go back to the official
plugin: `claude plugin enable typescript-lsp@claude-plugins-official` and remove
the `tsgo-lsp` directory.

Other gotchas:

- **The npm servers follow the active Node version.** They're global installs, so
  a Node major bump loses them. Re-run `./install.sh` after switching.
- **`jdtls` needs a JDK 21+** to run itself, independent of what a project
  compiles against. Homebrew pulls one in; on Linux `install.sh` only warns
  (sdkman is already wired into the fish config: `sdk install java`).

### rtk

[rtk](https://github.com/rtk-ai/rtk) filters verbose CLI output before it reaches
the model. It's wired in as a `PreToolUse` hook on `Bash` in
`claude/.claude/settings.json`, so `git status` silently becomes `rtk git status`.
`claude/.claude/RTK.md` is stowed to `~/.claude/RTK.md` and pulled into context by
an `@RTK.md` reference at the end of `CLAUDE.md` — it documents the meta commands
and the two cases where the rewrite bites (JSON piped to `jq`, multi-line Bash
blocks).

Notes:

- Not in Homebrew or apt on either platform; the upstream installer drops a
  prebuilt binary into `~/.local/bin`, which is already on `PATH` via
  `config.fish`. The hook command prepends `$HOME/.local/bin` itself and no-ops
  when `rtk` is absent, so a machine without it just runs commands unmodified.
- The hook is declared in this repo rather than via `rtk init -g`, which would
  patch `~/.claude/settings.json` and drop a generated `rtk-rewrite.sh` into
  `~/.claude/hooks/` — neither of which is tracked here.
- rtk leaves destructive commands alone (`git reset --hard`, `rm -rf` produce no
  rewrite at all) and only auto-approves ones it classifies read-only, so the
  `protect-secrets.sh` and `dangerous-git-commands.sh` hooks still see and can
  block the original command.
- `rtk` is a name collision: `rtk-ai/rtk` (this one) vs `reachingforthejack/rtk`
  on crates.io. `rtk gain` only exists on the former, which is how `install.sh`
  tells them apart.

### fd

[fd](https://github.com/sharkdp/fd) replaces `find` for filename searches and
respects `.gitignore`, so agent searches don't drown in `node_modules`. Homebrew
on macOS; on Linux the apt package is `fd-find` and installs the binary as
`fdfind` (a name clash with an unrelated package), so `install.sh` symlinks
`~/.local/bin/fd` to it — the command is `fd` on both platforms.

## Claude Code Status Line

`claude/.claude/statusline.sh` shows repo, branch, worktree (when in a linked
git worktree), context tokens used, and model, e.g.
`Clientroom | 🌿 (main) | 20k (10%) | 🤖 Opus 4.6`. Token count is colored grey
under 100k tokens, yellow from 100k-200k, red above 200k. Wired up via the
`statusLine` key in `claude/.claude/settings.json`.

## Machine-Specific Config

Files that vary per machine are git-ignored and must be created locally:

| File | Purpose |
|------|---------|
| `~/.secrets` | API tokens in bash syntax, sourced by both shells (see `secrets.example`) |
| `~/.claude/settings.json` | Plugin toggles (`enabledPlugins`) and any other per-machine overrides. Not stowed, but seeded from the repo baseline by `install.sh` — see below. |
| `~/.claude/settings.local.json` | Work-specific Claude settings (API keys, env vars, hooks). Note: `enabledPlugins` is **not** read from this file by Claude Code — plugin state must live in `settings.json` |
| `~/.claude/rules/local-*.md` | Work-specific Claude instructions (e.g. ticket-id branch and commit conventions). Only the `local-*` files are machine-local — the rest of `rules/` is stowed and shared. Gitignored so employer conventions never reach this public repo. Preferred over `~/.claude/CLAUDE.local.md`, which Claude Code documents only at *project* root, not user scope |
| `~/.gitconfig.local` | Machine-specific git settings (e.g., email) |
| `~/.claude.json` | User-scoped MCP servers (see below), plus Claude Code's own caches and per-project history. Never stowed — it's mostly machine state |

### Playwright MCP server

Registered at **user** scope so every project on the machine can drive a real
browser (navigate, click, read the accessibility tree) to verify changes end to
end — not just run the Playwright suite via `npm run e2e`, which is a plain
Bash command and needs no MCP. Recreate it on a new machine with:

```bash
claude mcp add --scope user playwright -- \
  npx -y @playwright/mcp@latest --headless --output-dir .playwright-mcp
```

- **user scope, not a per-repo `.mcp.json`** — one registration covers every
  repo, needs no per-project approval, adds no tracked file to shared repos,
  and works in fresh worktrees automatically.
- **`--headless`** — these machines have no `DISPLAY`.
- **`--output-dir`** — the server writes accessibility snapshots and console
  logs to files and returns links, so the refs needed to click an element live
  on disk. `.playwright-mcp/` is in `.gitignore_global`.
- `--vision` is deprecated (it's `--caps=vision` now) and is not used; the
  default snapshot mode returns structured element refs, and screenshots are
  still available via `browser_take_screenshot`.

`tideloop` also declares playwright in its own tracked `.mcp.json`. Project
scope wins there, so it keeps using its own copy; `claude mcp list` reports the
overlap as a warning, which is expected and harmless.

### Why `settings.json` isn't stowed

Claude Code only reads `enabledPlugins` from `~/.claude/settings.json` — a
symlinked, shared `settings.json` means every plugin toggle syncs to every
machine, and `settings.local.json` is not consulted for that key at all
(confirmed by testing; it's still fine for env vars, hooks, statusLine, etc.).
So `claude/.stow-local-ignore` excludes `settings.json` from stowing, and each
machine keeps its own real (non-symlinked) copy. `claude/.claude/settings.json`
in this repo is the shared baseline (permissions, hooks, model, output style —
no `enabledPlugins`). `install.sh` copies it to `~/.claude/settings.json` when
that file is absent and never touches it again, so a fresh machine gets the
hooks and statusline; `enabledPlugins` is then filled in per machine, by
`claude plugin enable` (which `install.sh` runs for the LSP plugins) or by
`/plugin`. Changes to the baseline don't propagate — merge them by hand.

## Platform Handling

macOS vs Linux differences are handled automatically:

- **Fish**: `conf.d/platform.fish` detects the OS for Homebrew paths and 1Password SSH agent socket
- **Git**: `includeIf` loads `.gitconfig.macos` or `.gitconfig.linux` for the 1Password signing program path
- **Agent tooling**: `fd` comes from Homebrew on macOS and apt's `fd-find` (symlinked from `fdfind`) on Linux; `rtk` uses the same prebuilt-binary installer on both; `jdtls` is a Homebrew formula on macOS and an Eclipse snapshot tarball unpacked into `~/.local/share/jdtls` on Linux. See [Agent Tooling](#agent-tooling).
- **Worktrunk**: `config.fish` runs `wt config shell init fish | source` only behind a `command -q wt` guard, so a freshly cloned machine doesn't error before the tool is installed. `install.sh` installs `wt` (plus `gh`/`glab`/`tmux`) cross-platform: Homebrew on macOS; on Linux, `gh` via its official apt repo, `glab` via the official `.deb` release, and `worktrunk` via `cargo install`. CLI auth (`gh auth login`, `glab auth login`) stays manual — the `issue` alias picks `gh` vs `glab` per repo from `remote_url`, not per machine.

## Secrets via 1Password

Secrets are injected at shell startup via `op read` (1Password CLI). Each server is fully isolated:

- **Own vault** (e.g., "Server-Foo") containing dedicated tokens for that server
- **Own service account** with read-only access to only that vault
- **Own GitHub token** (fine-grained PAT scoped to that server)

If a server is compromised, revoke its SA and tokens without affecting other machines.

**Setup per server:**

1. Create a vault in 1Password for the server
2. Store dedicated tokens in the vault (GitHub PAT, etc.)
3. Create a Service Account with access to only that vault
4. Add to `~/.config/fish/conf.d/secrets.fish`:
   ```fish
   set -gx OP_SERVICE_ACCOUNT_TOKEN "ops_..."
   set -gx GITHUB_TOKEN (op read "op://Server-Foo/GitHub Token/credential" 2>/dev/null)
   ```

On macOS, `op` authenticates via the 1Password app (biometrics) — no service account needed.

## Syncing

Pull updates on any machine:

```bash
dotfiles-sync
```

This runs `git pull --rebase` and restows all packages. The function is available after the fish config is stowed.

## Adding Changes

Config files are symlinks, so editing them directly edits the repo:

```bash
nvim ~/.config/fish/config.fish   # edits dotfiles/fish/.config/fish/config.fish
cd ~/dotfiles
git add -A && git commit -m "Update fish config" && git push
```
