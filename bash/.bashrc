# Non-interactive sessions: stop here
[[ $- != *i* ]] && return

# Interactive sessions: switch to fish
if command -v fish &>/dev/null; then
    exec fish
fi

# fnm
FNM_PATH="/home/mattijs/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --shell bash)"
fi
