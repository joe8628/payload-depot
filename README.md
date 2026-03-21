<div align="center">
  <img src="payload-depot.png" alt="Payload Depot" width="600"/>

  <h1>Payload Depot</h1>
  <p>Bootstrap any project with Claude Code agents, skills, session templates, and a codebase context index — in a single command.</p>

  ![Version](https://img.shields.io/badge/version-1.1.0-blue)
  ![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS-lightgrey)
  ![Shell](https://img.shields.io/badge/shell-bash%205%2B-green)
  ![License](https://img.shields.io/github/license/joe8628/payload-depot)
</div>

---

## Install

**One-liner (recommended)**

```bash
curl -fsSL https://raw.githubusercontent.com/joe8628/payload-depot/main/bootstrap.sh | bash
```

Clones the repo to `~/.rig` and symlinks `payload-depot` into `~/.local/bin`. Re-running updates to the latest version.

**Manual**

```bash
git clone https://github.com/joe8628/payload-depot.git ~/.rig
cd ~/.rig && make install
```

**PATH**

Make sure `~/.local/bin` is on your PATH:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Add that line to your `~/.bashrc` or `~/.zshrc`.

---

## Quick Start

```bash
cd ~/my-project
payload-depot install
```

---

## Usage

```bash
payload-depot install                        # Install for Claude Code (default)
payload-depot install --target claude-code   # Explicit target
payload-depot install --force                # Overwrite existing config files
payload-depot install --dry-run              # Preview without writing files
payload-depot install --no-hooks             # Skip pre-commit hook
payload-depot install --no-codebase-index    # Skip ccindex init

payload-depot list      # List available agents and skills
payload-depot version   # Print version
payload-depot help      # Print usage
```

---

## Requirements

- `bash` 5+
- `git`
- `claude` CLI — required for the Claude Code target
- `ccindex` — bundled via the `codebase-context/` submodule

---

## Documentation

Full specification: [`SPEC.md`](SPEC.md)
