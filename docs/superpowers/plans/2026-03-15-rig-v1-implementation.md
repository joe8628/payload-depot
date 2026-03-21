# Payload Depot v1.0 Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a working `rig install` CLI that bootstraps any project with Claude Code agents, skills, session templates, config files, and a codebase context index in a single command.

**Architecture:** Single bash entrypoint (`rig`) sources a target adapter (`targets/claude-code/adapter.sh`) that exports install paths and config mappings. The core script drives the install sequence using those variables — no target-specific logic lives in `rig` itself. Context between agents is persisted via `HANDOFF.md` and `DECISIONS.md` committed to git; codebase knowledge is persisted via the codebase-context MCP (git submodule at `codebase-context/`).

**Tech Stack:** bash 5+, git, standard Unix utilities (`cp`, `chmod`, `mkdir`, `cat`). No runtime dependencies.

**Spec:** `SPEC.md` at repo root.

---

## Chunk 1: Foundation (Phases 1–3)

### Task 1: Initialize repo structure + codebase-context submodule

**Files:**
- Create: `rig` (empty stub)
- Create: `.gitignore`
- Create: `README.md`
- Create: `CHANGELOG.md`
- Create: `targets/claude-code/README.md`
- Create: `targets/openai/README.md`
- Create: `targets/gemini/README.md`
- Submodule: `codebase-context/` from `https://github.com/joe8628/codebase-context.git`

- [ ] **Step 1: Create directory structure**

```bash
cd /path/to/rig
mkdir -p agents skills session hooks tests/fixtures/{python-project,typescript-project,cpp-project}
mkdir -p targets/{claude-code,openai,gemini}
mkdir -p docs/superpowers/{specs,plans}
```

- [ ] **Step 2: Add codebase-context as git submodule**

```bash
git submodule add https://github.com/joe8628/codebase-context.git codebase-context
git submodule update --init --recursive
```

- [ ] **Step 3: Write `.gitignore`**

```
# Payload Depot session files — ephemeral, not committed
SCRATCHPAD.md

# Codebase context — local vector DB, not committed
.codebase-context/chroma/

# OS
.DS_Store
```

- [ ] **Step 4: Write `README.md` stub**

```markdown
# Payload Depot

CLI scaffold that bootstraps any project with Claude Code agents, skills, session
templates, and a codebase context index.

## Quick start

```bash
./rig install
```

See `SPEC.md` for full documentation.
```

- [ ] **Step 5: Write `CHANGELOG.md` stub**

```markdown
# Changelog

All notable changes to Payload Depot will be documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

## [Unreleased]
```

- [ ] **Step 6: Write target README stubs**

`targets/claude-code/README.md`:
```markdown
# Claude Code Target

Default Payload Depot target. Installs agents to `.claude/agents/`, skills to `.claude/skills/`.
Requires the `claude` CLI to be installed.
```

`targets/openai/README.md`:
```markdown
# OpenAI Target (v2.0 — not yet implemented)

Planned. See SPEC.md section 7.
```

`targets/gemini/README.md`:
```markdown
# Gemini Target (v3.0 — not yet implemented)

Planned. See SPEC.md section 7.
```

- [ ] **Step 7: Create empty stub for `rig` and make executable**

```bash
touch rig && chmod +x rig
```

- [ ] **Step 8: Commit**

```bash
git add .
git commit -m "chore: initialize repo structure and codebase-context submodule"
```

---

### Task 2: `rig` CLI skeleton

**Files:**
- Modify: `rig`
- Create: `tests/lib.sh`
- Create: `tests/test_cli.sh`

- [ ] **Step 1: Write `tests/lib.sh`**

```bash
#!/usr/bin/env bash
# Minimal test assertion library for Payload Depot tests

PASS=0
FAIL=0

assert_eq() {
  local description="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "  ✓ $description"
    ((PASS++))
  else
    echo "  ✗ $description"
    echo "    expected: $(printf '%q' "$expected")"
    echo "    actual:   $(printf '%q' "$actual")"
    ((FAIL++))
  fi
}

assert_file_exists() {
  local description="$1" file="$2"
  if [[ -f "$file" ]]; then
    echo "  ✓ $description"
    ((PASS++))
  else
    echo "  ✗ $description"
    echo "    file not found: $file"
    ((FAIL++))
  fi
}

assert_dir_exists() {
  local description="$1" dir="$2"
  if [[ -d "$dir" ]]; then
    echo "  ✓ $description"
    ((PASS++))
  else
    echo "  ✗ $description"
    echo "    dir not found: $dir"
    ((FAIL++))
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
    ((PASS++))
  else
    echo "  ✗ $description"
    echo "    expected to find: $needle"
    ((FAIL++))
  fi
}

report() {
  echo ""
  echo "Results: $PASS passed, $FAIL failed"
  [[ $FAIL -eq 0 ]]
}
```

- [ ] **Step 2: Write failing CLI tests in `tests/test_cli.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

LOADOUT_DEPOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$LOADOUT_DEPOT_DIR/tests/lib.sh"

echo "=== CLI Tests ==="

echo ""
echo "-- rig version --"
output=$("$LOADOUT_DEPOT_DIR/rig" version 2>&1) || true
assert_contains "version outputs version string" "1.0.0" "$output"

echo ""
echo "-- rig help --"
output=$("$LOADOUT_DEPOT_DIR/rig" help 2>&1) || true
assert_contains "help mentions install" "install" "$output"
assert_contains "help mentions list" "list" "$output"

echo ""
echo "-- rig unknown command --"
"$LOADOUT_DEPOT_DIR/rig" unknown-cmd 2>/dev/null; code=$?
assert_exit_code "unknown command exits 1" "1" "$code"

echo ""
echo "-- rig install unknown target --"
tmp=$(mktemp -d) && git -C "$tmp" init -q
"$LOADOUT_DEPOT_DIR/rig" install --target nonexistent 2>/dev/null; code=$?
assert_exit_code "unknown target exits 3" "3" "$code"
rm -rf "$tmp"

echo ""
echo "-- rig install no git repo --"
tmp=$(mktemp -d)
(cd "$tmp" && "$LOADOUT_DEPOT_DIR/rig" install 2>/dev/null); code=$?
assert_exit_code "no git repo exits 2" "2" "$code"
rm -rf "$tmp"

report
```

- [ ] **Step 3: Run tests — expect failures**

```bash
bash tests/test_cli.sh
```

Expected: multiple FAIL (rig is an empty stub)

- [ ] **Step 4: Implement `rig` CLI**

```bash
#!/usr/bin/env bash
set -euo pipefail

LOADOUT_DEPOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RIG_VERSION="1.0.0"

# ── Helpers ──────────────────────────────────────────────────────────────────

log()  { echo "[rig] $*"; }
err()  { echo "[rig] ERROR: $*" >&2; }
skip() { echo "[rig] ~ Skipped              → $*"; }
ok()   { echo "[rig] ✓ $*"; }

usage() {
  cat <<EOF
Usage: rig <command> [options]

Commands:
  install   Bootstrap the current directory as an AI-assisted project
  list      List available agents and skills
  version   Print Payload Depot version
  help      Print this message

Options for install:
  --target <name>       Target adapter (default: claude-code)
  --force               Overwrite existing config files
  --dry-run             Print install plan without writing files
  --no-hooks            Skip git hook installation
  --no-codebase-index   Skip codebase context index initialisation
EOF
}

# ── Commands ─────────────────────────────────────────────────────────────────

cmd_version() { echo "rig $RIG_VERSION"; }

cmd_help() { usage; }

cmd_list() {
  echo "Agents:"
  for f in "$LOADOUT_DEPOT_DIR/agents/"*.md; do
    [[ -f "$f" ]] && echo "  $(basename "$f" .md)"
  done
  echo ""
  echo "Skills:"
  for f in "$LOADOUT_DEPOT_DIR/skills/"*.md; do
    [[ -f "$f" ]] && echo "  $(basename "$f" .md)"
  done
}

cmd_install() {
  # Defaults
  local target="claude-code" force=false dry_run=false no_hooks=false no_index=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --target)             target="$2"; shift 2 ;;
      --force)              force=true; shift ;;
      --dry-run)            dry_run=true; shift ;;
      --no-hooks)           no_hooks=true; shift ;;
      --no-codebase-index)  no_index=true; shift ;;
      *) err "Unknown flag: $1"; exit 1 ;;
    esac
  done

  # Pre-flight
  if [[ ! -d ".git" ]]; then
    err "No .git directory found in current path."
    err "Initialise a git repository first: git init"
    exit 2
  fi

  local adapter_dir="$LOADOUT_DEPOT_DIR/targets/$target"
  if [[ ! -d "$adapter_dir" ]]; then
    err "Target '$target' not found. Available targets: $(ls "$LOADOUT_DEPOT_DIR/targets/")"
    err "Run \`rig list-targets\` for details."
    exit 3
  fi

  if [[ ! -f "$adapter_dir/adapter.sh" ]]; then
    err "adapter.sh not found in $adapter_dir"
    exit 1
  fi

  # Load adapter
  # shellcheck source=/dev/null
  source "$adapter_dir/adapter.sh"

  log "Installing for target: $target"

  # Dry-run helper
  maybe_run() {
    if $dry_run; then
      echo "[rig] [dry-run] $*"
    else
      "$@"
    fi
  }

  # Step 1: adapter pre-install
  adapter_pre_install

  # Steps 2-3: Create directories
  maybe_run mkdir -p "$AGENT_INSTALL_PATH"
  maybe_run mkdir -p "$SKILL_INSTALL_PATH"

  # Step 4: Copy agents
  local agent_count
  agent_count=$(find "$LOADOUT_DEPOT_DIR/agents" -name "*.md" | wc -l | tr -d ' ')
  if $dry_run; then
    log "[dry-run] Copy agents/ → $AGENT_INSTALL_PATH ($agent_count files)"
  else
    cp "$LOADOUT_DEPOT_DIR/agents/"*.md "$AGENT_INSTALL_PATH/"
    ok "Agents copied       → $AGENT_INSTALL_PATH ($agent_count files)"
  fi

  # Step 5: Copy skills
  local skill_count
  skill_count=$(find "$LOADOUT_DEPOT_DIR/skills" -name "*.md" | wc -l | tr -d ' ')
  if $dry_run; then
    log "[dry-run] Copy skills/ → $SKILL_INSTALL_PATH ($skill_count files)"
  else
    cp "$LOADOUT_DEPOT_DIR/skills/"*.md "$SKILL_INSTALL_PATH/"
    ok "Skills copied        → $SKILL_INSTALL_PATH ($skill_count files)"
  fi

  # Step 6: Write config templates
  for pair in "${CONFIG_FILES[@]}"; do
    local template dest
    template="${pair%%:*}"
    dest="${pair##*:}"
    local src="$adapter_dir/$template"
    local dest_dir
    dest_dir="$(dirname "$dest")"

    if $dry_run; then
      log "[dry-run] Write config → $dest"
      continue
    fi

    [[ "$dest_dir" != "." ]] && mkdir -p "$dest_dir"

    if [[ -f "$dest" ]] && ! $force; then
      skip "$dest (already exists, use --force to overwrite)"
    else
      cp "$src" "$dest"
      ok "Config written       → $dest (new)"
    fi
  done

  # Step 7: Copy session templates (always overwrite)
  if $dry_run; then
    log "[dry-run] Copy session/ → . (3 files)"
  else
    cp "$LOADOUT_DEPOT_DIR/session/"*.template .
    # Rename .template → strip extension
    for f in ./*.template; do
      mv "$f" "${f%.template}"
    done
    ok "Session templates    → . (3 files)"
  fi

  # Step 8: Append .gitignore entries
  local gitignore_block
  gitignore_block="$(cat <<'EOF'

# Payload Depot session files — ephemeral, not committed
SCRATCHPAD.md

# Codebase context — local vector DB, not committed
.codebase-context/chroma/
EOF
)"
  if $dry_run; then
    log "[dry-run] Append .gitignore entries"
  elif ! grep -qF "Payload Depot session files" .gitignore 2>/dev/null; then
    echo "$gitignore_block" >> .gitignore
    ok ".gitignore           → updated"
  fi

  # Step 9: Install pre-commit hook
  if $no_hooks; then
    skip ".git/hooks/pre-commit (--no-hooks)"
  elif $dry_run; then
    log "[dry-run] Install .git/hooks/pre-commit"
  else
    cp "$LOADOUT_DEPOT_DIR/hooks/pre-commit" ".git/hooks/pre-commit"
    chmod +x ".git/hooks/pre-commit"
    ok "Git hook installed   → .git/hooks/pre-commit"
  fi

  # Step 10: Run codebase-context install + ccindex init
  if $no_index; then
    skip "codebase index (--no-codebase-index)"
  elif $dry_run; then
    log "[dry-run] Run ccindex init"
  else
    # Install codebase-context tool if submodule install script present
    local cb_install="$LOADOUT_DEPOT_DIR/codebase-context/install.sh"
    if [[ -x "$cb_install" ]]; then
      "$cb_install" || { err "codebase-context install failed"; exit 4; }
    fi
    # Initialise index
    if command -v ccindex &>/dev/null; then
      ccindex init || { err "ccindex init failed (exit $?)"; exit 4; }
      ok "Codebase index       → initialised (.codebase-context/)"
    else
      log "WARNING: ccindex not found on PATH — skipping index init"
      log "         Install codebase-context to enable semantic search."
    fi
  fi

  # Step 11: adapter post-install
  adapter_post_install

  # Summary
  log "Done. $agent_count agents, $skill_count skills, ${#CONFIG_FILES[@]} config files, 3 session templates."
}

# ── Dispatch ──────────────────────────────────────────────────────────────────

COMMAND="${1:-help}"
shift || true

case "$COMMAND" in
  install) cmd_install "$@" ;;
  list)    cmd_list ;;
  version) cmd_version ;;
  help|--help|-h) cmd_help ;;
  *) err "Unknown command: $COMMAND"; exit 1 ;;
esac
```

- [ ] **Step 5: Run CLI tests — expect pass**

```bash
bash tests/test_cli.sh
```

Expected: all PASS

- [ ] **Step 6: Commit**

```bash
git add rig tests/lib.sh tests/test_cli.sh
git commit -m "feat: add rig CLI skeleton with arg parsing and pre-flight checks"
```

---

### Task 3: Claude Code adapter

**Files:**
- Create: `targets/claude-code/adapter.sh`

- [ ] **Step 1: Write failing test for adapter export**

Add to `tests/test_cli.sh` before `report`:

```bash
echo ""
echo "-- adapter exports --"
source "$LOADOUT_DEPOT_DIR/targets/claude-code/adapter.sh" 2>/dev/null || true
assert_eq "ADAPTER_NAME is claude-code" "claude-code" "${ADAPTER_NAME:-}"
assert_eq "AGENT_INSTALL_PATH is .claude/agents" ".claude/agents" "${AGENT_INSTALL_PATH:-}"
assert_eq "SKILL_INSTALL_PATH is .claude/skills" ".claude/skills" "${SKILL_INSTALL_PATH:-}"
```

- [ ] **Step 2: Run — expect FAIL**

```bash
bash tests/test_cli.sh
```

- [ ] **Step 3: Write `targets/claude-code/adapter.sh`**

```bash
#!/usr/bin/env bash
# Claude Code target adapter
# Sourced by `rig install` — do not execute directly.

ADAPTER_NAME="claude-code"
AGENT_INSTALL_PATH=".claude/agents"
SKILL_INSTALL_PATH=".claude/skills"

CONFIG_FILES=(
  "CLAUDE.md.template:CLAUDE.md"
  "CONVENTIONS.md.template:CONVENTIONS.md"
  "AGENTS.md.template:AGENTS.md"
  "settings.json.template:.claude/settings.json"
)

adapter_validate() {
  command -v claude &>/dev/null
}

adapter_pre_install() {
  mkdir -p ".claude"
}

adapter_post_install() {
  : # no-op for v1.0
}
```

- [ ] **Step 4: Run tests — expect PASS**

```bash
bash tests/test_cli.sh
```

- [ ] **Step 5: Commit**

```bash
git add targets/claude-code/adapter.sh tests/test_cli.sh
git commit -m "feat: add claude-code target adapter"
```

---

## Chunk 2: Content Layer (Phases 4–5)

### Task 4: Session templates

**Files:**
- Create: `session/HANDOFF.md.template`
- Create: `session/SCRATCHPAD.md.template`
- Create: `session/DECISIONS.md.template`

- [ ] **Step 1: Write `session/HANDOFF.md.template`**

```markdown
# Handoff Log

<!-- HANDOFF.md is committed to git. Agents run `git pull` before reading it
     and `git add HANDOFF.md DECISIONS.md && git commit && git push` after appending. -->
<!-- Each agent appends one block when it completes its task. Do not edit previous blocks. -->

---

## Block Template (copy and fill per agent)

### Agent: <agent name>
**Completed:** <timestamp>
**Task:** <what was asked>

#### Output Files
<!-- List every file written or modified, with a one-line description of what changed. -->

#### Assumptions Made
<!-- List any assumptions that are not stated in the task brief. -->

#### What Was Not Done
<!-- Explicitly state what was out of scope or deferred, and why. -->

#### Uncertainties
<!-- Flag anything the next agent should verify before relying on. -->

#### Instructions for Next Agent
<!-- Direct instructions. What should the next agent read first, do first, watch out for. -->
```

- [ ] **Step 2: Write `session/SCRATCHPAD.md.template`**

```markdown
# Scratchpad — <session date>

**Agent:** <agent name>
**Task:** <one-line task description>
**Started:** <timestamp>

<!-- SCRATCHPAD.md is ephemeral — not committed to git. -->

---

## Working Notes
<!-- Append-only. Do not edit previous entries. -->

---

## Open Questions
<!-- Unresolved questions that may affect output. -->

---

## Session Summary
<!-- Fill in at session end before handing off or exporting context. -->
```

- [ ] **Step 3: Write `session/DECISIONS.md.template`**

```markdown
# Decisions — <session date>

<!-- DECISIONS.md is committed to git — it accumulates across sessions. -->
<!-- One entry per meaningful implementation decision. -->
<!-- Do not record trivial choices. Record choices that a reviewer would ask about. -->

---

## Decision Log

### <short title>
- **Decision:** What was chosen.
- **Alternatives considered:** What else was evaluated.
- **Rationale:** Why this option was selected.
- **Affected files:** List of files impacted by this decision.
- **Date:** YYYY-MM-DD
```

- [ ] **Step 4: Commit**

```bash
git add session/
git commit -m "feat: add session templates (HANDOFF, SCRATCHPAD, DECISIONS)"
```

---

### Task 5: Config templates

**Files:**
- Create: `targets/claude-code/CLAUDE.md.template`
- Create: `targets/claude-code/CONVENTIONS.md.template`
- Create: `targets/claude-code/AGENTS.md.template`
- Create: `targets/claude-code/settings.json.template`

- [ ] **Step 1: Write `targets/claude-code/CLAUDE.md.template`**

```markdown
@.codebase-context/repo_map.md

# <Project Name>

<!-- Replace <Project Name> with your project name above. -->

**Language/toolchain:** <language and primary tools>
**One-line description:** <what this project does>

---

## Conventions

Read `CONVENTIONS.md` before writing or reviewing any code. All coding decisions
must follow the rules defined there.

## Agent Registry

Read `AGENTS.md` for the full list of available agents, their roles, trigger
conditions, and expected outputs.

## Session Protocol

**At the start of every session:**
1. Run `git pull` to ensure `HANDOFF.md` and `DECISIONS.md` are current.
2. If `HANDOFF.md` exists, read it — find the most recent block and follow its instructions.
3. Read `CONVENTIONS.md`.
4. Write a session header to `SCRATCHPAD.md`.

**During every session:**
- Append working notes and decisions to `SCRATCHPAD.md` as you go.

**At the end of every session:**
1. Finalise `SCRATCHPAD.md` with a session summary.
2. Append your completed block to `HANDOFF.md`.
3. Record any non-trivial decisions to `DECISIONS.md`.
4. Commit and push: `git add HANDOFF.md DECISIONS.md && git commit -m "handoff: <agent> completed <task>" && git push`

## Codebase Context

The MCP codebase-context tool is available. Use it to explore the codebase:
- `search_codebase` — semantic search over code symbols
- `get_symbol` — exact symbol lookup by name
- `get_repo_map` — compact file/class/function outline

Prefer these tools over manual file reading when exploring unfamiliar code.
```

- [ ] **Step 2: Write `targets/claude-code/CONVENTIONS.md.template`**

```markdown
# Conventions

<!-- Fill in each section for your project. Remove sections that do not apply. -->
<!-- Agents read this file at session start. Keep it current. -->

---

## Naming Conventions

- **Files:** <kebab-case | snake_case | PascalCase — choose one>
- **Variables:** <camelCase | snake_case>
- **Functions:** <camelCase | snake_case>
- **Classes:** <PascalCase>
- **Constants:** <SCREAMING_SNAKE_CASE>

## File and Directory Structure

<!-- Describe where things live. E.g.: -->
<!-- - `src/` — application source -->
<!-- - `tests/` — test files mirror src/ structure -->
<!-- - `docs/` — documentation only, no code -->

## Error Handling

<!-- Describe your error handling pattern. E.g.: -->
<!-- - Always log before re-raising -->
<!-- - Never swallow exceptions silently -->
<!-- - Use typed errors/exceptions where supported -->

## Logging

<!-- Describe logging conventions. E.g.: -->
<!-- - Use structured logging (JSON) -->
<!-- - Log at INFO for business events, DEBUG for implementation details -->

## Preferred Libraries

| Purpose | Library | Notes |
|---|---|---|
| <purpose> | <library> | <when and how to use it> |

## Dependency Rules

- Never add a dependency without updating `env-setup`
- Never add a dependency without a documented reason in `DECISIONS.md`

## Never Do

- Never hardcode secrets or credentials — use environment variables
- Never use broad exception catches without logging the error
- Never commit commented-out code
- Never use `any` type (TypeScript) or equivalent type erasure
- Never push directly to `main` — use branches and PRs
- <add project-specific rules here>

## Branch Naming

`<type>/<short-description>`

Types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`

Example: `feat/add-auth`, `fix/null-pointer`

## Commit Message Format

Conventional Commits: `<type>: <short description>`

Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `perf`

Example: `feat: add user authentication`, `fix: handle null session token`
```

- [ ] **Step 3: Write `targets/claude-code/AGENTS.md.template`**

```markdown
# Agent Registry

<!-- This file is generated by rig install. Update it when agents are added or changed. -->
<!-- Agents read this file to understand the full agent landscape of the project. -->

---

## architect

**Role:** Produces structured system design — components, data flow, interface contracts, edge cases.
**Invoke when:** Before writing any code on a new feature or system.
**Input:** Task brief or user requirement.
**Output:** `ARCHITECT_OUTPUT.md` — structured design document.
**Writes:** `ARCHITECT_OUTPUT.md`, appends to `HANDOFF.md`.

---

## planner

**Role:** Decomposes a vague brief into a structured `TASKS.md`.
**Invoke when:** At project start or when beginning a large feature.
**Input:** Brief, architect output, or user description.
**Output:** `TASKS.md` — ordered task list with acceptance criteria.
**Writes:** `TASKS.md`, appends to `HANDOFF.md`.

---

## code-writer

**Role:** Implements features following project conventions.
**Invoke when:** After architect/planner output is ready.
**Input:** `ARCHITECT_OUTPUT.md`, `TASKS.md`, `HANDOFF.md` latest block, `CONVENTIONS.md`.
**Output:** Implementation code in the correct locations.
**Writes:** Source files, appends to `HANDOFF.md`.

---

## code-reviewer

**Role:** Reviews code for correctness, style, and maintainability.
**Invoke when:** After code-writer produces a diff or file set.
**Input:** Diff or changed files, `CONVENTIONS.md`.
**Output:** Inline review comments and a summary verdict.
**Writes:** Appends to `HANDOFF.md`.

---

## docs-writer

**Role:** Generates/updates README, API docs, and docstrings from existing code.
**Invoke when:** After implementation is stable.
**Input:** Source files, existing docs, `CONVENTIONS.md`.
**Output:** Updated docs.
**Writes:** Documentation files, appends to `HANDOFF.md`.

---

## security-auditor

**Role:** Reviews code and dependency manifests for vulnerabilities and insecure patterns.
**Invoke when:** Before any release or merge to main.
**Input:** Source files, dependency manifests.
**Output:** Security findings report.
**Writes:** Appends to `HANDOFF.md`.

---

## debugger

**Role:** Reads error output, relevant code, and git log to produce a structured root cause analysis and fix plan.
**Invoke when:** When a runtime error, test failure, or unexpected behaviour needs diagnosis.
**Input:** Error output, stack trace, relevant source files, `git log`.
**Output:** Root cause analysis and fix plan.
**Writes:** Appends to `HANDOFF.md`.
```

- [ ] **Step 4: Write `targets/claude-code/settings.json.template`**

```json
{
  "permissions": {
    "allow": [
      "read",
      "write",
      "bash"
    ],
    "deny": [
      "network"
    ]
  },
  "tools": {
    "bash": {
      "allowedCommands": [
        "git",
        "python",
        "python3",
        "node",
        "npm",
        "npx",
        "tsc",
        "mypy",
        "ruff",
        "eslint",
        "clang",
        "clang++",
        "make",
        "cmake",
        "pip",
        "pip3",
        "pip-audit",
        "npm audit",
        "ccindex"
      ]
    }
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add targets/claude-code/
git commit -m "feat: add claude-code config templates (CLAUDE.md, CONVENTIONS.md, AGENTS.md, settings.json)"
```

---

## Chunk 3: Install Sequence + Hook (Phases 6–7)

### Task 6: End-to-end install test

**Files:**
- Create: `tests/fixtures/python-project/pyproject.toml`
- Create: `tests/fixtures/typescript-project/package.json`
- Create: `tests/fixtures/typescript-project/tsconfig.json`
- Create: `tests/fixtures/cpp-project/CMakeLists.txt`
- Create: `tests/test_install.sh`
- Create: `agents/.gitkeep` (placeholder so agents/ dir exists)
- Create: `skills/.gitkeep` (placeholder so skills/ dir exists)
- Create: `hooks/pre-commit` (stub, implemented in Task 7)

- [ ] **Step 1: Create test fixtures**

```bash
# Python fixture
git -C tests/fixtures/python-project init -q
cat > tests/fixtures/python-project/pyproject.toml <<'EOF'
[project]
name = "test-project"
version = "0.1.0"
EOF

# TypeScript fixture
git -C tests/fixtures/typescript-project init -q
cat > tests/fixtures/typescript-project/package.json <<'EOF'
{ "name": "test-project", "version": "1.0.0" }
EOF
cat > tests/fixtures/typescript-project/tsconfig.json <<'EOF'
{ "compilerOptions": { "strict": true } }
EOF

# C++ fixture
git -C tests/fixtures/cpp-project init -q
cat > tests/fixtures/cpp-project/CMakeLists.txt <<'EOF'
cmake_minimum_required(VERSION 3.15)
project(TestProject)
EOF
```

- [ ] **Step 2: Create agent/skill/hook stubs so copy steps don't fail**

```bash
touch agents/.gitkeep skills/.gitkeep
cat > hooks/pre-commit <<'EOF'
#!/usr/bin/env bash
# Payload Depot pre-commit hook — stub (implemented in Phase 7)
exit 0
EOF
chmod +x hooks/pre-commit
```

- [ ] **Step 3: Write `tests/test_install.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

LOADOUT_DEPOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$LOADOUT_DEPOT_DIR/tests/lib.sh"

# Run rig install in an isolated copy of a fixture
setup_fixture() {
  local fixture="$1"
  local tmp
  tmp=$(mktemp -d)
  cp -r "$LOADOUT_DEPOT_DIR/tests/fixtures/$fixture/." "$tmp/"
  # Ensure .git exists (cp doesn't copy from the fixture init)
  git -C "$tmp" init -q 2>/dev/null || true
  echo "$tmp"
}

cleanup() { rm -rf "$1"; }

echo "=== Install Tests ==="

# 1. fresh-install-python
echo ""
echo "-- fresh-install-python --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$LOADOUT_DEPOT_DIR/rig" install --no-codebase-index 2>&1) || true
assert_dir_exists  "agents dir created"  "$dir/.claude/agents"
assert_dir_exists  "skills dir created"  "$dir/.claude/skills"
assert_file_exists "CLAUDE.md written"   "$dir/CLAUDE.md"
assert_file_exists "CONVENTIONS.md written" "$dir/CONVENTIONS.md"
assert_file_exists "AGENTS.md written"   "$dir/AGENTS.md"
assert_file_exists "settings.json written" "$dir/.claude/settings.json"
assert_file_exists "HANDOFF.md written"  "$dir/HANDOFF.md"
assert_file_exists "SCRATCHPAD.md written" "$dir/SCRATCHPAD.md"
assert_file_exists "DECISIONS.md written" "$dir/DECISIONS.md"
assert_file_exists "pre-commit hook"     "$dir/.git/hooks/pre-commit"
cleanup "$dir"

# 2. fresh-install-typescript
echo ""
echo "-- fresh-install-typescript --"
dir=$(setup_fixture typescript-project)
(cd "$dir" && "$LOADOUT_DEPOT_DIR/rig" install --no-codebase-index 2>&1) || true
assert_file_exists "CLAUDE.md written" "$dir/CLAUDE.md"
assert_dir_exists  "agents dir"        "$dir/.claude/agents"
cleanup "$dir"

# 3. fresh-install-cpp
echo ""
echo "-- fresh-install-cpp --"
dir=$(setup_fixture cpp-project)
(cd "$dir" && "$LOADOUT_DEPOT_DIR/rig" install --no-codebase-index 2>&1) || true
assert_file_exists "CLAUDE.md written" "$dir/CLAUDE.md"
assert_dir_exists  "agents dir"        "$dir/.claude/agents"
cleanup "$dir"

# 4. skip-existing-config
echo ""
echo "-- skip-existing-config --"
dir=$(setup_fixture python-project)
echo "# existing" > "$dir/CLAUDE.md"
output=$(cd "$dir" && "$LOADOUT_DEPOT_DIR/rig" install --no-codebase-index 2>&1) || true
assert_contains    "skip message printed"      "Skipped" "$output"
existing=$(cat "$dir/CLAUDE.md")
assert_eq          "CLAUDE.md not overwritten" "# existing" "$existing"
cleanup "$dir"

# 5. force-overwrite
echo ""
echo "-- force-overwrite --"
dir=$(setup_fixture python-project)
echo "# existing" > "$dir/CLAUDE.md"
(cd "$dir" && "$LOADOUT_DEPOT_DIR/rig" install --force --no-codebase-index 2>&1) || true
existing=$(cat "$dir/CLAUDE.md")
[[ "$existing" != "# existing" ]]
assert_eq "CLAUDE.md overwritten" "0" "$?"
cleanup "$dir"

# 6. dry-run
echo ""
echo "-- dry-run --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$LOADOUT_DEPOT_DIR/rig" install --dry-run --no-codebase-index 2>&1) || true
# No files should have been written
[[ ! -f "$dir/CLAUDE.md" ]]
assert_eq "dry-run: CLAUDE.md not written" "0" "$?"
cleanup "$dir"

# 7. no-git-repo
echo ""
echo "-- no-git-repo --"
dir=$(mktemp -d)
(cd "$dir" && "$LOADOUT_DEPOT_DIR/rig" install --no-codebase-index 2>/dev/null); code=$?
assert_exit_code "no git repo exits 2" "2" "$code"
cleanup "$dir"

# 8. unknown-target
echo ""
echo "-- unknown-target --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$LOADOUT_DEPOT_DIR/rig" install --target nonexistent --no-codebase-index 2>/dev/null); code=$?
assert_exit_code "unknown target exits 3" "3" "$code"
cleanup "$dir"

# 9. no-hooks
echo ""
echo "-- no-hooks --"
dir=$(setup_fixture python-project)
(cd "$dir" && "$LOADOUT_DEPOT_DIR/rig" install --no-hooks --no-codebase-index 2>&1) || true
[[ ! -f "$dir/.git/hooks/pre-commit" ]]
assert_eq "hook not installed" "0" "$?"
cleanup "$dir"

# 10. no-codebase-index
echo ""
echo "-- no-codebase-index --"
dir=$(setup_fixture python-project)
output=$(cd "$dir" && "$LOADOUT_DEPOT_DIR/rig" install --no-codebase-index 2>&1) || true
assert_contains "skip message for index" "codebase index" "$output"
cleanup "$dir"

report
```

- [ ] **Step 4: Run tests**

```bash
bash tests/test_install.sh
```

Fix any failures in `rig` until all 10 test cases pass.

- [ ] **Step 5: Commit**

```bash
git add tests/ agents/.gitkeep skills/.gitkeep hooks/pre-commit
git commit -m "test: add install integration tests and fixtures"
```

---

### Task 7: `hooks/pre-commit`

**Files:**
- Modify: `hooks/pre-commit`
- Create: `tests/test_hooks.sh`

- [ ] **Step 1: Write failing hook tests in `tests/test_hooks.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

LOADOUT_DEPOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$LOADOUT_DEPOT_DIR/tests/lib.sh"

HOOK="$LOADOUT_DEPOT_DIR/hooks/pre-commit"

echo "=== Hook Tests ==="

# Helper: create temp project with a given language marker
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

# 1. unknown-language: hook exits 0 with warning
echo ""
echo "-- unknown-language --"
dir=$(mktemp -d) && git -C "$dir" init -q
(cd "$dir" && RIG_HOOK_TEST=1 bash "$HOOK" 2>&1); code=$?
assert_exit_code "unknown language exits 0" "0" "$code"
rm -rf "$dir"

# 2. missing-tool: hook exits 0 with warning (mock via PATH override)
echo ""
echo "-- missing-tool (python project, no ruff) --"
dir=$(setup_project pyproject.toml)
(cd "$dir" && PATH="/nonexistent:$PATH" RIG_HOOK_TEST=1 bash "$HOOK" 2>&1); code=$?
assert_exit_code "missing tool exits 0" "0" "$code"
rm -rf "$dir"

# 3. python-clean: exits 0 (mock ruff and mypy to succeed)
echo ""
echo "-- python-clean (mocked) --"
dir=$(setup_project pyproject.toml)
# Create mock ruff and mypy that succeed
mkdir -p "$dir/mock-bin"
echo '#!/bin/bash' > "$dir/mock-bin/ruff" && echo 'exit 0' >> "$dir/mock-bin/ruff"
echo '#!/bin/bash' > "$dir/mock-bin/mypy" && echo 'exit 0' >> "$dir/mock-bin/mypy"
chmod +x "$dir/mock-bin/ruff" "$dir/mock-bin/mypy"
(cd "$dir" && PATH="$dir/mock-bin:$PATH" RIG_HOOK_TEST=1 bash "$HOOK" 2>&1); code=$?
assert_exit_code "python-clean exits 0" "0" "$code"
rm -rf "$dir"

# 4. python-lint-fail: exits 1
echo ""
echo "-- python-lint-fail (mocked) --"
dir=$(setup_project pyproject.toml)
mkdir -p "$dir/mock-bin"
echo '#!/bin/bash' > "$dir/mock-bin/ruff" && echo 'echo "E501 line too long"; exit 1' >> "$dir/mock-bin/ruff"
echo '#!/bin/bash' > "$dir/mock-bin/mypy" && echo 'exit 0' >> "$dir/mock-bin/mypy"
chmod +x "$dir/mock-bin/ruff" "$dir/mock-bin/mypy"
(cd "$dir" && PATH="$dir/mock-bin:$PATH" RIG_HOOK_TEST=1 bash "$HOOK" 2>&1); code=$?
assert_exit_code "python-lint-fail exits 1" "1" "$code"
rm -rf "$dir"

# 5. python-type-fail: exits 1
echo ""
echo "-- python-type-fail (mocked) --"
dir=$(setup_project pyproject.toml)
mkdir -p "$dir/mock-bin"
echo '#!/bin/bash' > "$dir/mock-bin/ruff" && echo 'exit 0' >> "$dir/mock-bin/ruff"
echo '#!/bin/bash' > "$dir/mock-bin/mypy" && echo 'echo "error: incompatible types"; exit 1' >> "$dir/mock-bin/mypy"
chmod +x "$dir/mock-bin/ruff" "$dir/mock-bin/mypy"
(cd "$dir" && PATH="$dir/mock-bin:$PATH" RIG_HOOK_TEST=1 bash "$HOOK" 2>&1); code=$?
assert_exit_code "python-type-fail exits 1" "1" "$code"
rm -rf "$dir"

# 6. typescript-clean (mocked)
echo ""
echo "-- typescript-clean (mocked) --"
dir=$(setup_project package.json)
mkdir -p "$dir/mock-bin"
echo '#!/bin/bash' > "$dir/mock-bin/eslint" && echo 'exit 0' >> "$dir/mock-bin/eslint"
echo '#!/bin/bash' > "$dir/mock-bin/tsc" && echo 'exit 0' >> "$dir/mock-bin/tsc"
chmod +x "$dir/mock-bin/eslint" "$dir/mock-bin/tsc"
(cd "$dir" && PATH="$dir/mock-bin:$PATH" RIG_HOOK_TEST=1 bash "$HOOK" 2>&1); code=$?
assert_exit_code "typescript-clean exits 0" "0" "$code"
rm -rf "$dir"

# 7. typescript-lint-fail (mocked)
echo ""
echo "-- typescript-lint-fail (mocked) --"
dir=$(setup_project package.json)
mkdir -p "$dir/mock-bin"
echo '#!/bin/bash' > "$dir/mock-bin/eslint" && echo 'echo "error"; exit 1' >> "$dir/mock-bin/eslint"
echo '#!/bin/bash' > "$dir/mock-bin/tsc" && echo 'exit 0' >> "$dir/mock-bin/tsc"
chmod +x "$dir/mock-bin/eslint" "$dir/mock-bin/tsc"
(cd "$dir" && PATH="$dir/mock-bin:$PATH" RIG_HOOK_TEST=1 bash "$HOOK" 2>&1); code=$?
assert_exit_code "typescript-lint-fail exits 1" "1" "$code"
rm -rf "$dir"

report
```

- [ ] **Step 2: Run — expect FAIL**

```bash
bash tests/test_hooks.sh
```

- [ ] **Step 3: Implement `hooks/pre-commit`**

```bash
#!/usr/bin/env bash
# Payload Depot pre-commit hook
# Detects project language and runs linting + type-checking.
# Blocks commit on failure. Skips gracefully if tools are missing.

set -euo pipefail

PREFIX="[rig:pre-commit]"

log()  { echo "$PREFIX $*"; }
warn() { echo "$PREFIX WARNING: $*" >&2; }
fail() { echo "$PREFIX $*" >&2; echo "$PREFIX Commit blocked. Fix errors and try again." >&2
         echo "$PREFIX To skip checks: git commit --no-verify" >&2; exit 1; }

run_check() {
  local label="$1"; shift
  local cmd="$1"; shift

  if ! command -v "$cmd" &>/dev/null; then
    warn "$cmd not found — skipping $label check"
    return 0
  fi

  log "Running $label..."
  local output exit_code=0
  output=$("$cmd" "$@" 2>&1) || exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    log "✗ $label: checks failed"
    echo ""
    echo "$output"
    echo ""
    return 1
  fi

  log "✓ $label: ok"
  return 0
}

# Language detection
if [[ -f "package.json" ]]; then
  LANG="typescript"
elif [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
  LANG="python"
elif [[ -f "CMakeLists.txt" ]] || [[ -f "Makefile" ]]; then
  LANG="cpp"
else
  warn "No recognised language marker found — skipping checks"
  exit 0
fi

log "Running $LANG checks..."

FAILED=false

case "$LANG" in
  python)
    run_check "ruff (lint)" ruff check . || FAILED=true
    run_check "mypy (types)" mypy . || FAILED=true
    ;;
  typescript)
    run_check "eslint (lint)" eslint . || FAILED=true
    run_check "tsc (types)" tsc --noEmit || FAILED=true
    ;;
  cpp)
    if command -v clang-tidy &>/dev/null; then
      run_check "clang-tidy (lint)" clang-tidy --quiet . || FAILED=true
    else
      warn "clang-tidy not found — skipping lint"
    fi
    if command -v make &>/dev/null; then
      run_check "make (build check)" make --dry-run || FAILED=true
    elif command -v cmake &>/dev/null; then
      run_check "cmake (build check)" cmake --build . --target all -- -n || FAILED=true
    else
      warn "Neither make nor cmake found — skipping build check"
    fi
    ;;
esac

$FAILED && fail "One or more checks failed."
exit 0
```

- [ ] **Step 4: Run hook tests — expect PASS**

```bash
bash tests/test_hooks.sh
```

- [ ] **Step 5: Commit**

```bash
git add hooks/pre-commit tests/test_hooks.sh
git commit -m "feat: add pre-commit hook with language detection and lint/type-check"
```

---

## Chunk 4: Agent and Skill Content (Phases 9–10)

For phases 9 and 10, each agent and skill file follows the exact structure defined in SPEC.md sections 6.1 and 6.2. Write them in order. Each file gets a prompt version header, role, inputs, process, outputs, handoff, and "do not" sections.

### Task 8: Core agents

**Files:** `agents/architect.md`, `agents/planner.md`, `agents/debugger.md`

Write each file per the agent template in SPEC.md §6.1. Key content:

- [ ] **Step 1: Write `agents/architect.md`**

Header + sections: Role (produces structured system design), Inputs (task brief, HANDOFF.md, CONVENTIONS.md, repo map), Process (read context → identify components → define interfaces → map data flow → surface edge cases → write ARCHITECT_OUTPUT.md → append HANDOFF.md), Outputs (ARCHITECT_OUTPUT.md), Handoff (fields: components identified, interfaces defined, edge cases flagged, assumptions made, instructions for code-writer), Do Not (write any implementation code; skip HANDOFF.md; produce design without reading CONVENTIONS.md).

- [ ] **Step 2: Write `agents/planner.md`**

Role (decomposes a brief into TASKS.md), Inputs (brief, architect output if available, HANDOFF.md), Process (read context → identify deliverables → sequence tasks → write acceptance criteria → produce TASKS.md → append HANDOFF.md), Outputs (TASKS.md), Handoff (tasks created, sequencing rationale, blockers identified, instructions for next agent), Do Not (implement anything; create tasks without acceptance criteria; ignore existing HANDOFF.md).

- [ ] **Step 3: Write `agents/debugger.md`**

Role (root cause analysis and fix plan), Inputs (error output or stack trace, relevant source files, git log), Process (read error → identify failure point → trace call chain → check recent commits → write root cause analysis → propose fix → append HANDOFF.md), Outputs (inline root cause analysis + fix plan written to SCRATCHPAD.md), Handoff (root cause, confidence level, fix proposed, files to change, instructions for code-writer), Do Not (implement the fix; speculate without evidence; skip git log check).

- [ ] **Step 4: Commit**

```bash
git add agents/architect.md agents/planner.md agents/debugger.md
git commit -m "feat: add architect, planner, debugger agents"
```

---

### Task 9: Core skills

**Files:** `skills/commit-msg.md`, `skills/tdd.md`, `skills/linting.md`, `skills/type-checking.md`, `skills/dependency-audit.md`

Write each per SPEC.md §6.2 (Purpose, Trigger, Language Support, Process, Output Format, Error Handling).

- [ ] **Step 1: Write `skills/commit-msg.md`**

Purpose (generate conventional commit message from staged diff), Trigger (user asks for commit message, or end of code-writer session), Language Support (language-agnostic), Process (run `git diff --staged` → read diff → identify change type → write conventional commit message → print to stdout), Output Format (single line: `<type>: <description>`; multi-line body if change is complex), Error Handling (if no staged changes: print warning and stop).

- [ ] **Step 2: Write `skills/tdd.md`**

Purpose (test-driven development workflow), Trigger (before implementing any feature or bugfix), Language Support (Python: pytest; TypeScript: jest/vitest; C/C++: catch2/gtest), Process (write failing test → run to confirm failure → implement minimal code → run to confirm pass → refactor → commit), Output Format (no file output; inline guidance), Error Handling (if test runner not installed: print setup instructions for the detected language).

- [ ] **Step 3: Write `skills/linting.md`**

Purpose (run and interpret linting for detected language), Trigger (explicit user request; pre-commit hook; code-reviewer session), Language Support (Python: ruff; TypeScript: eslint; C/C++: clang-tidy), Process (detect language → run linter → parse output → report violations with file:line references → suggest fixes for common patterns), Output Format (structured list of violations with severity), Error Handling (tool not installed: print install command for the language).

- [ ] **Step 4: Write `skills/type-checking.md`**

Purpose (run type checker and interpret output), Trigger (explicit user request; pre-commit hook), Language Support (Python: mypy; TypeScript: tsc --noEmit; C/C++: compiler warnings), Process (detect language → run type checker → parse output → report errors with context → suggest fixes), Output Format (list of type errors with file:line and suggested resolution), Error Handling (tool not installed: print install instructions).

- [ ] **Step 5: Write `skills/dependency-audit.md`**

Purpose (audit dependencies for known vulnerabilities), Trigger (before any release; after adding a new dependency), Language Support (Python: pip-audit; TypeScript: npm audit; C/C++: manual CVE check guidance), Process (detect language → run audit tool → parse output → summarise findings by severity → flag critical/high issues), Output Format (severity-grouped findings table; overall verdict), Error Handling (tool not installed: print install command; audit tool returns no vulnerabilities: confirm clean).

- [ ] **Step 6: Commit**

```bash
git add skills/commit-msg.md skills/tdd.md skills/linting.md skills/type-checking.md skills/dependency-audit.md
git commit -m "feat: add core skills (commit-msg, tdd, linting, type-checking, dependency-audit)"
```

---

### Task 10: Remaining agents

**Files:** `agents/code-writer.md`, `agents/code-reviewer.md`, `agents/docs-writer.md`, `agents/security-auditor.md`

- [ ] **Step 1: Write `agents/code-writer.md`**

Role (implements features per architect output and project conventions), Inputs (ARCHITECT_OUTPUT.md or TASKS.md, HANDOFF.md latest block, CONVENTIONS.md, relevant source files), Process (read context → implement in small commits → run tests after each step → append HANDOFF.md when done), Outputs (source files, test files), Handoff (files written, tests passing, what was deferred, instructions for code-reviewer), Do Not (implement without reading CONVENTIONS.md; skip tests; commit code that fails type-checking or linting).

- [ ] **Step 2: Write `agents/code-reviewer.md`**

Role (reviews code for correctness, style, maintainability), Inputs (diff or changed files, CONVENTIONS.md, HANDOFF.md), Process (read CONVENTIONS.md → read diff → check each change against conventions → flag violations → check for missing tests → check error handling → write verdict → append HANDOFF.md), Outputs (inline review comments + summary verdict), Handoff (verdict: approved/needs-changes, issues found, instructions for next agent), Do Not (approve code that violates CONVENTIONS.md; review without reading conventions first; rewrite code — only flag issues).

- [ ] **Step 3: Write `agents/docs-writer.md`**

Role (generates/updates README, API docs, docstrings), Inputs (source files, existing docs, CONVENTIONS.md), Process (read source → identify public interfaces → update/write docstrings → update README sections → update API docs if applicable → append HANDOFF.md), Outputs (updated documentation files), Handoff (files updated, sections changed, anything left incomplete), Do Not (document internal implementation details in public docs; copy-paste docstrings without reading the code; update docs without reading current state first).

- [ ] **Step 4: Write `agents/security-auditor.md`**

Role (reviews code and dependencies for vulnerabilities and insecure patterns), Inputs (source files, dependency manifests, HANDOFF.md), Process (run dependency-audit skill → scan for OWASP top-10 patterns → check secrets/credentials → check input validation → check error handling for info leakage → write findings → append HANDOFF.md), Outputs (security findings report), Handoff (findings by severity, critical blockers, recommended fixes, verdict: safe-to-merge/needs-fixes), Do Not (approve code with hardcoded secrets; skip dependency audit; give a pass without reading auth/input-handling code).

- [ ] **Step 5: Commit**

```bash
git add agents/code-writer.md agents/code-reviewer.md agents/docs-writer.md agents/security-auditor.md
git commit -m "feat: add remaining agents (code-writer, code-reviewer, docs-writer, security-auditor)"
```

---

### Task 11: Remaining skills + prompt versioning headers

**Files:** `skills/adr.md`, `skills/readme-gen.md`, `skills/openapi-lint.md`, `skills/changelog.md`, `skills/env-setup.md`

Also: add version headers to all agent and skill files that are missing them.

- [ ] **Step 1: Write remaining skills**

Write each per SPEC.md §6.2:

- `skills/adr.md` — scaffolds/maintains Architecture Decision Records in `docs/decisions/`
- `skills/readme-gen.md` — generates README skeleton from project tree and entry points
- `skills/openapi-lint.md` — validates/lints OpenAPI or AsyncAPI specs
- `skills/changelog.md` — generates CHANGELOG entries from git log (Keep a Changelog format)
- `skills/env-setup.md` — documents `.env.example`, required system deps, setup steps

- [ ] **Step 2: Verify all agent and skill files have version headers**

Each file must begin with:
```yaml
---
version: 1.0.0
updated: 2026-03-15
changelog:
  - 1.0.0: initial version
---
```

Run:
```bash
for f in agents/*.md skills/*.md; do
  head -1 "$f" | grep -q "^---" || echo "MISSING HEADER: $f"
done
```

Add headers to any file that is missing one.

- [ ] **Step 3: Run all tests**

```bash
bash tests/test_cli.sh
bash tests/test_install.sh
bash tests/test_hooks.sh
```

All tests must pass before this step is complete.

- [ ] **Step 4: Final commit**

```bash
git add skills/ agents/
git commit -m "feat: add remaining skills and prompt versioning headers — Payload Depot v1.0 complete"
```

---

## End-to-End Validation

After all tasks are complete, validate against a real project:

- [ ] Clone a fresh Python/TypeScript/C++ project
- [ ] Run `rig install --no-codebase-index` and verify all files land in the right places
- [ ] Run `rig install` (with ccindex) if `ccindex` is available
- [ ] Make a commit in the target project and verify the pre-commit hook runs
- [ ] Read `HANDOFF.md` and verify it matches the template structure
