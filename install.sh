#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# --- Pinned tool versions ---
# Neither tool lives in an ecosystem Dependabot understands, so these are
# bumped by .github/workflows/bump-pinned-tools.yml, which opens a PR when a
# newer version appears upstream. Keep the assignments on one line each — the
# workflow rewrites them with sed.
RTK_VERSION="v0.45.0"
JDTLS_VERSION="1.60.0"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# --- Stow packages (directories under $DOTFILES_DIR) ---
PACKAGES=(bash fish nvim git claude starship ghostty worktrunk herdr)

# --- Detect platform ---
OS="$(uname -s)"
case "$OS" in
    Darwin) PLATFORM="macos" ;;
    Linux)  PLATFORM="linux" ;;
    *)      error "Unsupported OS: $OS"; exit 1 ;;
esac
info "Detected platform: $PLATFORM"

# --- Install Neovim from GitHub releases (Linux) ---
# The apt package is too old for LazyVim; grab the latest stable binary instead.
install_neovim_linux() {
    local arch
    arch="$(uname -m)"
    case "$arch" in
        x86_64)  arch="x86_64" ;;
        aarch64) arch="aarch64" ;;
        *)       error "Unsupported architecture for Neovim: $arch"; return 1 ;;
    esac

    local tarball="nvim-linux-${arch}.tar.gz"
    local url="https://github.com/neovim/neovim/releases/latest/download/${tarball}"
    local install_dir="/opt/nvim-linux-${arch}"

    info "Downloading Neovim (latest stable) for ${arch}..."
    curl -fsSL -o "/tmp/${tarball}" "$url"
    sudo rm -rf "$install_dir"
    sudo tar -C /opt -xzf "/tmp/${tarball}"
    sudo ln -sf "${install_dir}/bin/nvim" /usr/local/bin/nvim
    rm -f "/tmp/${tarball}"
    info "Neovim installed: $(nvim --version | head -1)"
}

# --- Install Eclipse JDT.LS (Linux) ---
# No apt package exists. The tarball ships a python launcher at bin/jdtls, so
# unpacking it and symlinking that is the whole install. Take a pinned
# milestone rather than /snapshots/, which serves nightlies — two machines
# provisioned a week apart would otherwise get different servers.
install_jdtls_linux() {
    local dir="$HOME/.local/share/jdtls"
    local base="https://download.eclipse.org/jdtls/milestones/$JDTLS_VERSION"

    if ! command -v python3 &>/dev/null; then
        warn "jdtls needs python3 for its launcher; skipping"
        return 1
    fi

    # A milestone directory is immutable and names its tarball in latest.txt.
    local tarball
    tarball="$(curl -fsSL "$base/latest.txt" 2>/dev/null)" || true
    if [[ -z "$tarball" ]]; then
        warn "Could not resolve the JDT.LS $JDTLS_VERSION tarball; see $base/"
        return 1
    fi

    # Unpack to a staging dir and swap it in only on success, so a failed
    # download leaves any working install untouched.
    info "Downloading Eclipse JDT.LS $JDTLS_VERSION..."
    local staging="$dir.incoming"
    rm -rf "$staging"
    mkdir -p "$staging" "$HOME/.local/bin"
    if ! curl -fsSL "$base/$tarball" | tar -xz -C "$staging"; then
        warn "Could not download JDT.LS; install manually from $base/$tarball"
        rm -rf "$staging"
        return 1
    fi
    rm -rf "$dir"
    mv "$staging" "$dir"
    echo "$JDTLS_VERSION" >"$dir/.version"
    ln -sf "$dir/bin/jdtls" "$HOME/.local/bin/jdtls"
    info "jdtls $JDTLS_VERSION installed to $dir"
}

# --- Language servers for Claude Code's LSP tool ---
# Claude Code resolves each server from PATH; the *-lsp plugins only wire them
# up (see setup_claude). TypeScript and PHP servers are npm globals, so
# they're tied to whichever Node version is active — re-run install.sh after a
# Node major bump.
install_lsp_servers() {
    info "Checking language servers..."

    if command -v npm &>/dev/null; then
        local npm_missing=()
        # tsgo is the TypeScript server — see the tsgo-lsp plugin under
        # claude/.claude/skills/. It's self-contained, so unlike
        # typescript-language-server it doesn't need a `typescript` package in
        # the workspace, and it handles both TypeScript 5 and 7 projects.
        command -v tsgo &>/dev/null || npm_missing+=("@typescript/native-preview")
        command -v intelephense &>/dev/null || npm_missing+=("intelephense")
        if [[ ${#npm_missing[@]} -gt 0 ]]; then
            info "Installing npm language servers: ${npm_missing[*]}"
            npm install -g "${npm_missing[@]}" || warn "Could not install: ${npm_missing[*]}"
        fi
    else
        warn "npm not available; skipping tsgo + intelephense"
    fi

    if command -v jdtls &>/dev/null; then
        # Same idea as rtk: reinstall when the pin moves. Only on Linux, where
        # install.sh unpacks the tarball itself and stamps the version; the
        # macOS copy is brew's to upgrade.
        if [[ "$PLATFORM" == "macos" ]] ||
            [[ "$(cat "$HOME/.local/share/jdtls/.version" 2>/dev/null)" == "$JDTLS_VERSION" ]]; then
            return
        fi
        info "jdtls pin moved to $JDTLS_VERSION; reinstalling"
    fi

    info "Installing jdtls (Eclipse JDT.LS)..."
    if [[ "$PLATFORM" == "macos" ]]; then
        # The formula pulls its own JDK, so no version check is needed here.
        brew install jdtls || warn "Could not install jdtls"
    else
        # JDT.LS runs on the JDK, independent of the JDK a project compiles
        # against. Take the first number in the version line: that's the major
        # for JDK 9+, and 1 (i.e. correctly < 21) for the old 1.x scheme.
        local java_major=""
        if command -v java &>/dev/null; then
            java_major="$(java -version 2>&1 | head -1 | grep -oE '[0-9]+' | head -1 || true)"
        fi
        if [[ -z "$java_major" ]] || [[ "$java_major" -lt 21 ]]; then
            warn "jdtls needs a JDK 21+ to run (found: ${java_major:-none})"
            warn "  (sdkman is already wired into the fish config: sdk install java)"
        fi
        install_jdtls_linux || true
    fi
}

# --- Install dependencies ---
install_packages() {
    info "Checking dependencies..."

    local missing=()
    # jq and yq back the "query structured data, don't grep it" rule in
    # claude/.claude/CLAUDE.md, so agents can count on both being present.
    for cmd in fish nvim git stow curl jq yq unzip; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        info "All core dependencies are installed."
    else
        info "Missing packages: ${missing[*]}"

        if [[ "$PLATFORM" == "macos" ]]; then
            if ! command -v brew &>/dev/null; then
                info "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
            brew install "${missing[@]}"
        else
            info "Installing via apt..."
            sudo apt update
            # Map command names to package names (nvim handled separately)
            local pkgs=()
            for cmd in "${missing[@]}"; do
                case "$cmd" in
                    nvim) ;; # installed via install_neovim_linux below
                    *)    pkgs+=("$cmd") ;;
                esac
            done
            if [[ ${#pkgs[@]} -gt 0 ]]; then
                sudo apt install -y "${pkgs[@]}"
            fi
        fi
    fi

    # On Linux, ensure Neovim is recent enough for LazyVim (>= 0.10)
    if [[ "$PLATFORM" == "linux" ]]; then
        local nvim_version
        nvim_version="$(nvim --version 2>/dev/null | head -1 | grep -oP 'v\K[0-9]+\.[0-9]+')" || true
        if [[ -z "$nvim_version" ]] || [[ "$(printf '%s\n' "0.10" "$nvim_version" | sort -V | head -1)" != "0.10" ]]; then
            warn "Neovim ${nvim_version:-missing} is too old for LazyVim (need >= 0.10)"
            install_neovim_linux
        else
            info "Neovim v${nvim_version} is recent enough."
        fi
    fi

    # Starship prompt
    if ! command -v starship &>/dev/null; then
        info "Installing Starship prompt..."
        # The installer writes to /usr/local/bin by default, which doesn't
        # exist on fresh Apple Silicon machines. Create it first so the
        # installer doesn't bail.
        if [[ ! -d /usr/local/bin ]]; then
            sudo mkdir -p /usr/local/bin
        fi
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi

    # eza (ls replacement)
    if ! command -v eza &>/dev/null; then
        info "Installing eza..."
        if [[ "$PLATFORM" == "macos" ]]; then
            brew install eza
        else
            # eza via apt on Ubuntu 22.04+
            sudo apt install -y eza 2>/dev/null || warn "eza not available in apt; install manually"
        fi
    fi

    # fd — fast find replacement, used heavily by coding agents
    if ! command -v fd &>/dev/null; then
        info "Installing fd..."
        if [[ "$PLATFORM" == "macos" ]]; then
            brew install fd
        else
            # Debian/Ubuntu ship it as fd-find with the binary named `fdfind`
            # (a name clash with an unrelated package). Symlink it back to `fd`
            # so scripts and agent instructions are identical on both platforms.
            if sudo apt install -y fd-find; then
                # Don't let a missing binary abort the whole run (set -e): the
                # symlink is a convenience, the rest of the bootstrap isn't.
                local fdfind_bin
                fdfind_bin="$(command -v fdfind || true)"
                if [[ -n "$fdfind_bin" ]]; then
                    mkdir -p "$HOME/.local/bin"
                    ln -sf "$fdfind_bin" "$HOME/.local/bin/fd"
                else
                    warn "fd-find installed but no 'fdfind' on PATH; link it to ~/.local/bin/fd manually"
                fi
            else
                warn "fd not available in apt; install manually"
            fi
        fi
    fi

    # rtk (Rust Token Killer) — filters verbose CLI output before it reaches the
    # model. Wired into Claude Code as a PreToolUse hook (see claude/.claude/settings.json).
    # Not in Homebrew or apt; the upstream installer drops a prebuilt binary in
    # ~/.local/bin on both platforms and verifies it against the release
    # checksums. Fetch that script from the release tag rather than master, so
    # the installer and the binary it installs are pinned together — this hook
    # gets to rewrite every Bash command, so it shouldn't float.
    # Compare against the pin rather than just testing for presence, so a
    # version bump reaches machines that already have rtk, not only fresh ones.
    local rtk_have=""
    if command -v rtk &>/dev/null; then
        rtk_have="v$(rtk --version 2>/dev/null | awk '{print $2}' || true)"
    fi
    if [[ "$rtk_have" != "$RTK_VERSION" ]]; then
        info "Installing rtk $RTK_VERSION${rtk_have:+ (replacing $rtk_have)}..."
        mkdir -p "$HOME/.local/bin"
        curl -fsSL "https://raw.githubusercontent.com/rtk-ai/rtk/$RTK_VERSION/install.sh" \
            | RTK_VERSION="$RTK_VERSION" sh \
            || warn "Could not install rtk; see https://github.com/rtk-ai/rtk"
    fi
    # `rtk gain` distinguishes rtk-ai/rtk (what we want) from the unrelated
    # reachingforthejack/rtk, which squats the same binary name on crates.io.
    if command -v rtk &>/dev/null && ! rtk gain &>/dev/null; then
        warn "'rtk' on PATH is not rtk-ai/rtk (no 'rtk gain'). Remove it and re-run:"
        warn "  cargo uninstall rtk"
    fi

    # pngpaste — clipboard image access for `m paste-image` (macOS only)
    if [[ "$PLATFORM" == "macos" ]] && ! command -v pngpaste &>/dev/null; then
        info "Installing pngpaste..."
        brew install pngpaste
    fi

    # fnm (Fast Node Manager) — provides Node.js + npm (optional)
    if ! command -v fnm &>/dev/null; then
        local install_fnm=""
        read -rp "Install Node.js via fnm? [y/N] " install_fnm
        if [[ "$install_fnm" =~ ^[Yy]$ ]]; then
            info "Installing fnm..."
            if [[ "$PLATFORM" == "macos" ]]; then
                brew install fnm
            else
                curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell \
                    || warn "Could not install fnm"
            fi
        fi
    fi
    # fnm installs to ~/.local/bin — ensure it's on PATH for this session
    export PATH="$HOME/.local/bin:$PATH"

    # Ensure a Node.js version is installed (LTS)
    if command -v fnm &>/dev/null && [[ -z "$(fnm list 2>/dev/null | grep -v 'system')" ]]; then
        info "Installing Node.js LTS via fnm..."
        fnm install --lts
    fi
    # Make fnm's node/npm available in this bash session
    if command -v fnm &>/dev/null; then
        eval "$(fnm env)"
    fi

    # git-delta — pager set via core.pager in .gitconfig. Standalone Rust
    # binary, so unlike diff-so-fancy (which it replaced) it needs no Node/npm.
    if ! command -v delta &>/dev/null; then
        info "Installing git-delta..."
        if [[ "$PLATFORM" == "macos" ]]; then
            brew install git-delta
        else
            # No official apt repo; fetch the .deb from GitHub releases (same
            # pattern as glab below).
            local delta_arch delta_ver delta_deb
            delta_arch="$(dpkg --print-architecture)" # amd64 / arm64
            delta_ver="$(curl -fsSL "https://api.github.com/repos/dandavison/delta/releases/latest" \
                | jq -r '.tag_name')" || true
            if [[ -n "${delta_ver:-}" ]]; then
                delta_deb="git-delta_${delta_ver}_${delta_arch}.deb"
                if curl -fsSL -o "/tmp/${delta_deb}" \
                    "https://github.com/dandavison/delta/releases/download/${delta_ver}/${delta_deb}"; then
                    sudo dpkg -i "/tmp/${delta_deb}" || warn "Could not install git-delta (.deb)"
                    rm -f "/tmp/${delta_deb}"
                else
                    warn "Could not download git-delta .deb; install manually: https://github.com/dandavison/delta"
                fi
            else
                warn "Could not determine latest git-delta version; install manually: https://github.com/dandavison/delta"
            fi
        fi
    fi

    # 1Password CLI — for secret injection via op read
    if ! command -v op &>/dev/null; then
        info "Installing 1Password CLI..."
        if [[ "$PLATFORM" == "macos" ]]; then
            brew install --cask 1password-cli
        else
            # Official 1Password apt repository
            curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
                sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
                sudo tee /etc/apt/sources.list.d/1password.list
            sudo apt update && sudo apt install -y 1password-cli
        fi
    fi

    # GitHub CLI (gh) — used by the Worktrunk `issue` alias on GitHub repos
    if ! command -v gh &>/dev/null; then
        info "Installing GitHub CLI (gh)..."
        if [[ "$PLATFORM" == "macos" ]]; then
            brew install gh
        else
            # Official GitHub CLI apt repository
            sudo mkdir -p -m 755 /etc/apt/keyrings
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
                sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
            sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
                sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
            sudo apt update && sudo apt install -y gh || warn "Could not install gh"
        fi
    fi

    # GitLab CLI (glab) — used by the Worktrunk `issue` alias on GitLab repos
    if ! command -v glab &>/dev/null; then
        info "Installing GitLab CLI (glab)..."
        if [[ "$PLATFORM" == "macos" ]]; then
            brew install glab
        else
            # No official apt repo exists; fetch the official .deb from GitLab
            # releases (same pattern as install_neovim_linux above). jq is a
            # core dependency, installed earlier in this function.
            local glab_arch glab_ver glab_deb
            glab_arch="$(dpkg --print-architecture)" # amd64 / arm64
            glab_ver="$(curl -fsSL "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/releases" \
                | jq -r '.[0].tag_name' | sed 's/^v//')" || true
            if [[ -n "${glab_ver:-}" ]]; then
                glab_deb="glab_${glab_ver}_linux_${glab_arch}.deb"
                if curl -fsSL -o "/tmp/${glab_deb}" \
                    "https://gitlab.com/gitlab-org/cli/-/releases/v${glab_ver}/downloads/${glab_deb}"; then
                    sudo dpkg -i "/tmp/${glab_deb}" || warn "Could not install glab (.deb)"
                    rm -f "/tmp/${glab_deb}"
                else
                    warn "Could not download glab .deb; install manually: https://gitlab.com/gitlab-org/cli"
                fi
            else
                warn "Could not determine latest glab version; install manually: https://gitlab.com/gitlab-org/cli"
            fi
        fi
    fi

    # Worktrunk (wt) — git worktree manager
    if ! command -v wt &>/dev/null; then
        info "Installing Worktrunk (wt)..."
        if [[ "$PLATFORM" == "macos" ]]; then
            brew install worktrunk
        else
            # Not packaged for apt. Use the official installer script, which
            # fetches a prebuilt musl binary from GitHub releases — no cargo/
            # Rust toolchain required. Installed straight into ~/.local/bin
            # (already on PATH via fish config), so we skip its PATH/rc-file
            # management entirely.
            mkdir -p "$HOME/.local/bin"
            if WORKTRUNK_UNMANAGED_INSTALL="$HOME/.local/bin" WORKTRUNK_NO_MODIFY_PATH=1 \
                sh -c "$(curl -fsSL https://github.com/max-sixty/worktrunk/releases/latest/download/worktrunk-installer.sh)"; then
                :
            else
                warn "Could not install worktrunk automatically. Install manually:"
                warn "  curl -fsSL https://github.com/max-sixty/worktrunk/releases/latest/download/worktrunk-installer.sh | sh"
                warn "  (or see https://worktrunk.dev for other options)"
            fi
        fi
    fi

    # Ghostty terminfo (fixes backspace/tab rendering over SSH)
    if ! infocmp xterm-ghostty &>/dev/null; then
        if [[ -f "$DOTFILES_DIR/ghostty-terminfo.src" ]]; then
            info "Installing Ghostty terminfo..."
            tic -x "$DOTFILES_DIR/ghostty-terminfo.src"
        fi
    fi
}

# --- Back up files that would conflict with stow ---
# GNU stow refuses to overwrite a target that is a regular file (not a
# symlink) and aborts the ENTIRE package on the first conflict — even for
# items that would otherwise link cleanly. Ask stow itself (dry run) which
# targets actually conflict, rather than walking the package tree by hand:
# a hand-rolled walk doesn't know about `.stow-local-ignore` and will "back
# up" (i.e. delete) files like claude/.claude/settings.json that are
# intentionally excluded from stowing and never get restored.
backup_conflicts() {
    local moved_any=false

    for pkg in "$@"; do
        local pkg_dir="$DOTFILES_DIR/$pkg"
        [[ -d "$pkg_dir" ]] || continue

        while IFS= read -r rel; do
            local target="$HOME/$rel"
            [[ -f "$target" && ! -L "$target" ]] || continue

            if [[ "$moved_any" == "false" ]]; then
                info "Backing up conflicting files to $BACKUP_DIR"
                moved_any=true
            fi
            mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
            mv "$target" "$BACKUP_DIR/$rel"
            info "  Moved aside: $target"
        done < <(cd "$DOTFILES_DIR" && stow -n -v --target="$HOME" --restow "$pkg" 2>&1 \
            | grep -oP '(?<=existing target is neither a link nor a directory: ).+' || true)
    done

    if [[ "$moved_any" == "false" ]]; then
        info "No conflicting files to back up (all symlinks or absent)."
    fi
}

# --- Stow packages ---
stow_packages() {
    info "Stowing dotfiles packages..."
    cd "$DOTFILES_DIR"
    for pkg in "${PACKAGES[@]}"; do
        info "  Stowing: $pkg"
        stow -v --target="$HOME" --restow "$pkg" 2>&1 | grep -v "^$" || true
    done
}

# --- Secrets setup ---
setup_secrets() {
    # Secrets (bash-compatible, sourced by both bash and fish)
    local secrets_file="$HOME/.secrets"
    if [[ ! -f "$secrets_file" ]]; then
        warn "Creating ~/.secrets from template — edit it with your tokens:"
        cp "$DOTFILES_DIR/secrets.example" "$secrets_file"
        chmod 600 "$secrets_file"
    fi

}

# --- Find an enabled plugin that already serves a file extension ---
# Only one enabled plugin can own an extension: the first registered wins and
# the other never starts, with no warning from Claude Code (see README → Agent
# Tooling). Prints the offending plugin id, or returns 1 if the coast is clear.
lsp_extension_owner() {
    local ext="$1" ours="$2" id plugin marketplace manifest
    while IFS= read -r id; do
        [[ -n "$id" && "$id" != "$ours" ]] || continue
        plugin="${id%@*}"
        marketplace="${id#*@}"
        # Two layouts in the wild: the official plugins declare lspServers in
        # their marketplace entry, others ship a .lsp.json or plugin manifest
        # inside the versioned cache dir (cache/<marketplace>/<plugin>/<ver>/).
        if jq -e --arg p "$plugin" --arg e "$ext" \
                '.plugins[]? | select(.name == $p) | .lspServers[]?.extensionToLanguage[$e]' \
                "$HOME/.claude/plugins/marketplaces/$marketplace/.claude-plugin/marketplace.json" \
                &>/dev/null \
            || grep -qsrF --include='*.json' "\"$ext\":" \
                "$HOME/.claude/plugins/cache/$marketplace/$plugin/"; then
            echo "$id"
            return 0
        fi
    done < <(jq -r '.enabledPlugins // {} | to_entries[] | select(.value) | .key' \
        "$HOME/.claude/settings.json" 2>/dev/null)

    # Local plugins under ~/.claude/skills/ are enabled by their presence alone
    # and never appear in enabledPlugins — tsgo-lsp is one — so the loop above
    # is blind to them. They shadow just as silently, so check them too.
    for manifest in "$HOME"/.claude/skills/*/.claude-plugin/plugin.json; do
        [[ -f "$manifest" ]] || continue
        id="$(jq -r '.name // empty' "$manifest" 2>/dev/null)@skills-dir"
        [[ "$id" != "@skills-dir" && "$id" != "$ours" ]] || continue
        if jq -e --arg e "$ext" '.lspServers[]?.extensionToLanguage[$e]' \
                "$manifest" &>/dev/null; then
            echo "$id"
            return 0
        fi
    done
    return 1
}

# --- Claude Code settings + plugins ---
# settings.json is deliberately not stowed (see README → "Why settings.json
# isn't stowed"), so a fresh machine has no baseline at all: no hooks, no
# statusline, no LSP tool. Seed it once from the repo, then let the machine
# own it.
setup_claude() {
    local settings="$HOME/.claude/settings.json"
    if [[ -f "$settings" ]]; then
        info "~/.claude/settings.json exists — leaving it alone."
    else
        info "Seeding ~/.claude/settings.json from the repo baseline..."
        mkdir -p "$HOME/.claude"
        cp "$DOTFILES_DIR/claude/.claude/settings.json" "$settings"
    fi

    if ! command -v claude &>/dev/null; then
        warn "claude CLI not found; skipping LSP plugin setup"
        return
    fi

    # TypeScript is served by the tsgo-lsp plugin stowed into ~/.claude/skills/,
    # which loads automatically and needs no entry here. Only the marketplace
    # plugins do — and `enabledPlugins` is read from settings.json alone, hence
    # the seed above.
    claude plugin marketplace add anthropics/claude-plugins-official &>/dev/null || true

    # `claude plugin list` prints one block per (plugin, scope) pair, so a bare
    # id match can't tell a user-scope install from a project-scope one.
    # Flatten to `id@@scope` lines and match those — matching the id alone lets
    # a project-scoped plugin no-op every user-scope guard below.
    local installed
    installed="$(claude plugin list 2>/dev/null | awk '
        NF == 2 && $2 ~ /@/          { id = $2; next }
        $1 == "Scope:" && id != ""   { print id "@@" $2 }
    ' || true)"

    # typescript-lsp claims exactly the extensions tsgo-lsp does, and the first
    # server registered wins, so leaving it around would silently shadow tsgo.
    # Uninstalling drops its enabledPlugins entry too. Nothing installs it any
    # more; this only cleans up machines provisioned before the switch.
    # `uninstall` defaults to user scope, so pass each scope it's present in.
    local ts_id="typescript-lsp@claude-plugins-official" scope
    while IFS= read -r scope; do
        [[ -n "$scope" ]] || continue
        info "Removing typescript-lsp ($scope scope) — tsgo-lsp serves TypeScript instead"
        # -y: stdout is redirected, so a confirmation prompt would hang unseen.
        claude plugin uninstall "$ts_id" --scope "$scope" -y &>/dev/null \
            || warn "Could not uninstall typescript-lsp at $scope scope"
    done < <(grep -F "${ts_id}@@" <<<"$installed" | sed 's|.*@@||' | sort -u)

    # The *-lsp plugins carry no binaries — they just register a language
    # server (installed by install_lsp_servers) with Claude Code's LSP tool.
    local plugin id ext clash
    for plugin in php-lsp jdtls-lsp; do
        id="${plugin}@claude-plugins-official"
        if ! grep -qF "${id}@@user" <<<"$installed"; then
            info "Installing Claude Code plugin: $plugin"
            claude plugin install "$id" --scope user || warn "Could not install plugin $plugin"
        fi

        # Enabling ours on top of another server for the same extension would
        # shadow one of them silently. Which should win is a judgement call
        # (a work marketplace may ship a cached or preconfigured variant), so
        # report it and leave the existing one alone.
        case "$plugin" in
            php-lsp)   ext=".php" ;;
            jdtls-lsp) ext=".java" ;;
        esac
        if clash="$(lsp_extension_owner "$ext" "$id")"; then
            warn "$clash already serves $ext — leaving $plugin disabled"
            warn "  (only one enabled plugin can own an extension; disable one to switch)"
            continue
        fi

        # `claude plugin enable` errors on an already-enabled plugin, so check
        # the flag it writes rather than swallowing a real failure.
        if [[ "$(jq -r --arg id "$id" '.enabledPlugins[$id] // false' "$settings")" != "true" ]]; then
            claude plugin enable "$id" --scope user &>/dev/null \
                || warn "Could not enable plugin $plugin"
        fi
    done
}

# --- Fish plugins ---
setup_fish_plugins() {
    if ! command -v fish &>/dev/null; then
        return
    fi

    # Install fundle (fish plugin manager) if missing — download directly to
    # avoid spawning a fish subprocess (which would source config.fish too early).
    local fundle_path="$HOME/.config/fish/functions/fundle.fish"
    if [[ ! -f "$fundle_path" ]]; then
        info "Installing fundle..."
        mkdir -p "$(dirname "$fundle_path")"
        curl -sfL https://raw.githubusercontent.com/tuvistavie/fundle/master/functions/fundle.fish \
            -o "$fundle_path" || {
            warn "Could not download fundle; install manually"
            return
        }
    fi

    info "Installing fish plugins via fundle..."
    fish -c "fundle install" 2>/dev/null || warn "Could not install fish plugins"
}


# --- Main ---
main() {
    echo ""
    info "=== Dotfiles Bootstrap ==="
    echo ""

    install_packages
    echo ""
    install_lsp_servers
    echo ""
    backup_conflicts "${PACKAGES[@]}"
    echo ""
    stow_packages
    echo ""
    setup_secrets
    echo ""
    setup_claude
    echo ""
    setup_fish_plugins

    echo ""
    info "=== Done! ==="
    info "Restart your shell or run: exec fish"
    info "Fish launches automatically for interactive sessions via .bashrc"
    echo ""
    warn "Don't forget to:"
    warn "  1. Edit ~/.secrets with your tokens (or set up 1Password CLI)"
    warn "  2. Create ~/.gitconfig.local for machine-specific git settings (e.g., email)"
    echo ""
}

main "$@"
