# Rig — Project Brief

**Rig** is a CLI-installable scaffold that bootstraps any new project with a predefined set of AI coding agents, skills, config templates, and a context manager. A single command (`rig install`) copies everything into a target project and has it ready to work in seconds.

## Goal

Build and maintain the Rig scaffold repository so that any new project — regardless of language or LLM tooling — can be bootstrapped consistently and immediately. Rig is LLM-agnostic by design: agent and skill content lives once as canonical `.md` files; tool-specific wiring is handled by target adapters.

---

## Supported Project Types

- Web/API backends
- CLI tools & scripts
- AI agent systems
- Libraries/packages

## Supported Languages

Python, TypeScript, C/C++

---

## Repository Structure

```
rig/
├── agents/                        ← canonical agent prompts (LLM-agnostic)
│   ├── architect.md
│   ├── planner.md
│   ├── code-writer.md
│   ├── code-reviewer.md
│   ├── docs-writer.md
│   ├── security-auditor.md
│   └── debugger.md
├── skills/                        ← canonical skill prompts (LLM-agnostic)
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
├── targets/                       ← tool-specific wiring and config formats
│   ├── claude-code/               ← default target
│   │   ├── install.sh
│   │   ├── CLAUDE.md.template
│   │   ├── CONVENTIONS.md.template
│   │   ├── AGENTS.md.template
│   │   └── settings.json.template
│   ├── openai/                    ← future
│   └── gemini/                    ← future
├── session/
│   ├── SCRATCHPAD.md.template
│   ├── DECISIONS.md.template
│   └── HANDOFF.md.template
├── hooks/
│   └── pre-commit
├── context-manager/               ← existing submodule or install hook
└── rig-stage                      ← main CLI entrypoint
```

---

## Agents

| Agent | Role | When to invoke |
|---|---|---|
| `architect` | Produces structured system design: components, data flow, interface contracts, edge cases | Before writing any code on a new feature or system |
| `planner` | Decomposes a vague brief into a structured `TASKS.md` | At project start or when beginning a large feature |
| `code-writer` | Implements features following project conventions | After architect/planner output is ready |
| `code-reviewer` | Reviews code for correctness, style, and maintainability | After code-writer produces a diff or file set |
| `docs-writer` | Generates/updates README, API docs, and docstrings from existing code | After implementation is stable |
| `security-auditor` | Reviews code and dependency manifests for vulnerabilities and insecure patterns | Before any release or merge to main |
| `debugger` | Reads error output, relevant code, and git log to produce a structured root cause analysis and fix plan | When a runtime error, test failure, or unexpected behaviour needs diagnosis |

---

## Skills

| Skill | Purpose |
|---|---|
| `tdd` | Test-driven development workflow and test scaffolding |
| `linting` | Runs and interprets linting for the detected language |
| `type-checking` | Runs type checker (mypy, tsc, etc.) and interprets output |
| `dependency-audit` | Runs the appropriate audit tool (pip-audit, npm audit, cargo audit) and summarises findings |
| `adr` | Scaffolds and maintains Architecture Decision Records in `/docs/decisions/` |
| `readme-gen` | Generates a README skeleton from project tree and entry points |
| `openapi-lint` | Validates/lints OpenAPI or AsyncAPI specs; generates stubs from routes |
| `changelog` | Generates CHANGELOG entries from git log or task list (Keep a Changelog format) |
| `commit-msg` | Generates a conventional commit message from the staged diff; eliminates manual commit message decisions |
| `env-setup` | Documents and scaffolds local dev environment: `.env.example`, required system deps, and setup steps; updates automatically when new dependencies are added |

---

## Config Templates

### `CLAUDE.md.template`
Project-level instruction file that Claude Code reads automatically. Includes:
- Project coding conventions and preferred patterns
- Registry of available agents and when to invoke each
- Language and toolchain specifics
- Reference to `CONVENTIONS.md` for detailed rules

### `CONVENTIONS.md.template`
Codified project rules kept separate from agent instructions so conventions can evolve independently. Includes:
- Naming conventions (files, variables, functions, classes)
- Error handling patterns
- Preferred libraries and what to avoid
- Explicit "never do" rules (e.g. no inline secrets, no `any` types, no silent exceptions)
- Branch naming format that feeds directly into planner/architect output

### `settings.json.template`
`.claude/settings.json` baseline covering:
- Allowed and disallowed tools
- Permission defaults

### `AGENTS.md.template`
Human-readable agent registry listing all installed agents, their purpose, trigger conditions, expected inputs, and expected outputs.

---

## Session Files

Per-session working files copied into the project root at session start. Not committed to git (add to `.gitignore`).

### `SCRATCHPAD.md`
Agent working log for a single session. The active agent writes reasoning, decisions made, things skipped and why, and open questions as it works. Provides a debugging trail when reviewing agent decisions after the fact. Ephemeral — not committed to git.

**Template fields:** session date, agent name, task description, working notes (append-only), open questions, summary for handoff.

### `DECISIONS.md`
Implementation-level decision log. Distinct from ADRs (which cover architecture) — this captures micro-decisions made during coding: "chose X over Y because Z", "skipped refactor of module A as out of scope". One entry per meaningful decision. Committed to git — persists across sessions and machines.

**Template fields:** decision, alternatives considered, rationale, affected files.

### `HANDOFF.md`
Structured output file written by each agent when it finishes, read by the next agent as its starting context. Prevents context loss between sessions and between agents in a chain. Each agent appends its own block; the file accumulates the session chain. Committed to git — persists across sessions and machines. Agents run `git pull` before reading it and `git commit && git push` after appending.

**Template fields per agent block:** agent name, task completed, output files produced, assumptions made, what was not done and why, uncertainties, instructions for next agent.

---

## `rig-stage` CLI

The main entrypoint. Named `rig-stage` to avoid collision with the system `rig` apt package. Supports a `--target` flag for multi-LLM installs. Defaults to `claude-code`. Install globally with `make install`.

### Behaviour (unconditional copy with safe exceptions)

1. Copy `agents/` → target agents directory
2. Copy `skills/` → target skills directory
3. Copy target config templates → project root (skip if file exists unless `--force`)
4. Copy `session/` templates → project root
5. Install `hooks/pre-commit` → `.git/hooks/pre-commit` (make executable)
6. Run context-manager install command
7. Print install summary

### Usage

```bash
# Install for Claude Code (default)
./rig-stage install

# Install for a specific target
./rig-stage install --target claude-code
./rig-stage install --target openai       # future
./rig-stage install --target gemini       # future

# Force overwrite of existing config files
./rig-stage install --force
```

---

## Git Hooks

### `pre-commit`
Runs automatically before every commit. Invokes the `linting` and `type-checking` skills for the detected language. Blocks the commit if either check fails and prints actionable output. Eliminates a whole class of code-reviewer comments and makes those skills automatic rather than agent-triggered.

**Implementation notes:** must detect language/package manager from project root; must be fast enough not to disrupt flow (target under 10 seconds); should be skippable with `--no-verify` for emergencies.

---

## Prompt Versioning

Agent `.md` files are treated as versioned artifacts, not static config.

Each agent file includes a header block:
```
version: 1.0.0
updated: YYYY-MM-DD
changelog:
  - 1.0.0: initial version
```

**Rationale:** when an agent starts producing different output, versioning makes it possible to determine whether the prompt changed or the model did. Enables rollback to a known-good prompt. Supports structured improvement over time.

**Versioning convention:** semver. Patch = wording fix. Minor = new behaviour or output field. Major = fundamental change to role or output format.

---

## Codebase Context (MCP)

Pre-existing component. Provides shared codebase knowledge across agents via MCP. Storage layer is ChromaDB (PersistentClient) at `.codebase-context/chroma/`. Multiple agents sharing the same project root share the same collection and repo map.

MCP tools exposed to agents:
- `search_codebase` — semantic vector search over code symbols
- `get_symbol` — exact symbol lookup by name
- `get_repo_map` — compact file/class/function outline (also injected via `CLAUDE.md` → `@.codebase-context/repo_map.md`)

Initialised via `ccindex init` (full index) or `ccindex watch` (incremental on file change). Invoked as a step during `rig install`. The `.codebase-context/chroma/` directory is local and not committed.

---

## Multi-LLM Portability

Rig is designed so that agent and skill *content* is canonical and lives once. Tool-specific *wiring* — install paths, config formats, invocation conventions — lives in `targets/`.

### What is portable as-is

- All agent and skill `.md` files — plain prompt instructions any LLM can consume
- Session files (`SCRATCHPAD.md`, `DECISIONS.md`, `HANDOFF.md`) — LLM-agnostic structured markdown
- `CONVENTIONS.md` and project-level instruction files — human-readable rules any model can read
- `pre-commit` hook — git-native, fully portable

### What is target-specific

| Component | Claude Code | OpenAI | Gemini |
|---|---|---|---|
| Agent install path | `.claude/agents/` | TBD | TBD |
| Skill install path | `.claude/skills/` | TBD | TBD |
| Config format | `settings.json` | TBD | TBD |
| Project instruction file | `CLAUDE.md` | TBD | TBD |
| Agent invocation syntax | Claude Code conventions | Assistants/Threads API | Gemini agentic model |

### Target adapter spec

Each directory under `targets/` must contain:

- `install.sh` — target-specific copy logic called by `rig install --target <name>`
- Prompt wrappers or syntax adapters if the canonical `.md` files need reformatting for that tool
- Config templates in the tool's native format
- A `README.md` documenting any known behavioural differences from the Claude Code baseline

### Roadmap

- **v1.0** — Claude Code target only (current scope)
- **v2.0** — OpenAI target adapter
- **v3.0** — Gemini target adapter
- **Future** — `rig diff --target openai` to surface prompt compatibility issues before installing

---



### v1.0 — Claude Code target

1. `HANDOFF.md` template and spec — connective tissue for the whole agent chain
2. `architect` agent
3. `targets/claude-code/CLAUDE.md.template` and `CONVENTIONS.md.template`
4. `security-auditor` agent
5. `dependency-audit` skill
6. `debugger` agent
7. `pre-commit` hook
8. `commit-msg` skill
9. `rig-stage` CLI entrypoint with `install` command
10. `SCRATCHPAD.md` and `DECISIONS.md` templates
11. Remaining agents and skills
12. Prompt versioning headers on all agent files
13. Codebase context MCP (`ccindex init`) invoked as install step; `CLAUDE.md.template` references `@.codebase-context/repo_map.md`

### v2.0 — OpenAI target

13. Research OpenAI Codex/Assistants install paths and config format
14. Write `targets/openai/install.sh` and config templates
15. Identify and resolve any agent prompt syntax incompatibilities

### v3.0 — Gemini target

16. Research Gemini Code Assist install paths and config format
17. Write `targets/gemini/install.sh` and config templates
18. Identify and resolve any agent prompt syntax incompatibilities

---

## Open Tasks

### Agents
- [ ] Write `architect.md`
- [ ] Write `planner.md`
- [ ] Write `docs-writer.md`
- [ ] Write `security-auditor.md`
- [ ] Write `debugger.md`
- [ ] Add prompt version headers to all existing agent files (`code-writer.md`, `code-reviewer.md`)

### Skills
- [ ] Write `dependency-audit.md`
- [ ] Write `adr.md`
- [ ] Write `readme-gen.md`
- [ ] Write `openapi-lint.md`
- [ ] Write `changelog.md`
- [ ] Write `commit-msg.md`
- [ ] Write `env-setup.md`
- [ ] Add prompt version headers to all existing skill files (`tdd.md`, `linting.md`, `type-checking.md`)

### Config Templates — Claude Code target
- [ ] Write `targets/claude-code/CLAUDE.md.template`
- [ ] Write `targets/claude-code/CONVENTIONS.md.template`
- [ ] Write `targets/claude-code/settings.json.template`
- [ ] Write `targets/claude-code/AGENTS.md.template`
- [ ] Write `targets/claude-code/install.sh`

### Config Templates — OpenAI target (v2.0)
- [ ] Research OpenAI agentic tool install paths and config format
- [ ] Write `targets/openai/install.sh`
- [ ] Write `targets/openai/README.md` documenting differences from Claude Code baseline

### Config Templates — Gemini target (v3.0)
- [ ] Research Gemini Code Assist install paths and config format
- [ ] Write `targets/gemini/install.sh`
- [ ] Write `targets/gemini/README.md` documenting differences from Claude Code baseline

### Session Templates
- [ ] Write `SCRATCHPAD.md.template`
- [ ] Write `DECISIONS.md.template`
- [ ] Write `HANDOFF.md.template`

### Git Hooks
- [ ] Write `pre-commit` hook (linting + type-checking, language detection)

### Infrastructure
- [ ] Write `rig` CLI entrypoint (bash or Python) with `install` and `--target` flag
- [ ] Integrate context-manager as submodule or install hook
- [ ] Add session templates to `.gitignore` template
- [ ] Test end-to-end install on a fresh project for each supported language
