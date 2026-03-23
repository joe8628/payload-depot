# Handoff Log

---

### Agent: Claude Sonnet 4.6
**Completed:** 2026-03-22
**Task:** Add release-manager and refactor entries to AGENTS.md.template

#### Output Files
- `targets/claude-code/AGENTS.md.template` — added `release-manager` and `refactor` agent entries matching the content in `AGENTS.md`; fixed stale `rig install` → `payload-depot install` in the header comment

#### Assumptions Made
- Entry content copied verbatim from `AGENTS.md` (the live registry) — `AGENTS.md.template` is meant to be a faithful copy of what target projects receive, so no rewording was done
- The stale `rig install` comment was an artifact of the earlier rename and was a straightforward fix

#### What Was Not Done
- No tests added specifically for `AGENTS.md.template` content — the install test suite covers that agent files are present and valid in the installed directory, but does not assert that the template's documentation entries match the installed agent files
- `AGENTS.md.template` at `targets/gemini/` and `targets/openai/` (if they exist) were not checked for the same gap — only the `claude-code` target was in scope

#### Uncertainties
- The `agents/` ↔ `.claude/agents/` ↔ `AGENTS.md` ↔ `targets/claude-code/AGENTS.md.template` four-way sync is still a manual process. Any future agent addition must update all four locations. No automated check enforces this.

#### Instructions for Next Agent
- Run `bash tests/test_install.sh && bash tests/test_skill_check.sh` before any changes (103 + 17 = 120 tests, all passing)
- Check `targets/gemini/` and `targets/openai/` for their own `AGENTS.md.template` equivalents — they may also be missing `release-manager` and `refactor` entries
- Next milestone: v1.2 OpenSpec suite (F-008–F-016), start with F-008 (openspec-init) per FEATURES.md
- Review `WARNINGS.md` — W-001 and W-002 remain open and actionable

---

### Agent: Claude Sonnet 4.6
**Completed:** 2026-03-22
**Task:** Expand CLAUDE.md template with scaffolded sections + add slash commands

#### Output Files
- `targets/claude-code/CLAUDE.md.template` — added 7 new scaffolded sections with placeholder comments: Technology Stack, Commands, Architecture, Environment, Testing, Pre-commit Workflow, Rules; project-specific sections placed before infra sections
- `targets/claude-code/commands/review.md` — new slash command: reviews changed files, runs tests, reports Blockers/Warnings/Suggestions
- `targets/claude-code/commands/handoff.md` — new slash command: automates post-feature HANDOFF.md ritual, commits, and pushes
- `targets/claude-code/commands/debug.md` — new slash command: enforces hypothesis-first debugging loop
- `targets/claude-code/adapter.sh` — `adapter_pre_install` creates `.claude/commands/`; `adapter_post_install` copies all 3 command files
- `.claude/commands/review.md` — live copy for this repo
- `.claude/commands/handoff.md` — live copy for this repo
- `.claude/commands/debug.md` — live copy for this repo
- `CLAUDE.md` — header restored to correct values after template placeholder regression was caught by /project:review

#### Assumptions Made
- Commands installed into both `.claude/commands/` (live) and `targets/claude-code/commands/` (template) — target projects get them on `payload-depot install`
- `/project:review` references project-specific test commands from CLAUDE.md rather than hardcoding them, making it reusable across target projects
- `/project:handoff` hardcodes "Claude Sonnet 4.6" as agent name — acceptable for now, could be made dynamic later
- The CLAUDE.md header regression (template stubs overwriting project values) was caused by the `CLAUDE.md.template` edit being reflected in the live `CLAUDE.md` via the `@` import system — the fix was already in the last commit

#### What Was Not Done
- No tests added for command file installation — the adapter test suite covers `post_install` broadly but doesn't assert specific `.claude/commands/` file presence
- SPEC.md not updated to document the commands subsystem
- `/project:handoff` does not auto-detect the agent name or task from git context — it relies on Claude filling those in from conversation context

#### Uncertainties
- The CLAUDE.md template regression root cause needs confirmation: was it the `@` import expanding the template at read time, or a direct overwrite? If the former, the live `CLAUDE.md` may be vulnerable to future template edits again.

#### Instructions for Next Agent
- Run `bash tests/test_install.sh && bash tests/test_skill_check.sh` before any changes (90 + 17 = 107 tests, all passing)
- Three slash commands are live: `/project:review`, `/project:handoff`, `/project:debug`
- Consider adding install tests that assert `.claude/commands/review.md`, `handoff.md`, `debug.md` exist after `adapter_post_install`
- Next milestone: v1.2 OpenSpec suite (F-008–F-016), start with F-008 (openspec-init) per FEATURES.md

---

### Agent: Claude Sonnet 4.6
**Completed:** 2026-03-21
**Task:** Rename loadout-depot → payload-depot throughout the codebase

#### Output Files
- `payload-depot` — main CLI renamed from `loadout-depot`
- `payload-depot.png` — banner image renamed
- `targets/claude-code/payload-depot-health-check.sh` — renamed from `loadout-depot-health-check.sh`
- `targets/claude-code/payload-depot-skill-check.sh` — renamed from `loadout-depot-skill-check.sh`
- `.claude/hooks/payload-depot-health-check.sh` — renamed from `loadout-depot-health-check.sh`
- `.claude/hooks/payload-depot-skill-check.sh` — renamed from `loadout-depot-skill-check.sh`
- All 31 text files — 404 occurrences of `loadout-depot` replaced with `payload-depot`

#### Assumptions Made
- `loadout-repo` (the git repository directory name) was not renamed — only files and content within it
- All previously accumulated uncommitted changes from prior sessions are included in this commit

#### What Was Not Done
- Nothing deferred

#### Uncertainties
- None — 90 install tests + 17 skill check tests all pass

#### Instructions for Next Agent
- Run `bash tests/test_install.sh && bash tests/test_skill_check.sh` before any changes (90 + 17 = 107 tests)
- Next milestone: v1.2 OpenSpec suite (F-008–F-016), start with F-008 (openspec-init) per FEATURES.md

<!-- HANDOFF.md is committed to git. -->
<!-- Session start: run `git pull` before reading this file. -->
<!-- Session end: `git add HANDOFF.md DECISIONS.md && git commit -m "handoff: <agent> completed <task>" && git push` -->
<!-- Each agent appends one block when it completes its task. Do not edit previous blocks. -->

---

### Agent: Claude Sonnet 4.6
**Completed:** 2026-03-20
**Task:** Add prompt-master skill, redesign README.md, defer OpenSpec (F-008–F-016) to v1.3

#### Output Files
- `skills/prompt-master/SKILL.md` — new skill: prompt engineering for 20+ AI tools
- `skills/prompt-master/references/templates.md` — 12 prompt templates (RTF, CO-STAR, RISEN, etc.)
- `skills/prompt-master/references/patterns.md` — 35 anti-patterns diagnostic reference
- `.claude/skills/prompt-master/` — live copies of the above
- `skills/registry.md` + `.claude/skills/registry.md` — added prompt-master entry
- `README.md` — redesigned with centered banner image, shields.io badges, Quick Start section
- `docs/superpowers/plans/2026-03-19-openspec-skills.md` — rewritten as research/deferred document with 3 integration options and 7 open questions
- `FEATURES.md` — F-008–F-011 rewritten with correct scope (thin wrapper, not hand-written skills); F-012–F-016 retired as superseded by OpenSpec CLI

#### Assumptions Made
- prompt-master skill wraps the nidhinjs/prompt-master content into payload-depot folder format with required frontmatter
- OpenSpec CLI (`@fission-ai/openspec`) auto-generates all skills via `openspec init --tools claude` — hand-writing them is wrong
- F-012–F-016 (individual opsx skill stubs) are retired entirely; they map to OpenSpec-generated skills

#### What Was Not Done
- OpenSpec integration (F-008–F-011) deferred to v1.3 pending resolution of 7 open questions
- No new tests written this session (prompt-master is runtime-only, no bash testable behavior)

#### Uncertainties
- 7 open questions documented in `docs/superpowers/plans/2026-03-19-openspec-skills.md` must be resolved before v1.3 sprint

#### Instructions for Next Agent
- Run `bash tests/test_install.sh && bash tests/test_skill_check.sh` before any changes (84 + 17 tests)
- Next milestone is v1.3: resolve 7 open questions in OpenSpec plan doc, then implement F-008–F-011
- prompt-master skill follows payload-depot format — if upgrading from upstream (nidhinjs/prompt-master), preserve the frontmatter and folder structure

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
- `payload-depot` — step 7 rewritten: SCRATCHPAD.md always overwrites, HANDOFF.md + DECISIONS.md skip-if-exists (even under --force)
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
- All 46 tests in `tests/test_install.sh` must continue to pass after any changes to `payload-depot` or adapter files
- The B-001 fix (HANDOFF.md/DECISIONS.md preservation) is now an invariant — do not regress it
- Commit F-006/F-007 work before starting F-001 (user approved, pending commit)

---

### Agent: Claude Sonnet 4.6
**Completed:** 2026-03-19
**Task:** F-001, F-002, F-003, MCP wiring, navigation rules, session protocol enforcement

#### Output Files
- `payload-depot` — added `substitute_placeholders()` (F-001), `cmd_list_targets()` (F-002), `cmd_update()` (F-003); fixed `cmd_upgrade` to call `update` not `install --force`; updated `usage()`; fixed `set -e` bug in `&&` patterns
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
**Task:** F-007 health check system — payload-depot-health-check.sh, tests, recursion guard

#### Output Files
- `targets/claude-code/payload-depot-health-check.sh` — new: 31-check post-install health check; writes `.payload-depot-verified` on full pass; exits 1 on any failure
- `targets/claude-code/session-start.sh` — added step 0: run health check when `.payload-depot-verified` absent (with `RIG_HEALTH_CHECK_ACTIVE` guard)
- `targets/claude-code/adapter.sh` — `adapter_post_install` now installs `payload-depot-health-check.sh` and clears `.payload-depot-verified`
- `payload-depot` — `cmd_update` explicitly clears `.payload-depot-verified` after adapter_post_install
- `tests/lib.sh` — added `assert_not_file_exists` helper
- `tests/test_install.sh` — 10 new tests for F-007 health check (81 total, all passing)
- `.claude/hooks/payload-depot-health-check.sh` — live copy updated
- `.claude/hooks/session-start.sh` — live copy updated

#### Assumptions Made
- Health check should be advisory-only from session-start.sh (`|| true`) — a failing check should not block the user's work
- Recursion guard via env var (`RIG_HEALTH_CHECK_ACTIVE=1`) is the simplest safe fix; no marker file needed
- Agent count threshold ≥9 and skill count ≥10 are hardcoded to match current Loadout Depot v1.1 — must be updated if agents/skills are added

#### What Was Not Done
- F-008–F-016 (OpenSpec suite) — v1.2, not started
- Health check does not test `session-end.sh` behaviour (Stop hook output only visible in Claude UI, untestable in bash)

#### Uncertainties
- Health check thresholds (≥9 agents, ≥10 skills) will need bumping when new agents/skills are added to Loadout Depot

#### Instructions for Next Agent
- All 81 tests pass — run `bash tests/test_install.sh` to confirm before any changes
- v1.1 is complete. Next: v1.2 OpenSpec suite, start with F-008 (openspec-init)
- Health check thresholds are in `targets/claude-code/payload-depot-health-check.sh` lines 108+113 — update when adding agents/skills

---

### Agent: Claude Sonnet 4.6
**Completed:** 2026-03-19
**Task:** Skill check system — registry, three-layer validator, smoke test, auto-discovery

#### Output Files
- `skills/registry.md` — source registry with all 10 skills (triggers, descriptions, smoke test prompts); copied to `.claude/skills/registry.md` on install
- `targets/claude-code/payload-depot-skill-check.sh` — three-layer validator: presence (registry drift detection), structure (frontmatter + required sections), readability (non-empty + UTF-8)
- `targets/claude-code/adapter.sh` — added `payload-depot-skill-check.sh` installation in `adapter_post_install`
- `targets/claude-code/payload-depot-health-check.sh` — replaced skill count check with delegation to `payload-depot-skill-check.sh`; added file/exec checks for `payload-depot-skill-check.sh` and `registry.md`
- `targets/claude-code/CLAUDE.md.template` — added `@.claude/skills/registry.md` import and `## Skills` section
- `skill-smoke-test.md` — Claude-side prompt for functional skill verification (run inside Claude Code)
- `payload-depot` — excluded `registry.md` from skill count and `list` output
- `tests/test_skill_check.sh` — 19 tests covering all three validation layers
- `.claude/skills/registry.md` — live copy
- `.claude/hooks/payload-depot-skill-check.sh` — live copy
- `.claude/hooks/payload-depot-health-check.sh` — live copy (updated)
- `CLAUDE.md` — live copy (updated)
- `SPEC.md` — new §§ 6.3, 6.4 documenting the registry and skill check system; §§ 6.6–6.8 renumbered; § 10.4 test cases; § 14 file format reference updated

#### Assumptions Made
- `registry.md` lives in `skills/` (co-located with skills) and is excluded from skill count/list — no changes to payload-depot's copy logic needed since `cp skills/*.md` picks it up automatically
- Unregistered skills (file exists, not in registry) are a warning not a failure — allows gradual onboarding of new skills before registering them
- `grep -qF "---"` fails on some systems because `---` looks like an option; fixed with `grep -qF -- "---"`

#### What Was Not Done
- No test for `health-check-delegates` case from spec § 10.4 — the delegation is implicitly tested by the install test suite which runs the full health check
- `skill-smoke-test.md` is a prompt file only; functional invocation requires Claude Code at runtime and cannot be tested in bash

#### Uncertainties
- None known

#### Instructions for Next Agent
- All tests: `bash tests/test_install.sh` (84 passed) + `bash tests/test_skill_check.sh` (19 passed)
- When adding a new skill: drop `.md` in `skills/`, run `bash .claude/hooks/payload-depot-skill-check.sh` to confirm it's detected as unregistered, then add entry to `skills/registry.md` and copy to `.claude/skills/registry.md`
- Next milestone: v1.2 OpenSpec suite (F-008–F-016), starting with F-008 (openspec-init) per FEATURES.md

---

### Agent: Claude Sonnet 4.6
**Completed:** 2026-03-19
**Task:** Skill restructure — folder-based SKILL.md layout + 4 new skills registered

#### Output Files
- `skills/*/SKILL.md` — 10 existing flat skills migrated to folder structure (`skills/tdd.md` → `skills/tdd/SKILL.md`, etc.)
- `skills/registry.md` — updated `**File:**` fields to `<name>/SKILL.md` paths; added 4 new skills: `clean-code`, `architecture/lich`, `architecture/phylactery-lich`, `architecture/socratic-mvp`
- `payload-depot` — `cmd_install` and `cmd_update` now use `find -name SKILL.md` + per-folder `cp -r`; `cmd_list` reads skill folders instead of flat `.md` files
- `targets/claude-code/payload-depot-skill-check.sh` — rewritten for folder structure: discovers skills via `find -name SKILL.md`, looks for `$SKILLS_DIR/<name>/SKILL.md` on presence check, accepts both old (`version:`) and new (`name:`) frontmatter formats
- `tests/test_skill_check.sh` — rewritten: `make_valid_skill` creates folder/SKILL.md; new tests for new-format frontmatter, nested skill (architecture/lich), missing-name-and-version; tests now 17 (removed section-level checks that don't apply to new-format skills)
- `.claude/hooks/payload-depot-skill-check.sh` — live copy updated
- `.claude/skills/` — live skills synced to folder structure (14 skill folders)
- `DECISIONS.md` — recorded folder-structure decision

#### Assumptions Made
- Flat `registry.md` stays at `skills/registry.md` root (not in a folder) — it's config, not a skill
- `resources/` subdirectories inside architecture skills are copied as-is via `cp -r` of the skill folder
- Both old-format (`version:`, `updated:`) and new-format (`name:`, `category:`) frontmatter are valid — checker accepts either

#### What Was Not Done
- SPEC.md §3 (repo structure) not yet updated to reflect folder structure — minor doc gap
- `payload-depot-health-check.sh` skill count threshold not updated (still ≥10) — 14 skills now installed, threshold still passes

#### Instructions for Next Agent
- All 84 install tests + 17 skill check tests pass — run both: `bash tests/test_install.sh && bash tests/test_skill_check.sh`
- When adding a new skill: create `skills/<name>/SKILL.md`, add entry to `skills/registry.md`, re-run check
- Next: continue OpenSpec suite (F-008–F-016) — resume with F-008 (openspec-init) per FEATURES.md

---

### Agent: Claude Sonnet 4.6
**Completed:** 2026-03-19
**Task:** Unified skill format standard, relationship model, 4-layer validator, rename rig→payload-depot

#### Output Files
- `skills/SKILL.template.md` — canonical skill template with frontmatter reference section
- `skills/base/clean-code/SKILL.md` — moved from `skills/clean-code/`, reformatted to standard
- `skills/*/SKILL.md` (all 14 skills) — added `skill_type`, `hierarchy_level`, `parent_skills`, `uses_skills` to all frontmatter
- `skills/architecture/lich/SKILL.md` — `uses_skills: [base/clean-code, adr, tdd]`
- `skills/architecture/phylactery-lich/SKILL.md` — `hierarchy_level: 1`, `parent_skills: [architecture/lich]`, `uses_skills: [base/clean-code, adr, tdd, linting, type-checking, dependency-audit]`
- `skills/architecture/socratic-mvp/SKILL.md` — `hierarchy_level: 1`, `parent_skills: [architecture/lich, architecture/phylactery-lich]`
- `skills/changelog/SKILL.md` — `uses_skills: [commit-msg]`
- `skills/registry.md` + `.claude/skills/registry.md` — `clean-code` → `base/clean-code` entry updated
- `targets/claude-code/payload-depot-skill-check.sh` — 4-layer validator (presence, structure, references, readability); requires 5 frontmatter fields; `parent_skills` missing = FAIL, `uses_skills` missing = WARN
- `payload-depot` (was `rig-stage`) — full rename; env vars, marker files, log prefixes updated
- `targets/claude-code/adapter.sh` — all rig→payload-depot references
- `targets/claude-code/payload-depot-health-check.sh` (was `rig-health-check.sh`) — recursion guard renamed
- `targets/claude-code/session-start.sh` + `.claude/hooks/session-start.sh` — marker + guard renamed
- `.gitignore`, `Makefile`, `hooks/pre-commit` — all references updated
- All 73 `.md` files — `Rig`→`Loadout Depot`, `rig-stage`→`payload-depot` throughout
- `CLAUDE.md` + `targets/claude-code/CLAUDE.md.template` — `rig-skill-check.sh` → `payload-depot-skill-check.sh`
- `tests/test_install.sh` — all internal references renamed; 2 hardcoded expected strings updated
- `tests/test_skill_check.sh` — completely rewritten: `make_valid_skill` now includes all 5 required fields; removed old-format test; test 3 repurposed to `uses_skills` reference; test 7 updated to `missing-version`
- `DECISIONS.md` — 3 new entries: unified standard, relationship model, rename

#### Assumptions Made
- `base/clean-code` is the canonical namespace for the clean-code standard (matches architecture skill body references)
- `uses_skills` resolution failures are warnings, not errors — allows forward-references to planned skills
- `parent_skills` resolution failures are errors — a child referencing a non-existent parent is a structural defect
- Old `name:`/`category:` frontmatter format is now fully invalid — only `version:` format is accepted
- Rename used ordered sed (longest patterns first) to avoid partial matches

#### What Was Not Done
- New missing skills (`commit-msg-linting`, `test-runner`, `style-guide`) not created — user has a separate skill creator
- SPEC.md §3 repo structure diagram not updated for `base/` subdirectory or rename
- `payload-depot-health-check.sh` skill count threshold (≥10) not bumped — 14 installed, still passes

#### Uncertainties
- None known — 84 install tests + 17 skill check tests all pass

#### Instructions for Next Agent
- Run `bash tests/test_install.sh && bash tests/test_skill_check.sh` before any changes (84 + 17 = 101 tests, all passing)
- When adding a skill: create `skills/<name>/SKILL.md` with all 5 frontmatter fields, add registry entry, re-run skill check
- Next milestone: v1.2 OpenSpec suite (F-008–F-016), start with F-008 (openspec-init) per FEATURES.md
- `base/clean-code` skill is now separate from the architecture skills it serves — if it gains parent skills in future, update `parent_skills` only (not `uses_skills`)

---

### Agent: Claude Sonnet 4.6
**Completed:** 2026-03-21
**Task:** Update README and all documentation with new name payload-depot

#### Output Files
- `README.md` — "Loadout Depot" → "Payload Depot" (heading + alt text)
- `SPEC.md` — all occurrences replaced (20 → 0)
- `FEATURES.md` — all occurrences replaced (10 → 0)
- `CHANGELOG.md` — all occurrences replaced (1 → 0)
- `CLAUDE.md` — title updated to "Payload Depot"
- `targets/claude-code/README.md`, `targets/gemini/README.md`, `targets/openai/README.md` — descriptions updated
- `tests/fixtures/python-project/README.md` — fixture description updated
- `tests/test_install.sh` — 2 hardcoded expected strings updated to match new name
- `docs/superpowers/plans/*.md` — all occurrences replaced

#### Assumptions Made
- HANDOFF.md and DECISIONS.md historical entries are left as-is (they record past state accurately)
- `brief_Rig.md` is a historical brief and not updated

#### What Was Not Done
- Nothing deferred

#### Uncertainties
- None

#### Instructions for Next Agent
- Run `bash tests/test_install.sh && bash tests/test_skill_check.sh` before any changes (90 + 17 = 107 tests)
- No "Loadout Depot" or "loadout-depot" remain in any active doc files
- Next milestone: v1.2 OpenSpec suite (F-008–F-016), start with F-008 (openspec-init) per FEATURES.md

---

### Agent: Claude Sonnet 4.6
**Completed:** 2026-03-22
**Task:** Migrate .claude/agents/ to Claude Code subagent format + add release-manager and refactor agents

#### Output Files
- `.claude/agents/architect.md` — frontmatter replaced: version/updated/changelog → name/description/tools/model (opus, Read Glob Grep Bash)
- `.claude/agents/planner.md` — frontmatter replaced (sonnet, Read Write Bash)
- `.claude/agents/code-writer.md` — frontmatter replaced (sonnet, Read Write Edit Glob Grep Bash)
- `.claude/agents/code-reviewer.md` — frontmatter replaced (sonnet, Read Glob Grep Bash — read-only)
- `.claude/agents/debugger.md` — frontmatter replaced (opus, Read Glob Grep Bash — read-only)
- `.claude/agents/test-writer.md` — frontmatter replaced (sonnet, Read Write Edit Glob Grep Bash)
- `.claude/agents/security-auditor.md` — frontmatter replaced (opus, Read Glob Grep Bash — read-only)
- `.claude/agents/docs-writer.md` — frontmatter replaced (haiku, Read Write Edit Glob Grep Bash)
- `.claude/agents/issue-logger.md` — frontmatter replaced (haiku, Read Write Glob Bash)
- `.claude/agents/release-manager.md` — new agent: orchestrates full release ritual (changelog, version bump, tag, PR to main)
- `.claude/agents/refactor.md` — new agent: structural cleanup without behaviour change; requires green test baseline before starting
- `AGENTS.md` — added release-manager and refactor entries; fixed stale `rig install` → `payload-depot install` in line 3 comment

#### Assumptions Made
- Model assignments: opus for design/diagnostic agents (architect, debugger, security-auditor) where depth matters; haiku for utility agents (docs-writer, issue-logger) where cost matters; sonnet for everything else
- Read-only agents (code-reviewer, debugger, security-auditor, architect) intentionally exclude Write/Edit from their tool list to enforce their no-implementation contracts at the tool level
- `release-manager` is given Write/Edit/Bash because it must update CHANGELOG.md and version files — not just read
- `refactor` treats a green test baseline as a hard prerequisite; if tests are failing on entry it stops and reports rather than attempting to refactor broken code

#### What Was Not Done
- The two new agents (`release-manager`, `refactor`) are not yet wired into the install adapter (`targets/claude-code/adapter.sh`) — the `.claude/agents/` directory is not currently part of what `payload-depot install` deploys to target projects. This is a gap: target projects won't get these agents unless install is updated.
- No tests added for agent file format validation (presence of required frontmatter fields) — the test suite covers skills and install steps but not `.claude/agents/` structure

#### Uncertainties
- Claude Code's `.claude/agents/` subagent system is relatively new. The `description` field content determines when Claude auto-delegates — the descriptions written here are functional but may need tuning based on real usage patterns
- `release-manager` uses `gh pr create` — this assumes the `gh` CLI is authenticated in the target environment. No fallback documented if `gh` is unavailable.

#### Instructions for Next Agent
- Run `bash tests/test_install.sh && bash tests/test_skill_check.sh` before any changes (90 + 17 = 107 tests, all passing)
- **Gap to address:** `targets/claude-code/adapter.sh` does not copy `.claude/agents/` to target projects on install. Decide whether agents should be installed alongside skills, and if so update `adapter_pre_install` to create `.claude/agents/` and `adapter_post_install` to copy agent files. Add install tests to cover it.
- **Gap to address:** Consider adding a `payload-depot-agent-check.sh` validator (parallel to `payload-depot-skill-check.sh`) that verifies all agent files have the required frontmatter fields (name, description, tools, model)
- Next milestone remains: v1.2 OpenSpec suite (F-008–F-016), start with F-008 (openspec-init) per FEATURES.md

---

### Agent: Claude Sonnet 4.6
**Completed:** 2026-03-22
**Task:** Wire .claude/agents/ into install adapter + create payload-depot-agent-check.sh validator + fix stale comments + create WARNINGS.md

#### Output Files
- `targets/claude-code/payload-depot-agent-check.sh` — new: 4-layer validator (presence, frontmatter fields, required sections, readability); exits 1 on any failure; warns on missing `model` field
- `.claude/hooks/payload-depot-agent-check.sh` — live copy of the above
- `targets/claude-code/adapter.sh` — `adapter_pre_install` now creates `.claude/agents`; `adapter_post_install` installs and chmods `payload-depot-agent-check.sh`; fixed stale `rig install` → `payload-depot install` in line 3 comment
- `targets/claude-code/payload-depot-health-check.sh` — added `check_file` + `check_exec` for agent-check; added delegation block; bumped agent count threshold from ≥9 to ≥11; fixed `# Loadout Depot` → `# Payload Depot` in header comment
- `.claude/hooks/payload-depot-health-check.sh` — live copy synced
- `agents/architect.md` through `agents/test-writer.md` (9 files) — synced from `.claude/agents/` to pick up new frontmatter format (name/description/tools/model)
- `agents/refactor.md` — new: added to source agents/ dir so install copies it to target projects
- `agents/release-manager.md` — new: added to source agents/ dir so install copies it to target projects
- `tests/test_install.sh` — 13 new tests across 5 groups: agent-check-installed, agent-check-agents-present, agent-check-passes-fresh-install, agent-check-fails-missing-frontmatter, agent-check-fails-missing-sections
- `WARNINGS.md` — new: persistent warning tracker; W-001 (frontmatter scan scopes whole file) and W-002 (hardcoded ≥11 threshold) logged as open

#### Assumptions Made
- `agents/` (root-level, source for installs) and `.claude/agents/` (live copy for this repo) must be kept in sync manually — there is no automated sync between them. The source of truth is `.claude/agents/`; `agents/` is the install source.
- The agent-check validator treats `model` as optional (warn, not fail) — consistent with Claude Code docs where `model` is optional in subagent frontmatter
- `≥11` threshold is acceptable for now; W-002 tracks the fix. The threshold is a coarse sanity check — the agent-check validator is the real quality gate
- WARNINGS.md is committed (not gitignored) so all agents share visibility into open issues

#### What Was Not Done
- W-001 not fixed: `payload-depot-agent-check.sh` still scans the full file for frontmatter fields rather than scoping to the frontmatter block — logged in WARNINGS.md
- W-002 not fixed: hardcoded `≥11` threshold not yet made dynamic — logged in WARNINGS.md
- No `tests/test_agent_check.sh` created as a standalone test file parallel to `tests/test_skill_check.sh` — agent-check behaviour is covered through the install test suite instead
- `AGENTS.md.template` (in `targets/claude-code/`) not updated to include `release-manager` and `refactor` entries — target projects will get the agent files but their `AGENTS.md` won't document them

#### Uncertainties
- The `agents/` ↔ `.claude/agents/` dual-directory pattern is fragile. If someone edits one without the other, they drift silently. No check exists for this drift.
- `payload-depot-agent-check.sh` is not called standalone in any test — it is only exercised via the install test suite. Edge cases (empty dir, non-UTF-8 file) are not directly tested.

#### Instructions for Next Agent
- Run `bash tests/test_install.sh && bash tests/test_skill_check.sh` before any changes (103 + 17 = 120 tests, all passing)
- Review `WARNINGS.md` — W-001 and W-002 are open and actionable
- `AGENTS.md.template` at `targets/claude-code/AGENTS.md.template` does not include `release-manager` or `refactor` — add entries so target projects get complete documentation on install
- Next milestone: v1.2 OpenSpec suite (F-008–F-016), start with F-008 (openspec-init) per FEATURES.md

### Agent: Claude Sonnet 4.6
**Completed:** 2026-03-23
**Task:** Add three quality hooks — PostToolUse lint, PreToolUse secret scan, PostToolUse test summary

#### Output Files
- `targets/claude-code/post-edit-lint.sh` — new PostToolUse hook; fires on Write and Edit; detects language from file extension; runs ruff (Python), eslint (JS/TS), clang-tidy (C/C++), shellcheck (shell); exits 1 when violations found so Claude self-corrects in-session
- `targets/claude-code/pre-write-secret-scan.sh` — new PreToolUse hook; fires on Write and Edit; scans new content for 10 high-confidence secret patterns (AWS key IDs, PEM private keys, GitHub/Slack/Anthropic/OpenAI tokens); exits 2 to block the write; `grep -P -- "$pattern"` required to handle dash-prefixed patterns
- `targets/claude-code/post-bash-test.sh` — new PostToolUse hook; fires on Bash; detects test runner commands (pytest, bats, jest, npm test, make test, bash tests/*.sh); parses pass/fail counts from common formats; emits structured one-liner; silent on non-test commands; exits 0 always
- `targets/claude-code/settings.json.template` — added PreToolUse (Write, Edit → secret-scan) and PostToolUse (Write, Edit → post-edit-lint; Bash → post-bash-test) entries
- `targets/claude-code/adapter.sh` — adapter_post_install now copies and chmods all three hook scripts
- `.claude/hooks/post-edit-lint.sh`, `.claude/hooks/pre-write-secret-scan.sh`, `.claude/hooks/post-bash-test.sh` — live copies for this repo
- `.claude/settings.json` — live settings synced with same PreToolUse/PostToolUse entries
- `tests/test_install.sh` — 18 new tests: install presence + executable, settings.json wiring, functional behavior of each hook; 128 + 17 = 145 total, all passing

#### Assumptions Made
- Linting hooks exit 1 (not 0) so Claude sees violations as a tool failure and self-corrects; this is intentional — post-edit-lint is not advisory, it's a feedback loop
- `grep -P -- "$pattern"` (with `--`) is required for patterns starting with dashes (PEM headers); without `--`, grep misinterprets the leading dashes as unknown flags and silently returns no match
- Secret scan uses `check_pattern` with `2>/dev/null` to suppress grep errors from patterns that require Perl mode on systems without PCRE grep — those patterns are skipped gracefully rather than blocking writes
- post-bash-test.sh parses from the `tool_response` field in PostToolUse stdin JSON; handles both string and object response shapes defensively

#### What Was Not Done
- `post-edit-lint.sh` does not auto-fix (ruff format, prettier) — only lints and reports; auto-fixing is a higher-risk operation that warrants a separate decision
- Secret scan does not use `gitleaks` or `detect-secrets` — relies on `grep -P` only, no external tools required; upgrade path noted in code
- Health check thresholds not updated — the new hooks are validator scripts, not agents, so the ≥11 agent threshold is unaffected

#### Uncertainties
- Claude Code's `matcher` field regex support: using exact tool names (`"Write"`, `"Edit"`, `"Bash"`) which are confirmed to work; pattern matchers (e.g., `"Write|Edit"`) not tested and kept as separate entries to be safe
- `tool_response` shape for Bash PostToolUse may vary by Claude Code version — handled defensively with `jq` type check

#### Instructions for Next Agent
- Run `bash tests/test_install.sh && bash tests/test_skill_check.sh` before any changes (128 + 17 = 145 tests, all passing)
- Three new hooks now active in this repo's `.claude/settings.json` — they fire on every Write/Edit/Bash during this session
- Review `WARNINGS.md` — W-001 and W-002 remain open
- Next milestone: v1.2 OpenSpec suite (F-008–F-016), start with F-008 (openspec-init) per FEATURES.md


### Agent: Claude Sonnet 4.6
**Completed:** 2026-03-23
**Task:** Context window monitoring hook + /goal slash command

#### Output Files
- `targets/claude-code/context-monitor.sh` — new UserPromptSubmit hook; reads `transcript_path` from Claude Code stdin JSON; estimates tokens as `transcript_bytes / 4 + 20K system overhead`; warns to stderr at 70% (WARN), 85% (ALERT), 90%+ (CRITICAL); at CRITICAL also emits one line to stdout so Claude sees it; reads `.claude/session-goal.txt` and includes goal in warnings; configurable via `PAYLOAD_DEPOT_MAX_TOKENS` env var or `.claude/context.conf`; exits 0 always (never blocks)
- `targets/claude-code/commands/goal.md` — new `/goal` slash command; set goal with `/goal <text>`, view with `/goal`; explains 4-tier strategy; `.claude/session-goal.txt` is gitignored
- `targets/claude-code/settings.json.template` — context-monitor.sh added to UserPromptSubmit hooks array alongside session-start.sh
- `targets/claude-code/adapter.sh` — adapter_post_install installs context-monitor.sh and commands/goal.md
- `payload-depot` — `_ensure_gitignore_entries` adds `.claude/session-goal.txt` (fresh install block + upgrade path)
- `.claude/hooks/context-monitor.sh`, `.claude/commands/goal.md`, `.claude/settings.json` — live copies synced
- `tests/test_install.sh` — 13 new tests; 141 install + 17 skill check = 158 total, all passing

#### Assumptions Made
- Token estimation via `transcript_bytes / 4 + 20K overhead` is intentionally approximate; the overhead accounts for CLAUDE.md, repo map, and system prompt which are not in the transcript file but consume real context
- 200K default covers all Claude Sonnet/Opus/Haiku models (as of 2026); override via env var for projects on older models or smaller limits
- context-monitor fires on every UserPromptSubmit; warnings appear every prompt above threshold (no snooze mechanism); this is intentional — the signal should be persistent, not suppressible
- `/goal` is a slash command (not a hook) because goal-setting is a deliberate user action, not an automatic one; the hook just reads the goal file when it exists
- `.claude/session-goal.txt` is gitignored because goals are session-local context management, not project state worth committing

#### What Was Not Done
- No `context.conf` template installed — just env var override; could be added later for teams with shared token limits
- Hook does not auto-compact — Claude Code's `/compact` is a UI command, not a shell command; no hook can invoke it programmatically

#### Uncertainties
- `transcript_path` availability: Claude Code injects it into UserPromptSubmit hook stdin; if a future Claude Code version changes this field name, the hook exits silently (already guarded)
- Byte-to-token ratio varies: code is ~3 chars/token, prose is ~4-5 chars/token; using 4 as a middle estimate means code-heavy sessions may underestimate usage

#### Instructions for Next Agent
- Run `bash tests/test_install.sh && bash tests/test_skill_check.sh` before any changes (141 + 17 = 158 tests, all passing)
- Context monitor is now live in `.claude/settings.json` — it fires on every prompt in this session
- Next milestone: v1.2 OpenSpec suite (F-008–F-016), start with F-008 (openspec-init) per FEATURES.md
- Review `WARNINGS.md` — W-001 and W-002 remain open

