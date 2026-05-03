#!/bin/bash
# .claude/hooks/log-tool-use.sh — PostToolUse / PostToolUseFailure / PermissionRequest.
#
# Append a JSONL telemetry record for every tool call. Never block the workflow.
#
# Wired in settings.json three times, once per event, each with a different $1:
#   "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/log-tool-use.sh PostToolUse"
#   "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/log-tool-use.sh PostToolUseFailure"
#   "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/log-tool-use.sh PermissionRequest"
#
# Output: one JSONL line per call appended to .claude/tool-use.log.
# Schema documented in plan tool-use-logging-and-permissions-audit-skill-18564835.md §2.2.
#
# Fail-safe contract: if anything fails (lock contention, disk full, malformed
# envelope, jq missing) — exit 0 silently. Logging must never block the workflow.

set -uo pipefail   # NOT set -e: per fail-safe contract.

LOG_PATH="${CLAUDE_PROJECT_DIR:-/root/projects/phi}/.claude/tool-use.log"
LOCK_PATH="${LOG_PATH}.lock"
ROTATE_BYTES="${ROTATE_BYTES_OVERRIDE:-$((10 * 1024 * 1024))}"  # 10 MB; override for testing.
KEEP_ROTATIONS=5

# ── compute_signature: cluster-key for the audit skill ─────────────────────────
compute_signature() {
  local tool="$1" input="$2"
  case "$tool" in
    Bash)
      local cmd first_word first_arg
      cmd=$(echo "$input" | awk '{$1=$1; print}')
      first_word=$(echo "$cmd" | awk '{print $1}')
      first_arg=$(echo "$cmd" | awk '{for(i=2;i<=NF;i++) if(substr($i,1,1)!="-") {print $i; exit}}')
      echo "${first_word##*/}:${first_arg:0:50}"
      ;;
    Edit|Write|MultiEdit|Read|NotebookEdit)
      echo "$input" | awk -F/ '{out=""; for(i=1;i<=NF && i<=5;i++) out=out (i>1?"/":"") $i; print out (NF>5?"/...":"")}'
      ;;
    Grep|Glob)
      echo "${input:0:80}"
      ;;
    Agent|WebFetch)
      echo "$input" | head -c 80
      ;;
    *)
      echo "${tool}:${input:0:50}"
      ;;
  esac
}

# ── read envelope ──────────────────────────────────────────────────────────────
PAYLOAD=$(cat 2>/dev/null || echo '{}')

# Self-skip: don't log tool calls that touch the log file itself (avoid recursion).
case "$PAYLOAD" in
  *tool-use.log*) exit 0 ;;
esac

# ── event detection ────────────────────────────────────────────────────────────
# Source of truth: positional arg from settings.json registration.
# Belt-and-suspenders: if envelope carries hook_event_name, validate consistency.
EVENT="${1:-unknown}"
ENVELOPE_EVENT=$(echo "$PAYLOAD" | jq -r '.hook_event_name // .event_name // empty' 2>/dev/null || echo "")
if [[ -n "$ENVELOPE_EVENT" && "$ENVELOPE_EVENT" != "$EVENT" ]]; then
  echo "log-tool-use.sh: event mismatch — arg=$EVENT, envelope=$ENVELOPE_EVENT (trusting arg)" >&2
fi

# ── extract fields with jq (defaulting on missing) ─────────────────────────────
TOOL=$(echo "$PAYLOAD" | jq -r '.tool_name // ""' 2>/dev/null || echo "")
TOOL_USE_ID=$(echo "$PAYLOAD" | jq -r '.tool_use_id // ""' 2>/dev/null || echo "")
TURN_INDEX=$(echo "$PAYLOAD" | jq -r '.turn_index // 0' 2>/dev/null || echo "0")
DURATION_MS=$(echo "$PAYLOAD" | jq -r '.duration_ms // null' 2>/dev/null || echo "null")

# Tool input — varies by tool. Try common field names in order.
INPUT_FULL=$(echo "$PAYLOAD" | jq -r '
  if .tool_input.command then .tool_input.command
  elif .tool_input.file_path then .tool_input.file_path
  elif .tool_input.path then .tool_input.path
  elif .tool_input.pattern then .tool_input.pattern
  elif .tool_input.url then .tool_input.url
  elif .tool_input.subagent_type then ("Agent(" + .tool_input.subagent_type + "): " + (.tool_input.description // ""))
  else (.tool_input | tojson)
  end // ""
' 2>/dev/null || echo "")

# ── redaction: env-var values for sensitive vars ───────────────────────────────
REDACTED=false
if echo "$INPUT_FULL" | grep -qE '\b(SECRET|TOKEN|PASSWORD|KEY|CREDENTIAL)[A-Z_]*=[^[:space:]]+'; then
  INPUT_FULL=$(echo "$INPUT_FULL" | sed -E 's/\b(SECRET|TOKEN|PASSWORD|KEY|CREDENTIAL)([A-Z_]*)=[^[:space:]]+/\1\2=<redacted>/g')
  REDACTED=true
fi

# ── truncate input to 1000 chars ───────────────────────────────────────────────
if [[ ${#INPUT_FULL} -gt 1000 ]]; then
  INPUT_FULL="${INPUT_FULL:0:1000}…"
fi

# ── compute input_signature ────────────────────────────────────────────────────
INPUT_SIGNATURE=$(compute_signature "$TOOL" "$INPUT_FULL")

# ── outcome from event ─────────────────────────────────────────────────────────
case "$EVENT" in
  PostToolUse) OUTCOME=success ;;
  PostToolUseFailure) OUTCOME=failure ;;
  PermissionRequest) OUTCOME=prompted ;;
  *) OUTCOME=unknown ;;
esac

# ── output / error summaries (first 200 chars, line breaks → spaces, trim trailing) ─
# Use jq's // "" default to avoid the "null" string literal entirely.
OUTPUT_SUMMARY=$(echo "$PAYLOAD" | jq -r '.tool_output // ""' 2>/dev/null | head -c 200 | tr '\n' ' ' | sed 's/[[:space:]]*$//')
ERROR_SUMMARY=$(echo "$PAYLOAD" | jq -r '.error // .tool_error // ""' 2>/dev/null | head -c 200 | tr '\n' ' ' | sed 's/[[:space:]]*$//')

# ── compose JSONL line ─────────────────────────────────────────────────────────
LINE=$(jq -nc \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)" \
  --arg event "$EVENT" \
  --arg tool "$TOOL" \
  --arg tool_use_id "$TOOL_USE_ID" \
  --argjson turn "$TURN_INDEX" \
  --arg sig "$INPUT_SIGNATURE" \
  --arg input "$INPUT_FULL" \
  --arg outcome "$OUTCOME" \
  --argjson duration "$DURATION_MS" \
  --arg out "$OUTPUT_SUMMARY" \
  --arg err "$ERROR_SUMMARY" \
  --argjson redacted "$REDACTED" \
  '{ts:$ts, event:$event, tool:$tool, tool_use_id:$tool_use_id, turn_index:$turn,
    input_signature:$sig, input_full:$input, outcome:$outcome,
    duration_ms:$duration, output_summary:$out, error_summary:$err,
    redacted:$redacted, version:1}' 2>/dev/null) || exit 0

# Empty line means jq failed; bail without logging.
[[ -z "$LINE" ]] && exit 0

# ── append under flock with 1s timeout ─────────────────────────────────────────
(
  if flock -w 1 9; then
    # Rotate if needed.
    if [[ -f "$LOG_PATH" ]] && [[ $(stat -c%s "$LOG_PATH" 2>/dev/null || echo 0) -gt $ROTATE_BYTES ]]; then
      for i in $(seq $((KEEP_ROTATIONS - 1)) -1 1); do
        [[ -f "${LOG_PATH}.${i}" ]] && mv "${LOG_PATH}.${i}" "${LOG_PATH}.$((i+1))"
      done
      mv "$LOG_PATH" "${LOG_PATH}.1"
    fi
    echo "$LINE" >> "$LOG_PATH"
  fi
) 9>"$LOCK_PATH" 2>/dev/null

exit 0