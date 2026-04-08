#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

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

# --- Install dependencies ---
install_packages() {
    info "Checking dependencies..."

    local missing=()
    for cmd in fish nvim git stow curl jq unzip; do
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

    # fnm (Fast Node Manager) — provides Node.js + npm
    if ! command -v fnm &>/dev/null; then
        info "Installing fnm..."
        if [[ "$PLATFORM" == "macos" ]]; then
            brew install fnm
        else
            curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell \
                || warn "Could not install fnm"
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

    # diff-so-fancy
    if ! command -v diff-so-fancy &>/dev/null; then
        info "Installing diff-so-fancy..."
        if [[ "$PLATFORM" == "macos" ]]; then
            brew install diff-so-fancy
        else
            if command -v npm &>/dev/null; then
                npm install -g diff-so-fancy
            else
                warn "diff-so-fancy not installed (npm not available)"
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

    # Ghostty terminfo (fixes backspace/tab rendering over SSH)
    if ! infocmp xterm-ghostty &>/dev/null; then
        if [[ -f "$DOTFILES_DIR/ghostty-terminfo.src" ]]; then
            info "Installing Ghostty terminfo..."
            tic -x "$DOTFILES_DIR/ghostty-terminfo.src"
        fi
    fi
}

# --- Back up existing configs ---
backup_existing() {
    local needs_backup=false
    local items=(
        "$HOME/.bash_profile"
        "$HOME/.bashrc"
        "$HOME/.config/fish"
        "$HOME/.config/nvim"
        "$HOME/.gitconfig"
        "$HOME/.gitignore_global"
        "$HOME/.gitconfig.macos"
        "$HOME/.gitconfig.linux"
        "$HOME/.claude"
    )

    for item in "${items[@]}"; do
        if [[ -e "$item" && ! -L "$item" ]]; then
            needs_backup=true
            break
        fi
    done

    if [[ "$needs_backup" == "true" ]]; then
        info "Backing up existing configs to $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
        for item in "${items[@]}"; do
            if [[ -e "$item" && ! -L "$item" ]]; then
                cp -r "$item" "$BACKUP_DIR/" 2>/dev/null || true
                info "  Backed up: $item"
            fi
        done
    else
        info "No existing configs to back up (all symlinks or absent)."
    fi
}

# --- Stow packages ---
stow_packages() {
    info "Stowing dotfiles packages..."
    cd "$DOTFILES_DIR"
    for pkg in bash fish nvim git claude starship ghostty; do
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
    backup_existing
    echo ""
    stow_packages
    echo ""
    setup_secrets
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
