# OpenSpec Integration — Research & Deferred Plan

> **Status: DEFERRED** — Moved to v1.3. Original implementation plan was discarded after reviewing Fission-AI's documentation. See open questions below before starting implementation.

---

## What OpenSpec Actually Is

OpenSpec is a **Node.js CLI package** (`@fission-ai/openspec`) maintained by Fission-AI, not a set of conventions we implement ourselves.

- **Install:** `npm install -g @fission-ai/openspec`
- **Repo:** https://github.com/Fission-AI/OpenSpec
- **Docs:** https://github.com/Fission-AI/OpenSpec/tree/main/docs

The CLI handles everything end-to-end:

| Command | What it does |
|---|---|
| `openspec init --tools claude` | Creates `openspec/` tree + installs Claude Code skills |
| `openspec update` | Refreshes skills after CLI upgrades |
| `openspec archive` | Merges delta specs + moves change to archive |
| `openspec validate` | Structural validation of changes and specs |
| `openspec status` | Artifact completion status |
| `openspec list` | Lists active changes |
| `openspec show` | Shows change/spec details |

### What it installs into Claude Code

When you run `openspec init --tools claude`, it writes:

```
.claude/skills/openspec-propose/SKILL.md
.claude/skills/openspec-explore/SKILL.md
.claude/skills/openspec-apply-change/SKILL.md
.claude/skills/openspec-archive/SKILL.md
... (more depending on profile)
.claude/commands/opsx/propose.md
.claude/commands/opsx/apply.md
... etc.
```

Skills are generated from OpenSpec's own templates and kept current via `openspec update`.

### Directory structure it creates

```
openspec/
├── specs/              # Living source-of-truth; one file per domain
├── changes/            # One folder per in-flight change
│   └── archive/        # Completed changes land here after archive
└── config.yaml         # Optional project-level config (context injection)
```

---

## Why the Original Plan Was Wrong

The original plan (2026-03-19) proposed writing 8 SKILL.md files by hand for `opsx-propose`, `opsx-explore`, `opsx-apply`, `opsx-archive`, `opsx-verify`, `opsx-ff`, `opsx-continue`, `opsx-bulk-archive`.

**Problems with that approach:**

1. **Duplicates work OpenSpec already does.** `openspec init --tools claude` generates all these skills from its own versioned templates.
2. **Creates a maintenance burden.** Every time OpenSpec releases a new version, our hand-written skills go stale. OpenSpec already solves this with `openspec update`.
3. **Would conflict with OpenSpec-generated files.** If a user runs both `payload-depot install` and `openspec init`, they'd get conflicting skill files.
4. **Misses the CLI layer.** `openspec archive`, `openspec validate` etc. are CLI commands that must be run by the user — they can't be replaced by a SKILL.md.

---

## Correct Integration Strategy

Payload Depot's role is environment bootstrapping. For OpenSpec, that means:

### Option A — Thin wrapper (recommended starting point)

1. Add `openspec` CLI to `env-setup` skill as a required dependency
2. Add `payload-depot openspec-init` as a thin wrapper that:
   - Checks `openspec` CLI is installed (error with install instructions if not)
   - Runs `openspec init --tools claude` in the project directory
3. Register the OpenSpec-generated skills in `registry.md` so `payload-depot-skill-check.sh` doesn't flag them as unregistered
4. Wire `openspec update` into `payload-depot update` so skills stay current

### Option B — Self-contained (no openspec CLI dependency)

Bundle OpenSpec's skill templates directly into Payload Depot (copy them from the OpenSpec repo as static files). Payload Depot becomes responsible for keeping them current.

**Downside:** Becomes stale when OpenSpec releases new versions. More maintenance.

### Option C — Delegate entirely

Document that users should run `openspec init --tools claude` themselves after `payload-depot install`. No Payload Depot integration at all — just a note in the README.

---

## Open Questions (must resolve before implementation)

1. **Which option?** A, B, or C? Depends on how tightly Payload Depot should be coupled to the OpenSpec CLI.

2. **Dependency model:** If Option A — should `openspec` be a hard dependency (install fails without it) or soft (warn and skip)? The `ccindex` integration uses a soft-skip pattern — is that the right model here too?

3. **Profile selection:** OpenSpec has two profiles — `core` (4 commands: propose, explore, apply, archive) and `custom` (full suite including ff, continue, verify, sync, bulk-archive, onboard). Which should `payload-depot openspec-init` configure by default?

4. **Skill registration:** OpenSpec installs skills with names like `openspec-propose` (flat, with prefix). Payload Depot's registry uses `category/name` (e.g., `openspec/propose`). Do we register them as-is under their OpenSpec names, or rename?

5. **Skill-check compatibility:** OpenSpec manages its own skill files and can overwrite them with `openspec update`. Should `payload-depot-skill-check.sh` validate OpenSpec skills (and potentially conflict with OpenSpec's own validation), or explicitly exclude them?

6. **config.yaml:** OpenSpec's `config.yaml` injects project context into all planning prompts. Should Payload Depot pre-populate it with project metadata (name, language, description) after running `openspec init`? This would be analogous to F-001 (CLAUDE.md placeholder substitution).

7. **F-008 through F-016 scope:** Are all 9 features still relevant? Some (F-013 verify, F-014 ff, F-015 continue, F-016 bulk-archive) map to OpenSpec's expanded profile commands. Should they become registry entries pointing at OpenSpec-generated skills rather than hand-written SKILL.md files?

---

## Recommended Next Steps Before Implementation

1. **Install OpenSpec locally and run `openspec init --tools claude`** in a test project. Inspect what skills it generates and what they contain. This answers questions 3, 4, 5.
2. **Decide on Option A/B/C** based on how much coupling is acceptable.
3. **Rewrite FEATURES.md F-008 through F-016** to reflect the correct integration approach once option is chosen.
4. **Write a new implementation plan** — the 2026-03-19 plan is invalid and should not be executed.

---

## References

- CLI docs: https://github.com/Fission-AI/OpenSpec/blob/main/docs/cli.md
- Commands docs: https://github.com/Fission-AI/OpenSpec/blob/main/docs/commands.md
- Workflows docs: https://github.com/Fission-AI/OpenSpec/blob/main/docs/workflows.md
- Supported tools: https://github.com/Fission-AI/OpenSpec/blob/main/docs/supported-tools.md
- Getting started: https://github.com/Fission-AI/OpenSpec/blob/main/docs/getting-started.md
