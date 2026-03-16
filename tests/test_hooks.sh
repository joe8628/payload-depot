#!/usr/bin/env bash
set -uo pipefail

RIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$RIG_DIR/tests/lib.sh"

HOOK="$RIG_DIR/hooks/pre-commit"

# Create a temp project with a language marker file and a fresh git repo
setup_project() {
  local marker="$1"
  local dir
  dir=$(mktemp -d)
  git -C "$dir" init -q
  git -C "$dir" config user.email "test@test.com"
  git -C "$dir" config user.name "Test"
  touch "$dir/$marker"
  echo "$dir"
}

# Create a mock binary that exits with a given code and optionally prints output
mock_bin() {
  local dir="$1" name="$2" exit_code="$3" output="${4:-}"
  mkdir -p "$dir/mock-bin"
  printf '#!/bin/bash\n%s\nexit %s\n' "${output:+echo \"$output\"}" "$exit_code" > "$dir/mock-bin/$name"
  chmod +x "$dir/mock-bin/$name"
}

echo "=== Hook Tests ==="

# 1. unknown-language: no language marker → exits 0 with warning
echo ""
echo "-- unknown-language --"
dir=$(mktemp -d) && git -C "$dir" init -q
code=0; (cd "$dir" && bash "$HOOK" 2>&1) || code=$?
assert_exit_code "unknown language exits 0" "0" "$code"
rm -rf "$dir"

# 2. missing-tool: python project, ruff not on PATH → exits 0 with warning
echo ""
echo "-- missing-tool --"
dir=$(setup_project pyproject.toml)
code=0; (cd "$dir" && PATH="/nonexistent:$PATH" bash "$HOOK" 2>&1) || code=$?
assert_exit_code "missing tool exits 0" "0" "$code"
rm -rf "$dir"

# 3. python-clean: ruff and mypy both succeed → exits 0
echo ""
echo "-- python-clean --"
dir=$(setup_project pyproject.toml)
mock_bin "$dir" ruff 0
mock_bin "$dir" mypy 0
code=0; (cd "$dir" && PATH="$dir/mock-bin:$PATH" bash "$HOOK" 2>&1) || code=$?
assert_exit_code "python-clean exits 0" "0" "$code"
rm -rf "$dir"

# 4. python-lint-fail: ruff fails → exits 1
echo ""
echo "-- python-lint-fail --"
dir=$(setup_project pyproject.toml)
mock_bin "$dir" ruff 1 "E501 line too long"
mock_bin "$dir" mypy 0
code=0; (cd "$dir" && PATH="$dir/mock-bin:$PATH" bash "$HOOK" 2>&1) || code=$?
assert_exit_code "python-lint-fail exits 1" "1" "$code"
rm -rf "$dir"

# 5. python-type-fail: mypy fails → exits 1
echo ""
echo "-- python-type-fail --"
dir=$(setup_project pyproject.toml)
mock_bin "$dir" ruff 0
mock_bin "$dir" mypy 1 "error: incompatible types"
code=0; (cd "$dir" && PATH="$dir/mock-bin:$PATH" bash "$HOOK" 2>&1) || code=$?
assert_exit_code "python-type-fail exits 1" "1" "$code"
rm -rf "$dir"

# 6. typescript-clean: eslint and tsc both succeed → exits 0
echo ""
echo "-- typescript-clean --"
dir=$(setup_project package.json)
mock_bin "$dir" eslint 0
mock_bin "$dir" tsc 0
code=0; (cd "$dir" && PATH="$dir/mock-bin:$PATH" bash "$HOOK" 2>&1) || code=$?
assert_exit_code "typescript-clean exits 0" "0" "$code"
rm -rf "$dir"

# 7. typescript-lint-fail: eslint fails → exits 1
echo ""
echo "-- typescript-lint-fail --"
dir=$(setup_project package.json)
mock_bin "$dir" eslint 1 "error  no-unused-vars"
mock_bin "$dir" tsc 0
code=0; (cd "$dir" && PATH="$dir/mock-bin:$PATH" bash "$HOOK" 2>&1) || code=$?
assert_exit_code "typescript-lint-fail exits 1" "1" "$code"
rm -rf "$dir"

report
