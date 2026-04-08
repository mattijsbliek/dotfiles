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

# --- Install dependencies ---
install_packages() {
    info "Checking dependencies..."

    local missing=()
    for cmd in fish nvim git stow curl jq; do
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
            # Map command names to package names
            local pkgs=()
            for cmd in "${missing[@]}"; do
                case "$cmd" in
                    nvim) pkgs+=("neovim") ;;
                    *)    pkgs+=("$cmd") ;;
                esac
            done
            sudo apt install -y "${pkgs[@]}"
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

    # diff-so-fancy
    if ! command -v diff-so-fancy &>/dev/null; then
        info "Installing diff-so-fancy..."
        if [[ "$PLATFORM" == "macos" ]]; then
            brew install diff-so-fancy
        else
            # Install via npm if available, otherwise skip
            if command -v npm &>/dev/null; then
                sudo npm install -g diff-so-fancy
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
    for item in "$HOME/.config/fish" "$HOME/.config/nvim" "$HOME/.gitconfig" "$HOME/.gitignore_global" "$HOME/.gitconfig.macos" "$HOME/.gitconfig.linux" "$HOME/.claude"; do
        if [[ -e "$item" && ! -L "$item" ]]; then
            needs_backup=true
            break
        fi
    done

    if [[ "$needs_backup" == "true" ]]; then
        info "Backing up existing configs to $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
        for item in "$HOME/.config/fish" "$HOME/.config/nvim" "$HOME/.gitconfig" "$HOME/.gitignore_global" "$HOME/.gitconfig.macos" "$HOME/.gitconfig.linux" "$HOME/.claude"; do
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
    if command -v fish &>/dev/null; then
        info "Installing fish plugins via fundle..."
        fish -c "
            if functions -q fundle
                fundle install
            else
                echo 'fundle not found — it will be bootstrapped on first shell start'
            end
        " 2>/dev/null || warn "Could not install fish plugins (will happen on first shell start)"
    fi
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
