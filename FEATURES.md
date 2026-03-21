# Payload Depot — Pending Features & Bugs

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
`payload-depot install` (and therefore `payload-depot upgrade`) always overwrites all three session template files — `SCRATCHPAD.md`, `HANDOFF.md`, and `DECISIONS.md` — by copying the blank templates over them unconditionally (payload-depot lines 191–200).

This is correct for `SCRATCHPAD.md`, which is ephemeral and gitignored. It is destructive for `HANDOFF.md` and `DECISIONS.md`, which spec §12 explicitly states are committed to git and accumulate across sessions as the cross-session context persistence layer. Running `payload-depot upgrade` silently wipes the entire agent handoff history.

The spec contradicts itself: §5.3 groups all three as "always overwrite", while §12 and §14 treat HANDOFF.md and DECISIONS.md as persistent committed files.

#### Expected behaviour
| File | Correct behaviour |
|---|---|
| `SCRATCHPAD.md` | Always overwrite — ephemeral, gitignored |
| `HANDOFF.md` | Skip if exists — accumulates across sessions |
| `DECISIONS.md` | Skip if exists — accumulates across sessions |

#### Implementation notes
- In `payload-depot` step 7, split the session template loop into two cases: always-overwrite for `SCRATCHPAD.md.template`, skip-if-exists for `HANDOFF.md.template` and `DECISIONS.md.template`.
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
`payload-depot install` copies `CLAUDE.md.template` to `CLAUDE.md` with a plain `cp`, leaving all `<...>` placeholders verbatim. The project name, language/toolchain, and description are never filled in. Users must edit the file manually after every fresh install.

#### Expected behaviour
After copying the template, `payload-depot install` detects project metadata and substitutes known placeholders before writing the file:

| Placeholder | Detection strategy |
|---|---|
| `<Project Name>` | `name` field in `pyproject.toml` or `package.json`; fallback to `basename $(pwd)` |
| `<language and primary tools>` | Presence of `pyproject.toml` → Python + ruff/mypy; `package.json` → TypeScript/JS + eslint/tsc; `CMakeLists.txt` or `Makefile` → C/C++ + clang-tidy |
| `<what this project does>` | First non-empty line of `README.md` after the `#` heading; fallback to empty string with a comment prompt |

Placeholders that cannot be auto-detected are left as-is so the user knows what still needs filling.

#### Implementation notes
- Add a `substitute_placeholders()` function in `payload-depot` that runs `sed -i` passes after the `cp` in step 6 of the install sequence.
- Reuse the language detection logic already in `hooks/pre-commit` — extract it to a shared helper or duplicate the three-condition check.
- Only substitute in `CLAUDE.md`; other config templates (`CONVENTIONS.md`, `AGENTS.md`) have no auto-detectable placeholders.
- Must not run in `--dry-run` mode (print what would be substituted instead).

---

### F-002 — `payload-depot list-targets` subcommand

**Status:** done
**Priority:** P2
**Target version:** v1.1
**Source:** Spec §7.3

#### Problem
The spec states that adding a new target requires adding it to the `payload-depot list-targets` output, but the subcommand does not exist. The current `payload-depot list` only shows agents and skills. There is no way to discover available targets from the CLI.

#### Expected behaviour
`payload-depot list-targets` prints all directories under `targets/` that contain an `adapter.sh`, along with their `ADAPTER_NAME` and a one-line description sourced from `targets/<name>/README.md`.

```
Available targets:
  claude-code   Claude Code (default)
  openai        OpenAI Codex (stub — not yet implemented)
  gemini        Google Gemini CLI (stub — not yet implemented)
```

#### Implementation notes
- Add `cmd_list_targets()` in `payload-depot` and wire it to the `list-targets` case in the dispatch block.
- Source each `adapter.sh` in a subshell to read `ADAPTER_NAME` safely without polluting the parent environment.
- Extract the description from the first non-heading line of the target's `README.md`.
- Update `usage()` to document the new subcommand.

---

### F-003 — `payload-depot update` — refresh agents/skills without clobbering user config

**Status:** done
**Priority:** P2
**Target version:** v1.1
**Source:** Spec §15 open questions

#### Problem
`payload-depot upgrade` pulls the latest Payload Depot source and then calls `install --force`, which overwrites user-edited config files (`CLAUDE.md`, `CONVENTIONS.md`, `AGENTS.md`, `settings.json`). There is no way to pull updated agent and skill prompts without risking loss of project-specific customisations.

#### Expected behaviour
`payload-depot update` refreshes only the files that Payload Depot owns and versions (agent `.md` files, skill `.md` files) while leaving all config files untouched regardless of `--force`.

```
[payload-depot] Updating agents and skills only (config files preserved)...
[payload-depot] ✓ Agents updated  → .claude/agents/ (9 files)
[payload-depot] ✓ Skills updated  → .claude/skills/ (10 files)
[payload-depot] ~ Skipped         → CLAUDE.md (user config — use install --force to overwrite)
```

#### Implementation notes
- Add `cmd_update()` in `payload-depot` that runs steps 4–5 of the install sequence (copy agents and skills) but skips step 6 (config templates) unconditionally.
- Accepts `--target` flag; defaults to `claude-code`.
- `payload-depot upgrade` should call `update` instead of `install --force` so that pulling a new Payload Depot version does not destroy user config.

---

### F-004 — OpenAI target adapter

**Status:** planned
**Priority:** P3
**Target version:** v2.0
**Source:** Spec §7; stub at `targets/openai/`

#### Problem
The `targets/openai/` directory contains only a `README.md` stub. No `adapter.sh` or config templates exist. `payload-depot install --target openai` exits with error code 1 (missing `adapter.sh`).

#### Expected behaviour
`payload-depot install --target openai` fully installs agent and skill prompts adapted for the OpenAI Codex/Assistants tooling, with appropriate config file equivalents for that platform.

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
The `targets/gemini/` directory contains only a `README.md` stub. No `adapter.sh` or config templates exist. `payload-depot install --target gemini` exits with error code 1 (missing `adapter.sh`).

#### Expected behaviour
`payload-depot install --target gemini` fully installs agent and skill prompts adapted for the Gemini CLI tooling.

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

### F-008 — OpenSpec: `payload-depot openspec-init` wrapper

**Type:** feature
**Status:** deferred
**Priority:** P1
**Target version:** v1.3
**Source:** https://github.com/Fission-AI/OpenSpec — reviewed 2026-03-20

> ⚠️ **Implementation approach revised.** Original plan assumed Payload Depot would scaffold the `openspec/` tree itself. After reviewing Fission-AI's docs, the OpenSpec CLI (`@fission-ai/openspec`) already handles this via `openspec init --tools claude`. Payload Depot's role is a thin wrapper, not a reimplementation.

#### Problem
After `payload-depot install`, users have no automated path to set up OpenSpec in their project. They must manually install the `openspec` CLI and run `openspec init --tools claude` themselves.

#### Expected behaviour
`payload-depot openspec-init`:
1. Checks that the `openspec` CLI is installed (`openspec --version`). If not, prints install instructions and exits.
2. Runs `openspec init --tools claude` in the current project directory.
3. Optionally pre-populates `openspec/config.yaml` with project metadata (name, language) detected by the same logic used for CLAUDE.md substitution (F-001).

#### Implementation notes
- Do NOT recreate the directory scaffold ourselves — delegate entirely to `openspec init`.
- Soft dependency: warn and skip if `openspec` is not installed (same pattern as `ccindex`).
- Add `openspec` to the `env-setup` skill as an optional dependency with install instructions.
- Open question: should `--openspec` flag on `install` trigger this automatically, or keep it a standalone subcommand?
- Full open questions documented in `docs/superpowers/plans/2026-03-19-openspec-skills.md`.

---

### F-009 — OpenSpec: register OpenSpec-generated skills in registry

**Type:** feature
**Status:** deferred
**Priority:** P1
**Target version:** v1.3
**Source:** https://github.com/Fission-AI/OpenSpec/blob/main/docs/supported-tools.md — reviewed 2026-03-20

> ⚠️ **Implementation approach revised.** Original plan assumed Payload Depot would write these skills from scratch. After reviewing Fission-AI's docs, `openspec init --tools claude` generates all `/opsx:*` skills automatically into `.claude/skills/openspec-*/SKILL.md`. Payload Depot should register them, not rewrite them.

#### Problem
After `openspec init --tools claude` runs, it installs skills like `.claude/skills/openspec-propose/SKILL.md`. The `payload-depot-skill-check.sh` validator flags these as "unregistered" because they don't appear in `skills/registry.md`.

#### Expected behaviour
`skills/registry.md` includes entries for all OpenSpec-generated skills (propose, explore, apply, archive — core profile minimum). The skill-check does not WARN about them.

#### Implementation notes
- Registry entries point at OpenSpec-generated paths (e.g., `openspec-propose/SKILL.md`), not hand-written files.
- Alternatively, teach `payload-depot-skill-check.sh` to exclude skills under a configurable prefix (e.g., `openspec-*`) from the "unregistered" warning.
- Must be done after F-008 so we know the exact skill names OpenSpec generates.
- Full open questions in `docs/superpowers/plans/2026-03-19-openspec-skills.md`.

---

### F-010 — OpenSpec: wire `openspec update` into `payload-depot update`

**Type:** feature
**Status:** deferred
**Priority:** P2
**Target version:** v1.3
**Source:** https://github.com/Fission-AI/OpenSpec/blob/main/docs/cli.md — reviewed 2026-03-20

> ⚠️ **Implementation approach revised.** F-010 through F-016 were originally individual skills to write by hand. All are now collapsed into this single integration feature.

#### Problem
`openspec update` refreshes the Claude Code skills after OpenSpec CLI upgrades. Users who run `payload-depot update` to refresh their Payload Depot skills will not automatically get updated OpenSpec skills.

#### Expected behaviour
`payload-depot update` calls `openspec update` if the `openspec` CLI is installed, so OpenSpec skills stay current alongside Payload Depot skills.

#### Implementation notes
- Soft: skip silently if `openspec` is not installed.
- Run after the Payload Depot skill copy step, not before.

---

### F-011 — OpenSpec: `env-setup` skill update for openspec dependency

**Type:** feature
**Status:** deferred
**Priority:** P2
**Target version:** v1.3
**Source:** https://github.com/Fission-AI/OpenSpec/blob/main/docs/installation.md — reviewed 2026-03-20

#### Problem
The `env-setup` skill does not mention OpenSpec as an optional dependency. Users don't know they need Node.js ≥ 20.19 and `npm install -g @fission-ai/openspec` to use the `/opsx:*` workflow.

#### Expected behaviour
The `env-setup` skill includes an **Optional: OpenSpec** section documenting the install command and pointing to `payload-depot openspec-init`.

#### Implementation notes
- Node.js ≥ 20.19.0 is required by the OpenSpec CLI.
- Install: `npm install -g @fission-ai/openspec`
- Verify: `openspec --version`

---

> **F-012 through F-016 retired.** The original features (opsx-archive, opsx-verify, opsx-ff, opsx-continue, opsx-bulk-archive as hand-written skills) are superseded by the OpenSpec CLI and its generated skills. All functionality is provided by `openspec archive`, `openspec validate`, and the `/opsx:*` commands installed by `openspec init`. No Payload Depot skills need to be written for these.

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
| F-008 | feature | OpenSpec: `openspec-init` wrapper subcommand | deferred | P1 | v1.3 |
| F-009 | feature | OpenSpec: register generated skills in registry | deferred | P1 | v1.3 |
| F-010 | feature | OpenSpec: wire `openspec update` into `payload-depot update` | deferred | P2 | v1.3 |
| F-011 | feature | OpenSpec: `env-setup` skill update for openspec dependency | deferred | P2 | v1.3 |
| F-012–016 | feature | OpenSpec: hand-written opsx skills | retired | — | — |
