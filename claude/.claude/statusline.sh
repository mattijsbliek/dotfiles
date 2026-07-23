#!/bin/bash
# Claude Code status line: repo | branch | context tokens used | model.
# e.g. "Clientroom | 🌿 (main) | 20k (10%) | 🤖 Opus 4.6"
# Token color: grey under 100k tokens, yellow 100k-200k, red above 200k.

input=$(cat)

CYAN='\033[36m'
GREEN='\033[32m'
GREY='\033[90m'
YELLOW='\033[33m'
RED='\033[31m'
MAGENTA='\033[35m'
RESET='\033[0m'

REPO=$(echo "$input" | jq -r '.workspace.repo.name // empty')
if [ -z "$REPO" ]; then
  DIR=$(echo "$input" | jq -r '.workspace.current_dir')
  REPO="${DIR##*/}"
fi

BRANCH=$(git branch --show-current 2>/dev/null)

TOKENS=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

if [ "$TOKENS" -ge 200000 ]; then
  TOKEN_COLOR="$RED"
elif [ "$TOKENS" -ge 100000 ]; then
  TOKEN_COLOR="$YELLOW"
else
  TOKEN_COLOR="$GREY"
fi

if [ "$TOKENS" -ge 1000 ]; then
  TOKEN_DISPLAY="$((TOKENS / 1000))k"
else
  TOKEN_DISPLAY="$TOKENS"
fi

MODEL=$(echo "$input" | jq -r '.model.display_name // empty')

OUTPUT="${CYAN}${REPO}${RESET}"
[ -n "$BRANCH" ] && OUTPUT="${OUTPUT} | ${GREEN}🌿 (${BRANCH})${RESET}"
OUTPUT="${OUTPUT} | ${TOKEN_COLOR}${TOKEN_DISPLAY} (${PCT}%)${RESET}"
[ -n "$MODEL" ] && OUTPUT="${OUTPUT} | ${MAGENTA}🤖 ${MODEL}${RESET}"

printf '%b\n' "$OUTPUT"
