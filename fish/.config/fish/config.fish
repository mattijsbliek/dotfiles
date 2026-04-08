# PATH
set -gx PATH /usr/local/bin $PATH
set -gx PATH node_modules/.bin $PATH
set -gx PATH $HOME/.bin $PATH
set -gx PATH /usr/local/sbin $PATH
set -gx PATH $HOME/.local/bin $PATH

# Elixir/OTP
set -gx PATH $HOME/.elixir-install/installs/otp/27.1.2/bin $PATH
set -gx PATH $HOME/.elixir-install/installs/elixir/1.17.3-otp-27/bin $PATH

# SDKMan
if test -d "$HOME/.sdkman"
    set -gx SDKMAN_DIR "$HOME/.sdkman"
end

# Go
set -x -U GOPATH $HOME/Sites/go

# Disable welcome message
set fish_greeting ""

# Language settings
set -x LC_ALL en_US.UTF-8
set -x LANG en_US.UTF-8

# Editor
set -gx EDITOR nvim

# Docker host IDs
export DOCKER_HOST_UID=(id -u)
export DOCKER_HOST_GID=(id -g)

# Fundle plugins (installed via install.sh)
if functions -q fundle
    fundle plugin tuvistavie/fish-ssh-agent
    fundle plugin edc/bass
    fundle init
end

# Load secrets (bash-compatible file, sourced via bass)
# On Linux servers, .bash_profile already sources this before exec-ing fish,
# so the vars are inherited. This covers macOS where fish is the login shell.
if test -f ~/.secrets; and not set -q __secrets_loaded
    if functions -q bass
        bass source ~/.secrets
        set -gx __secrets_loaded 1
    end
end

# Starship prompt
starship init fish | source

# eza as ls replacement
alias ls='eza --group-directories-first --icons -1'

# Reload fish profile
alias reload='source ~/.config/fish/config.fish'

# Git aliases
alias gl='git pull --rebase'
alias gp='git push'
alias gs='git status'
alias gmm='git co master; gl; git co -; git merge master'
alias amend='git add .; git commit --amend --no-edit'
alias ldc='git log -1 (git tag --list | tail -2 | head -1)'

# cd shortcuts
alias ..="cd ../"
alias ...="cd ../../"
alias ....="cd ../../../"
alias .....="cd ../../../../"

# rbenv (if installed)
if command -q rbenv
    status --is-interactive; and rbenv init - --no-rehash fish | source
end

# pyenv (if installed)
if command -q pyenv
    pyenv init - | source
end

# SDKMan for fish (if fundle plugin is installed)
if test -f ~/.config/fish/fundle/reitzig/sdkman-for-fish/conf.d/sdk.fish
    source ~/.config/fish/fundle/reitzig/sdkman-for-fish/conf.d/sdk.fish
end
