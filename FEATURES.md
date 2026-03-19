# Rig — Pending Features & Bugs

> Structured backlog of planned functionality and confirmed bugs.
> Status values: `planned` | `in-progress` | `done`.

---

## Schema

Features use the `F-NNN` prefix. Bugs use the `B-NNN` prefix.

```
### [F|B]-NNN — <Title>

**Type:** feature | bug
**Status:** planned | in-progress | done
**Priority:** P0 (blocking) | P1 (high) | P2 (medium) | P3 (low)
**Target version:** vX.Y
**Source:** <spec section, open question, or discovery note>

#### Problem
What is currently broken or missing, and why it matters.

#### Expected behaviour
What the system should do once this is fixed or implemented.

#### Implementation notes
Concrete steps, files to change, and any known constraints.
```

---

## Bugs

### B-001 — `install` overwrites HANDOFF.md and DECISIONS.md, destroying session history

**Type:** bug
**Status:** done
**Priority:** P0
**Target version:** v1.1
**Source:** Spec §5.3 vs §12 contradiction; discovered 2026-03-18

#### Problem
`rig-stage install` (and therefore `rig-stage upgrade`) always overwrites all three session template files — `SCRATCHPAD.md`, `HANDOFF.md`, and `DECISIONS.md` — by copying the blank templates over them unconditionally (rig-stage lines 191–200).

This is correct for `SCRATCHPAD.md`, which is ephemeral and gitignored. It is destructive for `HANDOFF.md` and `DECISIONS.md`, which spec §12 explicitly states are committed to git and accumulate across sessions as the cross-session context persistence layer. Running `rig-stage upgrade` silently wipes the entire agent handoff history.

The spec contradicts itself: §5.3 groups all three as "always overwrite", while §12 and §14 treat HANDOFF.md and DECISIONS.md as persistent committed files.

#### Expected behaviour
| File | Correct behaviour |
|---|---|
| `SCRATCHPAD.md` | Always overwrite — ephemeral, gitignored |
| `HANDOFF.md` | Skip if exists — accumulates across sessions |
| `DECISIONS.md` | Skip if exists — accumulates across sessions |

#### Implementation notes
- In `rig-stage` step 7, split the session template loop into two cases: always-overwrite for `SCRATCHPAD.md.template`, skip-if-exists for `HANDOFF.md.template` and `DECISIONS.md.template`.
- Apply the same `[[ -f "$dest" ]]` guard used for config files (step 6).
- `--force` should not override this — HANDOFF.md and DECISIONS.md should never be silently wiped, even with `--force`. Document this explicitly.
- Update spec §5.3 table to reflect the corrected per-file behaviour.

---

## Backlog

### F-001 — Auto-populate CLAUDE.md placeholders after install

**Status:** done
**Priority:** P1
**Target version:** v1.1
**Source:** Spec §6.4; discovered during session 2026-03-18

#### Problem
`rig-stage install` copies `CLAUDE.md.template` to `CLAUDE.md` with a plain `cp`, leaving all `<...>` placeholders verbatim. The project name, language/toolchain, and description are never filled in. Users must edit the file manually after every fresh install.

#### Expected behaviour
After copying the template, `rig-stage install` detects project metadata and substitutes known placeholders before writing the file:

| Placeholder | Detection strategy |
|---|---|
| `<Project Name>` | `name` field in `pyproject.toml` or `package.json`; fallback to `basename $(pwd)` |
| `<language and primary tools>` | Presence of `pyproject.toml` → Python + ruff/mypy; `package.json` → TypeScript/JS + eslint/tsc; `CMakeLists.txt` or `Makefile` → C/C++ + clang-tidy |
| `<what this project does>` | First non-empty line of `README.md` after the `#` heading; fallback to empty string with a comment prompt |

Placeholders that cannot be auto-detected are left as-is so the user knows what still needs filling.

#### Implementation notes
- Add a `substitute_placeholders()` function in `rig-stage` that runs `sed -i` passes after the `cp` in step 6 of the install sequence.
- Reuse the language detection logic already in `hooks/pre-commit` — extract it to a shared helper or duplicate the three-condition check.
- Only substitute in `CLAUDE.md`; other config templates (`CONVENTIONS.md`, `AGENTS.md`) have no auto-detectable placeholders.
- Must not run in `--dry-run` mode (print what would be substituted instead).

---

### F-002 — `rig-stage list-targets` subcommand

**Status:** done
**Priority:** P2
**Target version:** v1.1
**Source:** Spec §7.3

#### Problem
The spec states that adding a new target requires adding it to the `rig-stage list-targets` output, but the subcommand does not exist. The current `rig-stage list` only shows agents and skills. There is no way to discover available targets from the CLI.

#### Expected behaviour
`rig-stage list-targets` prints all directories under `targets/` that contain an `adapter.sh`, along with their `ADAPTER_NAME` and a one-line description sourced from `targets/<name>/README.md`.

```
Available targets:
  claude-code   Claude Code (default)
  openai        OpenAI Codex (stub — not yet implemented)
  gemini        Google Gemini CLI (stub — not yet implemented)
```

#### Implementation notes
- Add `cmd_list_targets()` in `rig-stage` and wire it to the `list-targets` case in the dispatch block.
- Source each `adapter.sh` in a subshell to read `ADAPTER_NAME` safely without polluting the parent environment.
- Extract the description from the first non-heading line of the target's `README.md`.
- Update `usage()` to document the new subcommand.

---

### F-003 — `rig-stage update` — refresh agents/skills without clobbering user config

**Status:** done
**Priority:** P2
**Target version:** v1.1
**Source:** Spec §15 open questions

#### Problem
`rig-stage upgrade` pulls the latest Rig source and then calls `install --force`, which overwrites user-edited config files (`CLAUDE.md`, `CONVENTIONS.md`, `AGENTS.md`, `settings.json`). There is no way to pull updated agent and skill prompts without risking loss of project-specific customisations.

#### Expected behaviour
`rig-stage update` refreshes only the files that Rig owns and versions (agent `.md` files, skill `.md` files) while leaving all config files untouched regardless of `--force`.

```
[rig-stage] Updating agents and skills only (config files preserved)...
[rig-stage] ✓ Agents updated  → .claude/agents/ (9 files)
[rig-stage] ✓ Skills updated  → .claude/skills/ (10 files)
[rig-stage] ~ Skipped         → CLAUDE.md (user config — use install --force to overwrite)
```

#### Implementation notes
- Add `cmd_update()` in `rig-stage` that runs steps 4–5 of the install sequence (copy agents and skills) but skips step 6 (config templates) unconditionally.
- Accepts `--target` flag; defaults to `claude-code`.
- `rig-stage upgrade` should call `update` instead of `install --force` so that pulling a new Rig version does not destroy user config.

---

### F-004 — OpenAI target adapter

**Status:** planned
**Priority:** P3
**Target version:** v2.0
**Source:** Spec §7; stub at `targets/openai/`

#### Problem
The `targets/openai/` directory contains only a `README.md` stub. No `adapter.sh` or config templates exist. `rig-stage install --target openai` exits with error code 1 (missing `adapter.sh`).

#### Expected behaviour
`rig-stage install --target openai` fully installs agent and skill prompts adapted for the OpenAI Codex/Assistants tooling, with appropriate config file equivalents for that platform.

#### Implementation notes
- Requires research into OpenAI's equivalent of `CLAUDE.md`, agent invocation conventions, and tool permission config format.
- Define the adapter interface variables and functions per Spec §7.1.
- Agent and skill `.md` content is LLM-agnostic and can be reused; only config templates and `adapter.sh` are target-specific.

---

### F-005 — Gemini CLI target adapter

**Status:** planned
**Priority:** P3
**Target version:** v3.0
**Source:** Spec §7; stub at `targets/gemini/`

#### Problem
The `targets/gemini/` directory contains only a `README.md` stub. No `adapter.sh` or config templates exist. `rig-stage install --target gemini` exits with error code 1 (missing `adapter.sh`).

#### Expected behaviour
`rig-stage install --target gemini` fully installs agent and skill prompts adapted for the Gemini CLI tooling.

#### Implementation notes
- Same adapter interface contract as F-004.
- Gemini uses `GEMINI.md` as its equivalent of `CLAUDE.md`; config template must match that convention.
- Skill invocation syntax differs from Claude Code — document in `targets/gemini/README.md`.

---

### F-006 — Auto-load session files via `@file` imports in CLAUDE.md template

**Status:** done
**Priority:** P0
**Target version:** v1.1
**Source:** Discovered 2026-03-18 — session files never enter context

#### Problem
`HANDOFF.md`, `CONVENTIONS.md`, and `AGENTS.md` are referenced only in prose instructions inside `CLAUDE.md.template`. Claude Code auto-loads files referenced with `@filename` syntax at session start, but plain text instructions require Claude to act proactively before the user's first message — which it does not do. As a result, all three files are ignored every session regardless of their content.

The repo map works correctly because it uses `@.codebase-context/repo_map.md`. The session files do not.

#### Expected behaviour
At session start, Claude automatically has the content of `HANDOFF.md`, `CONVENTIONS.md`, and `AGENTS.md` in its context without any user prompt. It reads the most recent handoff block and loads project conventions before responding to anything.

#### Implementation notes
- Add `@HANDOFF.md`, `@CONVENTIONS.md`, and `@AGENTS.md` to `targets/claude-code/CLAUDE.md.template` using the same `@filename` syntax as the repo map reference.
- Place them near the top of the file, after the repo map line, so they are the first things loaded.
- `SCRATCHPAD.md` should not be imported — it is write-only at session start (handled by F-007).
- `DECISIONS.md` does not need to be imported at session start — it is written to at session end, not read at start.
- Guard the `@HANDOFF.md` import: if the file does not yet exist (fresh install), Claude Code silently ignores missing `@file` references, so no special handling is needed.

---

### F-007 — Session-start hook in `settings.json.template`

**Status:** done
**Priority:** P0
**Target version:** v1.1
**Source:** Discovered 2026-03-18 — `git pull` and SCRATCHPAD.md write never execute

#### Problem
The session protocol requires two actions that cannot be handled by `@file` imports — they require shell execution:

1. `git pull` to sync `HANDOFF.md` and `DECISIONS.md` before reading them
2. Writing a session header to `SCRATCHPAD.md`

The `settings.json.template` has no hooks configured. There is no mechanism in the current install that causes these steps to run automatically. The session protocol in `CLAUDE.md` is advisory text that Claude ignores in practice.

#### Expected behaviour
On session start (before the user's first prompt is processed), a hook:
1. Runs `git pull --ff-only` to sync the repo
2. Writes a dated session header to `SCRATCHPAD.md` if one does not already exist for today

#### Implementation notes
- Add a `hooks` block to `settings.json.template` using Claude Code's `UserPromptSubmit` hook type. This fires before the first user prompt is processed.
- The hook script should be a small bash one-liner or reference a script in `.claude/hooks/session-start.sh` installed by the adapter.
- `git pull` should use `--ff-only` to avoid silent merges that could corrupt `HANDOFF.md`.
- The SCRATCHPAD.md header write should be idempotent — check if today's date already appears in the file before writing.
- Add `session-start.sh` as a file copied by `adapter.sh` during install.
- `git` must already be in `allowedCommands` (it is); no permissions change needed.

---

### F-008 — OpenSpec: project directory initialisation

**Type:** feature
**Status:** planned
**Priority:** P1
**Target version:** v1.2
**Source:** OpenSpec spec; https://github.com/Fission-AI/OpenSpec

#### Problem
Rig has no mechanism to scaffold the `openspec/` directory tree that OpenSpec commands expect to exist. Running any `opsx:*` skill on a fresh project fails because neither `openspec/specs/` nor `openspec/changes/` exist.

#### Expected behaviour
`rig-stage install` (or a new `rig-stage openspec-init` subcommand) creates the following skeleton when the user opts in:

```
openspec/
├── specs/           # Living source-of-truth; one subdirectory per domain
├── changes/         # One subdirectory per in-flight change
│   └── archive/     # Completed changes land here after /opsx:archive
└── config.yaml      # Optional project-level OpenSpec configuration
```

`config.yaml` is written from a template with sensible defaults (schema profile, archive date format).

#### Implementation notes
- Add `openspec-init` subcommand to `rig-stage` that creates the tree and copies `config.yaml.template`.
- Wire it into `install` behind an `--openspec` flag so existing installs are unaffected.
- Add `openspec/changes/archive/` to `.gitignore` if the user wants archives excluded; leave `openspec/specs/` tracked.
- Template: `targets/claude-code/openspec/config.yaml.template`.

---

### F-009 — OpenSpec: `opsx-propose` skill

**Type:** feature
**Status:** planned
**Priority:** P1
**Target version:** v1.2
**Source:** OpenSpec core profile; `/opsx:propose`

#### Problem
There is no Rig skill that initiates a spec-driven change. Without `/opsx:propose`, the OpenSpec workflow cannot start — the change folder and its four required artifacts (`proposal.md`, `specs/`, `design.md`, `tasks.md`) are never created.

#### Expected behaviour
Invoking `/opsx:propose <feature-name>` (or the trigger phrase "propose a change for…"):

1. Creates `openspec/changes/<feature-name>/` with four artifacts in dependency order:
   - `proposal.md` — rationale, scope, problem statement, capability inventory
   - `specs/<domain>.md` — delta spec using ADDED / MODIFIED / REMOVED sections with RFC 2119 language
   - `design.md` — technical decisions, alternatives, risks, migration plan (omitted for trivial changes)
   - `tasks.md` — implementation checklist as `- [ ]` items grouped by dependency order
2. Prints a summary of what was created and suggests `/opsx:apply` as the next step.

#### Implementation notes
- Skill file: `.claude/skills/opsx-propose.md`
- Trigger: `opsx:propose`, "propose a change", "new openspec change"
- Artifact schema: requirements in specs use SHALL/MUST/SHOULD; scenarios use Given/When/Then under `####` headings (four hashtags exactly)
- The dependency chain `proposal → specs → design → tasks` must be respected; each step reads its predecessor before writing

---

### F-010 — OpenSpec: `opsx-explore` skill

**Type:** feature
**Status:** planned
**Priority:** P2
**Target version:** v1.2
**Source:** OpenSpec core profile; `/opsx:explore`

#### Problem
When requirements are unclear or the codebase is unfamiliar, jumping straight to `/opsx:propose` produces shallow proposals. There is no Rig skill for the investigative phase that precedes requirement writing.

#### Expected behaviour
`/opsx:explore` (triggered by "explore before proposing" or "investigate this area"):

1. Reads existing `openspec/specs/` to surface relevant prior requirements
2. Analyses the codebase for affected modules, existing patterns, and integration points
3. Outputs a structured exploration report covering: current behaviour, open questions, risks, and suggested scope for the proposal
4. Does **not** create any files — output is conversational, feeding into a subsequent `/opsx:propose`

#### Implementation notes
- Skill file: `.claude/skills/opsx-explore.md`
- Uses `search_codebase` and `get_repo_map` MCP tools when available
- Output is Markdown printed to the conversation — no file writes
- Skill preamble must state: "Do not write any specs or tasks yet; this is analysis only"

---

### F-011 — OpenSpec: `opsx-apply` skill

**Type:** feature
**Status:** planned
**Priority:** P1
**Target version:** v1.2
**Source:** OpenSpec core profile; `/opsx:apply`

#### Problem
After a change folder is created by `/opsx:propose`, there is no skill to read `tasks.md` and drive implementation. Without `/opsx:apply`, the spec-to-code link is manual and the checklist goes unused.

#### Expected behaviour
`/opsx:apply` (triggered by "apply the openspec tasks" or "implement the change"):

1. Locates the active change folder (most recently modified, or disambiguates if multiple are open)
2. Reads `tasks.md` and works through unchecked items in dependency order
3. After each completed task, updates the `- [ ]` to `- [x]` in `tasks.md`
4. Respects existing Rig skills (TDD, code-review) during implementation — does not bypass them
5. On completion, prints a summary and suggests `/opsx:verify`

#### Implementation notes
- Skill file: `.claude/skills/opsx-apply.md`
- Active change detection: scan `openspec/changes/` for directories without a date-prefixed name (not yet archived)
- Task parsing: read `- [ ]` lines; skip `- [x]` lines
- Integrates with `superpowers:test-driven-development` skill — invoke TDD workflow per task
- Does not modify `specs/` or `proposal.md`; only touches source files and `tasks.md`

---

### F-012 — OpenSpec: `opsx-archive` skill

**Type:** feature
**Status:** planned
**Priority:** P1
**Target version:** v1.2
**Source:** OpenSpec core profile; `/opsx:archive`

#### Problem
Completed changes accumulate in `openspec/changes/` with no mechanism to finalise them. Delta specs are never merged into the main `openspec/specs/` tree, so the living spec drifts from actual behaviour over time.

#### Expected behaviour
`/opsx:archive` (triggered by "archive the openspec change" or "finalise this change"):

1. Reads the delta `specs/` inside the active change folder
2. Merges ADDED/MODIFIED/REMOVED sections into the matching files under `openspec/specs/` (creates domain files if absent; removes requirements marked REMOVED)
3. Moves the change folder to `openspec/changes/archive/<YYYY-MM-DD>-<feature-name>/`
4. Prints a merge summary showing which spec files were touched

#### Implementation notes
- Skill file: `.claude/skills/opsx-archive.md`
- Date prefix: ISO 8601 (`YYYY-MM-DD`) sourced from system date
- Merge is additive for ADDED, in-place edit for MODIFIED, deletion for REMOVED
- After move, the skill suggests: `git add openspec/ && git commit -m "spec: archive <feature-name>"`
- Conflict detection: if a requirement ID already exists in main specs as MODIFIED by another in-flight change, surface a warning rather than silently overwriting

---

### F-013 — OpenSpec: `opsx-verify` skill

**Type:** feature
**Status:** planned
**Priority:** P2
**Target version:** v1.2
**Source:** OpenSpec expanded profile; `/opsx:verify`

#### Problem
There is no Rig skill that validates whether an implementation actually satisfies its OpenSpec requirements. The gap between spec and code is invisible until review or production.

#### Expected behaviour
`/opsx:verify` performs three checks and reports pass/fail for each:

| Dimension | What is checked |
|---|---|
| **Completeness** | All `tasks.md` items are `[x]`; all requirements have at least one test covering a scenario |
| **Correctness** | Implementation matches the intent of each SHALL/MUST requirement in `specs/` |
| **Coherence** | Code structure reflects the design decisions in `design.md` (naming, module boundaries, patterns) |

Outputs a structured report. Exits non-zero (for CI use) if any check fails.

#### Implementation notes
- Skill file: `.claude/skills/opsx-verify.md`
- Completeness: mechanical — parse `tasks.md` for unchecked items; grep test files for scenario keywords
- Correctness and Coherence: LLM-driven analysis reading spec, design, and implementation files side by side
- Invokes `superpowers:verification-before-completion` before reporting success

---

### F-014 — OpenSpec: `opsx-ff` fast-forward skill

**Type:** feature
**Status:** planned
**Priority:** P2
**Target version:** v1.2
**Source:** OpenSpec expanded profile; `/opsx:ff`

#### Problem
For small, well-understood features, going through `/opsx:propose` step by step is more ceremony than the change warrants. There is no "batch" path through the artifact pipeline.

#### Expected behaviour
`/opsx:ff <feature-name>` (triggered by "fast-forward openspec" or "opsx ff"):

Runs the full artifact pipeline in one pass — `proposal.md → specs/ → design.md → tasks.md` — without pausing for user review between steps. Prints all four artifacts at the end for review before implementation begins.

#### Implementation notes
- Skill file: `.claude/skills/opsx-ff.md`
- Appropriate only when scope is clear; skill preamble prompts the LLM to assess scope before proceeding
- Internally calls the same logic as `opsx-propose` but batches the writes

---

### F-015 — OpenSpec: `opsx-continue` skill

**Type:** feature
**Status:** planned
**Priority:** P2
**Target version:** v1.2
**Source:** OpenSpec expanded profile; `/opsx:continue`

#### Problem
When a session ends mid-change, the next session has no skill to resume from where the previous session stopped. The user must manually inspect the change folder and figure out which artifact to work on next.

#### Expected behaviour
`/opsx:continue` (triggered by "continue the openspec change" or "resume openspec"):

1. Reads the active change folder
2. Detects the furthest completed artifact (`proposal.md` exists? specs written? `design.md` present? `tasks.md` complete?)
3. Resumes from the next incomplete step
4. If all artifacts exist but tasks remain, delegates to `opsx-apply`

#### Implementation notes
- Skill file: `.claude/skills/opsx-continue.md`
- Detection heuristic: check file existence; for `tasks.md` check for unchecked items
- Prints a one-line status before resuming: "Resuming from: design.md (proposal and specs complete)"

---

### F-016 — OpenSpec: `opsx-bulk-archive` skill

**Type:** feature
**Status:** planned
**Priority:** P3
**Target version:** v1.2
**Source:** OpenSpec expanded profile; `/opsx:bulk-archive`

#### Problem
When multiple changes finish in the same sprint, archiving them one at a time is tedious and risks spec conflicts going undetected until the last archive operation.

#### Expected behaviour
`/opsx:bulk-archive` archives all changes whose `tasks.md` are fully checked, with cross-change conflict detection before writing anything:

1. Scans all non-archived change folders; selects those with all tasks `[x]`
2. Runs conflict analysis on their delta specs (same requirement modified by two changes)
3. Reports conflicts and aborts if any are found; otherwise archives all selected changes in one pass

#### Implementation notes
- Skill file: `.claude/skills/opsx-bulk-archive.md`
- Conflict detection: build a map of `(domain, requirement-id) → [change-name]`; flag any ID appearing in more than one in-flight delta
- Archive order: alphabetical by change name for reproducibility

---

## Status Summary

| ID | Type | Title | Status | Priority | Version |
|---|---|---|---|---|---|
| B-001 | bug | `install` overwrites HANDOFF.md and DECISIONS.md | done | P0 | v1.1 |
| F-001 | feature | Auto-populate CLAUDE.md placeholders | done | P1 | v1.1 |
| F-002 | feature | `list-targets` subcommand | done | P2 | v1.1 |
| F-003 | feature | `update` command (agents/skills only) | done | P2 | v1.1 |
| F-004 | feature | OpenAI target adapter | planned | P3 | v2.0 |
| F-005 | feature | Gemini CLI target adapter | planned | P3 | v3.0 |
| F-006 | feature | Auto-load session files via `@file` imports | done | P0 | v1.1 |
| F-007 | feature | Session-start hook in `settings.json.template` | done | P0 | v1.1 |
| F-008 | feature | OpenSpec: project directory initialisation | planned | P1 | v1.2 |
| F-009 | feature | OpenSpec: `opsx-propose` skill | planned | P1 | v1.2 |
| F-010 | feature | OpenSpec: `opsx-explore` skill | planned | P2 | v1.2 |
| F-011 | feature | OpenSpec: `opsx-apply` skill | planned | P1 | v1.2 |
| F-012 | feature | OpenSpec: `opsx-archive` skill | planned | P1 | v1.2 |
| F-013 | feature | OpenSpec: `opsx-verify` skill | planned | P2 | v1.2 |
| F-014 | feature | OpenSpec: `opsx-ff` fast-forward skill | planned | P2 | v1.2 |
| F-015 | feature | OpenSpec: `opsx-continue` skill | planned | P2 | v1.2 |
| F-016 | feature | OpenSpec: `opsx-bulk-archive` skill | planned | P3 | v1.2 |
