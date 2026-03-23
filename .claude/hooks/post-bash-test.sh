#!/usr/bin/env bash
# PostToolUse hook: surface a structured test summary after Claude runs a test command.
# Installed to .claude/hooks/post-bash-test.sh by payload-depot.
# Fires on all Bash tool calls; exits silently when the command is not a test runner.
#
# Stdin (from Claude Code): JSON with tool_name, tool_input, and tool_response.
# Always exits 0 (observational — does not block or retry).

PREFIX="[payload-depot:test-summary]"

if ! command -v jq &>/dev/null; then
  exit 0
fi

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)

[[ -z "$command" ]] && exit 0

# Only act on recognised test runners
is_test_command=false
case "$command" in
  pytest*|py.test*|\
  bats*|\
  "npm test"*|"npm run test"*|\
  jest*|vitest*|\
  "make test"*|"make check"*|"make -C"*" test"*|\
  bash\ tests/*.sh*|bash\ test_*.sh*)
    is_test_command=true
    ;;
esac

$is_test_command || exit 0

# Extract test output from tool_response (string or object)
output=$(echo "$input" | jq -r '
  if (.tool_response | type) == "string" then .tool_response
  elif .tool_response.output then .tool_response.output
  else ""
  end' 2>/dev/null)

[[ -z "$output" ]] && exit 0

# Parse pass/fail counts from common test runner formats
passed=0
failed=0
errors=0
summary=""

# pytest: "3 passed", "2 failed", "1 error"
if echo "$output" | grep -qE '[0-9]+ passed'; then
  passed=$(echo "$output" | grep -oE '[0-9]+ passed' | grep -oE '[0-9]+' | tail -1)
fi
if echo "$output" | grep -qE '[0-9]+ failed'; then
  failed=$(echo "$output" | grep -oE '[0-9]+ failed' | grep -oE '[0-9]+' | tail -1)
fi
if echo "$output" | grep -qE '[0-9]+ error'; then
  errors=$(echo "$output" | grep -oE '[0-9]+ error' | grep -oE '[0-9]+' | tail -1)
fi

# bats: "N tests, N failures"
if echo "$output" | grep -qE '[0-9]+ tests,'; then
  passed=$(echo "$output" | grep -oE '[0-9]+ tests' | grep -oE '[0-9]+' | tail -1)
  bats_fail=$(echo "$output" | grep -oE '[0-9]+ failures?' | grep -oE '[0-9]+' | tail -1)
  failed=${bats_fail:-0}
  passed=$(( passed - failed ))
fi

# payload-depot lib.sh format: "Results: N passed, N failed"
if echo "$output" | grep -qF 'Results:'; then
  passed=$(echo "$output" | grep 'Results:' | grep -oE '[0-9]+ passed' | grep -oE '[0-9]+' | tail -1)
  failed=$(echo "$output" | grep 'Results:' | grep -oE '[0-9]+ failed' | grep -oE '[0-9]+' | tail -1)
fi

passed=${passed:-0}
failed=${failed:-0}
errors=${errors:-0}
total=$(( passed + failed + errors ))

if [[ $total -eq 0 ]]; then
  exit 0
fi

if [[ $failed -eq 0 && $errors -eq 0 ]]; then
  echo "$PREFIX $passed/$total passed"
else
  echo "$PREFIX $passed/$total passed  |  $failed failed  |  $errors errors"
fi

exit 0
