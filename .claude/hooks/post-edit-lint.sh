#!/usr/bin/env bash
# PostToolUse hook: lint files immediately after Claude writes or edits them.
# Installed to .claude/hooks/post-edit-lint.sh by payload-depot.
# Fires on Write and Edit tool calls.
#
# Stdin (from Claude Code): JSON with tool_name and tool_input.
# Exits 1 when violations are found — Claude sees the output and self-corrects.
# Exits 0 when clean or when linter is unavailable.

PREFIX="[payload-depot:post-edit-lint]"

if ! command -v jq &>/dev/null; then
  echo "$PREFIX jq not found — skipping lint" >&2
  exit 0
fi

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

[[ -z "$file_path" ]] && exit 0
[[ ! -f "$file_path" ]] && exit 0

run_linter() {
  local label="$1" cmd="$2"
  shift 2

  if ! command -v "$cmd" &>/dev/null; then
    echo "$PREFIX $cmd not found — skipping $label" >&2
    return 0
  fi

  local output exit_code=0
  output=$("$cmd" "$@" 2>&1) || exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    echo "$PREFIX $label violations in $file_path:"
    echo "$output"
    return 1
  fi

  echo "$PREFIX $label: clean"
  return 0
}

FAILED=false

case "$file_path" in
  *.py)
    run_linter "ruff" ruff check --quiet "$file_path" || FAILED=true
    ;;
  *.ts|*.tsx|*.js|*.jsx)
    run_linter "eslint" eslint --quiet "$file_path" || FAILED=true
    ;;
  *.c|*.cpp|*.h|*.hpp)
    run_linter "clang-tidy" clang-tidy --quiet "$file_path" -- || FAILED=true
    ;;
  *.sh|*.bash)
    run_linter "shellcheck" shellcheck "$file_path" || FAILED=true
    ;;
esac

$FAILED && exit 1
exit 0
