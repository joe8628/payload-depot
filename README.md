# Rig

CLI scaffold that bootstraps any project with Claude Code agents, skills, session
templates, config files, and a codebase context index in a single command.

## Install globally

```bash
make install   # symlinks rig-stage → ~/.local/bin/rig-stage
```

Then use from any project:

```bash
cd my-project
rig-stage install
```

Or run directly without installing:

```bash
./rig-stage install
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
