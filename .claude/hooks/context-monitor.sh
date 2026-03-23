#!/usr/bin/env bash
# UserPromptSubmit hook: monitor context window usage and warn at key thresholds.
# Installed to .claude/hooks/context-monitor.sh by payload-depot.
#
# Thresholds:
#   70%  — WARN:     stay alert, consider /compact soon
#   85%  — ALERT:    run /compact now
#   90%+ — CRITICAL: run /clear (responses become unreliable above this)
#
# Stdin (from Claude Code): JSON with session_id and transcript_path.
#
# Output behaviour:
#   - Warnings go to stderr — visible in terminal, does not consume context.
#   - At CRITICAL level, a single-line notice is also emitted to stdout so
#     Claude is aware and can prompt the user to run /clear.
#
# Configuration:
#   Set PAYLOAD_DEPOT_MAX_TOKENS in the environment or in .claude/context.conf
#   to override the default 200 000-token limit.

PREFIX="[payload-depot:context]"

if ! command -v jq &>/dev/null; then
  exit 0
fi

input=$(cat)
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty' 2>/dev/null)

[[ -z "$transcript_path" || ! -f "$transcript_path" ]] && exit 0

# ── Configuration ─────────────────────────────────────────────────────────────
# Default: 200 000 tokens (all current Claude models).
# Override: set PAYLOAD_DEPOT_MAX_TOKENS or add it to .claude/context.conf.
MAX_TOKENS=200000
[[ -f ".claude/context.conf" ]] && source ".claude/context.conf" 2>/dev/null || true
MAX_TOKENS=${PAYLOAD_DEPOT_MAX_TOKENS:-$MAX_TOKENS}

WARN_PCT=70
ALERT_PCT=85
CRITICAL_PCT=90

# ── Token estimation ──────────────────────────────────────────────────────────
# Approximation: transcript_bytes / 4  +  20 000 tokens overhead for
# CLAUDE.md, system prompt, and repo map loaded at session start.
transcript_bytes=$(wc -c < "$transcript_path" 2>/dev/null || echo 0)
system_overhead=20000
tokens_est=$(( (transcript_bytes / 4) + system_overhead ))
pct=$(( (tokens_est * 100) / MAX_TOKENS ))

[[ $pct -lt $WARN_PCT ]] && exit 0

# ── Session goal (optional) ───────────────────────────────────────────────────
goal_line=""
if [[ -f ".claude/session-goal.txt" ]]; then
  goal=$(head -1 ".claude/session-goal.txt" 2>/dev/null | tr -d '\n')
  [[ -n "$goal" ]] && goal_line="  Goal: $goal"
fi

# ── Threshold label and advice ────────────────────────────────────────────────
if [[ $pct -ge $CRITICAL_PCT ]]; then
  level="CRITICAL"
  bar="[##########] 90%+"
  advice="Run /clear — above 90% responses become erratic. Start a fresh session."
elif [[ $pct -ge $ALERT_PCT ]]; then
  level="ALERT"
  bar="[########..] 85%"
  advice="Run /compact now to compress conversation history."
else
  level="WARN"
  bar="[#######...] ~${pct}%"
  advice="Run /compact soon — precision degrades above 70%."
fi

# ── Emit terminal warning (stderr) ───────────────────────────────────────────
echo "" >&2
echo "$PREFIX $level  $bar  (~${tokens_est} / ${MAX_TOKENS} est. tokens)" >&2
[[ -n "$goal_line" ]] && echo "$PREFIX$goal_line" >&2
echo "$PREFIX $advice" >&2
echo "" >&2

# ── At CRITICAL: inject a brief notice into Claude's context (stdout) ─────────
# One line only — ~20 tokens, negligible cost.
if [[ $pct -ge $CRITICAL_PCT ]]; then
  echo "CONTEXT MONITOR: ~${pct}% context used. Please advise the user to run /clear and start a fresh session before continuing."
fi

exit 0
