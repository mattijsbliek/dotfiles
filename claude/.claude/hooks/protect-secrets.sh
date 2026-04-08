#!/bin/bash
# Claude Code Hook: Block access to sensitive files
# Place this at: ~/.claude/hooks/protect-secrets.sh
# Then make it executable: chmod +x ~/.claude/hooks/protect-secrets.sh

# Read the tool input JSON from stdin
INPUT=$(cat)

# Extract the tool name and relevant path/command fields
TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null)
TOOL_INPUT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(json.dumps(d.get('tool_input','')))" 2>/dev/null)

# Patterns for sensitive files
SENSITIVE_PATTERNS=(
  # Environment files
  '\.env$'
  '\.env\.'
  '\.envrc'
  # SSH keys and config
  '\.ssh/'
  'id_rsa'
  'id_ed25519'
  'id_ecdsa'
  'id_dsa'
  '\.pem$'
  '\.key$'
  # GPG keys
  '\.gpg$'
  '\.asc$'
  # AWS credentials
  '\.aws/credentials'
  '\.aws/config'
  # GCP credentials
  'gcloud/credentials'
  'application_default_credentials\.json'
  # Kubernetes secrets
  '\.kube/config'
  # Docker config (may contain registry tokens)
  '\.docker/config\.json'
  # Password/secret stores
  '\.netrc$'
  '\.pgpass$'
  'credentials\.json$'
  'secrets\.json$'
  'secrets\.yaml$'
  'secrets\.yml$'
  # macOS Keychain
  '\.keychain'
  # Git credentials
  '\.git-credentials'
  # NPM / pip tokens
  '\.npmrc$'
  '\.pypirc$'
  # Terraform state (may contain secrets)
  '\.tfstate$'
  '\.tfvars$'
)

# Function to check if a path matches any sensitive pattern
is_sensitive() {
  local path="$1"
  for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if echo "$path" | grep -qE "$pattern"; then
      return 0
    fi
  done
  return 1
}

# Check Read tool
if [[ "$TOOL_NAME" == "Read" ]]; then
  FILE_PATH=$(echo "$TOOL_INPUT" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('file_path',''))" 2>/dev/null)
  if is_sensitive "$FILE_PATH"; then
    echo "🔒 BLOCKED: Access to sensitive file denied: $FILE_PATH" >&2
    echo "This file may contain secrets or credentials. Access has been blocked by the protect-secrets hook." >&2
    exit 2  # Exit code 2 = block the tool call
  fi
fi

# Check Edit / Write tools
if [[ "$TOOL_NAME" == "Edit" || "$TOOL_NAME" == "Write" ]]; then
  FILE_PATH=$(echo "$TOOL_INPUT" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('file_path',''))" 2>/dev/null)
  if is_sensitive "$FILE_PATH"; then
    echo "🔒 BLOCKED: Write access to sensitive file denied: $FILE_PATH" >&2
    echo "This file may contain secrets or credentials. Access has been blocked by the protect-secrets hook." >&2
    exit 2
  fi
fi

# Check Bash tool for cat/read commands targeting sensitive files
if [[ "$TOOL_NAME" == "Bash" ]]; then
  COMMAND=$(echo "$TOOL_INPUT" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('command',''))" 2>/dev/null)
  for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if echo "$COMMAND" | grep -qE "$pattern"; then
      echo "🔒 BLOCKED: Bash command references a sensitive file path." >&2
      echo "Command: $COMMAND" >&2
      echo "Matched pattern: $pattern" >&2
      echo "Access has been blocked by the protect-secrets hook." >&2
      exit 2
    fi
  done
fi

# All checks passed — allow the tool call
exit 0
