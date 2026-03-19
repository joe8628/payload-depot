#!/usr/bin/env bash
set -uo pipefail

RIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$RIG_DIR/tests/lib.sh"

SKILL_CHECK="$RIG_DIR/targets/claude-code/rig-skill-check.sh"

# ── Helpers ───────────────────────────────────────────────────────────────────

setup_skill_env() {
  local tmp
  tmp=$(mktemp -d)
  mkdir -p "$tmp/.claude/skills"
  echo "$tmp"
}

make_valid_skill() {
  local dir="$1" name="$2"
  cat > "$dir/.claude/skills/$name.md" <<'SKILL'
---
version: 1.0.0
updated: 2026-03-01
changelog:
  - 1.0.0: initial version
---

# test-skill

## Purpose
Test purpose.

## Trigger
Test trigger.

## Process
Test process.
SKILL
}

make_registry_entry() {
  local dir="$1" name="$2"
  cat >> "$dir/.claude/skills/registry.md" <<REG

## $name
**File:** $name.md
**Triggers:** test trigger
**Description:** Test skill
**Smoke test:** \`Test the skill\`
REG
}

init_registry() {
  local dir="$1"
  echo "# Skills Registry" > "$dir/.claude/skills/registry.md"
}

run_check() {
  local dir="$1"
  (cd "$dir" && bash "$SKILL_CHECK" 2>&1)
}

echo "=== Skill Check Tests ==="

# ── 1. no-registry ────────────────────────────────────────────────────────────
echo ""
echo "-- no-registry --"
dir=$(setup_skill_env)
exit_code=0; output=$(run_check "$dir" 2>&1) || exit_code=$?
assert_exit_code "no registry exits 1"       "1" "$exit_code"
assert_contains  "no registry prints error"  "registry.md not found" "$output"
rm -rf "$dir"

# ── 2. all-valid ──────────────────────────────────────────────────────────────
echo ""
echo "-- all-valid --"
dir=$(setup_skill_env)
init_registry "$dir"
make_valid_skill "$dir" "tdd"
make_registry_entry "$dir" "tdd"
exit_code=0; run_check "$dir" > /dev/null 2>&1 || exit_code=$?
assert_exit_code "all valid exits 0" "0" "$exit_code"
rm -rf "$dir"

# ── 3. unregistered-skill (warn only, exit 0) ─────────────────────────────────
echo ""
echo "-- unregistered-skill --"
dir=$(setup_skill_env)
init_registry "$dir"
make_valid_skill "$dir" "tdd"
# tdd.md exists but registry is empty — should warn, not fail
exit_code=0; output=$(run_check "$dir" 2>&1) || exit_code=$?
assert_exit_code "unregistered exits 0 (warn)" "0" "$exit_code"
assert_contains  "unregistered prints warning"  "not in registry" "$output"
rm -rf "$dir"

# ── 4. missing-skill (registered but file absent) ────────────────────────────
echo ""
echo "-- missing-skill --"
dir=$(setup_skill_env)
init_registry "$dir"
make_registry_entry "$dir" "tdd"
# tdd.md NOT created
exit_code=0; output=$(run_check "$dir" 2>&1) || exit_code=$?
assert_exit_code "missing skill exits 1"     "1" "$exit_code"
assert_contains  "missing skill prints fail" "registered but not found" "$output"
rm -rf "$dir"

# ── 5. missing-frontmatter ────────────────────────────────────────────────────
echo ""
echo "-- missing-frontmatter --"
dir=$(setup_skill_env)
init_registry "$dir"
make_registry_entry "$dir" "tdd"
printf '# tdd\n\n## Purpose\np\n## Trigger\nt\n## Process\np\n' \
  > "$dir/.claude/skills/tdd.md"
exit_code=0; output=$(run_check "$dir" 2>&1) || exit_code=$?
assert_exit_code "missing frontmatter exits 1"    "1" "$exit_code"
assert_contains  "missing frontmatter prints fail" "missing frontmatter" "$output"
rm -rf "$dir"

# ── 6. missing-version ────────────────────────────────────────────────────────
echo ""
echo "-- missing-version --"
dir=$(setup_skill_env)
init_registry "$dir"
make_registry_entry "$dir" "tdd"
cat > "$dir/.claude/skills/tdd.md" <<'SKILL'
---
updated: 2026-03-01
---

# tdd

## Purpose
p

## Trigger
t

## Process
p
SKILL
exit_code=0; output=$(run_check "$dir" 2>&1) || exit_code=$?
assert_exit_code "missing version exits 1"    "1" "$exit_code"
assert_contains  "missing version prints fail" "missing 'version'" "$output"
rm -rf "$dir"

# ── 7. missing-trigger-section ────────────────────────────────────────────────
echo ""
echo "-- missing-trigger-section --"
dir=$(setup_skill_env)
init_registry "$dir"
make_registry_entry "$dir" "tdd"
cat > "$dir/.claude/skills/tdd.md" <<'SKILL'
---
version: 1.0.0
updated: 2026-03-01
---

# tdd

## Purpose
p

## Process
p
SKILL
exit_code=0; output=$(run_check "$dir" 2>&1) || exit_code=$?
assert_exit_code "missing Trigger section exits 1"    "1" "$exit_code"
assert_contains  "missing Trigger section prints fail" "missing '## Trigger'" "$output"
rm -rf "$dir"

# ── 8. missing-process-section ────────────────────────────────────────────────
echo ""
echo "-- missing-process-section --"
dir=$(setup_skill_env)
init_registry "$dir"
make_registry_entry "$dir" "tdd"
cat > "$dir/.claude/skills/tdd.md" <<'SKILL'
---
version: 1.0.0
updated: 2026-03-01
---

# tdd

## Purpose
p

## Trigger
t
SKILL
exit_code=0; output=$(run_check "$dir" 2>&1) || exit_code=$?
assert_exit_code "missing Process section exits 1"    "1" "$exit_code"
assert_contains  "missing Process section prints fail" "missing '## Process'" "$output"
rm -rf "$dir"

# ── 9. empty-skill-file ───────────────────────────────────────────────────────
echo ""
echo "-- empty-skill-file --"
dir=$(setup_skill_env)
init_registry "$dir"
make_registry_entry "$dir" "tdd"
touch "$dir/.claude/skills/tdd.md"
exit_code=0; output=$(run_check "$dir" 2>&1) || exit_code=$?
assert_exit_code "empty skill exits 1"    "1" "$exit_code"
assert_contains  "empty skill prints fail" "is empty" "$output"
rm -rf "$dir"

# ── 10. registry-excluded ─────────────────────────────────────────────────────
echo ""
echo "-- registry-excluded --"
dir=$(setup_skill_env)
init_registry "$dir"
make_valid_skill "$dir" "tdd"
make_registry_entry "$dir" "tdd"
# registry.md has no skill structure — must NOT be validated as a skill
exit_code=0; output=$(run_check "$dir" 2>&1) || exit_code=$?
assert_exit_code    "registry excluded exits 0"   "0" "$exit_code"
assert_not_contains "registry not validated"      "registry.md missing" "$output"
rm -rf "$dir"

report
