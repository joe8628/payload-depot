#!/usr/bin/env bash
set -uo pipefail

RIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$RIG_DIR/tests/lib.sh"

# Copy a fixture into a temp dir with a fresh .git so tests are isolated
setup_fixture() {
  local fixture="$1"
  local tmp
  tmp=$(mktemp -d)
  cp -r "$RIG_DIR/tests/fixtures/$fixture/." "$tmp/"
  git -C "$tmp" init -q 2>/dev/null
  echo "$tmp"
}

cleanup() { rm -rf "$1"; }

echo "=== Install Tests ==="

# 1. fresh-install-python
echo ""
echo "-- fresh-install-python --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$RIG_DIR/rig" install --no-codebase-index 2>&1) || true
assert_dir_exists  "agents dir created"           "$dir/.claude/agents"
assert_dir_exists  "skills dir created"           "$dir/.claude/skills"
assert_file_exists "CLAUDE.md written"            "$dir/CLAUDE.md"
assert_file_exists "CONVENTIONS.md written"       "$dir/CONVENTIONS.md"
assert_file_exists "AGENTS.md written"            "$dir/AGENTS.md"
assert_file_exists "settings.json written"        "$dir/.claude/settings.json"
assert_file_exists "HANDOFF.md written"           "$dir/HANDOFF.md"
assert_file_exists "SCRATCHPAD.md written"        "$dir/SCRATCHPAD.md"
assert_file_exists "DECISIONS.md written"         "$dir/DECISIONS.md"
assert_file_exists "pre-commit hook installed"    "$dir/.git/hooks/pre-commit"
cleanup "$dir"

# 2. fresh-install-typescript
echo ""
echo "-- fresh-install-typescript --"
dir=$(setup_fixture typescript-project)
(cd "$dir" && "$RIG_DIR/rig" install --no-codebase-index 2>&1) || true
assert_dir_exists  "agents dir created"  "$dir/.claude/agents"
assert_file_exists "CLAUDE.md written"   "$dir/CLAUDE.md"
assert_file_exists "HANDOFF.md written"  "$dir/HANDOFF.md"
cleanup "$dir"

# 3. fresh-install-cpp
echo ""
echo "-- fresh-install-cpp --"
dir=$(setup_fixture cpp-project)
(cd "$dir" && "$RIG_DIR/rig" install --no-codebase-index 2>&1) || true
assert_dir_exists  "agents dir created"  "$dir/.claude/agents"
assert_file_exists "CLAUDE.md written"   "$dir/CLAUDE.md"
assert_file_exists "HANDOFF.md written"  "$dir/HANDOFF.md"
cleanup "$dir"

# 4. skip-existing-config
echo ""
echo "-- skip-existing-config --"
dir=$(setup_fixture python-project)
echo "# existing" > "$dir/CLAUDE.md"
output=$(cd "$dir" && "$RIG_DIR/rig" install --no-codebase-index 2>&1) || true
assert_contains    "skip message printed"        "Skipped" "$output"
assert_eq          "CLAUDE.md not overwritten"   "# existing" "$(cat "$dir/CLAUDE.md")"
cleanup "$dir"

# 5. force-overwrite
echo ""
echo "-- force-overwrite --"
dir=$(setup_fixture python-project)
echo "# existing" > "$dir/CLAUDE.md"
(cd "$dir" && "$RIG_DIR/rig" install --force --no-codebase-index 2>&1) || true
content=$(cat "$dir/CLAUDE.md")
[[ "$content" != "# existing" ]] && result=0 || result=1
assert_eq "CLAUDE.md overwritten" "0" "$result"
cleanup "$dir"

# 6. dry-run
echo ""
echo "-- dry-run --"
dir=$(setup_fixture python-project)
output=$(cd "$dir" && "$RIG_DIR/rig" install --dry-run --no-codebase-index 2>&1) || true
assert_contains    "dry-run output shown"        "dry-run" "$output"
[[ ! -f "$dir/CLAUDE.md" ]] && result=0 || result=1
assert_eq          "dry-run: no files written"   "0" "$result"
cleanup "$dir"

# 7. no-git-repo
echo ""
echo "-- no-git-repo --"
dir=$(mktemp -d)
code=0; (cd "$dir" && "$RIG_DIR/rig" install --no-codebase-index 2>/dev/null) || code=$?
assert_exit_code "no git repo exits 2" "2" "$code"
cleanup "$dir"

# 8. unknown-target
echo ""
echo "-- unknown-target --"
dir=$(setup_fixture python-project)
code=0; (cd "$dir" && "$RIG_DIR/rig" install --target nonexistent --no-codebase-index 2>/dev/null) || code=$?
assert_exit_code "unknown target exits 3" "3" "$code"
cleanup "$dir"

# 9. no-hooks
echo ""
echo "-- no-hooks --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$RIG_DIR/rig" install --no-hooks --no-codebase-index 2>&1) || true
[[ ! -f "$dir/.git/hooks/pre-commit" ]] && result=0 || result=1
assert_eq "hook not installed" "0" "$result"
cleanup "$dir"

# 10. no-codebase-index
echo ""
echo "-- no-codebase-index --"
dir=$(setup_fixture python-project)
output=$(cd "$dir" && "$RIG_DIR/rig" install --no-codebase-index 2>&1) || true
assert_contains "skip message for index" "codebase index" "$output"
cleanup "$dir"

report
