# Load secrets (available in all login sessions, including non-interactive)
[ -f ~/.secrets ] && source ~/.secrets

# Source .bashrc for interactive session handling
[ -f ~/.bashrc ] && source ~/.bashrc
