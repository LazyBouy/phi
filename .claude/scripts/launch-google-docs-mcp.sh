#!/usr/bin/env bash
# launch-google-docs-mcp.sh — orchestrator-side launcher for the
# a-bonus/google-docs-mcp MCP server. Reads OAuth credentials from
# /root/projects/phi/.env (gitignored), exports them under the names the MCP
# expects (GOOGLE_CLIENT_ID + GOOGLE_CLIENT_SECRET), then execs `npx -y` to
# spawn the server.
#
# Wired into /root/projects/phi/.mcp.json as the `a-bonus-google-docs` server's
# command. Claude Code prompts a one-time trust dialog for project-scoped MCP
# servers; reset via `claude mcp reset-project-choices` if needed.
#
# Authored at Phase 1.4 of the T3.6+ publish-agent build per the approved plan
# at /root/.claude/plans/hi-i-would-like-wobbly-naur.md.

set -euo pipefail

ENV_FILE="/root/projects/phi/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE not found. Set GOOGLE_DOCS_MCP_CLIENT_ID + GOOGLE_DOCS_MCP_CLIENT_SECRET before launching the MCP." >&2
  exit 1
fi

# Source .env with auto-export so child processes inherit the vars.
set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

if [[ -z "${GOOGLE_DOCS_MCP_CLIENT_ID:-}" || -z "${GOOGLE_DOCS_MCP_CLIENT_SECRET:-}" ]]; then
  echo "ERROR: GOOGLE_DOCS_MCP_CLIENT_ID or GOOGLE_DOCS_MCP_CLIENT_SECRET missing in $ENV_FILE." >&2
  echo "       See /root/.claude/plans/hi-i-would-like-wobbly-naur.md Phase 1.2 + 1.3 for setup." >&2
  exit 1
fi

# Map our prefixed env vars to the names the MCP expects.
export GOOGLE_CLIENT_ID="$GOOGLE_DOCS_MCP_CLIENT_ID"
export GOOGLE_CLIENT_SECRET="$GOOGLE_DOCS_MCP_CLIENT_SECRET"

# Optional: profile isolation if the user sets it (per a-bonus README).
if [[ -n "${GOOGLE_DOCS_MCP_PROFILE:-}" ]]; then
  export GOOGLE_MCP_PROFILE="$GOOGLE_DOCS_MCP_PROFILE"
fi

# Hand off to npx. -y auto-accepts the fetch prompt on first run.
exec npx -y @a-bonus/google-docs-mcp "$@"
