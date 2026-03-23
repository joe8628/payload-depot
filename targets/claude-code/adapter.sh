#!/usr/bin/env bash
# Claude Code target adapter
# Sourced by `payload-depot install` — do not execute directly.

ADAPTER_NAME="claude-code"
AGENT_INSTALL_PATH=".claude/agents"
SKILL_INSTALL_PATH=".claude/skills"

CONFIG_FILES=(
  "CLAUDE.md.template:CLAUDE.md"
  "CONVENTIONS.md.template:CONVENTIONS.md"
  "AGENTS.md.template:AGENTS.md"
  "settings.json.template:.claude/settings.json"
)

adapter_validate() {
  command -v claude &>/dev/null
}

adapter_pre_install() {
  mkdir -p ".claude/hooks"
  mkdir -p ".claude/commands"
  mkdir -p ".claude/agents"
}

adapter_post_install() {
  cp "$PAYLOAD_DEPOT_DIR/targets/claude-code/session-start.sh"    ".claude/hooks/session-start.sh"
  chmod +x ".claude/hooks/session-start.sh"
  cp "$PAYLOAD_DEPOT_DIR/targets/claude-code/session-end.sh"      ".claude/hooks/session-end.sh"
  chmod +x ".claude/hooks/session-end.sh"
  cp "$PAYLOAD_DEPOT_DIR/targets/claude-code/payload-depot-health-check.sh" ".claude/hooks/payload-depot-health-check.sh"
  chmod +x ".claude/hooks/payload-depot-health-check.sh"
  cp "$PAYLOAD_DEPOT_DIR/targets/claude-code/payload-depot-skill-check.sh"  ".claude/hooks/payload-depot-skill-check.sh"
  chmod +x ".claude/hooks/payload-depot-skill-check.sh"
  cp "$PAYLOAD_DEPOT_DIR/targets/claude-code/payload-depot-agent-check.sh" ".claude/hooks/payload-depot-agent-check.sh"
  chmod +x ".claude/hooks/payload-depot-agent-check.sh"
  # Install context monitor hook
  cp "$PAYLOAD_DEPOT_DIR/targets/claude-code/context-monitor.sh"      ".claude/hooks/context-monitor.sh"
  chmod +x ".claude/hooks/context-monitor.sh"
  # Install quality hooks
  cp "$PAYLOAD_DEPOT_DIR/targets/claude-code/post-edit-lint.sh"       ".claude/hooks/post-edit-lint.sh"
  chmod +x ".claude/hooks/post-edit-lint.sh"
  cp "$PAYLOAD_DEPOT_DIR/targets/claude-code/pre-write-secret-scan.sh" ".claude/hooks/pre-write-secret-scan.sh"
  chmod +x ".claude/hooks/pre-write-secret-scan.sh"
  cp "$PAYLOAD_DEPOT_DIR/targets/claude-code/post-bash-test.sh"        ".claude/hooks/post-bash-test.sh"
  chmod +x ".claude/hooks/post-bash-test.sh"
  # Install slash commands
  cp "$PAYLOAD_DEPOT_DIR/targets/claude-code/commands/review.md"  ".claude/commands/review.md"
  cp "$PAYLOAD_DEPOT_DIR/targets/claude-code/commands/handoff.md" ".claude/commands/handoff.md"
  cp "$PAYLOAD_DEPOT_DIR/targets/claude-code/commands/debug.md"   ".claude/commands/debug.md"
  cp "$PAYLOAD_DEPOT_DIR/targets/claude-code/commands/goal.md"    ".claude/commands/goal.md"
  # Clear the verified marker so the health check runs on the next session start
  rm -f ".payload-depot-verified"
}
