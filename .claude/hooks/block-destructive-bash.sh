#!/bin/bash
# .claude/hooks/block-destructive-bash.sh — PreToolUse for Bash.
# Defense-in-depth: regex-deny destructive bash even if rules slip through.
#
# Hook contract: stdin is a JSON envelope from Claude Code with
#   { "tool_name": "Bash", "tool_input": { "command": "..." } }
# Output a deny-decision JSON to stdout if the command matches any blocked pattern.
# Exit 0 in all cases (we use the JSON decision channel, not exit codes).
#
# The patterns below intentionally overlap with settings.json deny rules — this
# is belt-and-suspenders. If the user / orchestrator adds an allow rule that
# accidentally covers a destructive command, this hook still blocks it.

set -euo pipefail

PAYLOAD=$(cat)
TOOL_NAME=$(echo "$PAYLOAD" | jq -r '.tool_name // ""')
COMMAND=$(echo "$PAYLOAD" | jq -r '.tool_input.command // ""')

[[ "$TOOL_NAME" != "Bash" ]] && exit 0
[[ -z "$COMMAND" ]] && exit 0

deny() {
  jq -n --arg cmd "$COMMAND" --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: ("block-destructive-bash hook: " + $reason + " Command: " + $cmd)
    }
  }'
  exit 0
}

# Destructive rm
echo "$COMMAND" | grep -qE '\brm\s+-[rRfF]+' && deny "rm with destructive flags blocked; use Edit/Write tool or ask user explicitly."
# Privilege escalation
echo "$COMMAND" | grep -qE '\bsudo\b|\bsu\s' && deny "Privilege escalation blocked."
# Git destructive
echo "$COMMAND" | grep -qE '\bgit\s+(commit|push|reset\s+--hard|rebase|merge|tag|clean\s+-[df]|checkout\s+--)' && deny "Destructive git operation blocked; user owns commit/push/rebase."
# Network
echo "$COMMAND" | grep -qE '\b(curl|wget|nc|ssh|scp|rsync|sftp|telnet)\b' && deny "Network I/O blocked; use WebFetch tool for URL access."
# Package install
echo "$COMMAND" | grep -qE '\b(npm|yarn|pnpm)\s+(install|i|add)\b|\bpip3?\s+install\b|\bbrew\s+(install|uninstall)\b|\b(apt|apt-get)\s+(install|remove)\b|\bdpkg\s+-i\b|\bcargo\s+install\b' && deny "Package install blocked; user authorizes installs in their terminal."
# Disk / filesystem
echo "$COMMAND" | grep -qE '\bdd\s+(if|of)=|\bmkfs(\.|\b)|>\s*/dev/sd[a-z]' && deny "Disk-level operation blocked."
# Permissive chmod
echo "$COMMAND" | grep -qE '\bchmod\s+-?R?\s*777\b' && deny "chmod 777 blocked."

exit 0