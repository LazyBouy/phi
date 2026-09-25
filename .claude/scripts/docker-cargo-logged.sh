#!/usr/bin/env bash
# docker-cargo-logged.sh — docker-cargo.sh with the full output captured to a log file.
#
# Replaces `bash docker-cargo.sh ... 2>&1 | tail -N` / `| grep ...`: a trailing
# pipe defeats the docker-cargo.sh allow rule and prompts every time (185 prompts
# in the joint-retro f4aa7e38 window). One call, one allow rule, full log kept
# for later `grep` / `tail` reads (joint-retro f4aa7e38 P16a / §5 row 14).
#
# Usage:
#   bash /root/projects/phi/.claude/scripts/docker-cargo-logged.sh <log-path> <cargo-subcmd> [args...]
#
# Examples:
#   bash docker-cargo-logged.sh /root/projects/phi/i-phi/docs/tmp/ar03c/test-serial.log test -j 4 -- --test-threads=1
#   RUSTFLAGS="-Dwarnings" bash docker-cargo-logged.sh /root/projects/phi/i-phi/docs/tmp/ar03c/clippy.log clippy --all-targets -j 4
#   IPHI_ROOT=/root/projects/phi/worktrees/phi-v05/i-phi bash docker-cargo-logged.sh /tmp/v05-build.log build -j 4
#
# Behaviour:
#   - stdout+stderr of cargo go to <log-path> (parent dir created; file overwritten).
#   - Prints the last 40 lines of the log, then `docker-cargo-logged: exit=<rc> log=<path>`.
#   - Exits with cargo's exit code.
#   - Environment is inherited unchanged (IPHI_ROOT, IPHI_WORKTREE_TAG, RUSTFLAGS,
#     RUST_LOG, ...), so worktree volume tagging works exactly as in docker-cargo.sh.
#     The one default: CARGO_TERM_COLOR=never unless the caller set it, so the log
#     is greppable (docker-cargo.sh otherwise forces `always` -> ANSI escapes).

set -uo pipefail

usage() {
  echo "usage: bash docker-cargo-logged.sh <log-path> <cargo-subcmd> [args...]" >&2
}

if [[ $# -lt 2 ]]; then
  usage
  exit 64
fi

log="$1"
shift

# Guard against a forgotten log path (`docker-cargo-logged.sh test -j 4` would
# otherwise write a log named "test" and run `cargo -j 4`).
if [[ "${log}" != */* && "${log}" != *.log ]]; then
  echo "docker-cargo-logged.sh: first argument must be a log path (contain '/' or end in .log), got '${log}'" >&2
  usage
  exit 64
fi

log_dir="$(dirname -- "${log}")"
mkdir -p -- "${log_dir}" || { echo "docker-cargo-logged.sh: cannot create ${log_dir}" >&2; exit 1; }

export CARGO_TERM_COLOR="${CARGO_TERM_COLOR:-never}"

bash /root/projects/phi/.claude/scripts/docker-cargo.sh "$@" > "${log}" 2>&1
rc=$?

echo "--- last 40 lines of ${log} ---"
tail -n 40 -- "${log}"
echo "docker-cargo-logged: exit=${rc} log=${log}"
exit "${rc}"
