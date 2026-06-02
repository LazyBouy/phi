#!/usr/bin/env bash
# fetch-dev-v05.sh — authenticated, read-only fetch of LazyBouy/i-phi origin
# into the v0.5 worktree (private repo needs the PAT for fetch too).
#
# Read-only: fetch + prune only. No checkout, no merge, no push. The caller
# does branch switch / fast-forward with plain local git afterward.
#
# Auth: GITHUB_PAT_IPHI from /root/projects/phi/.env via a transient
# GIT_ASKPASS shim (token never in argv, never echoed).

set -euo pipefail

readonly ENV_FILE="/root/projects/phi/.env"
readonly IPHI_DIR="/root/projects/phi/worktrees/phi-v05/i-phi"
readonly IPHI_URL="https://LazyBouy@github.com/LazyBouy/i-phi.git"

err() { printf 'fetch-dev-v05: %s\n' "$*" >&2; }
die() { err "$*"; exit 1; }

[[ -f "$ENV_FILE" ]] || die ".env not found at $ENV_FILE"
GITHUB_PAT_IPHI=$(grep -E '^GITHUB_PAT_IPHI=' "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '"'"'"'')
[[ -n "${GITHUB_PAT_IPHI:-}" ]] || die "GITHUB_PAT_IPHI missing/empty in $ENV_FILE"
export GITHUB_PAT_IPHI

ASKPASS=$(mktemp)
trap 'rm -f "$ASKPASS"' EXIT
printf '#!/bin/sh\nexec printf "%%s" "$GITHUB_PAT_IPHI"\n' > "$ASKPASS"
chmod 700 "$ASKPASS"
export GIT_ASKPASS="$ASKPASS"
export GIT_TERMINAL_PROMPT=0

err "fetching origin (LazyBouy/i-phi) into worktree, with prune ..."
# Fetch updates the origin/* remote-tracking refs for this worktree's repo.
git -C "$IPHI_DIR" fetch --prune "$IPHI_URL" \
  '+refs/heads/*:refs/remotes/origin/*' 2>&1 | sed 's/[A-Za-z0-9_-]\{20,\}/<redacted>/g'
err "fetch OK."