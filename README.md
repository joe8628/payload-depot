# Rig

CLI scaffold that bootstraps any project with Claude Code agents, skills, session
templates, config files, and a codebase context index in a single command.

## Install

### One-liner (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/joe8628/Rig/main/bootstrap.sh | bash
```

This clones the repo to `~/.rig` and symlinks `rig-stage` into `~/.local/bin`.
Re-running it updates Rig to the latest version.

### Manual

```bash
git clone https://github.com/joe8628/Rig.git ~/.rig
cd ~/.rig && make install
```

### PATH

Make sure `~/.local/bin` is on your PATH. If not, add this to your `~/.bashrc` or `~/.zshrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Use from any project

```bash
cd ~/my-project
rig-stage install
```

## Usage

```bash
./rig-stage install                        # Install for Claude Code (default)
./rig-stage install --target claude-code   # Explicit target
./rig-stage install --force                # Overwrite existing config files
./rig-stage install --dry-run              # Preview without writing files
./rig-stage install --no-hooks             # Skip pre-commit hook
./rig-stage install --no-codebase-index    # Skip ccindex init

./rig-stage list      # List available agents and skills
./rig-stage version   # Print Rig version
./rig-stage help      # Print usage
```

## Requirements

- bash 5+
- git
- `claude` CLI (for Claude Code target)
- `ccindex` (for codebase context indexing — from the bundled `codebase-context/` submodule)

## Documentation

See `SPEC.md` for full specification.
