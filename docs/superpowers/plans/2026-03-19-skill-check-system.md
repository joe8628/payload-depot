# Skill Check System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a skill registry, three-layer skill validator (`payload-depot-skill-check.sh`), and a Claude-side smoke test prompt so that skills are auto-discovered, validated on install, and functionally verifiable.

**Architecture:** `skills/registry.md` is the single source of truth — copied to `.claude/skills/registry.md` on install, `@imported` in `CLAUDE.md` for auto-discovery, and read by `payload-depot-skill-check.sh` for drift detection. The validator runs as part of the health check; the smoke test is a standalone prompt run inside Claude Code.

**Tech Stack:** Bash, Markdown, bats-compatible bash test runner (`tests/lib.sh`)

---

## File Map

| Action | File | Responsibility |
|--------|------|---------------|
| Create | `skills/registry.md` | Source registry — all 10 skills with triggers and smoke test prompts |
| Create | `targets/claude-code/payload-depot-skill-check.sh` | Three-layer validator: presence, structure, readability |
| Create | `skill-smoke-test.md` | Claude prompt for functional skill verification |
| Create | `tests/test_skill_check.sh` | Integration tests for payload-depot-skill-check.sh |
| Modify | `targets/claude-code/CLAUDE.md.template` | Add `@.claude/skills/registry.md` import + Skills section |
| Modify | `targets/claude-code/adapter.sh` | Install payload-depot-skill-check.sh in `adapter_post_install` |
| Modify | `targets/claude-code/payload-depot-health-check.sh` | Replace skill count check with call to payload-depot-skill-check.sh |
| Update | `.claude/skills/registry.md` | Live copy of registry for the Payload Depot repo itself |
| Update | `.claude/hooks/payload-depot-health-check.sh` | Live copy (mirrors targets/) |
| Update | `CLAUDE.md` | Live copy (add @import + Skills section) |

**No changes needed to `payload-depot`** — it already copies `skills/*.md` → `.claude/skills/` via the glob, so `registry.md` is picked up automatically.

---

## Task 1: Create `skills/registry.md`

**Files:**
- Create: `skills/registry.md`

- [ ] **Step 1: Write the registry file**

```markdown
# Skills Registry

<!-- @imported in CLAUDE.md for auto-discovery -->
<!-- payload-depot-skill-check.sh reads this to detect unregistered or missing skills -->
<!-- Format: one ## <name> block per skill. Name must match the .md filename exactly. -->

## tdd
**File:** tdd.md
**Triggers:** "use TDD", "write tests first", "failing test first", before implementing any feature or bugfix
**Description:** Guide test-driven development: write failing test, implement minimum code, refactor
**Smoke test:** `Use TDD to write a function that returns the sum of two numbers`

## linting
**File:** linting.md
**Triggers:** "lint", "run linter", "check style", before committing, after writing code
**Description:** Run and interpret linting for the detected project language
**Smoke test:** `Run linting on the current project and report any violations`

## type-checking
**File:** type-checking.md
**Triggers:** "type check", "run mypy", "run tsc", "check types", before committing
**Description:** Run static type checker for the detected project language
**Smoke test:** `Run type checking on the current project and report any errors`

## dependency-audit
**File:** dependency-audit.md
**Triggers:** "audit dependencies", "check for vulnerabilities", "security audit", before release
**Description:** Audit project dependencies for known security vulnerabilities
**Smoke test:** `Run a dependency audit on the current project`

## adr
**File:** adr.md
**Triggers:** "record decision", "write an ADR", "architecture decision", "document this choice"
**Description:** Write an Architecture Decision Record for a significant design choice
**Smoke test:** `Write an ADR for the decision to use Bash as the primary scripting language`

## readme-gen
**File:** readme-gen.md
**Triggers:** "generate README", "write README", "update README", "document the project"
**Description:** Generate or update a project README from existing code and docs
**Smoke test:** `Generate a README for the current project`

## openapi-lint
**File:** openapi-lint.md
**Triggers:** "lint OpenAPI", "validate OpenAPI spec", "check API spec", "openapi-lint"
**Description:** Validate and lint an OpenAPI specification file
**Smoke test:** `Run openapi-lint on any OpenAPI spec file in the current project`

## changelog
**File:** changelog.md
**Triggers:** "update changelog", "write changelog entry", "CHANGELOG", after completing a release
**Description:** Write or update a CHANGELOG following Keep a Changelog format
**Smoke test:** `Add a changelog entry for a hypothetical v1.1.0 release`

## commit-msg
**File:** commit-msg.md
**Triggers:** "write commit message", "commit message", "conventional commit", before committing
**Description:** Write a Conventional Commits-compliant commit message for staged changes
**Smoke test:** `Write a commit message for adding a new skill check system`

## env-setup
**File:** env-setup.md
**Triggers:** "set up environment", "env setup", "onboarding", "install dependencies", "first time setup"
**Description:** Guide environment setup for the detected project language and toolchain
**Smoke test:** `Run env setup for the current project`
```

Save to `skills/registry.md`.

- [ ] **Step 2: Verify the file**

```bash
grep "^## " skills/registry.md
```

Expected output — 10 lines, one per skill:
```
## tdd
## linting
## type-checking
## dependency-audit
## adr
## readme-gen
## openapi-lint
## changelog
## commit-msg
## env-setup
```

- [ ] **Step 3: Commit**

```bash
git add skills/registry.md
git commit -m "feat: add skills/registry.md — source registry for skill check system"
```

---

## Task 2: Write failing tests for `payload-depot-skill-check.sh`

**Files:**
- Create: `tests/test_skill_check.sh`

- [ ] **Step 1: Create the test file**

```bash
#!/usr/bin/env bash
set -uo pipefail

PAYLOAD_DEPOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PAYLOAD_DEPOT_DIR/tests/lib.sh"

SKILL_CHECK="$PAYLOAD_DEPOT_DIR/targets/claude-code/payload-depot-skill-check.sh"

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
output=$(run_check "$dir" 2>&1) || exit_code=$?
exit_code=${exit_code:-0}
assert_exit_code "no registry exits 1"        "1" "$exit_code"
assert_contains  "no registry prints error"   "registry.md not found" "$output"
rm -rf "$dir"

# ── 2. all-valid ──────────────────────────────────────────────────────────────
echo ""
echo "-- all-valid --"
dir=$(setup_skill_env)
init_registry "$dir"
make_valid_skill "$dir" "tdd"
make_registry_entry "$dir" "tdd"
exit_code=0; run_check "$dir" > /dev/null 2>&1 || exit_code=$?
assert_exit_code "all valid exits 0"  "0" "$exit_code"
rm -rf "$dir"

# ── 3. unregistered-skill (warn only, exit 0) ─────────────────────────────────
echo ""
echo "-- unregistered-skill --"
dir=$(setup_skill_env)
init_registry "$dir"
make_valid_skill "$dir" "tdd"
# tdd.md exists but registry is empty
exit_code=0; output=$(run_check "$dir" 2>&1) || exit_code=$?
assert_exit_code "unregistered exits 0 (warn)"  "0" "$exit_code"
assert_contains  "unregistered prints warning"   "not in registry" "$output"
rm -rf "$dir"

# ── 4. missing-skill (registered but file absent) ────────────────────────────
echo ""
echo "-- missing-skill --"
dir=$(setup_skill_env)
init_registry "$dir"
make_registry_entry "$dir" "tdd"
# tdd.md NOT created
exit_code=0; output=$(run_check "$dir") || exit_code=$?
assert_exit_code "missing skill exits 1"    "1" "$exit_code"
assert_contains  "missing skill prints fail" "registered but not found" "$output"
rm -rf "$dir"

# ── 5. missing-frontmatter ────────────────────────────────────────────────────
echo ""
echo "-- missing-frontmatter --"
dir=$(setup_skill_env)
init_registry "$dir"
make_registry_entry "$dir" "tdd"
echo "# tdd\n\n## Purpose\np\n## Trigger\nt\n## Process\np" > "$dir/.claude/skills/tdd.md"
exit_code=0; output=$(run_check "$dir") || exit_code=$?
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
exit_code=0; output=$(run_check "$dir") || exit_code=$?
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
exit_code=0; output=$(run_check "$dir") || exit_code=$?
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
exit_code=0; output=$(run_check "$dir") || exit_code=$?
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
exit_code=0; output=$(run_check "$dir") || exit_code=$?
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
# registry.md has no skill structure — it should NOT be validated as a skill
exit_code=0; output=$(run_check "$dir") || exit_code=$?
assert_exit_code "registry excluded exits 0" "0" "$exit_code"
assert_not_contains "registry not validated" "registry.md missing" "$output"
rm -rf "$dir"

report
```

Save to `tests/test_skill_check.sh`.

- [ ] **Step 2: Make it executable and run it — expect failures**

```bash
chmod +x tests/test_skill_check.sh
bash tests/test_skill_check.sh 2>&1 | tail -20
```

Expected: all tests fail (script doesn't exist yet).

---

## Task 3: Create `targets/claude-code/payload-depot-skill-check.sh`

**Files:**
- Create: `targets/claude-code/payload-depot-skill-check.sh`

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
# payload-depot-skill-check.sh — Three-layer skill validation
# Installed to .claude/hooks/payload-depot-skill-check.sh by adapter_post_install.
# Run from the project root. Called by payload-depot-health-check.sh.
# Run manually: bash .claude/hooks/payload-depot-skill-check.sh
set -uo pipefail

PASS=0
FAIL=0
WARN=0

ok()   { echo "  ✓ $1"; PASS=$((PASS+1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL+1)); }
warn() { echo "  ~ $1"; WARN=$((WARN+1)); }

SKILLS_DIR=".claude/skills"
REGISTRY="$SKILLS_DIR/registry.md"

echo "[rig:skill-check] Checking skills in $SKILLS_DIR..."
echo ""

# ── Layer 1: Presence check ───────────────────────────────────────────────────
echo "-- presence --"

if [[ ! -f "$REGISTRY" ]]; then
  fail "registry.md not found at $REGISTRY"
  echo ""
  echo "[rig:skill-check] $PASS passed, $WARN warnings, $FAIL failed"
  exit 1
fi

# Extract registered skill names (## <name> headings)
registered=()
while IFS= read -r line; do
  name="${line#\#\# }"
  registered+=("$name")
done < <(grep "^## " "$REGISTRY")

# Extract installed skill filenames (exclude registry.md itself)
installed=()
while IFS= read -r f; do
  base="$(basename "$f" .md)"
  [[ "$base" == "registry" ]] && continue
  installed+=("$base")
done < <(find "$SKILLS_DIR" -maxdepth 1 -name "*.md" 2>/dev/null | sort)

# Installed but not registered → warning
for skill in "${installed[@]+"${installed[@]}"}"; do
  found=false
  for reg in "${registered[@]+"${registered[@]}"}"; do
    [[ "$reg" == "$skill" ]] && found=true && break
  done
  if $found; then
    ok "$skill registered"
  else
    warn "$skill not in registry — add it to $REGISTRY"
  fi
done

# Registered but missing from disk → fail
for skill in "${registered[@]+"${registered[@]}"}"; do
  if [[ ! -f "$SKILLS_DIR/$skill.md" ]]; then
    fail "$skill.md registered but not found in $SKILLS_DIR"
  fi
done

# ── Layer 2: Structural check ─────────────────────────────────────────────────
echo ""
echo "-- structure --"

for skill in "${registered[@]+"${registered[@]}"}"; do
  file="$SKILLS_DIR/$skill.md"
  [[ -f "$file" ]] || continue

  if [[ ! -s "$file" ]]; then
    fail "$skill.md is empty"
    continue
  fi

  if ! head -1 "$file" | grep -qF "---"; then
    fail "$skill.md missing frontmatter block"
    continue
  fi

  local_fail=false

  if ! grep -qF "version:" "$file"; then
    fail "$skill.md frontmatter missing 'version' field"
    local_fail=true
  fi

  if ! grep -qF "updated:" "$file"; then
    fail "$skill.md frontmatter missing 'updated' field"
    local_fail=true
  fi

  for section in "## Purpose" "## Trigger" "## Process"; do
    if ! grep -qF "$section" "$file"; then
      fail "$skill.md missing '$section' section"
      local_fail=true
    fi
  done

  $local_fail || ok "$skill.md valid"
done

# ── Layer 3: Readability check ────────────────────────────────────────────────
echo ""
echo "-- readability --"

for skill in "${registered[@]+"${registered[@]}"}"; do
  file="$SKILLS_DIR/$skill.md"
  [[ -f "$file" ]] || continue

  if [[ ! -s "$file" ]]; then
    fail "$skill.md is empty"
    continue
  fi

  if command -v file &>/dev/null; then
    if file "$file" | grep -qE "(UTF-8|ASCII|text)"; then
      ok "$skill.md readable"
    else
      fail "$skill.md is not valid UTF-8 text"
    fi
  else
    ok "$skill.md readable (file command unavailable, skipped encoding check)"
  fi
done

# ── Result ─────────────────────────────────────────────────────────────────────
echo ""
echo "[rig:skill-check] $PASS passed, $WARN warnings, $FAIL failed"

if [[ $FAIL -gt 0 ]]; then
  echo "[rig:skill-check] ✗ Fix failures then re-run: bash .claude/hooks/payload-depot-skill-check.sh"
  exit 1
fi

echo "[rig:skill-check] ✓ All checks passed"
```

Save to `targets/claude-code/payload-depot-skill-check.sh`.

- [ ] **Step 2: Make executable**

```bash
chmod +x targets/claude-code/payload-depot-skill-check.sh
```

- [ ] **Step 3: Run the tests — expect all to pass**

```bash
bash tests/test_skill_check.sh
```

Expected: `Results: 10 passed, 0 failed`

- [ ] **Step 4: Commit**

```bash
git add targets/claude-code/payload-depot-skill-check.sh tests/test_skill_check.sh
git commit -m "feat: add payload-depot-skill-check.sh and tests (three-layer skill validation)"
```

---

## Task 4: Exclude `registry.md` from `payload-depot` skill count

**Files:**
- Modify: `payload-depot`

`payload-depot install` and `payload-depot update` count skills with `find "$PAYLOAD_DEPOT_DIR/skills" -name "*.md" | wc -l`. After adding `registry.md` to `skills/`, this would report 11 skills instead of 10. Exclude it.

- [ ] **Step 1: Read the current skill-count lines in `payload-depot`**

There are two places — `cmd_install` (around line 325) and `cmd_update` (around line 205):

```bash
skill_count=$(find "$PAYLOAD_DEPOT_DIR/skills" -name "*.md" | wc -l | tr -d ' ')
```

And the copy line:
```bash
cp "$PAYLOAD_DEPOT_DIR/skills/"*.md "$SKILL_INSTALL_PATH/"
```

The copy line correctly copies ALL `.md` files including `registry.md` — that's correct behaviour. Only the count needs fixing.

- [ ] **Step 2: Update both count lines** (in both `cmd_install` and `cmd_update`)

Replace:
```bash
skill_count=$(find "$PAYLOAD_DEPOT_DIR/skills" -name "*.md" | wc -l | tr -d ' ')
```

With:
```bash
skill_count=$(find "$PAYLOAD_DEPOT_DIR/skills" -name "*.md" ! -name "registry.md" | wc -l | tr -d ' ')
```

Also update `cmd_list` to skip registry.md:
```bash
cmd_list() {
  echo "Agents:"
  for f in "$PAYLOAD_DEPOT_DIR/agents/"*.md; do
    [[ -f "$f" ]] && echo "  $(basename "$f" .md)"
  done
  echo ""
  echo "Skills:"
  for f in "$PAYLOAD_DEPOT_DIR/skills/"*.md; do
    local base
    base="$(basename "$f" .md)"
    [[ "$base" == "registry" ]] && continue
    [[ -f "$f" ]] && echo "  $base"
  done
}
```

- [ ] **Step 3: Verify**

```bash
bash payload-depot list | grep -v "registry"
bash payload-depot list | grep "registry" && echo "FAIL: registry in list" || echo "OK: registry excluded"
```

Expected second command prints `OK: registry excluded`.

- [ ] **Step 4: Run existing tests**

```bash
bash tests/test_install.sh 2>&1 | tail -5
```

Expected: `Results: 81 passed, 0 failed`

- [ ] **Step 5: Commit**

```bash
git add payload-depot
git commit -m "fix: exclude registry.md from payload-depot skill count and list output"
```

---

## Task 6: Update `targets/claude-code/adapter.sh`

**Files:**
- Modify: `targets/claude-code/adapter.sh`

- [ ] **Step 1: Read the current file**

Read `targets/claude-code/adapter.sh` and find `adapter_post_install`.

- [ ] **Step 2: Add payload-depot-skill-check.sh installation**

Current `adapter_post_install`:
```bash
adapter_post_install() {
  cp "$PAYLOAD_DEPOT_DIR/targets/claude-code/session-start.sh"    ".claude/hooks/session-start.sh"
  chmod +x ".claude/hooks/session-start.sh"
  cp "$PAYLOAD_DEPOT_DIR/targets/claude-code/session-end.sh"      ".claude/hooks/session-end.sh"
  chmod +x ".claude/hooks/session-end.sh"
  cp "$PAYLOAD_DEPOT_DIR/targets/claude-code/payload-depot-health-check.sh" ".claude/hooks/payload-depot-health-check.sh"
  chmod +x ".claude/hooks/payload-depot-health-check.sh"
  # Clear the verified marker so the health check runs on the next session start
  rm -f ".payload-depot-verified"
}
```

Add after the payload-depot-health-check.sh lines:
```bash
  cp "$PAYLOAD_DEPOT_DIR/targets/claude-code/payload-depot-skill-check.sh"  ".claude/hooks/payload-depot-skill-check.sh"
  chmod +x ".claude/hooks/payload-depot-skill-check.sh"
```

- [ ] **Step 3: Verify by doing a test install**

```bash
tmp=$(mktemp -d) && git -C "$tmp" init -q
(cd "$tmp" && bash "$PWD/payload-depot" install --no-codebase-index 2>&1) || true
ls "$tmp/.claude/hooks/"
```

Expected output includes `payload-depot-skill-check.sh`.

- [ ] **Step 4: Run existing install tests to ensure no regression**

```bash
bash tests/test_install.sh 2>&1 | tail -5
```

Expected: `Results: 81 passed, 0 failed`

- [ ] **Step 5: Commit**

```bash
git add targets/claude-code/adapter.sh
git commit -m "feat: install payload-depot-skill-check.sh via adapter_post_install"
```

---

## Task 7: Update `targets/claude-code/payload-depot-health-check.sh`

**Files:**
- Modify: `targets/claude-code/payload-depot-health-check.sh`

- [ ] **Step 1: Read the current skill count block**

In `targets/claude-code/payload-depot-health-check.sh`, find this block (around line 103–117):

```bash
# ── Agent and skill counts ─────────────────────────────────────────────────────
echo ""
echo "-- agents / skills --"
agent_count=$(find .claude/agents -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
skill_count=$(find .claude/skills -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$agent_count" -ge 9 ]]; then
  ok "agents installed ($agent_count)"
else
  fail "agents: expected >=9, got $agent_count"
fi
if [[ "$skill_count" -ge 10 ]]; then
  ok "skills installed ($skill_count)"
else
  fail "skills: expected >=10, got $skill_count"
fi
```

- [ ] **Step 2: Replace the skill count block**

Replace the full block with:

```bash
# ── Agent count ────────────────────────────────────────────────────────────────
echo ""
echo "-- agents / skills --"
agent_count=$(find .claude/agents -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$agent_count" -ge 9 ]]; then
  ok "agents installed ($agent_count)"
else
  fail "agents: expected >=9, got $agent_count"
fi

# ── Skill check (delegates to payload-depot-skill-check.sh) ──────────────────────────────
if bash ".claude/hooks/payload-depot-skill-check.sh" > /dev/null 2>&1; then
  ok "skills valid (payload-depot-skill-check passed)"
else
  fail "skills: payload-depot-skill-check.sh failed — run: bash .claude/hooks/payload-depot-skill-check.sh"
fi
```

- [ ] **Step 3: Also add `payload-depot-skill-check.sh` to the file existence checks**

In the `-- files --` section (around line 68), add after `payload-depot-health-check.sh`:

```bash
check_file "payload-depot-skill-check.sh"          ".claude/hooks/payload-depot-skill-check.sh"
check_file "skills registry"             ".claude/skills/registry.md"
```

- [ ] **Step 4: Also add `payload-depot-skill-check.sh` to the permissions checks**

In the `-- permissions --` section, add:

```bash
check_exec "payload-depot-skill-check.sh executable" ".claude/hooks/payload-depot-skill-check.sh"
```

- [ ] **Step 5: Run existing install tests**

```bash
bash tests/test_install.sh 2>&1 | tail -5
```

Expected: `Results: 81 passed, 0 failed`

- [ ] **Step 6: Commit**

```bash
git add targets/claude-code/payload-depot-health-check.sh
git commit -m "feat: health check delegates skill validation to payload-depot-skill-check.sh"
```

---

## Task 8: Update `targets/claude-code/CLAUDE.md.template`

**Files:**
- Modify: `targets/claude-code/CLAUDE.md.template`

- [ ] **Step 1: Add `@.claude/skills/registry.md` import**

Current top of file:
```
@.codebase-context/repo_map.md
@HANDOFF.md
@CONVENTIONS.md
@AGENTS.md
```

Add the registry import after `@AGENTS.md`:
```
@.codebase-context/repo_map.md
@HANDOFF.md
@CONVENTIONS.md
@AGENTS.md
@.claude/skills/registry.md
```

- [ ] **Step 2: Add `## Skills` section**

After the `## Agent Registry` section, add:

```markdown
## Skills

Project skills live in `.claude/skills/`. The registry above (`@.claude/skills/registry.md`)
lists all available skills and their triggers — when a conversation matches a trigger, invoke
the skill with the `Skill` tool before responding.

To add a skill:
1. Write a `.md` file in `.claude/skills/` with frontmatter (`version`, `updated`) and sections (`## Purpose`, `## Trigger`, `## Process`)
2. Run `bash .claude/hooks/payload-depot-skill-check.sh` — it detects unregistered skills
3. Add an entry to `.claude/skills/registry.md` following the existing format
```

- [ ] **Step 3: Run the install tests**

```bash
bash tests/test_install.sh 2>&1 | tail -5
```

Expected: `Results: 81 passed, 0 failed`

- [ ] **Step 4: Commit**

```bash
git add targets/claude-code/CLAUDE.md.template
git commit -m "feat: add registry @import and Skills section to CLAUDE.md.template"
```

---

## Task 9: Create `skill-smoke-test.md`

**Files:**
- Create: `skill-smoke-test.md`

- [ ] **Step 1: Write the prompt file**

```markdown
# Skill Smoke Test

Run this prompt inside Claude Code to functionally verify all registered skills.

---

## Instructions for Claude

You are about to run a smoke test for all skills registered in `.claude/skills/registry.md`.

**Steps:**

1. Read `.claude/skills/registry.md` and extract:
   - Each skill name (lines starting with `## `)
   - Its smoke test prompt (lines starting with `**Smoke test:**`)

2. For each registered skill, in order:
   a. Invoke it using the `Skill` tool: `Skill(skill="<name>")`
   b. If the Skill tool returns content → mark as **Loaded: ✓**
   b. If the Skill tool returns an error or empty response → mark as **Loaded: ✗**
   c. Execute the smoke test prompt for that skill (abbreviated — just enough to confirm the skill runs without tool errors)
   d. If execution completes without tool errors → mark as **Executed: ✓**
   d. If a tool call fails → mark as **Executed: ✗** and capture the error

3. Print a summary table:

```
| Skill            | Loaded | Executed | Status |
|------------------|--------|----------|--------|
| tdd              | ✓      | ✓        | PASS   |
| linting          | ✓      | ✓        | PASS   |
| type-checking    | ✗      | —        | FAIL   |
```

4. For each FAIL row, print the error message from the Skill tool or execution.

5. Print final counts: `X passed, Y failed`

**Notes:**
- Run smoke tests in minimal mode — the goal is load and invocation verification, not full output quality
- If a skill's smoke test would modify files, describe what it *would* do instead of doing it
- This prompt is safe to run at any time; it does not commit, push, or write files
```

Save to `skill-smoke-test.md`.

- [ ] **Step 2: Commit**

```bash
git add skill-smoke-test.md
git commit -m "feat: add skill-smoke-test.md — Claude-side functional skill verification prompt"
```

---

## Task 10: Update live copies and write handoff

**Files:**
- Update: `.claude/skills/registry.md`
- Update: `.claude/hooks/payload-depot-health-check.sh`
- Update: `.claude/hooks/payload-depot-skill-check.sh` (new)
- Update: `CLAUDE.md`

- [ ] **Step 1: Preflight — verify existing skill files have required structure**

Run this before copying anything. If any skill fails, fix it first.

```bash
for f in skills/*.md; do
  [[ "$(basename "$f")" == "registry.md" ]] && continue
  name="$(basename "$f" .md)"
  missing=""
  head -1 "$f" | grep -qF "---"        || missing="$missing frontmatter"
  grep -qF "version:" "$f"             || missing="$missing version"
  grep -qF "updated:" "$f"             || missing="$missing updated"
  grep -qF "## Purpose" "$f"           || missing="$missing Purpose"
  grep -qF "## Trigger" "$f"           || missing="$missing Trigger"
  grep -qF "## Process" "$f"           || missing="$missing Process"
  [[ -z "$missing" ]] && echo "  ✓ $name" || echo "  ✗ $name — missing:$missing"
done
```

Expected: all 10 skills print `✓`. If any print `✗`, fix the skill file before continuing.

- [ ] **Step 2: Copy registry to live location**

```bash
cp skills/registry.md .claude/skills/registry.md
```

- [ ] **Step 2: Copy updated hook files to live location**

```bash
cp targets/claude-code/payload-depot-health-check.sh .claude/hooks/payload-depot-health-check.sh
cp targets/claude-code/payload-depot-skill-check.sh  .claude/hooks/payload-depot-skill-check.sh
chmod +x .claude/hooks/payload-depot-skill-check.sh
```

- [ ] **Step 3: Update `CLAUDE.md` — add registry import**

In `CLAUDE.md`, find the `@AGENTS.md` line and add `@.claude/skills/registry.md` after it.

- [ ] **Step 4: Update `CLAUDE.md` — add Skills section**

After the `## Agent Registry` section, add the same Skills section as in the template:

```markdown
## Skills

Project skills live in `.claude/skills/`. The registry above (`@.claude/skills/registry.md`)
lists all available skills and their triggers — when a conversation matches a trigger, invoke
the skill with the `Skill` tool before responding.

To add a skill:
1. Write a `.md` file in `.claude/skills/` following the structure in `SPEC.md § 6.2`
2. Run `bash .claude/hooks/payload-depot-skill-check.sh` — it detects unregistered skills
3. Add an entry to `.claude/skills/registry.md` following the existing format
```

- [ ] **Step 5: Run the full skill check against the live Payload Depot install**

```bash
bash .claude/hooks/payload-depot-skill-check.sh
```

Expected: all 10 skills pass all three layers.

- [ ] **Step 6: Run all tests**

```bash
bash tests/test_install.sh && bash tests/test_skill_check.sh
```

Expected: `Results: 81 passed, 0 failed` + `Results: 10 passed, 0 failed`

- [ ] **Step 7: Commit live copies**

```bash
git add .claude/skills/registry.md .claude/hooks/payload-depot-health-check.sh \
        .claude/hooks/payload-depot-skill-check.sh CLAUDE.md
git commit -m "chore: update live copies — registry, skill-check, health-check, CLAUDE.md"
```

- [ ] **Step 8: Write handoff**

Append a completed block to `HANDOFF.md`, record decisions in `DECISIONS.md`, then:

```bash
git add HANDOFF.md DECISIONS.md
git commit -m "handoff: code-writer completed skill check system"
git push
```
