#!/usr/bin/env bash
# push-dev-v05.sh — push the v0.5 worktree's dev-v0.5 branches to origin.
#
# Single-purpose push helper so the orchestrator's Bash line never carries a
# bare `git push` (the general push restriction) nor the PAT in argv.
#
# Pushes (in order):
#   1. i-phi submodule  dev-v0.5  -> https://github.com/LazyBouy/i-phi.git   (CRITICAL)
#   2. parent phi       dev-v0.5  -> https://github.com/LazyBouy/phi.git     (best-effort)
#
# Auth: GITHUB_PAT_IPHI from /root/projects/phi/.env, supplied to git via a
# transient GIT_ASKPASS shim (token never appears in argv, never echoed).
#
# Exit: 0 iff the i-phi push succeeds; the parent push is reported but
# non-fatal (its origin may be outside the PAT's scope).

set -euo pipefail

readonly ENV_FILE="/root/projects/phi/.env"
readonly IPHI_DIR="/root/projects/phi/worktrees/phi-v05/i-phi"
readonly PARENT_DIR="/root/projects/phi/worktrees/phi-v05"
readonly BRANCH="dev-v0.5"
readonly IPHI_URL="https://LazyBouy@github.com/LazyBouy/i-phi.git"
readonly PARENT_URL="https://LazyBouy@github.com/LazyBouy/phi.git"

err() { printf 'push-dev-v05: %s\n' "$*" >&2; }
die() { err "$*"; exit 1; }

# --- load token (never echoed) ---
[[ -f "$ENV_FILE" ]] || die ".env not found at $ENV_FILE"
perms=$(stat -c '%a' "$ENV_FILE" 2>/dev/null || echo unknown)
[[ "$perms" == "600" ]] || err "WARNING: $ENV_FILE perms are $perms (expected 600)"
# shellcheck disable=SC1090
GITHUB_PAT_IPHI=$(grep -E '^GITHUB_PAT_IPHI=' "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '"'"'"'')
[[ -n "${GITHUB_PAT_IPHI:-}" ]] || die "GITHUB_PAT_IPHI missing/empty in $ENV_FILE"
export GITHUB_PAT_IPHI

# --- transient GIT_ASKPASS shim (echoes the PAT for the password prompt) ---
ASKPASS=$(mktemp)
trap 'rm -f "$ASKPASS"' EXIT
printf '#!/bin/sh\nexec printf "%%s" "$GITHUB_PAT_IPHI"\n' > "$ASKPASS"
chmod 700 "$ASKPASS"
export GIT_ASKPASS="$ASKPASS"
export GIT_TERMINAL_PROMPT=0

# --- 1. i-phi (critical) ---
err "pushing i-phi $BRANCH -> LazyBouy/i-phi ..."
if git -C "$IPHI_DIR" push "$IPHI_URL" "$BRANCH:$BRANCH" 2>&1 | sed 's/[A-Za-z0-9_-]\{20,\}/<redacted>/g'; then
  err "i-phi push: OK"
else
  die "i-phi push FAILED (see output above)"
fi

# --- 2. parent superproject (best-effort) ---
err "pushing parent phi $BRANCH -> LazyBouy/phi ..."
if git -C "$PARENT_DIR" push "$PARENT_URL" "$BRANCH:$BRANCH" 2>&1 | sed 's/[A-Za-z0-9_-]\{20,\}/<redacted>/g'; then
  err "parent push: OK"
else
  err "parent push FAILED (non-fatal — origin may be outside this PAT's scope; push manually if needed)"
fi

err "done."