#!/usr/bin/env bash
# gate-lib.sh — shared helpers for close-gate and gate-2/gate-4 invariant scripts.
#
# Origin: joint-retro f4aa7e38 (FI-34 → AR-03b), proposal P3 / §5 row 11.
# Self-test: bash /root/projects/phi/.claude/scripts/gate-lib-selftest.sh
#
# Usage (from a harness SCRIPT, not an interactive shell):
#   set -euo pipefail
#   source /root/projects/phi/.claude/scripts/gate-lib.sh
#   n=$(count_of grep -c 'RedactedSecret' "$EV/export.json")
#   expect_eq redacted_count "$n" 0 || fails=$((fails + 1))
#
# Exit-code contract for a harness that sources this file:
#   0 = every assertion passed
#   1 = an assertion failed (a PRODUCT finding; the caller decides via expect_eq's return)
#   2 = HARNESS ABORT (the gate could not measure what it claims to measure;
#       triage as a harness defect, never record it as a product finding)
#
# ---------------------------------------------------------------------------
# The empty-result trap (why count_of exists)
# ---------------------------------------------------------------------------
# `grep -c` prints "0" AND exits 1 when nothing matches. Under `set -o pipefail`
# the idiom `grep -c X f | grep -qx 0` therefore FAILS on exactly the result it
# is trying to assert (zero hits), and the usual workarounds (`|| true`,
# `|| echo 0`) swing the other way: a missing file, a typo'd path, or a jq
# precedence bug yields an EMPTY count that compares as "not N" and gets written
# up as a product finding that never existed (AR-03a close-gate dry run) — or,
# worse, a vacuous PASS. count_of separates the two failure classes: a numeric
# 0 is a normal result; empty or non-numeric output aborts the harness.
#
# ---------------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------------
# harness_abort <msg...>
#   Prints "HARNESS ABORT: <msg>" to stderr and exits 2. Exit 2 is deliberately
#   distinct from an assertion failure (1). When called inside a subshell — e.g.
#   n=$(count_of ...) — it also signals the top-level harness (SIGUSR1, trapped
#   below as `exit 2`), so the abort cannot be swallowed by `local n=$(...)`,
#   by a missing `set -e`, or by use inside a pipeline.
#
# count_of <cmd> [args...]
#   Runs the command (stdout captured; stderr passes through for diagnosis) and
#   prints its output as a bare integer. Returns 0 for ANY integer, including 0.
#   Command exit status 0 or 1 is accepted (1 = grep's "no match"); >= 2 is a
#   command error and aborts. Empty, multi-line or non-numeric output aborts.
#   A pipeline must be wrapped:  count_of bash -c 'grep -rh X dir | wc -l'
#   (Note `grep -c` over several files prints "file:N" lines -> aborts by design.)
#
# expect_eq <name> <value> <expected>
#   Prints "name=value (EXPECT expected)" and returns 0 on a string match.
#   On mismatch prints "FAIL name=value (EXPECT expected)" and returns 1.
#   An empty value never matches a non-empty expectation. Under `set -e` a
#   failing expect_eq stops the script; use `expect_eq ... || fails=$((fails+1))`
#   to tally instead.
#
# pin_binary <path> [sha-cmd...]
#   First call on <path>: records its sha256 and prints it. Every later call on
#   the same <path>: recomputes and aborts (exit 2) if the sha changed — i.e. a
#   cargo invocation rebuilt the binary between pin and assertion, so the gate
#   would be asserting against a binary it did not pin (joint-retro f4aa7e38 S5
#   guard 4; live-close-gate rule: no cargo invocation between pin and assert).
#   Default: `sha256sum <path>` on the host. For a binary that lives only inside
#   a Docker named volume, pass the command that computes it, e.g.
#     pin_binary i-phi docker exec iphi-cg sha256sum /work/target/debug/i-phi
#   (<path> is then just the pin key; the first 64-hex token of the command's
#   output is the sha). Call pin_binary directly, NOT inside $(...): the pin
#   table lives in the calling shell.

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "gate-lib.sh is a library: source it from a harness script (see header)." >&2
  exit 1
fi

# Idempotent: a second `source` must not reset the pin table.
if [[ -n "${_GATE_LIB_LOADED:-}" ]]; then
  return 0
fi
_GATE_LIB_LOADED=1

declare -gA _GATE_LIB_PINS=()

# A harness_abort raised inside a subshell signals the top-level shell, which
# then exits 2 as soon as its current command completes.
trap 'exit 2' USR1

harness_abort() {
  printf 'HARNESS ABORT: %s\n' "$*" >&2
  if [[ "${BASHPID:-$$}" != "$$" ]]; then
    kill -USR1 "$$" 2>/dev/null || true
  fi
  exit 2
}

count_of() {
  [[ $# -gt 0 ]] || harness_abort "count_of: no command given"
  local out rc trimmed
  out="$("$@")" && rc=0 || rc=$?
  if [[ $rc -gt 1 ]]; then
    harness_abort "count_of: command exited $rc (error, not a count): $*"
  fi
  trimmed="${out#"${out%%[![:space:]]*}"}"
  trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
  if [[ -z "$trimmed" ]]; then
    harness_abort "count_of: EMPTY output (exit $rc) from: $*"
  fi
  if [[ ! "$trimmed" =~ ^[0-9]+$ ]]; then
    harness_abort "count_of: non-numeric output '${trimmed:0:80}' from: $*"
  fi
  printf '%s\n' "$((10#$trimmed))"
}

expect_eq() {
  [[ $# -eq 3 ]] || harness_abort "expect_eq: need <name> <value> <expected>, got $# arg(s)"
  local name="$1" value="$2" expected="$3"
  if [[ "$value" == "$expected" ]]; then
    printf '%s=%s (EXPECT %s)\n' "$name" "$value" "$expected"
    return 0
  fi
  printf 'FAIL %s=%s (EXPECT %s)\n' "$name" "$value" "$expected"
  return 1
}

pin_binary() {
  [[ $# -ge 1 ]] || harness_abort "pin_binary: need <path> [sha-cmd...]"
  local path="$1" raw sha
  shift
  if [[ $# -eq 0 ]]; then
    [[ -f "$path" ]] || harness_abort "pin_binary: $path does not exist"
    raw="$(sha256sum -- "$path")" || harness_abort "pin_binary: sha256sum failed on $path"
  else
    raw="$("$@")" || harness_abort "pin_binary: sha command failed for $path: $*"
  fi
  [[ "$raw" =~ ([0-9a-f]{64}) ]] || harness_abort "pin_binary: no sha256 in output for $path: '${raw:0:80}'"
  sha="${BASH_REMATCH[1]}"
  if [[ -z "${_GATE_LIB_PINS[$path]+set}" ]]; then
    _GATE_LIB_PINS[$path]="$sha"
    printf 'pin_binary: %s sha256=%s (pinned)\n' "$path" "$sha"
  elif [[ "${_GATE_LIB_PINS[$path]}" == "$sha" ]]; then
    printf 'pin_binary: %s sha256=%s (unchanged)\n' "$path" "$sha"
  else
    harness_abort "pin_binary: $path CHANGED since pinned (was ${_GATE_LIB_PINS[$path]}, now $sha) — something rebuilt it between pin and assertion"
  fi
}
