#!/usr/bin/env bash
set -uo pipefail

PAYLOAD_DEPOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PAYLOAD_DEPOT_DIR/tests/lib.sh"

# Copy a fixture into a temp dir with a fresh .git so tests are isolated
setup_fixture() {
  local fixture="$1"
  local tmp
  tmp=$(mktemp -d)
  cp -r "$PAYLOAD_DEPOT_DIR/tests/fixtures/$fixture/." "$tmp/"
  git -C "$tmp" init -q 2>/dev/null
  echo "$tmp"
}

cleanup() { rm -rf "$1"; }

echo "=== Install Tests ==="

# 1. fresh-install-python
echo ""
echo "-- fresh-install-python --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
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
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
assert_dir_exists  "agents dir created"  "$dir/.claude/agents"
assert_file_exists "CLAUDE.md written"   "$dir/CLAUDE.md"
assert_file_exists "HANDOFF.md written"  "$dir/HANDOFF.md"
cleanup "$dir"

# 3. fresh-install-cpp
echo ""
echo "-- fresh-install-cpp --"
dir=$(setup_fixture cpp-project)
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
assert_dir_exists  "agents dir created"  "$dir/.claude/agents"
assert_file_exists "CLAUDE.md written"   "$dir/CLAUDE.md"
assert_file_exists "HANDOFF.md written"  "$dir/HANDOFF.md"
cleanup "$dir"

# 4. skip-existing-config
echo ""
echo "-- skip-existing-config --"
dir=$(setup_fixture python-project)
echo "# existing" > "$dir/CLAUDE.md"
output=$(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
assert_contains    "skip message printed"        "Skipped" "$output"
assert_eq          "CLAUDE.md not overwritten"   "# existing" "$(cat "$dir/CLAUDE.md")"
cleanup "$dir"

# 5. force-overwrite
echo ""
echo "-- force-overwrite --"
dir=$(setup_fixture python-project)
echo "# existing" > "$dir/CLAUDE.md"
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --force --no-codebase-index 2>&1) || true
content=$(cat "$dir/CLAUDE.md")
[[ "$content" != "# existing" ]] && result=0 || result=1
assert_eq "CLAUDE.md overwritten" "0" "$result"
cleanup "$dir"

# 6. dry-run
echo ""
echo "-- dry-run --"
dir=$(setup_fixture python-project)
output=$(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --dry-run --no-codebase-index 2>&1) || true
assert_contains    "dry-run output shown"        "dry-run" "$output"
[[ ! -f "$dir/CLAUDE.md" ]] && result=0 || result=1
assert_eq          "dry-run: no files written"   "0" "$result"
cleanup "$dir"

# 7. no-git-repo
echo ""
echo "-- no-git-repo --"
dir=$(mktemp -d)
code=0; (cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>/dev/null) || code=$?
assert_exit_code "no git repo exits 2" "2" "$code"
cleanup "$dir"

# 8. unknown-target
echo ""
echo "-- unknown-target --"
dir=$(setup_fixture python-project)
code=0; (cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --target nonexistent --no-codebase-index 2>/dev/null) || code=$?
assert_exit_code "unknown target exits 3" "3" "$code"
cleanup "$dir"

# 9. no-hooks
echo ""
echo "-- no-hooks --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-hooks --no-codebase-index 2>&1) || true
[[ ! -f "$dir/.git/hooks/pre-commit" ]] && result=0 || result=1
assert_eq "hook not installed" "0" "$result"
cleanup "$dir"

# 10. no-codebase-index
echo ""
echo "-- no-codebase-index --"
dir=$(setup_fixture python-project)
output=$(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
assert_contains "skip message for index" "codebase index" "$output"
cleanup "$dir"

# 11. session-history-preserved-on-reinstall (B-001)
echo ""
echo "-- session-history-preserved-on-reinstall --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
echo "# existing handoff"   > "$dir/HANDOFF.md"
echo "# existing decisions" > "$dir/DECISIONS.md"
echo "# existing scratch"   > "$dir/SCRATCHPAD.md"
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
assert_eq "HANDOFF.md preserved"   "# existing handoff"   "$(cat "$dir/HANDOFF.md")"
assert_eq "DECISIONS.md preserved" "# existing decisions" "$(cat "$dir/DECISIONS.md")"
content=$(cat "$dir/SCRATCHPAD.md")
[[ "$content" != "# existing scratch" ]] && result=0 || result=1
assert_eq "SCRATCHPAD.md overwritten" "0" "$result"
cleanup "$dir"

# 12. session-history-preserved-with-force (B-001)
echo ""
echo "-- session-history-preserved-with-force --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
echo "# existing handoff"   > "$dir/HANDOFF.md"
echo "# existing decisions" > "$dir/DECISIONS.md"
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --force --no-codebase-index 2>&1) || true
assert_eq "HANDOFF.md preserved under --force"   "# existing handoff"   "$(cat "$dir/HANDOFF.md")"
assert_eq "DECISIONS.md preserved under --force" "# existing decisions" "$(cat "$dir/DECISIONS.md")"
cleanup "$dir"

# 13. fresh-install creates session files when absent (B-001)
echo ""
echo "-- fresh-install-creates-session-files --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
assert_file_exists "HANDOFF.md created on fresh install"    "$dir/HANDOFF.md"
assert_file_exists "DECISIONS.md created on fresh install"  "$dir/DECISIONS.md"
assert_file_exists "SCRATCHPAD.md created on fresh install" "$dir/SCRATCHPAD.md"
cleanup "$dir"

# 14. F-006: CLAUDE.md contains @file imports for session files
echo ""
echo "-- claude-md-at-file-imports (F-006) --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
content=$(cat "$dir/CLAUDE.md")
assert_contains "@HANDOFF.md import present"     "@HANDOFF.md"     "$content"
assert_contains "@CONVENTIONS.md import present" "@CONVENTIONS.md" "$content"
assert_contains "@AGENTS.md import present"      "@AGENTS.md"      "$content"
cleanup "$dir"

# 15. F-007: session-start and session-end hooks installed and settings.json wired
echo ""
echo "-- session-hooks (F-007) --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
assert_file_exists "session-start.sh installed"  "$dir/.claude/hooks/session-start.sh"
assert_file_exists "session-end.sh installed"    "$dir/.claude/hooks/session-end.sh"
settings=$(cat "$dir/.claude/settings.json")
assert_contains "settings.json has UserPromptSubmit hook" "UserPromptSubmit"   "$settings"
assert_contains "settings.json has Stop hook"             "Stop"               "$settings"
assert_contains "settings.json references session-start"  "session-start.sh"   "$settings"
assert_contains "settings.json references session-end"    "session-end.sh"     "$settings"
cleanup "$dir"

# 16. F-007: session-start hook writes dated header to SCRATCHPAD.md
echo ""
echo "-- session-start-hook-writes-header (F-007) --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
today=$(date +%Y-%m-%d)
# Run the hook directly (simulates Claude Code firing it)
(cd "$dir" && bash .claude/hooks/session-start.sh 2>/dev/null) || true
# Fresh template: hook substitutes <session date> → today in the heading
assert_contains "SCRATCHPAD.md has today's date" "$today" "$(cat "$dir/SCRATCHPAD.md")"
# Run again — must be idempotent (date appears exactly once)
(cd "$dir" && bash .claude/hooks/session-start.sh 2>/dev/null) || true
count=$(grep -cF "$today" "$dir/SCRATCHPAD.md" || true)
assert_eq "date written exactly once (idempotent)" "1" "$count"
cleanup "$dir"

# 17. F-007: hook appends new session block on a new calendar day
echo ""
echo "-- session-start-hook-new-day-append (F-007) --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
today=$(date +%Y-%m-%d)
# Run hook once to fill the <session date> placeholder (normal first-run)
(cd "$dir" && bash .claude/hooks/session-start.sh 2>/dev/null) || true
# Simulate the scratchpad having been used on a previous day by replacing today's date
sed -i "s|$today|2000-01-01|g" "$dir/SCRATCHPAD.md"
# Now run hook — today's date is absent, so it should append a new session block
(cd "$dir" && bash .claude/hooks/session-start.sh 2>/dev/null) || true
assert_contains "new day block appended"  "# Session $today"    "$(cat "$dir/SCRATCHPAD.md")"
assert_contains "old day block preserved" "2000-01-01"          "$(cat "$dir/SCRATCHPAD.md")"
cleanup "$dir"

# 18. F-001: project name substituted from pyproject.toml
echo ""
echo "-- placeholder-project-name-python (F-001) --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
assert_contains "project name from pyproject.toml" "test-project" "$(cat "$dir/CLAUDE.md")"
assert_not_contains "Project Name placeholder gone" "<Project Name>" "$(cat "$dir/CLAUDE.md")"
cleanup "$dir"

# 19. F-001: language/toolchain substituted for Python project
echo ""
echo "-- placeholder-lang-python (F-001) --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
assert_contains "Python lang detected" "Python + ruff/mypy" "$(cat "$dir/CLAUDE.md")"
assert_not_contains "lang placeholder gone" "<language and primary tools>" "$(cat "$dir/CLAUDE.md")"
cleanup "$dir"

# 20. F-001: language/toolchain substituted for TypeScript project
echo ""
echo "-- placeholder-lang-typescript (F-001) --"
dir=$(setup_fixture typescript-project)
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
assert_contains "TypeScript lang detected" "TypeScript/JS + eslint/tsc" "$(cat "$dir/CLAUDE.md")"
cleanup "$dir"

# 21. F-001: language/toolchain substituted for C++ project
echo ""
echo "-- placeholder-lang-cpp (F-001) --"
dir=$(setup_fixture cpp-project)
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
assert_contains "C/C++ lang detected" "C/C++ + clang-tidy" "$(cat "$dir/CLAUDE.md")"
cleanup "$dir"

# 22. F-001: description substituted from README.md
echo ""
echo "-- placeholder-description-readme (F-001) --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
assert_contains "description from README.md" "A test fixture for Payload Depot install tests." "$(cat "$dir/CLAUDE.md")"
assert_not_contains "description placeholder gone" "<what this project does>" "$(cat "$dir/CLAUDE.md")"
cleanup "$dir"

# 23. F-001: dry-run logs substitution plan, does not write CLAUDE.md
echo ""
echo "-- placeholder-dry-run (F-001) --"
dir=$(setup_fixture python-project)
output=$(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --dry-run --no-codebase-index 2>&1)
assert_contains "dry-run logs project name"   "test-project"   "$output"
assert_contains "dry-run logs lang tools"     "Python + ruff/mypy" "$output"
assert_eq "CLAUDE.md not written in dry-run" "missing" "$(test -f "$dir/CLAUDE.md" && echo exists || echo missing)"
cleanup "$dir"

# 24. F-001: project name falls back to dirname when no manifest present
echo ""
echo "-- placeholder-name-fallback (F-001) --"
dir=$(setup_fixture cpp-project)
dirname_expected=$(basename "$dir")
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
# C++ fixture has no package.json/pyproject.toml, so name = dirname
assert_contains "fallback name is dirname" "$dirname_expected" "$(cat "$dir/CLAUDE.md")"
cleanup "$dir"

# 25. F-002: list-targets shows claude-code with description
echo ""
echo "-- list-targets-shows-claude-code (F-002) --"
output=$("$PAYLOAD_DEPOT_DIR/payload-depot" list-targets 2>&1)
assert_contains "claude-code listed"          "claude-code"       "$output"
assert_contains "claude-code has description" "Default Payload Depot target" "$output"

# 26. F-002: list-targets omits stubs without adapter.sh
echo ""
echo "-- list-targets-omits-stubs (F-002) --"
assert_not_contains "openai not listed (no adapter.sh)" "openai"  "$output"
assert_not_contains "gemini not listed (no adapter.sh)" "gemini"  "$output"

# 27. F-003: update refreshes agents and skills
echo ""
echo "-- update-refreshes-agents-skills (F-003) --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
output=$(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" update 2>&1)
assert_contains "update agents line"  "Agents updated"  "$output"
assert_contains "update skills line"  "Skills updated"  "$output"
assert_dir_exists "agents dir still present" "$dir/.claude/agents"
cleanup "$dir"

# 28. F-003: update does NOT overwrite user config files
echo ""
echo "-- update-preserves-user-config (F-003) --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
echo "user-sentinel" > "$dir/CLAUDE.md"
echo "user-sentinel" > "$dir/CONVENTIONS.md"
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" update 2>&1) || true
assert_contains "CLAUDE.md preserved"      "user-sentinel" "$(cat "$dir/CLAUDE.md")"
assert_contains "CONVENTIONS.md preserved" "user-sentinel" "$(cat "$dir/CONVENTIONS.md")"
cleanup "$dir"

# 29. F-003: update prints skip messages for each config file
echo ""
echo "-- update-skip-messages (F-003) --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
output=$(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" update 2>&1)
assert_contains "CLAUDE.md skip shown"       "CLAUDE.md"       "$output"
assert_contains "CONVENTIONS.md skip shown"  "CONVENTIONS.md"  "$output"
assert_contains "settings.json skip shown"   "settings.json"   "$output"
cleanup "$dir"

# 30. F-003: update requires a .git directory
echo ""
echo "-- update-requires-git (F-003) --"
dir=$(mktemp -d)
exit_code=$(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" update 2>&1; echo $?)
assert_eq "update without git exits 2" "2" "$(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" update 2>/dev/null; echo $?)"
rm -rf "$dir"

# ── B-002: .gitignore upgrade path ────────────────────────────────────────────

# 31. update adds .payload-depot-verified to .gitignore when block exists but entry is missing
echo ""
echo "-- gitignore-upgrade-rig-verified (B-002) --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
# Simulate pre-F-007 state: remove .payload-depot-verified from .gitignore
sed -i '/.payload-depot-verified/d' "$dir/.gitignore"
assert_not_contains ".payload-depot-verified absent before fix" ".payload-depot-verified" "$(cat "$dir/.gitignore")"
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" update 2>&1) || true
assert_contains ".payload-depot-verified added by update" ".payload-depot-verified" "$(cat "$dir/.gitignore")"
cleanup "$dir"

# 32. install adds .payload-depot-verified to .gitignore when block exists but entry is missing
echo ""
echo "-- gitignore-install-rig-verified (B-002) --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
sed -i '/.payload-depot-verified/d' "$dir/.gitignore"
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
assert_contains ".payload-depot-verified re-added by install" ".payload-depot-verified" "$(cat "$dir/.gitignore")"
cleanup "$dir"

# ── F-007: health check (payload-depot-health-check.sh) ─────────────────────────────────

# 31. payload-depot-health-check.sh is installed into .claude/hooks/
echo ""
echo "-- health-check-installed (F-007) --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
assert_file_exists "payload-depot-health-check.sh installed" "$dir/.claude/hooks/payload-depot-health-check.sh"
assert_contains    "payload-depot-health-check.sh executable" "x" \
  "$(test -x "$dir/.claude/hooks/payload-depot-health-check.sh" && echo x || echo '')"
cleanup "$dir"

# 32. health check passes on a fresh install and writes .payload-depot-verified
echo ""
echo "-- health-check-passes-fresh (F-007) --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
rm -f "$dir/.payload-depot-verified"
hc_output=$(cd "$dir" && bash ".claude/hooks/payload-depot-health-check.sh" 2>&1)
assert_contains    "health check passes"      "0 failed"     "$hc_output"
assert_file_exists ".payload-depot-verified written"    "$dir/.payload-depot-verified"
assert_contains    ".payload-depot-verified has marker" "PAYLOAD_DEPOT_VERIFIED=true" "$(cat "$dir/.payload-depot-verified")"
cleanup "$dir"

# 33. health check is skipped on second session-start when .payload-depot-verified exists
echo ""
echo "-- health-check-skipped-when-verified (F-007) --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
# Ensure .payload-depot-verified present (write it manually)
printf "PAYLOAD_DEPOT_VERIFIED=true\nTIMESTAMP=test\nCHECKS=0 passed\n" > "$dir/.payload-depot-verified"
ss_output=$(cd "$dir" && bash ".claude/hooks/session-start.sh" 2>&1)
assert_not_contains "health check not re-run" "Running post-install health check" "$ss_output"
cleanup "$dir"

# 34. adapter_post_install clears .payload-depot-verified on update (forces re-check)
echo ""
echo "-- health-check-cleared-on-update (F-007) --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
printf "PAYLOAD_DEPOT_VERIFIED=true\nTIMESTAMP=test\nCHECKS=0 passed\n" > "$dir/.payload-depot-verified"
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" update 2>&1) || true
assert_not_file_exists ".payload-depot-verified cleared after update" "$dir/.payload-depot-verified"
cleanup "$dir"

# 35. session-start calls health check when .payload-depot-verified is absent
echo ""
echo "-- session-start-triggers-health-check (F-007) --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
rm -f "$dir/.payload-depot-verified"
ss_output=$(cd "$dir" && bash ".claude/hooks/session-start.sh" 2>&1)
assert_contains "session-start runs health check" "Running post-install health check" "$ss_output"
assert_file_exists ".payload-depot-verified written by session-start" "$dir/.payload-depot-verified"
cleanup "$dir"

# 36. PAYLOAD_DEPOT_HEALTH_CHECK_ACTIVE guard prevents recursion
echo ""
echo "-- health-check-no-recursion (F-007) --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
rm -f "$dir/.payload-depot-verified"
# Health check sets PAYLOAD_DEPOT_HEALTH_CHECK_ACTIVE=1 before calling session-start.sh;
# session-start.sh must NOT call the health check again.
hc_output=$(cd "$dir" && bash ".claude/hooks/payload-depot-health-check.sh" 2>&1)
health_check_count=$(echo "$hc_output" | grep -c "Running post-install health check" || true)
assert_eq "health check runs exactly once" "1" "$health_check_count"
cleanup "$dir"

# ── openspec-init subcommand ──────────────────────────────────────────────────
echo ""
echo "-- openspec-init --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" openspec-init) > /dev/null 2>&1
assert_dir_exists     "openspec-init creates specs dir"     "$dir/openspec/specs"
assert_dir_exists     "openspec-init creates changes dir"   "$dir/openspec/changes"
assert_dir_exists     "openspec-init creates archive dir"   "$dir/openspec/changes/archive"
assert_file_exists    "openspec-init creates config.yaml"   "$dir/openspec/config.yaml"
cleanup "$dir"

echo ""
echo "-- openspec-init idempotent --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index 2>&1) || true
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" openspec-init) > /dev/null 2>&1
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" openspec-init) > /dev/null 2>&1
assert_file_exists    "openspec-init idempotent"            "$dir/openspec/config.yaml"
cleanup "$dir"

echo ""
echo "-- install --openspec flag --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$PAYLOAD_DEPOT_DIR/payload-depot" install --no-codebase-index --openspec 2>&1) || true
assert_dir_exists     "--openspec flag creates tree"        "$dir/openspec/specs"
cleanup "$dir"

report
