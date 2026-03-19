# Handoff Log

<!-- HANDOFF.md is committed to git. -->
<!-- Session start: run `git pull` before reading this file. -->
<!-- Session end: `git add HANDOFF.md DECISIONS.md && git commit -m "handoff: <agent> completed <task>" && git push` -->
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

---

### Agent: code-writer (Claude Sonnet 4.6)
**Completed:** 2026-03-19
**Task:** Implement B-001, F-006, F-007 — session file preservation, @file imports, session hooks

#### Output Files
- `rig-stage` — step 7 rewritten: SCRATCHPAD.md always overwrites, HANDOFF.md + DECISIONS.md skip-if-exists (even under --force)
- `targets/claude-code/CLAUDE.md.template` — added `@HANDOFF.md`, `@CONVENTIONS.md`, `@AGENTS.md` imports after repo map line
- `targets/claude-code/settings.json.template` — added `UserPromptSubmit` and `Stop` hooks
- `targets/claude-code/session-start.sh` — new: git pull + dated SCRATCHPAD header (idempotent, sed-substitutes fresh template)
- `targets/claude-code/session-end.sh` — new: Stop hook reminder to write HANDOFF.md/DECISIONS.md if not yet updated today
- `targets/claude-code/adapter.sh` — pre_install creates `.claude/hooks/`; post_install copies + chmods both hook scripts
- `session/DECISIONS.md.template` — removed `<session date>` from heading (file accumulates across all sessions)
- `DECISIONS.md` — same fix applied to live repo file
- `tests/test_install.sh` — 16 new tests covering B-001, F-006, F-007 (46 total, all passing)
- `FEATURES.md` — F-008 (OpenAPI) replaced with F-008–F-016 (OpenSpec skill suite)

#### Assumptions Made
- `--force` should NEVER wipe HANDOFF.md or DECISIONS.md — confirmed with user, treated as invariant
- Claude Code silently ignores missing `@file` references — no guard needed for fresh installs
- `Stop` hook output is shown to the user in the terminal (not injected back to Claude)

#### What Was Not Done
- F-001 (CLAUDE.md placeholder substitution) — deferred, next in priority after this session
- OpenSpec skills (F-008–F-016) — features documented but not implemented
- `--force` does not reset HANDOFF.md/DECISIONS.md even when explicitly requested — this is intentional but not yet documented in the spec

#### Uncertainties
- Verify that `Stop` hook output actually appears in the Claude Code UI — behaviour depends on Claude Code version
- `git pull --ff-only` will silently fail in repos with no remote; this is intentional (`|| true`) but worth monitoring

#### Instructions for Next Agent
- Read FEATURES.md — start with F-001 (auto-populate CLAUDE.md placeholders), then F-002/F-003
- All 46 tests in `tests/test_install.sh` must continue to pass after any changes to `rig-stage` or adapter files
- The B-001 fix (HANDOFF.md/DECISIONS.md preservation) is now an invariant — do not regress it
- Commit F-006/F-007 work before starting F-001 (user approved, pending commit)

---

### Agent: Claude Sonnet 4.6
**Completed:** 2026-03-19
**Task:** F-001, F-002, F-003, MCP wiring, navigation rules, session protocol enforcement

#### Output Files
- `rig-stage` — added `substitute_placeholders()` (F-001), `cmd_list_targets()` (F-002), `cmd_update()` (F-003); fixed `cmd_upgrade` to call `update` not `install --force`; updated `usage()`; fixed `set -e` bug in `&&` patterns
- `tests/test_install.sh` — 25 new tests (71 total); covers F-001 placeholder substitution, F-002 list-targets, F-003 update/preserve
- `tests/lib.sh` — added `assert_not_contains` helper
- `tests/fixtures/python-project/README.md` — new fixture for F-001 description detection
- `targets/claude-code/settings.json.template` — added `mcpServers` block for ccindex serve
- `targets/claude-code/CLAUDE.md.template` — expanded Codebase Context section (navigation priority, Grep/Glob table); rewrote session protocol trigger from "end of session" to "after each feature"
- `.claude/settings.json` — added `mcpServers` (live project)
- `CLAUDE.md` — same navigation + protocol updates (live project)
- `hooks/pre-commit` — added handoff reminder warning when code staged without today's HANDOFF entry
- `FEATURES.md` — marked B-001, F-001, F-002, F-003, F-006, F-007 as done

#### Assumptions Made
- `set -e` + `[[ ... ]] && cmd` was the root cause of TypeScript/C++ fixture install failures — confirmed by stash test
- Session protocol "end of session" trigger is unenforceable in Claude Code — redesigned to per-feature-commit trigger
- Pre-commit warning (not block) is appropriate for missing HANDOFF — blocking would frustrate mid-feature commits

#### What Was Not Done
- F-004 (OpenAI adapter), F-005 (Gemini adapter) — P3, deferred to v2.0/v3.0
- F-008–F-016 (OpenSpec suite) — v1.2 milestone, not started
- ccindex `init` still references `.claude/mcp.json` (wrong filename) — a separate prompt was written for the ccindex repo owner to fix

#### Uncertainties
- MCP server requires Claude Code restart to pick up the new `mcpServers` entry — not tested end-to-end
- Pre-commit hook warning uses `date +%Y-%m-%d` — will fire in UTC offset edge cases around midnight

#### Instructions for Next Agent
- v1.1 backlog is fully cleared (B-001, F-001, F-002, F-003, F-006, F-007 all done)
- Next milestone is v1.2: OpenSpec suite (F-008–F-016), starting with F-008 (openspec-init)
- All 71 tests must continue to pass — run `bash tests/test_install.sh` before committing
- **Follow the new session protocol**: after each feature commit, update SCRATCHPAD.md, HANDOFF.md, DECISIONS.md, then `git add HANDOFF.md DECISIONS.md && git commit -m "handoff: ..." && git push`

---

### Agent: Claude Sonnet 4.6
**Completed:** 2026-03-19
**Task:** F-007 health check system — rig-health-check.sh, tests, recursion guard

#### Output Files
- `targets/claude-code/rig-health-check.sh` — new: 31-check post-install health check; writes `.rig-verified` on full pass; exits 1 on any failure
- `targets/claude-code/session-start.sh` — added step 0: run health check when `.rig-verified` absent (with `RIG_HEALTH_CHECK_ACTIVE` guard)
- `targets/claude-code/adapter.sh` — `adapter_post_install` now installs `rig-health-check.sh` and clears `.rig-verified`
- `rig-stage` — `cmd_update` explicitly clears `.rig-verified` after adapter_post_install
- `tests/lib.sh` — added `assert_not_file_exists` helper
- `tests/test_install.sh` — 10 new tests for F-007 health check (81 total, all passing)
- `.claude/hooks/rig-health-check.sh` — live copy updated
- `.claude/hooks/session-start.sh` — live copy updated

#### Assumptions Made
- Health check should be advisory-only from session-start.sh (`|| true`) — a failing check should not block the user's work
- Recursion guard via env var (`RIG_HEALTH_CHECK_ACTIVE=1`) is the simplest safe fix; no marker file needed
- Agent count threshold ≥9 and skill count ≥10 are hardcoded to match current Rig v1.1 — must be updated if agents/skills are added

#### What Was Not Done
- F-008–F-016 (OpenSpec suite) — v1.2, not started
- Health check does not test `session-end.sh` behaviour (Stop hook output only visible in Claude UI, untestable in bash)

#### Uncertainties
- Health check thresholds (≥9 agents, ≥10 skills) will need bumping when new agents/skills are added to Rig

#### Instructions for Next Agent
- All 81 tests pass — run `bash tests/test_install.sh` to confirm before any changes
- v1.1 is complete. Next: v1.2 OpenSpec suite, start with F-008 (openspec-init)
- Health check thresholds are in `targets/claude-code/rig-health-check.sh` lines 108+113 — update when adding agents/skills
