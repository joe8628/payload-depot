# Changelog

All notable changes to Payload Depot will be documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
Versioning: [Semantic Versioning](https://semver.org/)

## [1.0.0] — 2026-03-15

### Added

- `payload-depot` CLI entrypoint with `install`, `list`, `version`, and `help` commands (named `payload-depot` to avoid collision with `rig` apt package)
- `payload-depot install` flags: `--target`, `--force`, `--dry-run`, `--no-hooks`, `--no-codebase-index`
- `Makefile` with `install` target (symlink to `~/.local/bin/payload-depot`) and `uninstall` target
- Claude Code target adapter (`targets/claude-code/adapter.sh`)
- 9 agents with prompt versioning headers: `architect`, `planner`, `code-writer`, `code-reviewer`, `docs-writer`, `security-auditor`, `debugger`, `test-writer`, `issue-logger`
- 10 skills with prompt versioning headers: `tdd`, `linting`, `type-checking`, `dependency-audit`, `adr`, `readme-gen`, `openapi-lint`, `changelog`, `commit-msg`, `env-setup`
- Config templates for Claude Code: `CLAUDE.md`, `CONVENTIONS.md`, `AGENTS.md`, `settings.json`
- Session templates: `HANDOFF.md`, `SCRATCHPAD.md`, `DECISIONS.md`
- `HANDOFF.md` and `DECISIONS.md` committed to git for cross-session, cross-machine context persistence
- `pre-commit` hook with language detection (Python, TypeScript, C/C++) and lint + type-check enforcement
- `codebase-context` MCP integration via `ccindex init` — semantic search across agent sessions
- `@.codebase-context/repo_map.md` reference in `CLAUDE.md.template` for automatic codebase overview injection
- Session start protocol: `git pull` → read `HANDOFF.md` → read `CONVENTIONS.md`
- Session end protocol: finalise `SCRATCHPAD.md` → append `HANDOFF.md` → commit and push
- 41 automated tests across CLI, install, and hook test suites
- Target adapter interface for future OpenAI and Gemini targets (v2.0/v3.0 stubs)

### Design decisions

- Context manager removed — replaced by `HANDOFF.md`/`DECISIONS.md` committed to git (no encryption overhead, native git sync)
- `rig` implemented as a bash script with zero runtime dependencies beyond bash, git, and standard Unix utilities
- Agent and skill content is LLM-agnostic markdown; tool-specific wiring lives in `targets/`
