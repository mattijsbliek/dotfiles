# Dotfiles

Development configuration managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Quick Start

```bash
git clone git@github.com:mattijsbliek/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The bootstrap script installs dependencies (fish, neovim, stow, starship, etc.), backs up existing configs, and creates symlinks via stow.

## Structure

Seven stow packages, each mirroring the target directory structure under `$HOME`:

```
bash/      → ~/.bash_profile, ~/.bashrc   Sources secrets, execs fish for interactive sessions
fish/      → ~/.config/fish/              Shell config, aliases, functions
nvim/      → ~/.config/nvim/              LazyVim-based Neovim config
git/       → ~/.gitconfig, etc.           Git aliases, diff-so-fancy, SSH signing
claude/    → ~/.claude/                   Claude Code settings, hooks, skills
starship/  → ~/.config/starship.toml      Prompt configuration
ghostty/   → ~/.config/ghostty/           Terminal emulator config (macOS)
```

## Machine-Specific Config

Files that vary per machine are git-ignored and must be created locally:

| File | Purpose |
|------|---------|
| `~/.secrets` | API tokens in bash syntax, sourced by both shells (see `secrets.example`) |
| `~/.claude/settings.local.json` | Work-specific Claude settings (API keys, plugins) |
| `~/.claude/CLAUDE.local.md` | Work-specific Claude instructions (role, branching) |
| `~/.gitconfig.local` | Machine-specific git settings (e.g., email) |

## Platform Handling

macOS vs Linux differences are handled automatically:

- **Fish**: `conf.d/platform.fish` detects the OS for Homebrew paths and 1Password SSH agent socket
- **Git**: `includeIf` loads `.gitconfig.macos` or `.gitconfig.linux` for the 1Password signing program path

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
