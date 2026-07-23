#!/bin/bash
# Claude Code status line: repo | branch | worktree (if in one) | context tokens used | model.
# e.g. "Clientroom | 🌿 (mattijs/JIRA-1-fix) | 🌳 mattijs/JIRA-1-fix | 20k (10%) | 🤖 Opus 4.6"
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

GIT_DIR=$(git rev-parse --git-dir 2>/dev/null)
GIT_COMMON_DIR=$(git rev-parse --git-common-dir 2>/dev/null)
if [ -n "$GIT_COMMON_DIR" ] && [ "$GIT_DIR" != "$GIT_COMMON_DIR" ]; then
  TOPLEVEL=$(git rev-parse --show-toplevel 2>/dev/null)
  WORKTREE="${TOPLEVEL##*/}"
  MAIN_DIR="${GIT_COMMON_DIR%/.git}"
  if [ "$WORKTREE" = "${MAIN_DIR##*/}" ]; then
    PARENT="${TOPLEVEL%/*}"
    WORKTREE="${PARENT##*/}"
  fi
fi

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
[ -n "$WORKTREE" ] && OUTPUT="${OUTPUT} | ${GREEN}🌳 ${WORKTREE}${RESET}"
OUTPUT="${OUTPUT} | ${TOKEN_COLOR}${TOKEN_DISPLAY} (${PCT}%)${RESET}"
[ -n "$MODEL" ] && OUTPUT="${OUTPUT} | ${MAGENTA}🤖 ${MODEL}${RESET}"

printf '%b\n' "$OUTPUT"
