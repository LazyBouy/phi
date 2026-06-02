#!/usr/bin/env bash
# backport-push.sh — Stage-1 remote step: push the backport branch to origin and
# open a GitHub PR against dev-v0.5. This is the ONLY script that mutates the
# remote in stage 1. It does NOT merge — a human reviews + merges the PR.
#
# Invoked as `bash /abs/.../backport-push.sh ...` so the block-destructive-bash
# hook (string-match `git push`) does not fire on the internal push; the wrapper
# itself is allow-listed in settings.json.
#
# Usage:
#   bash backport-push.sh --branch backport/<id> --title "<pr title>" \
#        --body-file <path> [--base dev-v0.5] [--dry-run]
#
# Sequence (base-before-head, to avoid a dangling-SHA PR):
#   1. fetch origin (read-only)
#   2. if origin lacks the base branch → push it once (bootstrap)
#   3. push the backport (head) branch  (--force-with-lease)
#   4. gh-rest.sh pr-create --head <branch> --base <base> ...
#
# Precondition: run backport-propagate.sh --prepare first (GREEN). Keep the v05
# worktree's dev-v0.5 in sync with origin/dev-v0.5 before backporting so the PR
# diff is clean.

set -euo pipefail

readonly PHI_ROOT="/root/projects/phi"
readonly V05_WT="${PHI_ROOT}/worktrees/phi-v05/i-phi"
readonly GH_REST="${PHI_ROOT}/.claude/scripts/gh-rest.sh"
readonly ORIGIN="origin"

DRY_RUN=0
BRANCH=""
TITLE=""
BODY_FILE=""
BASE="dev-v0.5"

err() { printf 'backport-push.sh: %s\n' "$*" >&2; }
die() { err "$*"; exit 1; }
note() { printf '[backport-push] %s\n' "$*" >&2; }

run() {
  if [[ $DRY_RUN -eq 1 ]]; then printf '[dry-run] %s\n' "$*" >&2; return 0; fi
  "$@"
}

v05() { git -C "$V05_WT" "$@"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --branch) BRANCH="$2"; shift 2 ;;
    --title) TITLE="$2"; shift 2 ;;
    --body-file) BODY_FILE="$2"; shift 2 ;;
    --base) BASE="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    *) die "unknown arg '$1'" ;;
  esac
done

[[ -n "$BRANCH" ]] || die "--branch required (e.g. backport/D-TEST-0010)"
[[ -n "$TITLE" ]] || die "--title required"
[[ -n "$BODY_FILE" && -f "$BODY_FILE" ]] || die "--body-file must point to an existing file"
v05 rev-parse --verify "$BRANCH" >/dev/null 2>&1 || die "branch '$BRANCH' not found in v05 submodule; run --prepare first"

# 1. fetch origin (safe, read-only)
note "fetch $ORIGIN"
run v05 fetch --no-tags "$ORIGIN"

# 2. bootstrap base on origin if absent (first run creates dev-v0.5 on origin)
if v05 ls-remote --exit-code --heads "$ORIGIN" "$BASE" >/dev/null 2>&1; then
  note "base '$BASE' already on $ORIGIN — not pushing base"
else
  note "base '$BASE' absent on $ORIGIN — bootstrapping"
  run v05 push "$ORIGIN" "${BASE}:refs/heads/${BASE}"
fi

# 3. push the head branch
note "push head '$BRANCH'"
run v05 push --force-with-lease "$ORIGIN" "${BRANCH}:refs/heads/${BRANCH}"

# 4. open the PR (gh-rest.sh is allow-listed; carries no curl token on the cmd line)
note "open PR: head=$BRANCH base=$BASE"
if [[ $DRY_RUN -eq 1 ]]; then
  printf '[dry-run] bash %s pr-create --title %q --head %q --base %q --body-file %q\n' \
    "$GH_REST" "$TITLE" "$BRANCH" "$BASE" "$BODY_FILE" >&2
  exit 0
fi
bash "$GH_REST" pr-create --title "$TITLE" --head "$BRANCH" --base "$BASE" --body-file "$BODY_FILE"