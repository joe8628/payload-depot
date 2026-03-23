# /goal — Set or view the current session goal

Use this command to name the objective of the current session explicitly.
Naming the goal helps maintain focus, manage context, and signal when the
scope has changed enough to warrant a fresh session.

## Process

1. **View current goal** (no argument given):
   - Check whether `.claude/session-goal.txt` exists.
   - If it exists, read and display the first line.
   - If it does not exist, say: "No session goal set. Use `/goal <description>` to set one."

2. **Set a new goal** (argument provided after `/goal`):
   - Write the provided text as the first (and only) line of `.claude/session-goal.txt`.
   - Confirm: "Session goal set: <goal>"
   - Note: setting a new goal mid-session is a signal to consider whether the context should be compacted first.

3. **Display context health** after showing the goal:
   - Run: `bash .claude/hooks/context-monitor.sh < /dev/null 2>&1 | head -5`
   - This gives the user a current context usage estimate alongside the goal.

4. **Remind the user** of the session strategy:
   - 0–70%: work freely
   - 70–85%: stay alert, run /compact soon
   - 85–90%: run /compact now
   - 90%+: run /clear and start a fresh session

## Goal file location
`.claude/session-goal.txt` — one line, plain text. Gitignored (session-local only).
