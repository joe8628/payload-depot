#!/usr/bin/env bash
# Minimal test assertion library for Rig tests

PASS=0
FAIL=0

assert_eq() {
  local description="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "  ✓ $description"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $description"
    echo "    expected: $(printf '%q' "$expected")"
    echo "    actual:   $(printf '%q' "$actual")"
    FAIL=$((FAIL + 1))
  fi
}

assert_file_exists() {
  local description="$1" file="$2"
  if [[ -f "$file" ]]; then
    echo "  ✓ $description"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $description"
    echo "    file not found: $file"
    FAIL=$((FAIL + 1))
  fi
}

assert_dir_exists() {
  local description="$1" dir="$2"
  if [[ -d "$dir" ]]; then
    echo "  ✓ $description"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $description"
    echo "    dir not found: $dir"
    FAIL=$((FAIL + 1))
  fi
}

assert_exit_code() {
  local description="$1" expected="$2" actual="$3"
  assert_eq "$description (exit code)" "$expected" "$actual"
}

assert_contains() {
  local description="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -qF "$needle"; then
    echo "  ✓ $description"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $description"
    echo "    expected to find: $needle"
    echo "    in: $haystack"
    FAIL=$((FAIL + 1))
  fi
}

assert_not_file_exists() {
  local description="$1" file="$2"
  if [[ ! -f "$file" ]]; then
    echo "  ✓ $description"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $description"
    echo "    file should not exist: $file"
    FAIL=$((FAIL + 1))
  fi
}

assert_not_contains() {
  local description="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -qF "$needle"; then
    echo "  ✗ $description"
    echo "    expected NOT to find: $needle"
    FAIL=$((FAIL + 1))
  else
    echo "  ✓ $description"
    PASS=$((PASS + 1))
  fi
}

report() {
  echo ""
  echo "Results: $PASS passed, $FAIL failed"
  [[ $FAIL -eq 0 ]]
}
