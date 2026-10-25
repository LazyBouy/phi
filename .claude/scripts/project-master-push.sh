#!/usr/bin/env bash
# project-master-push.sh — push the main branch of the phi submodule
# iphi-flow/project_master to origin (LazyBouy/project_master). The ONLY push
# this session may run besides backport-push.sh; the general `git push` /
# `git -C * push*` deny rules in settings.json stay in force for every other
# repo (user-approved 2026-10-25).
#
# Fixed repo, fixed remote, fixed branch, never forced. Takes no arguments
# except --dry-run.
#
# Usage:
#   bash /root/projects/phi/.claude/scripts/project-master-push.sh [--dry-run]

set -euo pipefail

readonly REPO="/root/projects/phi/iphi-flow/project_master"
readonly REMOTE="origin"
readonly BRANCH="main"

DRY_RUN=0
case "${1:-}" in
  "") ;;
  --dry-run) DRY_RUN=1 ;;
  *) printf 'project-master-push.sh: unknown arg %s\n' "$1" >&2; exit 1 ;;
esac

current=$(git -C "$REPO" rev-parse --abbrev-ref HEAD)
if [[ "$current" != "$BRANCH" ]]; then
  printf 'project-master-push.sh: %s is on %s, not %s; refusing\n' "$REPO" "$current" "$BRANCH" >&2
  exit 1
fi

if [[ $DRY_RUN -eq 1 ]]; then
  git -C "$REPO" push --dry-run "$REMOTE" "${BRANCH}:refs/heads/${BRANCH}"
  exit 0
fi

git -C "$REPO" push "$REMOTE" "${BRANCH}:refs/heads/${BRANCH}"
