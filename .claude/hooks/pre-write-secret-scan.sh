#!/usr/bin/env bash
# PreToolUse hook: scan content for secrets before Claude writes or edits a file.
# Installed to .claude/hooks/pre-write-secret-scan.sh by payload-depot.
# Fires on Write and Edit tool calls.
#
# Stdin (from Claude Code): JSON with tool_name and tool_input.
# Exits 2 when a secret pattern is matched — Claude Code blocks the tool call.
# Exits 0 when clean or when jq is unavailable.
#
# Patterns are intentionally high-confidence to minimise false positives.
# If a match is a false positive, move the value to an environment variable.

PREFIX="[payload-depot:secret-scan]"

if ! command -v jq &>/dev/null; then
  echo "$PREFIX jq not found — skipping secret scan" >&2
  exit 0
fi

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty' 2>/dev/null)

# Extract the content being written depending on the tool
case "$tool_name" in
  Write)
    content=$(echo "$input" | jq -r '.tool_input.content // empty' 2>/dev/null)
    ;;
  Edit)
    content=$(echo "$input" | jq -r '.tool_input.new_string // empty' 2>/dev/null)
    ;;
  *)
    exit 0
    ;;
esac

[[ -z "$content" ]] && exit 0

FOUND=false
MATCHES=()

check_pattern() {
  local label="$1" pattern="$2"
  if echo "$content" | grep -qP -- "$pattern" 2>/dev/null; then
    MATCHES+=("$label")
    FOUND=true
  fi
}

# High-confidence patterns only
check_pattern "AWS access key ID"          'AKIA[0-9A-Z]{16}'
check_pattern "AWS secret access key"      '(?i)aws_secret_access_key\s*[=:]\s*[A-Za-z0-9/+=]{40}'
check_pattern "PEM private key"            '-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY'
check_pattern "GitHub personal token"      'ghp_[A-Za-z0-9]{36}'
check_pattern "GitHub Actions token"       'ghs_[A-Za-z0-9]{36}'
check_pattern "GitHub OAuth token"         'gho_[A-Za-z0-9]{36}'
check_pattern "Slack bot token"            'xoxb-[0-9]{11}-[0-9]{11}-[A-Za-z0-9]{24}'
check_pattern "Slack user token"           'xoxp-[0-9]{11}-[0-9]{11}-[A-Za-z0-9]{24}'
check_pattern "Anthropic API key"          'sk-ant-[A-Za-z0-9\-_]{90,}'
check_pattern "OpenAI API key"             'sk-[A-Za-z0-9]{48}'

if $FOUND; then
  echo "$PREFIX SECRET DETECTED — write blocked."
  echo "$PREFIX Pattern(s) matched: ${MATCHES[*]}"
  echo "$PREFIX Move the value to an environment variable and reference it symbolically."
  exit 2
fi

exit 0
