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

# Require explicit user approval for any push that lands on main/master,
# even when not a force-push (auto permission mode won't otherwise prompt for it).
# Ask git what it will ACTUALLY do (via --dry-run --porcelain) instead of guessing
# from the command text: a branch's upstream tracking can silently redirect an
# explicit `git push origin <branch>` onto a completely different remote ref.
if echo "$COMMAND" | grep -qE '\bgit[[:space:]]+push\b'; then
  CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
  PUSH_SEGMENT=$(echo "$COMMAND" | sed -E 's/.*(git[[:space:]]+push)/\1/; s/(&&|;|\|).*$//')
  DRYRUN_SEGMENT=$(echo "$PUSH_SEGMENT" | sed -E 's/^(git[[:space:]]+push)/\1 --dry-run --porcelain/')

  PORCELAIN=$(cd "$CWD" 2>/dev/null && eval "$DRYRUN_SEGMENT" 2>/dev/null)
  DESTS=$(echo "$PORCELAIN" | awk -F'\t' '$2 { split($2, a, ":"); print a[2] }' | sed -E 's#^refs/heads/##')

  if echo "$DESTS" | grep -qxE 'main|master'; then
    DEST=$(echo "$DESTS" | grep -xE 'main|master' | head -1)
    REASON="Direct push to $DEST detected: '$COMMAND'. Confirm with the user before this push runs."
    jq -n --arg reason "$REASON" \
      '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "ask", permissionDecisionReason: $reason}}'
    exit 0
  fi
fi

exit 0