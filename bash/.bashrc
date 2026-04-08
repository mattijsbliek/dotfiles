# Non-interactive sessions: stop here
[[ $- != *i* ]] && return

# Interactive sessions: switch to fish
if command -v fish &>/dev/null; then
    exec fish
fi
