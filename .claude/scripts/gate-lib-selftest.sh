#!/usr/bin/env bash
# gate-lib-selftest.sh — proves the gate-lib.sh contract (joint-retro f4aa7e38 P3 / §5 row 11).
#
#   bash /root/projects/phi/.claude/scripts/gate-lib-selftest.sh
#
# Runs under `set -euo pipefail` (the mode every close-gate uses). Abort cases run
# in a child bash, because harness_abort exits the shell that sourced the lib.
# Prints one PASS/FAIL line per check; exits 0 only if every check passed.
set -euo pipefail

GATE_LIB="/root/projects/phi/.claude/scripts/gate-lib.sh"
export GATE_LIB
# shellcheck source=/dev/null
source "$GATE_LIB"

tmp="$(mktemp -d)"
cleanup() {
  rm -- "$tmp"/* 2>/dev/null || true
  rmdir -- "$tmp" 2>/dev/null || true
}
trap cleanup EXIT

f="$tmp/sample.txt"
printf 'alpha\nbeta\n' > "$f"

passed=0
failed=0
check() { # check <name> <condition-result 0|1> <detail>
  if [[ "$2" -eq 0 ]]; then
    printf 'PASS %s\n' "$1"
    passed=$((passed + 1))
  else
    printf 'FAIL %s -- %s\n' "$1" "$3"
    failed=$((failed + 1))
  fi
}

# Runs a snippet in a child bash that sources the lib; sets child_rc / child_out.
run_child() {
  child_out="$(bash -c "$1" 2>&1)" && child_rc=0 || child_rc=$?
}

# --- 0. The trap itself: the naive idiom fails on a zero count under pipefail.
naive_rc=0
{ grep -c zzz "$f" | grep -qx 0; } || naive_rc=$?
check "trap-demo: naive 'grep -c | grep -qx 0' fails on zero hits under pipefail (rc=$naive_rc)" \
  "$([[ $naive_rc -ne 0 ]] && echo 0 || echo 1)" "naive idiom unexpectedly passed"

# --- 1. count_of returns 0 for a zero-match grep, without aborting.
n="$(count_of grep -c zzz "$f")"
check "count_of: zero-match grep -> '$n', status 0, no abort" \
  "$([[ "$n" == "0" ]] && echo 0 || echo 1)" "got '$n'"

n="$(count_of grep -c alpha "$f")"
check "count_of: one-match grep -> '$n'" \
  "$([[ "$n" == "1" ]] && echo 0 || echo 1)" "got '$n'"

n="$(count_of bash -c "grep -h a '$f' | wc -l")"
check "count_of: wrapped pipeline -> '$n'" \
  "$([[ "$n" == "2" ]] && echo 0 || echo 1)" "got '$n'"

# --- 2. count_of aborts (exit 2) on empty output — and the abort is not swallowed.
run_child 'set -euo pipefail; source "$GATE_LIB"; n=$(count_of true); echo REACHED'
check "count_of: empty output aborts the harness (set -e; rc=$child_rc)" \
  "$([[ $child_rc -eq 2 && "$child_out" == *"HARNESS ABORT"* && "$child_out" != *REACHED* ]] && echo 0 || echo 1)" \
  "rc=$child_rc out=$child_out"

run_child 'source "$GATE_LIB"; f() { local n=$(count_of true); echo "REACHED n=[$n]"; }; f; echo REACHED2'
check "count_of: empty output aborts even via 'local n=\$(...)' without set -e (rc=$child_rc)" \
  "$([[ $child_rc -eq 2 && "$child_out" != *REACHED* ]] && echo 0 || echo 1)" \
  "rc=$child_rc out=$child_out"

run_child 'set -euo pipefail; source "$GATE_LIB"; n=$(count_of echo "3 matches"); echo REACHED'
check "count_of: non-numeric output aborts (rc=$child_rc)" \
  "$([[ $child_rc -eq 2 && "$child_out" == *"non-numeric"* ]] && echo 0 || echo 1)" \
  "rc=$child_rc out=$child_out"

run_child 'set -euo pipefail; source "$GATE_LIB"; n=$(count_of grep -c x /nonexistent/gate-lib-selftest); echo REACHED'
check "count_of: command error (missing file, grep rc 2) aborts (rc=$child_rc)" \
  "$([[ $child_rc -eq 2 && "$child_out" == *"HARNESS ABORT"* && "$child_out" != *REACHED* ]] && echo 0 || echo 1)" \
  "rc=$child_rc out=$child_out"

# --- 3. expect_eq pass and fail.
out="$(expect_eq redacted_count 0 0)" && rc=0 || rc=$?
check "expect_eq: pass -> '$out' rc=$rc" \
  "$([[ $rc -eq 0 && "$out" == "redacted_count=0 (EXPECT 0)" ]] && echo 0 || echo 1)" "rc=$rc out=$out"

out="$(expect_eq redacted_count 3 0)" && rc=0 || rc=$?
check "expect_eq: mismatch -> '$out' rc=$rc" \
  "$([[ $rc -eq 1 && "$out" == "FAIL redacted_count=3 (EXPECT 0)" ]] && echo 0 || echo 1)" "rc=$rc out=$out"

out="$(expect_eq empty_value "" 0)" && rc=0 || rc=$?
check "expect_eq: empty value never passes a non-empty expectation (rc=$rc)" \
  "$([[ $rc -eq 1 ]] && echo 0 || echo 1)" "rc=$rc out=$out"

# --- 4. pin_binary pins, confirms unchanged, and detects a change.
bin="$tmp/fake-bin"
printf 'build-1\n' > "$bin"
out="$(pin_binary "$bin")"   # subshell: only checks the output shape here
check "pin_binary: first call pins" \
  "$([[ "$out" == *"(pinned)"* ]] && echo 0 || echo 1)" "out=$out"

run_child "set -euo pipefail; source \"\$GATE_LIB\"; pin_binary '$bin'; pin_binary '$bin'"
check "pin_binary: second call on an unchanged binary passes (rc=$child_rc)" \
  "$([[ $child_rc -eq 0 && "$child_out" == *"(unchanged)"* ]] && echo 0 || echo 1)" \
  "rc=$child_rc out=$child_out"

run_child "set -euo pipefail; source \"\$GATE_LIB\"; pin_binary '$bin'; printf 'build-2\n' > '$bin'; pin_binary '$bin'; echo REACHED"
check "pin_binary: a changed binary aborts the harness (rc=$child_rc)" \
  "$([[ $child_rc -eq 2 && "$child_out" == *"CHANGED since pinned"* && "$child_out" != *REACHED* ]] && echo 0 || echo 1)" \
  "rc=$child_rc out=$child_out"

run_child "set -euo pipefail; source \"\$GATE_LIB\"; pin_binary key sha256sum -- '$bin'; pin_binary key sha256sum -- '$bin'"
check "pin_binary: custom sha-cmd form (for in-volume binaries) pins + confirms (rc=$child_rc)" \
  "$([[ $child_rc -eq 0 && "$child_out" == *"(unchanged)"* ]] && echo 0 || echo 1)" \
  "rc=$child_rc out=$child_out"

printf 'selftest: %d passed, %d failed\n' "$passed" "$failed"
[[ $failed -eq 0 ]]
