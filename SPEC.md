# Rig — Project Specification

**Version:** 1.0.0
**Status:** Draft
**Scope:** v1.0 — Claude Code target only

---

## 1. Overview

Rig is a CLI tool and scaffold repository. Running `rig install` in any project root copies a predefined set of AI agent prompts, skill prompts, session templates, config files, and git hooks into the correct locations for the target LLM tool. It then invokes the context manager installer.

The system has two layers:

- **Canonical content layer** — agent and skill `.md` files that are LLM-agnostic and live once in the Rig repo
- **Target adapter layer** — per-tool wiring that maps canonical content to the right install paths, config formats, and invocation conventions

This spec covers the v1.0 Claude Code target. Future targets (OpenAI, Gemini) follow the same adapter contract defined in Section 7.

---

## 2. Constraints and Assumptions

- Rig is a developer tool. The user is a technical operator running it from a terminal.
- The `rig` entrypoint is a single bash script for v1.0. No runtime dependencies beyond bash, git, and standard Unix utilities (`cp`, `chmod`, `mkdir`, `cat`).
- The target project must have a git repository initialised (`.git/` must exist) before running `rig install`.
- Context manager is a pre-existing external component. Rig invokes it but does not own it.
- All agent and skill files are UTF-8 plain text markdown.
- v1.0 supports Python, TypeScript, and C/C++ projects.
- Rig does not require network access to install.

---

## 3. Repository Structure

```
rig/
├── agents/                          ← canonical agent prompts (LLM-agnostic)
│   ├── architect.md
│   ├── planner.md
│   ├── code-writer.md
│   ├── code-reviewer.md
│   ├── docs-writer.md
│   ├── security-auditor.md
│   ├── debugger.md
│   ├── test-writer.md
│   └── issue-logger.md
│
├── skills/                          ← canonical skill prompts (LLM-agnostic)
│   ├── tdd.md
│   ├── linting.md
│   ├── type-checking.md
│   ├── dependency-audit.md
│   ├── adr.md
│   ├── readme-gen.md
│   ├── openapi-lint.md
│   ├── changelog.md
│   ├── commit-msg.md
│   └── env-setup.md
│
├── targets/
│   ├── claude-code/                 ← v1.0 default target
│   │   ├── adapter.sh               ← target-specific install logic
│   │   ├── CLAUDE.md.template
│   │   ├── CONVENTIONS.md.template
│   │   ├── AGENTS.md.template
│   │   ├── settings.json.template
│   │   └── README.md
│   ├── openai/                      ← v2.0 stub
│   │   └── README.md
│   └── gemini/                      ← v3.0 stub
│       └── README.md
│
├── session/
│   ├── SCRATCHPAD.md.template
│   ├── DECISIONS.md.template
│   └── HANDOFF.md.template
│
├── hooks/
│   └── pre-commit
│
├── tests/
│   ├── test_install.sh
│   ├── test_hooks.sh
│   └── fixtures/
│       ├── python-project/
│       ├── typescript-project/
│       └── cpp-project/
│
├── rig                              ← main CLI entrypoint (bash)
├── README.md
├── CHANGELOG.md
└── .gitignore
```

---

## 4. CLI Specification

### 4.1 Entrypoint

`rig` is a bash script located at the repo root, made executable with `chmod +x`. It is designed to be invoked from the target project root, with the path to the Rig repo either in `$PATH` or referenced directly.

```bash
# Invocation patterns
rig <command> [options]
```

### 4.2 Commands

#### `rig install`

Bootstraps the current working directory as an AI-assisted project.

```
rig install [--target <name>] [--force] [--dry-run] [--no-hooks] [--no-context-manager]
```

| Flag | Default | Description |
|---|---|---|
| `--target` | `claude-code` | Target LLM tool adapter to use |
| `--force` | false | Overwrite existing config files (CLAUDE.md, CONVENTIONS.md, AGENTS.md) |
| `--dry-run` | false | Print what would be installed without writing any files |
| `--no-hooks` | false | Skip git hook installation |
| `--no-codebase-index` | false | Skip codebase context index initialisation (`ccindex init`) |

#### `rig list`

Prints all available agents and skills with their descriptions. No flags.

#### `rig version`

Prints the current Rig version.

#### `rig help`

Prints usage information.

### 4.3 Exit Codes

| Code | Meaning |
|---|---|
| 0 | Success |
| 1 | General error |
| 2 | Prerequisite not met (no `.git/`, missing dependency) |
| 3 | Target not found |
| 4 | Codebase index initialisation failed |

### 4.4 Output Format

All output goes to stdout. Errors go to stderr. Each install step is printed as it completes:

```
[rig] Installing for target: claude-code
[rig] ✓ Agents copied       → .claude/agents/ (7 files)
[rig] ✓ Skills copied        → .claude/skills/ (10 files)
[rig] ✓ Config written       → CLAUDE.md (new)
[rig] ✓ Config written       → CONVENTIONS.md (new)
[rig] ✓ Config written       → AGENTS.md (new)
[rig] ✓ Config written       → .claude/settings.json (new)
[rig] ✓ Session templates    → . (3 files)
[rig] ✓ Git hook installed   → .git/hooks/pre-commit
[rig] ✓ Codebase index       → initialised (.codebase-context/)
[rig] Done. 7 agents, 10 skills, 4 config files, 3 session templates.
```

Skipped files are reported as:

```
[rig] ~ Skipped              → CLAUDE.md (already exists, use --force to overwrite)
```

---

## 5. Install Logic

### 5.1 Pre-flight Checks

Before any file operations, `rig install` validates:

1. Current directory contains a `.git/` folder — abort with exit code 2 if not
2. Target adapter exists under `targets/<name>/` — abort with exit code 3 if not
3. `adapter.sh` is executable in the target directory — abort with exit code 1 if not

### 5.2 Install Sequence

Steps execute in order. Failure in any step (except context manager) halts execution and prints an error.

```
1. Run pre-flight checks
2. Load target adapter (source targets/<target>/adapter.sh)
3. Create target directories if they do not exist
4. Copy agents/   → $AGENT_INSTALL_PATH
5. Copy skills/   → $SKILL_INSTALL_PATH
6. Write config templates → project root (skip or overwrite per --force)
7. Copy session templates → project root (always overwrite — these are per-session files)
8. Append .gitignore entries
9. Install pre-commit hook (skip if --no-hooks)
10. Run ccindex init (skip if --no-codebase-index; exit 4 on failure)
11. Print summary
```

### 5.3 Safe-copy Rules

| File type | Behaviour without `--force` | Behaviour with `--force` |
|---|---|---|
| Agent `.md` files | Always overwrite (versioned content, not user-edited) | Always overwrite |
| Skill `.md` files | Always overwrite | Always overwrite |
| `CLAUDE.md` | Skip if exists | Overwrite |
| `CONVENTIONS.md` | Skip if exists | Overwrite |
| `AGENTS.md` | Skip if exists | Overwrite |
| `settings.json` | Skip if exists | Overwrite |
| Session templates | Always overwrite | Always overwrite |

Rationale: agent and skill files are versioned prompt content owned by Rig. Config files are user-customised per project and must not be clobbered silently.

---

## 6. Component Specifications

### 6.1 Agent Files

Each file in `agents/` is a Claude Code subagent prompt. All agent files follow this structure:

```markdown
---
version: 1.0.0
updated: YYYY-MM-DD
changelog:
  - 1.0.0: initial version
---

# <Agent Name>

## Role
One paragraph describing what this agent is and what it is responsible for.

## Inputs
What the agent reads before starting work. May include files, HANDOFF.md blocks,
user instructions, or project context.

## Process
Step-by-step description of what the agent does. Written as instructions to the
model, not as documentation. Use imperative voice.

## Outputs
What the agent produces. List all files written, their locations, and their formats.

## Handoff
What the agent must write to HANDOFF.md when it finishes. Specifies the exact
fields and their expected content.

## Do Not
Explicit list of behaviours this agent must never exhibit. At least 3 items.
```

**Versioning convention:** semver applied to the prompt content itself.
- Patch: wording fix with no behavioural change
- Minor: new output field or modified process step
- Major: fundamental change to role, inputs, or output format

### 6.2 Skill Files

Each file in `skills/` is a Claude Code skill prompt. Skills are invoked by agents or directly by the user. Skill files follow this structure:

```markdown
---
version: 1.0.0
updated: YYYY-MM-DD
changelog:
  - 1.0.0: initial version
---

# <Skill Name>

## Purpose
One sentence description.

## Trigger
When and how this skill should be invoked. Describes both explicit invocation
(user request) and implicit invocation (by an agent or hook).

## Language Support
List of supported languages and the specific tool used for each:
- Python: <tool>
- TypeScript: <tool>
- C/C++: <tool>

## Process
Step-by-step instructions for executing the skill.

## Output Format
What the skill produces. If it writes a file, specify the path and format.
If it returns inline output, describe the structure.

## Error Handling
What to do when the tool is not installed, the check fails, or the output
is ambiguous.
```

### 6.3 Session Templates

#### `SCRATCHPAD.md.template`

```markdown
# Scratchpad — <session date>

**Agent:** <agent name>
**Task:** <one-line task description>
**Started:** <timestamp>

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

#### `DECISIONS.md.template`

```markdown
# Decisions — <session date>

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

#### `HANDOFF.md.template`

```markdown
# Handoff Log

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

### 6.4 Config Templates (Claude Code target)

#### `CLAUDE.md.template`

Top-level instruction file read automatically by Claude Code on every session. Template includes:

- Project name and one-line description (placeholder)
- Language and toolchain (placeholder)
- Pointer to `CONVENTIONS.md` for coding rules
- Pointer to `AGENTS.md` for agent registry
- Standard operating procedure: always read `HANDOFF.md` at session start if it exists
- Standard operating procedure: always write to `SCRATCHPAD.md` during work
- Standard operating procedure: always append to `HANDOFF.md` at session end

#### `CONVENTIONS.md.template`

Coding conventions file. Template includes placeholder sections for:

- Naming conventions (files, variables, functions, classes, constants)
- File and directory structure rules
- Error handling patterns
- Logging conventions
- Preferred libraries and their approved use cases
- Dependency rules (what is never to be added without review)
- Explicit "never do" list with at least 5 default entries:
  - Never hardcode secrets or credentials
  - Never use broad exception catches without logging
  - Never commit commented-out code
  - Never add a dependency without updating `env-setup`
  - Never use `any` type (TypeScript) or equivalent type erasure
- Branch naming format: `<type>/<short-description>` (e.g. `feat/add-auth`, `fix/null-pointer`)
- Commit message format: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, etc.)

#### `AGENTS.md.template`

Human-readable agent registry. One section per agent with:

- Agent name
- Role summary
- When to invoke
- Expected input
- Expected output
- Files it writes

#### `settings.json.template`

Claude Code permissions baseline:

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
        "npm audit"
      ]
    }
  }
}
```

### 6.5 Git Hook — `pre-commit`

Shell script installed to `.git/hooks/pre-commit`. Executable.

**Language detection logic:**

```
if package.json exists         → TypeScript/JavaScript project
elif pyproject.toml or setup.py exists → Python project
elif CMakeLists.txt or Makefile exists → C/C++ project
else                           → unknown, skip checks and warn
```

**Check sequence:**

1. Detect language
2. Run linter for detected language (see table below)
3. If linter exits non-zero: print output, abort commit
4. Run type checker for detected language
5. If type checker exits non-zero: print output, abort commit
6. Exit 0

| Language | Linter | Type Checker |
|---|---|---|
| Python | `ruff check .` | `mypy .` |
| TypeScript | `eslint .` | `tsc --noEmit` |
| C/C++ | `clang-tidy` (if available) | compiler warnings via `make` or `cmake --build` |

**If a tool is not installed:** print a warning and skip that check. Do not abort the commit for a missing tool — only abort for a failing check.

**Performance target:** complete in under 10 seconds on a typical project. If checks exceed 15 seconds, print a warning suggesting `--no-verify` for speed-sensitive workflows.

---

## 7. Target Adapter Interface

Each adapter under `targets/<name>/` must implement the following interface so that `rig` can call it generically.

### 7.1 Required File: `adapter.sh`

Sourced by `rig` before the install sequence. Must export these variables:

```bash
ADAPTER_NAME="claude-code"           # display name
AGENT_INSTALL_PATH=".claude/agents"  # where to copy agents/
SKILL_INSTALL_PATH=".claude/skills"  # where to copy skills/
CONFIG_FILES=(                       # list of template → destination pairs
  "CLAUDE.md.template:CLAUDE.md"
  "CONVENTIONS.md.template:CONVENTIONS.md"
  "AGENTS.md.template:AGENTS.md"
  "settings.json.template:.claude/settings.json"
)
```

Must implement these functions:

```bash
adapter_pre_install()   # called before file copy; any target-specific setup
adapter_post_install()  # called after file copy; any target-specific finalisation
adapter_validate()      # returns 0 if target tool is installed, 1 if not
```

### 7.2 Adapter Validation

`adapter_validate()` checks whether the target tool is available on the system. For Claude Code it checks for the `claude` binary. If validation fails, `rig` prints a warning but does not abort — the files are still installed since the project may be shared with others who have the tool.

### 7.3 Adding a New Target

To add support for a new LLM tool:

1. Create `targets/<name>/` directory
2. Write `adapter.sh` implementing the interface above
3. Write config templates in the tool's native format
4. Write `targets/<name>/README.md` documenting:
   - How agent invocation differs from Claude Code
   - Any prompt syntax changes required
   - Known compatibility issues with canonical agent files
5. Add target to the `rig list-targets` output

---

## 8. Codebase Context MCP Integration

The codebase context MCP is an external component providing shared codebase knowledge across agents. Storage is ChromaDB (PersistentClient) at `.codebase-context/chroma/`. Rig does not own or modify it.

### 8.1 What It Provides

Three MCP tools exposed to agents:

- `search_codebase` — semantic vector search over code symbols
- `get_symbol` — exact symbol lookup by name
- `get_repo_map` — compact file/class/function outline

The repo map is also injected into every session via `CLAUDE.md` using `@.codebase-context/repo_map.md`.

### 8.2 Invocation

During `rig install`, after all file copies and hook installation, Rig invokes:

```bash
ccindex init
```

If this command is not found or exits non-zero, Rig prints an error and exits with code 4. The `--no-codebase-index` flag skips this step entirely.

### 8.3 Gitignore

The ChromaDB directory is local and must not be committed. Rig appends this entry during install:

```
.codebase-context/chroma/
```

### 8.4 Contract

Rig requires only that `ccindex init` is available on `$PATH` and exits 0 on success.

---

## 9. Prompt Versioning

All agent and skill files carry a YAML front matter block as the first element of the file:

```yaml
---
version: 1.0.0
updated: YYYY-MM-DD
changelog:
  - 1.0.0: initial version
---
```

**Semver rules for prompts:**

| Change type | Version bump | Example |
|---|---|---|
| Typo or wording fix with no behavioural change | Patch | 1.0.0 → 1.0.1 |
| New output field, new process step, extended scope | Minor | 1.0.0 → 1.1.0 |
| Changed role definition, removed output, new required input | Major | 1.0.0 → 2.0.0 |

**Rig version vs prompt versions:** Rig carries its own semver in `rig --version`. Prompt versions are independent. A single Rig release may contain prompts at different versions.

---

## 10. Testing Strategy

### 10.1 Test Structure

Tests live in `tests/`. All test files are bash scripts using a minimal assertion library defined in `tests/lib.sh`.

```
tests/
├── lib.sh                    ← assert_eq, assert_file_exists, assert_exit_code helpers
├── test_install.sh           ← install command integration tests
├── test_hooks.sh             ← pre-commit hook unit tests
└── fixtures/
    ├── python-project/       ← minimal Python project with pyproject.toml
    ├── typescript-project/   ← minimal TS project with package.json and tsconfig.json
    └── cpp-project/          ← minimal C++ project with CMakeLists.txt
```

### 10.2 Test Cases — `rig install`

| Test | Description | Expected result |
|---|---|---|
| fresh-install-python | Run `rig install` in a clean Python fixture | All agents, skills, config, session, hook installed; exit 0 |
| fresh-install-typescript | Run `rig install` in a clean TS fixture | All agents, skills, config, session, hook installed; exit 0 |
| fresh-install-cpp | Run `rig install` in a clean C++ fixture | All agents, skills, config, session, hook installed; exit 0 |
| skip-existing-config | Run `rig install` where CLAUDE.md already exists | CLAUDE.md not overwritten; warning printed; exit 0 |
| force-overwrite | Run `rig install --force` where CLAUDE.md exists | CLAUDE.md overwritten; exit 0 |
| dry-run | Run `rig install --dry-run` | No files written; install plan printed; exit 0 |
| no-git-repo | Run `rig install` in directory with no `.git/` | Error printed; exit 2 |
| unknown-target | Run `rig install --target nonexistent` | Error printed; exit 3 |
| no-hooks | Run `rig install --no-hooks` | All files installed; hook not installed; exit 0 |
| no-codebase-index | Run `rig install --no-codebase-index` | All files installed; ccindex not invoked; exit 0 |

### 10.3 Test Cases — `pre-commit` hook

| Test | Description | Expected result |
|---|---|---|
| python-clean | Commit in Python project with clean linting and types | Hook exits 0, commit proceeds |
| python-lint-fail | Commit in Python project with ruff violations | Hook exits 1, error output printed, commit blocked |
| python-type-fail | Commit in Python project with mypy errors | Hook exits 1, error output printed, commit blocked |
| typescript-clean | Commit in TS project with clean lint and tsc | Hook exits 0 |
| typescript-lint-fail | Commit in TS project with eslint violations | Hook exits 1 |
| missing-tool | Commit when ruff is not installed | Warning printed; hook exits 0 (missing tool is not blocking) |
| unknown-language | Commit in project with no recognised language marker | Warning printed; hook exits 0 |

### 10.4 Running Tests

```bash
# Run all tests
bash tests/test_install.sh
bash tests/test_hooks.sh

# Run with verbose output
RIG_TEST_VERBOSE=1 bash tests/test_install.sh
```

---

## 11. Error Handling

### 11.1 `rig install` Errors

All errors print a clear message to stderr with the prefix `[rig] ERROR:` and a hint for resolution where applicable.

```
[rig] ERROR: No .git directory found in current path.
             Initialise a git repository first: git init

[rig] ERROR: Target 'foobar' not found. Available targets: claude-code
             Run `rig list-targets` for details.

[rig] ERROR: Context manager install failed (exit code 1).
             Check context-manager/install.sh output above.
             Use --no-context-manager to skip this step.
```

### 11.2 `pre-commit` Hook Errors

The hook prints directly to the terminal. Format:

```
[rig:pre-commit] Running Python checks...
[rig:pre-commit] ✗ ruff: 3 violations found

<ruff output here>

[rig:pre-commit] Commit blocked. Fix linting errors and try again.
                 To skip checks: git commit --no-verify
```

---

## 12. `.gitignore` Template

The following entries must be added to the project's `.gitignore` during install (appended, not overwritten):

```
# Rig session files — ephemeral, not committed
SCRATCHPAD.md

# Codebase context — local vector DB, not committed
.codebase-context/chroma/
```

`HANDOFF.md` and `DECISIONS.md` are committed to git — they are the cross-session, cross-machine context persistence layer.

---

## 13. Agent Interaction Flows

### 13.1 New Feature Flow

```
User → planner (produces TASKS.md)
     → architect (produces ARCHITECT_OUTPUT.md, updates HANDOFF.md)
     → code-writer (implements, updates HANDOFF.md)
     → code-reviewer (reviews diff, updates HANDOFF.md)
     → docs-writer (updates docs, updates HANDOFF.md)
     → security-auditor (final check before merge)
```

### 13.2 Bug Fix Flow

```
User → debugger (produces root cause analysis, updates HANDOFF.md)
     → code-writer (implements fix, updates HANDOFF.md)
     → code-reviewer (reviews fix)
```

### 13.3 Session Start Protocol (all agents)

Every agent, at the start of every session, must:

1. Run `git pull` to ensure `HANDOFF.md` and `DECISIONS.md` are current
2. Read `HANDOFF.md` if it exists — identify the most recent block and its instructions
3. Read `CONVENTIONS.md` — load project rules
4. Read relevant source files as needed
5. Write session header to `SCRATCHPAD.md`

### 13.4 Session End Protocol (all agents)

Every agent, before ending a session, must:

1. Finalise `SCRATCHPAD.md` with a session summary
2. Append a completed block to `HANDOFF.md`
3. Record any non-trivial decisions to `DECISIONS.md`
4. Commit `HANDOFF.md` and `DECISIONS.md` and push: `git add HANDOFF.md DECISIONS.md && git commit -m "handoff: <agent> completed <task>" && git push`

---

## 14. File Format Reference

| File | Format | Owner | Committed |
|---|---|---|---|
| `agents/*.md` | Markdown with YAML front matter | Rig | Yes (in Rig repo) |
| `skills/*.md` | Markdown with YAML front matter | Rig | Yes (in Rig repo) |
| `CLAUDE.md` | Markdown | User (from template) | Yes |
| `CONVENTIONS.md` | Markdown | User (from template) | Yes |
| `AGENTS.md` | Markdown | User (from template) | Yes |
| `.claude/settings.json` | JSON | User (from template) | Yes |
| `SCRATCHPAD.md` | Markdown | Agent (session) | No |
| `DECISIONS.md` | Markdown | Agent (session) | Yes |
| `HANDOFF.md` | Markdown | Agent (session) | Yes |
| `TASKS.md` | Markdown | planner agent | Yes |
| `ARCHITECT_OUTPUT.md` | Markdown | architect agent | Yes |
| `docs/decisions/*.md` | Markdown | adr skill | Yes |
| `CHANGELOG.md` | Markdown (Keep a Changelog) | changelog skill | Yes |
| `.env.example` | dotenv | env-setup skill | Yes |

---

## 15. Open Questions

- Should `rig` be a bash script (zero dependencies, maximum portability) or a Python CLI (richer arg parsing, better testability)? **Decision deferred. Start with bash for v1.0; revisit if argument complexity grows.**
- Should session files (SCRATCHPAD, DECISIONS, HANDOFF) be per-session (wiped on each `rig install`) or accumulated? **Decision: SCRATCHPAD.md wiped on install (ephemeral). HANDOFF.md and DECISIONS.md committed to git and accumulated — they are the cross-session context persistence layer.**
- Should `rig` support updating existing installs (`rig update`) that refreshes only agent and skill files while preserving user config? **Out of scope for v1.0. Log as v1.1 feature.**
- Should `ccindex init` be a hard requirement or optional? **Optional via `--no-codebase-index`. Missing `ccindex` binary is a warning, not an error — exit code 4 only on failed execution, not on missing binary.**
