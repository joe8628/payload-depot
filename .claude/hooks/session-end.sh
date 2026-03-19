#!/usr/bin/env bash
# Rig session-end reminder
# Installed to .claude/hooks/session-end.sh by rig-stage.
# Fires on the Stop event (when Claude finishes responding).
# Reminds to write session files if HANDOFF.md has no entry for today.

today=$(date +%Y-%m-%d)

if ! grep -qF "$today" HANDOFF.md 2>/dev/null; then
  echo ""
  echo "[rig] Session-end checklist (HANDOFF.md not yet updated today):"
  echo "  1. Append your completed block to HANDOFF.md"
  echo "  2. Record non-trivial decisions to DECISIONS.md"
  echo "  3. Finalise SCRATCHPAD.md with a session summary"
  echo "  4. git add HANDOFF.md DECISIONS.md && git commit -m 'handoff: <agent> completed <task>' && git push"
fi
