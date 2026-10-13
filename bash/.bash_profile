# The following lines were added by Docker Desktop to add commands to your PATH.
export PATH="$PATH:/Users/mattijsbliek/.docker/bin"
# End of Docker Desktop section.

# Load secrets (available in all login sessions, including non-interactive)
[ -f ~/.secrets ] && source ~/.secrets

# Source .bashrc for interactive session handling
[ -f ~/.bashrc ] && source ~/.bashrc
. "$HOME/.cargo/env"
