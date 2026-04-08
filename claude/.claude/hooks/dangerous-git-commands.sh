#!/bin/bash
# Claude Code Hook: prevent dangerous Git commands
# Place this at: ~/.claude/hooks/dangerous-git-commands.sh
# Then make it executable: chmod +x ~/.claude/hooks/dangerous-git-commands.sh

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

SAFE_PATTERNS=(
  "push --force-with-lease"
)

DANGEROUS_PATTERNS=(
  "git reset --hard"
  "git clean -fd"
  "git clean -f"
  "git branch -D"
  "git checkout \."
  "git restore \."
  "push --force"
  "reset --hard"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    safe=false
    for safe_pattern in "${SAFE_PATTERNS[@]}"; do
      if echo "$COMMAND" | grep -qE "$safe_pattern"; then
        safe=true
        break
      fi
    done
    if [ "$safe" = false ]; then
      echo "BLOCKED: '$COMMAND' matches dangerous pattern '$pattern'. The user has prevented you from doing this." >&2
      exit 2
    fi
  fi
done

exit 0