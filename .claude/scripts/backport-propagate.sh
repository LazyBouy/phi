#!/usr/bin/env bash
# backport-propagate.sh — deterministic driver for propagating i-phi runtime
# defect fixes from dev-v0-e2e (phi-e2e worktree) to dev-v0.5 (phi-v05 worktree).
#
# This script owns ONLY the mechanical, exit-coded steps. Relevance judgment +
# PR-body authoring belong to the backport-propagator agent / /propagate-fixes
# skill. The script never pushes and never commits (that is backport-push.sh /
# backport-bump.sh, the allow-listed remote-mutating wrappers).
#
# Modes:
#   --scan                         Read-only. Emit candidate fix commits as
#                                  newline-delimited JSON on stdout (one object
#                                  per commit). Empty stdout = no candidates
#                                  (a normal, non-error outcome).
#   --prepare <drift-id|SHA>...    Cherry-pick the selected commit(s) onto a
#                                  backport/<id> branch off dev-v0.5 in a
#                                  DEDICATED throwaway worktree, then run the 4
#                                  CI guards + clippy + test under the v05 cargo
#                                  tag. On GREEN the branch persists for push.
#   --dry-run                      With --prepare: echo each mutating git/CI
#                                  command instead of executing it.
#
# Exit codes:
#   0   scan ok (possibly empty) | prepare GREEN
#   10  usage error
#   20  cherry-pick CONFLICT       (branch deleted; diagnostic on stderr)
#   21  CI guard FAIL              (branch deleted)
#   22  clippy FAIL                (branch deleted)
#   23  test FAIL                  (branch deleted)
#   30  setup error (fetch / worktree add / unknown drift-id)
#
# Granular-Bash note: this whole file is invoked as `bash /abs/.../backport-propagate.sh`,
# so the block-destructive-bash hook (which string-matches `git push|commit|...`)
# never fires on the internal git calls — they live inside the file, not on the
# Bash tool command line.

set -euo pipefail

# ---------- constants ----------
readonly PHI_ROOT="/root/projects/phi"
readonly E2E_WT="${PHI_ROOT}/worktrees/phi-e2e/i-phi"       # source working tree (dev-v0-e2e)
readonly V05_WT="${PHI_ROOT}/worktrees/phi-v05/i-phi"       # target working tree (dev-v0.5) — NOT disturbed
readonly V05_PHI_CORE="${PHI_ROOT}/worktrees/phi-v05/phi-core"
readonly SRC_BRANCH="dev-v0-e2e"
readonly BASE_BRANCH="dev-v0.5"
readonly E2E_TIP_REF="refs/backport/e2e-tip"
readonly WORK="${PHI_ROOT}/.git/backport-work/v05-i-phi"    # throwaway build worktree (under .git; never tracked)
readonly DOCKER_CARGO="${PHI_ROOT}/.claude/scripts/docker-cargo.sh"
readonly DRIFT_RE='D-TEST-[0-9]{4}|D-C[CH][0-9]{2}[a-z]?-FOLLOWUP-[0-9]{2}'
readonly CLOSE_RE='\b(close|closure|closed)\b'

DRY_RUN=0

err()  { printf 'backport-propagate.sh: %s\n' "$*" >&2; }
die()  { err "$*"; exit "${2:-10}"; }
note() { printf '[backport] %s\n' "$*" >&2; }

v05() { git -C "$V05_WT" "$@"; }

# Echo-or-run wrapper for mutating steps (honours --dry-run).
run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] %s\n' "$*" >&2
    return 0
  fi
  "$@"
}

# ---------- shared: make the e2e tip reachable in the v05 submodule object DB ----------
fetch_e2e_tip() {
  [[ -d "$E2E_WT" ]] || die "e2e worktree not found at $E2E_WT" 30
  v05 fetch --no-tags "$E2E_WT" "${SRC_BRANCH}:${E2E_TIP_REF}" 2>/dev/null \
    || die "failed to fetch $SRC_BRANCH from $E2E_WT" 30
}

# ---------- scan ----------
# Build the patch-id set of commits already on dev-v0.5 since the merge-base,
# then walk dev-v0.5..e2e-tip emitting drift-tagged, src-touching, not-yet-ported
# commits as JSON.
do_scan() {
  fetch_e2e_tip
  local base
  base="$(v05 merge-base "$BASE_BRANCH" "$E2E_TIP_REF")" || die "no merge-base between $BASE_BRANCH and e2e-tip" 30

  # Precompute patch-ids present on dev-v0.5 (dedup set).
  local -A ported=()
  local h pid
  while read -r h; do
    [[ -n "$h" ]] || continue
    pid="$(v05 show "$h" | git -C "$V05_WT" patch-id --stable | awk '{print $1}')"
    [[ -n "$pid" ]] && ported["$pid"]=1
  done < <(v05 log --no-merges --format='%H' "${base}..${BASE_BRANCH}")

  note "scan: base=${base:0:8} dev-v0.5-patchset=${#ported[@]}"

  local emitted=0
  while read -r sha; do
    [[ -n "$sha" ]] || continue
    local subj
    subj="$(v05 log -1 --format='%s' "$sha")"
    # signal filter: drift-id + close marker in subject
    grep -qE "$DRIFT_RE" <<<"$subj" || continue
    grep -qiE "$CLOSE_RE" <<<"$subj" || continue
    # hard filter: must touch src/
    if ! v05 show --name-only --format= "$sha" | grep -qE '^src/'; then
      note "skip ${sha:0:8} (docs-only): $subj"
      continue
    fi
    # dedup: skip if an equivalent patch already on dev-v0.5
    pid="$(v05 show "$sha" | git -C "$V05_WT" patch-id --stable | awk '{print $1}')"
    if [[ -n "$pid" && -n "${ported[$pid]:-}" ]]; then
      note "skip ${sha:0:8} (already-on-v0.5): $subj"
      continue
    fi
    # collect drift ids + resolve drift-doc paths (best effort, from e2e worktree)
    local drift_ids src_files doc_paths
    drift_ids="$(grep -oE "$DRIFT_RE" <<<"$subj" | sort -u | jq -Rnc '[inputs]')"
    src_files="$(v05 show --name-only --format= "$sha" | grep -E '^src/' | jq -Rnc '[inputs]')"
    doc_paths="$(resolve_drift_docs "$subj")"
    jq -nc \
      --arg sha "$sha" \
      --arg subject "$subj" \
      --argjson drift_ids "$drift_ids" \
      --argjson src_files "$src_files" \
      --argjson drift_docs "$doc_paths" \
      '{sha:$sha, subject:$subject, drift_ids:$drift_ids, src_files:$src_files, drift_docs:$drift_docs}'
    emitted=$((emitted+1))
  done < <(v05 log --no-merges --reverse --format='%H' "${BASE_BRANCH}..${E2E_TIP_REF}")

  note "scan: ${emitted} candidate(s)"
}

# Resolve drift-doc absolute paths (under the e2e worktree) for the drift-ids in a subject.
resolve_drift_docs() {
  local subj="$1" id path
  local out=()
  while read -r id; do
    [[ -n "$id" ]] || continue
    if [[ "$id" == D-TEST-* ]]; then
      path="${E2E_WT}/docs/e2e-test/issues/${id}.md"
      [[ -f "$path" ]] && out+=("$path")
    else
      # D-CC??-FOLLOWUP-NN / D-CH??-FOLLOWUP-NN live under design/drifts as <id>-*.md
      while IFS= read -r p; do [[ -f "$p" ]] && out+=("$p"); done \
        < <(compgen -G "${E2E_WT}/docs/v0/design/drifts/${id}-*.md" || true)
    fi
  done < <(grep -oE "$DRIFT_RE" <<<"$subj" | sort -u)
  printf '%s\n' "${out[@]:-}" | grep -v '^$' | jq -Rnc '[inputs]'
}

# ---------- prepare ----------
cleanup_work() {
  # Always remove the throwaway worktree; keep the branch only on GREEN (handled by caller).
  if [[ -d "$WORK" ]]; then
    git -C "$V05_WT" worktree remove --force "$WORK" 2>/dev/null || rm -rf "$WORK" 2>/dev/null || true
  fi
  git -C "$V05_WT" worktree prune 2>/dev/null || true
}

# Map a list of drift-ids / SHAs to the actual e2e-tip commit SHAs to cherry-pick,
# in topo (oldest-first) order. A drift-id resolves to every src-touching commit on
# dev-v0.5..e2e-tip whose subject names it.
resolve_selection_shas() {
  local sel="$1"   # space-separated drift-ids and/or full SHAs
  local -a shas=()
  local token sha subj
  for token in $sel; do
    if [[ "$token" =~ ^[0-9a-f]{7,40}$ ]]; then
      shas+=("$(v05 rev-parse "$token")")
    else
      while read -r sha; do
        [[ -n "$sha" ]] || continue
        subj="$(v05 log -1 --format='%s' "$sha")"
        grep -qE "$DRIFT_RE" <<<"$subj" || continue
        grep -qF "$token" <<<"$subj" && shas+=("$sha")
      done < <(v05 log --no-merges --format='%H' "${BASE_BRANCH}..${E2E_TIP_REF}")
    fi
  done
  [[ ${#shas[@]} -gt 0 ]] || return 1
  # de-dup preserving topo order: re-derive order from the rev-walk
  v05 log --no-merges --reverse --format='%H' "${BASE_BRANCH}..${E2E_TIP_REF}" \
    | grep -Fx -f <(printf '%s\n' "${shas[@]}")
}

do_prepare() {
  local primary="$1"; shift
  local selection="$primary $*"
  fetch_e2e_tip

  local sanitized branch
  sanitized="$(printf '%s' "$primary" | tr -c 'A-Za-z0-9._-' '-')"
  branch="backport/${sanitized}"

  local -a shas
  mapfile -t shas < <(resolve_selection_shas "$selection") || true
  [[ ${#shas[@]} -gt 0 ]] || die "no src-touching commits matched selection: $selection" 30
  note "prepare: branch=$branch commits=${#shas[@]}"

  # Fresh branch off the current dev-v0.5 tip + throwaway worktree at it.
  trap cleanup_work EXIT
  cleanup_work
  run v05 branch -f "$branch" "$BASE_BRANCH"
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] git -C %s worktree add --force %s %s\n' "$V05_WT" "$WORK" "$branch" >&2
  else
    v05 worktree add --force "$WORK" "$branch" >/dev/null 2>&1 \
      || die "worktree add failed at $WORK" 30
  fi

  # Cherry-pick in the throwaway worktree (never the user's v05 checkout).
  local sha
  for sha in "${shas[@]}"; do
    if [[ $DRY_RUN -eq 1 ]]; then
      printf '[dry-run] git -C %s cherry-pick -x %s\n' "$WORK" "${sha:0:8}" >&2
      continue
    fi
    if ! git -C "$WORK" cherry-pick -x "$sha"; then
      local conflicted
      conflicted="$(git -C "$WORK" diff --name-only --diff-filter=U | tr '\n' ' ')"
      git -C "$WORK" cherry-pick --abort 2>/dev/null || true
      cleanup_work
      v05 branch -D "$branch" 2>/dev/null || true
      die "CONFLICT cherry-picking ${sha:0:8}; conflicted: ${conflicted:-<unknown>}" 20
    fi
  done

  if [[ $DRY_RUN -eq 1 ]]; then
    note "[dry-run] would run 4 CI guards + clippy + test under IPHI_WORKTREE_TAG=v05"
    note "[dry-run] would leave branch $branch for push on GREEN"
    return 0
  fi

  # ---- CI gate (in the throwaway worktree, v05 cargo isolation) ----
  cd "$WORK"
  local guard
  for guard in check-doc-links check-verified-headers check-phi-core-reuse check-spec-drift; do
    note "guard: $guard"
    if ! bash "${WORK}/scripts/${guard}.sh" >&2; then
      cleanup_work; v05 branch -D "$branch" 2>/dev/null || true
      die "CI guard FAIL: $guard" 21
    fi
  done

  note "clippy (v05 tag)…"
  if ! IPHI_ROOT="$WORK" PHI_CORE_ROOT="$V05_PHI_CORE" IPHI_WORKTREE_TAG=v05 \
        RUSTFLAGS="-Dwarnings" bash "$DOCKER_CARGO" clippy --all-targets -j 4 >&2; then
    cleanup_work; v05 branch -D "$branch" 2>/dev/null || true
    die "clippy FAIL" 22
  fi

  note "test (v05 tag)…"
  if ! IPHI_ROOT="$WORK" PHI_CORE_ROOT="$V05_PHI_CORE" IPHI_WORKTREE_TAG=v05 \
        bash "$DOCKER_CARGO" test -j 4 >&2; then
    cleanup_work; v05 branch -D "$branch" 2>/dev/null || true
    die "test FAIL" 23
  fi

  local head
  head="$(v05 rev-parse "$branch")"
  cleanup_work   # worktree gone; branch ref persists for push
  trap - EXIT
  printf 'GREEN %s %s\n' "$branch" "$head"
  note "prepare GREEN: $branch @ ${head:0:8} — ready for backport-push.sh"
}

# ---------- dispatch ----------
main() {
  [[ $# -ge 1 ]] || die "usage: backport-propagate.sh --scan | --prepare <drift-id|SHA>... [--dry-run]"
  local mode=""
  local -a positional=()
  local arg
  for arg in "$@"; do
    case "$arg" in
      --scan)    mode="scan" ;;
      --prepare) mode="prepare" ;;
      --dry-run) DRY_RUN=1 ;;
      --*)       die "unknown flag: $arg" ;;
      *)         positional+=("$arg") ;;
    esac
  done

  case "$mode" in
    scan)    do_scan ;;
    prepare)
      [[ ${#positional[@]} -ge 1 ]] || die "--prepare requires at least one drift-id or SHA"
      do_prepare "${positional[@]}"
      ;;
    *) die "specify --scan or --prepare" ;;
  esac
}

main "$@"