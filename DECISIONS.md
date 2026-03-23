# Decisions

<!-- DECISIONS.md is committed to git — it accumulates across sessions. -->
<!-- One entry per meaningful implementation decision. -->
<!-- Do not record trivial choices. Record choices that a reviewer would ask about. -->

---

### 2026-03-19 — Folder-based skill structure

**Decision:** Migrate all skills from flat `skills/<name>.md` to `skills/<name>/SKILL.md` (folder-based).

**Why:** New architecture skills (lich, phylactery-lich, socratic-mvp) ship with companion resource files (`resources/` subdirectories). The flat layout cannot accommodate these without losing the association between a skill and its resources. Folder-based structure makes each skill a self-contained unit — the skill file plus any resources live together.

**Trade-offs accepted:**
- `payload-depot` install logic now uses `find -name SKILL.md` + per-folder `cp -r` instead of `cp skills/*.md` — slightly more complex but handles nesting.
- `payload-depot-skill-check.sh` presence check looks for `$SKILLS_DIR/<name>/SKILL.md` — path in registry entries now includes the folder (e.g. `architecture/lich` not `lich.md`).
- Nested skills (e.g. `architecture/lich`) use slash-delimited names in the registry — consistent with how superpowers uses namespace prefixes.

**Frontmatter:** Accepted both old-style (`version:`, `updated:`) and new-style (`name:`, `category:`) in the structural check — new architecture skills use the new format.

---

### 2026-03-19 — Unified skill frontmatter standard + skill relationship model

**Decision:** All skills must use a single frontmatter standard with 5 required fields: `version`, `skill_type`, `hierarchy_level`, `parent_skills`, `uses_skills`. Old `name:`/`category:` format is invalid.

**Why:** Two incompatible frontmatter formats (old `version:` style vs new superpowers `name:`/`category:` style) made the skill tree uninterpretable and the validator ambiguous. Standardising on a single format enables the dependency graph and automated validation.

**Relationship model:**
- `parent_skills`: inheritance/extension — child derives from parent. Children are derived; never maintain child lists manually.
- `uses_skills`: runtime invocation — skill invokes another at runtime. Missing `parent_skills` = FAIL; missing `uses_skills` = WARN (forward-reference to planned skill allowed).
- `hierarchy_level`: priority on contradiction — 1 wins (project-specific), 2 mid (domain orchestrator), 3 base (universal).

**Trade-offs accepted:**
- Existing `clean-code` skill moved to `base/clean-code/` to match the namespace referenced by architecture skills.
- Validator upgraded to 4 layers (presence → structure → references → readability); tests fully rewritten.
- `uses_skills` resolution issues are warnings, not failures, to allow forward-references during incremental skill authoring.

---

### 2026-03-19 — Rename rig/rig-stage → payload-depot

**Decision:** Rename the CLI binary and all internal references from `rig`/`rig-stage` to `payload-depot`.

**Why:** The name "Rig" was too generic. "Loadout Depot" better captures the tool's purpose (assembling and deploying a coding session loadout). Requested by user.

**Rename scope:** 26 files affected — binary, adapter, health check, skill check, session scripts, hooks, tests, gitignore, Makefile, and all documentation. Env vars (`RIG_DIR` → `PAYLOAD_DEPOT_DIR`), marker files (`.rig-verified` → `.payload-depot-verified`), and recursion guard (`RIG_HEALTH_CHECK_ACTIVE` → `PAYLOAD_DEPOT_HEALTH_CHECK_ACTIVE`) all updated.

**Execution order:** File renames → functional files (sed, ordered longest-first) → documentation files — prevents partial matches and ensures tests pass at each step.

---

## Decision Log

### --force does not override HANDOFF.md / DECISIONS.md preservation
- **Decision:** `--force` flag only affects config files (CLAUDE.md, CONVENTIONS.md, AGENTS.md, settings.json). It never overwrites HANDOFF.md or DECISIONS.md.
- **Alternatives considered:** Allow `--force` to wipe all files including session history (original behaviour before B-001 fix).
- **Rationale:** Session history is irreplaceable. A user running `upgrade --force` to refresh agent prompts should never silently lose months of handoff context. If someone genuinely needs to reset session history they can `rm` the files manually.
- **Affected files:** `payload-depot` (step 7), `tests/test_install.sh`
- **Date:** 2026-03-19

### session-start hook uses sed substitution on fresh template, not append
- **Decision:** On a fresh SCRATCHPAD.md template (detected by `<session date>` placeholder), the hook substitutes the date in-place with `sed`. On subsequent days it appends a new `# Session` block.
- **Alternatives considered:** Always append `# Session YYYY-MM-DD` at the bottom (original F-007 spec). This produced a document with two conflicting headers — unfilled placeholder at top, appended date at bottom.
- **Rationale:** Substituting the placeholder produces a clean, well-formed document. The two-pattern idempotency guard (check for date string, not header prefix) makes both paths safe.
- **Affected files:** `targets/claude-code/session-start.sh`
- **Date:** 2026-03-19

### Stop hook prints reminder, does not auto-write session files
- **Decision:** The `Stop` hook runs `session-end.sh`, which checks if HANDOFF.md has today's date and prints a checklist if not. It does not attempt to write HANDOFF.md or DECISIONS.md automatically.
- **Alternatives considered:** Auto-writing session files from the hook (impossible — the hook is a bash script with no access to conversation context); no Stop hook at all.
- **Rationale:** Meaningful content (what was done, what decisions were made) can only come from the agent. The hook's job is to surface the gap so the agent or user notices and acts.
- **Affected files:** `targets/claude-code/session-end.sh`, `targets/claude-code/settings.json.template`
- **Date:** 2026-03-19

### DECISIONS.md heading does not include session date
- **Decision:** `# Decisions` (no date). Each individual entry has its own `**Date:** YYYY-MM-DD` field.
- **Alternatives considered:** `# Decisions — <session date>` (original template) — placeholder never gets substituted since DECISIONS.md is persistent and never overwritten after first install.
- **Rationale:** The file accumulates across all sessions; a single date in the heading is meaningless and stays as a broken placeholder forever.
- **Affected files:** `session/DECISIONS.md.template`, `DECISIONS.md`
- **Date:** 2026-03-19

### upgrade calls update, not install --force
- **Decision:** `cmd_upgrade` runs `bash "$PAYLOAD_DEPOT_DIR/payload-depot" update` instead of `bash "$PAYLOAD_DEPOT_DIR/payload-depot" install --force --no-codebase-index`.
- **Alternatives considered:** Keep `install --force` (original behaviour — clobbers all user config on every upgrade).
- **Rationale:** `install --force` silently overwrites CLAUDE.md, CONVENTIONS.md, AGENTS.md, and settings.json — files the user has customised for their project. `update` copies only agent and skill `.md` files, which are Loadout Depot-versioned content the user never edits. Config files are preserved unconditionally.
- **Affected files:** `payload-depot` (`cmd_upgrade`), `tests/test_install.sh`
- **Date:** 2026-03-19

### Session protocol trigger: per-feature-commit, not end-of-session
- **Decision:** HANDOFF.md and DECISIONS.md are updated immediately after each completed feature or fix commit, not at "end of session."
- **Alternatives considered:** Keep "end of session" trigger (original spec). End of session is undetectable in Claude Code — the Stop hook fires on every response, not just true session end. The agent loses track of the obligation across multiple tasks.
- **Rationale:** Tying the ritual to a git commit gives a concrete, observable trigger. The pre-commit hook reinforces it with a warning. Memory rule enforces it across future sessions.
- **Affected files:** `CLAUDE.md`, `targets/claude-code/CLAUDE.md.template`, `hooks/pre-commit`
- **Date:** 2026-03-19

### Pre-commit handoff warning is advisory, not blocking
- **Decision:** The HANDOFF.md staleness check in `hooks/pre-commit` prints a warning but does not block the commit.
- **Alternatives considered:** Block the commit until HANDOFF.md is updated (too aggressive — would block mid-feature commits where updating HANDOFF early makes no sense).
- **Rationale:** The warning fires on any commit that touches `payload-depot`, `tests/`, `hooks/`, or `targets/` when HANDOFF.md lacks today's date. It reminds without interrupting. The agent can commit, then immediately follow up with the handoff commit.
- **Affected files:** `hooks/pre-commit`
- **Date:** 2026-03-19

### MCP server configured in settings.json, not a separate mcp.json
- **Decision:** The `mcpServers` key is added inside `.claude/settings.json`, not a separate `.claude/mcp.json` file.
- **Alternatives considered:** `.claude/mcp.json` (what ccindex's `init` command documents — but this file does not exist in Claude Code's spec).
- **Rationale:** Claude Code reads MCP server config from the `mcpServers` key inside `settings.json`. The separate `mcp.json` approach is undocumented and non-functional.
- **Affected files:** `targets/claude-code/settings.json.template`, `.claude/settings.json`
- **Date:** 2026-03-19

### Health check recursion guard uses env var, not a second marker file
- **Decision:** `payload-depot-health-check.sh` exports `RIG_HEALTH_CHECK_ACTIVE=1` before calling `session-start.sh`. `session-start.sh` checks this var before triggering the health check.
- **Alternatives considered:** A second marker file (e.g. `.rig-health-running`) — would work but adds filesystem state; would leave stale file if the process is killed mid-run.
- **Rationale:** Env var is scoped to the process and its children — it disappears automatically when the shell exits, leaving no stale state.
- **Affected files:** `targets/claude-code/payload-depot-health-check.sh`, `targets/claude-code/session-start.sh`
- **Date:** 2026-03-19

### Health check is advisory-only from session-start.sh
- **Decision:** `session-start.sh` runs the health check with `|| true`, so a failing check never blocks the user's prompt.
- **Alternatives considered:** Exit non-zero to block the session until checks pass — would prevent broken installs from silently proceeding, but would also block work on machines with unusual setups (no network for git pull, etc).
- **Rationale:** The health check is a diagnostic aid. It should surface problems loudly but never prevent the user from working. Manual re-run is always available: `rm .payload-depot-verified && bash .claude/hooks/payload-depot-health-check.sh`.
- **Affected files:** `targets/claude-code/session-start.sh`
- **Date:** 2026-03-19

### Registry co-located with skills in `.claude/skills/`
- **Decision:** `registry.md` lives in `skills/` (copied to `.claude/skills/registry.md`) rather than a separate top-level file.
- **Alternatives considered:** `skills/registry.yaml` (machine-readable but not importable into CLAUDE.md), top-level `registry.md` (requires extra copy logic in payload-depot).
- **Rationale:** Co-location means the existing `cp skills/*.md` install step picks it up automatically. Markdown format allows `@.claude/skills/registry.md` import in CLAUDE.md for auto-discovery. Excluded from skill count and list with `! -name "registry.md"` filter.
- **Affected files:** `payload-depot`, `targets/claude-code/payload-depot-skill-check.sh`, `targets/claude-code/CLAUDE.md.template`
- **Date:** 2026-03-19

### Unregistered skills are warnings, not failures
- **Decision:** A skill file present in `.claude/skills/` but absent from `registry.md` produces a warning and exits 0, not a failure.
- **Alternatives considered:** Hard failure (exit 1) — too strict, blocks workflows mid-development.
- **Rationale:** Allows incremental adoption: write the skill file first, verify it structurally, then register it. Only missing registered skills (registered but file absent) are hard failures.
- **Affected files:** `targets/claude-code/payload-depot-skill-check.sh`, `tests/test_skill_check.sh`
- **Date:** 2026-03-19

### Agent files use tool-scoped frontmatter to enforce role contracts
- **Decision:** Read-only agents (architect, code-reviewer, debugger, security-auditor) declare only `Read, Glob, Grep, Bash` in their `tools:` frontmatter — explicitly excluding `Write` and `Edit`.
- **Alternatives considered:** Give all agents full tool access and rely on prompt instructions alone — simpler, but nothing prevents an agent from writing when it shouldn't.
- **Rationale:** Claude Code enforces the `tools:` list at the system level. A code-reviewer that cannot call `Write` or `Edit` cannot accidentally implement fixes, even if instructed to. The constraint is structural, not just instructional.
- **Affected files:** `.claude/agents/architect.md`, `.claude/agents/code-reviewer.md`, `.claude/agents/debugger.md`, `.claude/agents/security-auditor.md`
- **Date:** 2026-03-22

### Model tiers assigned by agent cognitive load
- **Decision:** opus for architect/debugger/security-auditor, sonnet for code-writer/code-reviewer/planner/test-writer/refactor/release-manager, haiku for docs-writer/issue-logger.
- **Alternatives considered:** Sonnet for everything — simpler, slightly higher cost for utility agents.
- **Rationale:** Agents that require multi-step reasoning over ambiguous evidence (architecture design, root cause analysis, security threat modelling) benefit from opus. Agents with well-structured, mechanical tasks (doc generation, issue logging) don't need it and run faster and cheaper on haiku.
- **Affected files:** All `.claude/agents/*.md`
- **Date:** 2026-03-22
