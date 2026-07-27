# Dotfiles

Development configuration managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Quick Start

```bash
git clone git@github.com:mattijsbliek/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The bootstrap script installs dependencies (fish, neovim, stow, starship, the `gh`/`glab` CLIs, tmux, worktrunk, etc.), backs up existing configs, and creates symlinks via stow.

## Structure

Nine stow packages, each mirroring the target directory structure under `$HOME`:

```
bash/      → ~/.bash_profile, ~/.bashrc   Sources secrets, execs fish for interactive sessions
fish/      → ~/.config/fish/              Shell config, aliases, functions
nvim/      → ~/.config/nvim/              LazyVim-based Neovim config
git/       → ~/.gitconfig, etc.           Git aliases, diff-so-fancy, SSH signing
claude/    → ~/.claude/                   Claude Code settings, hooks, skills
starship/  → ~/.config/starship.toml      Prompt configuration
ghostty/   → ~/.config/ghostty/           Terminal emulator config (macOS)
tmux/      → ~/.tmux.conf                 Status bar, mouse mode
worktrunk/ → ~/.config/worktrunk/         wt aliases + tmux window-rename hooks
```

## Worktree Workflow

The `m` fish function (`fish/.config/fish/functions/m.fish`) wraps worktrunk +
tmux + Claude Code into three verbs:

```
m start my-feature             # wt switch --create -x claude:
                                #   creates worktree + branch, cds in,
                                #   renames the tmux window, launches claude
m start my-feature -- "prompt" # same, but starts claude with an initial prompt
m cleanup                      # wt remove (branch deleted if merged), then
                                #   kills the tmux window. Refuses a dirty tree.
m cleanup --force              # remove even with uncommitted changes
m cleanup --reap               # also kill leftover dev servers in the worktree
m prune                        # wt step prune: bulk-remove worktrees/branches
                                #   already merged into the default branch
m prune --dry-run              # preview what prune would remove
```

`m cleanup` runs `wt remove` first and only kills the window if it succeeds, so
uncommitted work can't be silently destroyed. The tmux window-rename comes from
the worktrunk `post-start`/`post-switch` hooks in `worktrunk/`. `m prune` skips
the main worktree, locked worktrees, and anything younger than a day; it's for
tidying up worktrees left behind after a manual merge or a forgotten `m
cleanup` — it doesn't kill tmux windows for the worktrees it removes.

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
| `~/.claude/settings.json` | Plugin toggles (`enabledPlugins`) and any other per-machine overrides. Not stowed — see below. |
| `~/.claude/settings.local.json` | Work-specific Claude settings (API keys, env vars, hooks). Note: `enabledPlugins` is **not** read from this file by Claude Code — plugin state must live in `settings.json` |
| `~/.claude/CLAUDE.local.md` | Work-specific Claude instructions (role, branching) |
| `~/.gitconfig.local` | Machine-specific git settings (e.g., email) |

### Why `settings.json` isn't stowed

Claude Code only reads `enabledPlugins` from `~/.claude/settings.json` — a
symlinked, shared `settings.json` means every plugin toggle syncs to every
machine, and `settings.local.json` is not consulted for that key at all
(confirmed by testing; it's still fine for env vars, hooks, statusLine, etc.).
So `claude/.stow-local-ignore` excludes `settings.json` from stowing, and each
machine keeps its own real (non-symlinked) copy. `claude/.claude/settings.json`
in this repo is the shared baseline (permissions, hooks, model, output style —
no `enabledPlugins`); copy it to `~/.claude/settings.json` on a new machine and
add whichever plugins that machine needs.

## Platform Handling

macOS vs Linux differences are handled automatically:

- **Fish**: `conf.d/platform.fish` detects the OS for Homebrew paths and 1Password SSH agent socket
- **Git**: `includeIf` loads `.gitconfig.macos` or `.gitconfig.linux` for the 1Password signing program path
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
