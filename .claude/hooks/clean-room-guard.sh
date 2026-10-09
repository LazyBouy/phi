#!/bin/bash
# .claude/hooks/clean-room-guard.sh — PreToolUse for Bash|Read|Grep|Glob.
# Clean-room guard for the n8n look-and-feel work
# (iphi-flow/docs/plans/n8n-look-and-feel-clean-room.md, "Clean-room protocol").
#
# The build lane must never read the n8n reference tree. This hook denies any
# Bash command, Read path, Grep path or Glob pattern that points into
# /root/projects/phi/iphi-flow/n8n (absolute, or relative as ../n8n or
# iphi-flow/n8n). The one exception is the auditor's provenance script
# clean-room-audit.sh, which compares the fork against n8n by hash and clone scan.
#
# Wired from settings.local.json of every build-lane session. Not wired into the
# reference lane (Phase 1), which is allowed to read n8n.

set -euo pipefail

PAYLOAD=$(cat)
TOOL_NAME=$(echo "$PAYLOAD" | jq -r '.tool_name // ""')

case "$TOOL_NAME" in
  Bash) TARGET=$(echo "$PAYLOAD" | jq -r '.tool_input.command // ""') ;;
  Read) TARGET=$(echo "$PAYLOAD" | jq -r '.tool_input.file_path // ""') ;;
  Grep|Glob) TARGET=$(echo "$PAYLOAD" | jq -r '[.tool_input.path // "", .tool_input.pattern // "", .tool_input.glob // ""] | join(" ")') ;;
  *) exit 0 ;;
esac

[[ -z "$TARGET" ]] && exit 0

if [[ "$TOOL_NAME" == "Bash" ]] && echo "$TARGET" | grep -qE '(^|[[:space:]/])clean-room-audit\.sh([[:space:]]|$)'; then
  exit 0
fi

if echo "$TARGET" | grep -qE '(iphi-flow/n8n|(^|[[:space:]"'"'"'=])\.\./n8n)(/|[[:space:]"'"'"']|$)'; then
  jq -n --arg target "$TARGET" --arg tool "$TOOL_NAME" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: ("clean-room-guard hook: the build lane may not access the n8n reference tree. Work from iphi-flow/docs/specs/n8n-vibe/ (facts-only spec) and the Activepieces fork only. Tool: " + $tool + " Target: " + $target)
    }
  }'
  exit 0
fi

exit 0
