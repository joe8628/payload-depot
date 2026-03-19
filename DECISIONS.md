# Decisions

<!-- DECISIONS.md is committed to git — it accumulates across sessions. -->
<!-- One entry per meaningful implementation decision. -->
<!-- Do not record trivial choices. Record choices that a reviewer would ask about. -->

---

## Decision Log

### --force does not override HANDOFF.md / DECISIONS.md preservation
- **Decision:** `--force` flag only affects config files (CLAUDE.md, CONVENTIONS.md, AGENTS.md, settings.json). It never overwrites HANDOFF.md or DECISIONS.md.
- **Alternatives considered:** Allow `--force` to wipe all files including session history (original behaviour before B-001 fix).
- **Rationale:** Session history is irreplaceable. A user running `upgrade --force` to refresh agent prompts should never silently lose months of handoff context. If someone genuinely needs to reset session history they can `rm` the files manually.
- **Affected files:** `rig-stage` (step 7), `tests/test_install.sh`
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
- **Decision:** `cmd_upgrade` runs `bash "$RIG_DIR/rig-stage" update` instead of `bash "$RIG_DIR/rig-stage" install --force --no-codebase-index`.
- **Alternatives considered:** Keep `install --force` (original behaviour — clobbers all user config on every upgrade).
- **Rationale:** `install --force` silently overwrites CLAUDE.md, CONVENTIONS.md, AGENTS.md, and settings.json — files the user has customised for their project. `update` copies only agent and skill `.md` files, which are Rig-versioned content the user never edits. Config files are preserved unconditionally.
- **Affected files:** `rig-stage` (`cmd_upgrade`), `tests/test_install.sh`
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
- **Rationale:** The warning fires on any commit that touches `rig-stage`, `tests/`, `hooks/`, or `targets/` when HANDOFF.md lacks today's date. It reminds without interrupting. The agent can commit, then immediately follow up with the handoff commit.
- **Affected files:** `hooks/pre-commit`
- **Date:** 2026-03-19

### MCP server configured in settings.json, not a separate mcp.json
- **Decision:** The `mcpServers` key is added inside `.claude/settings.json`, not a separate `.claude/mcp.json` file.
- **Alternatives considered:** `.claude/mcp.json` (what ccindex's `init` command documents — but this file does not exist in Claude Code's spec).
- **Rationale:** Claude Code reads MCP server config from the `mcpServers` key inside `settings.json`. The separate `mcp.json` approach is undocumented and non-functional.
- **Affected files:** `targets/claude-code/settings.json.template`, `.claude/settings.json`
- **Date:** 2026-03-19
