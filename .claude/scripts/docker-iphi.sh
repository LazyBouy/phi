#!/usr/bin/env bash
# Docker wrapper for running the built i-phi binary inside the container.
# Builds on demand if target/<profile>/i-phi is absent, then exec's it.
#
# Usage:
#   bash /root/projects/phi/.claude/scripts/docker-iphi.sh <iphi-subcmd> [args...]
#
# Examples:
#   bash docker-iphi.sh --help
#   bash docker-iphi.sh status
#   bash docker-iphi.sh prompt --model=anthropic/claude-sonnet-4 "hello"
#
# Profile selection:
#   IPHI_PROFILE=debug (default) -> target/debug/i-phi
#   IPHI_PROFILE=release         -> target/release/i-phi
#
# Source selection (added at v0-re-seal event 2026-05-29; see
#   /root/projects/phi/i-phi/docs/v0/proposal/plan/v0-reseal-event-4d936327.md):
#   IPHI_SOURCE=submodule (default, dev) -> mount /root/projects/phi/i-phi at /work
#   IPHI_SOURCE=tag                       -> mount IPHI_TAG_DIR at /work; use a
#                                            git-worktree-checked-out tag (e.g.
#                                            /root/projects/phi/iphi-worktrees/v0.1.0)
#                                            isolated cargo target via volume override
#
# Tag mode workflow (one-time setup):
#   git -C /root/projects/phi/i-phi worktree add /root/projects/phi/iphi-worktrees/v0.1.0 v0.1.0
#   IPHI_SOURCE=tag IPHI_TAG_DIR=/root/projects/phi/iphi-worktrees/v0.1.0 \
#     bash docker-iphi.sh prompt --model=google/gemma-2-27b-it "hello"
#
# Tag mode build cache is isolated by deriving the cargo-target volume name from
# the basename of IPHI_TAG_DIR — so v0.1.0 builds don't poison the dev cache.
#
# Networking note: no -p port forwarding. Daemon-mode HTTP (TC-0003/0004)
# needs port mapping; those TCs are deferred to T5.
#
# Auto-daemon mode (added at CC-03 P-IMPL-F3 per F3.a; cycle hex 0008b87d):
#   IPHI_AUTO_DAEMON=0 (default) -> single container exec (legacy behavior).
#   IPHI_AUTO_DAEMON=1            -> wrapper picks an ephemeral TCP port,
#                                    spawns a sidecar `iphi daemon start
#                                    --ipc-listen=tcp:<port>` inside the SAME
#                                    container (backgrounded), polls
#                                    `http://127.0.0.1:<port>/v1/status` with
#                                    bounded retry (1s/2s/4s/1s; 8s ceiling),
#                                    then exec's the user iphi command with a
#                                    prefixed `--ipc-listen=tcp:127.0.0.1:<port>`
#                                    (R6 back-compat: --ipc-listen doubles as
#                                    client-side endpoint discovery). Traps
#                                    SIGTERM / SIGINT / EXIT on the outer
#                                    wrapper to docker-stop the container; the
#                                    container-side trap forwards SIGTERM to
#                                    the daemon sidecar PID before exit.
#
#   Use auto-daemon mode for e2e-test replay smokes where an out-of-band
#   daemon would over-complicate test harness shape. Production users running
#   `iphi prompt --auto-daemon ...` get equivalent behavior natively via the
#   F1.c in-process spawn path; the wrapper mode is a docker-side convenience
#   for replay scripts that exec the binary directly.
#
# Reference: Phase 1.5 plan at
#   /root/projects/phi/i-phi/docs/v0/proposal/plan/e2e-test/dockerize-i-phi-30de6ed2.md
#   CC-03 plan at
#   /root/projects/phi/i-phi/docs/v0/proposal/plan/build/ch-cc-03-iphi-prompt-daemon-decoupling-and-wrapper-auto-daemon-0008b87d/plan.md

set -euo pipefail

# Source selection (v0-re-seal addition)
IPHI_SOURCE="${IPHI_SOURCE:-submodule}"

# Auto-daemon mode (CC-03 F3.a addition; see header comment for semantics)
IPHI_AUTO_DAEMON="${IPHI_AUTO_DAEMON:-0}"

case "${IPHI_SOURCE}" in
  submodule)
    IPHI_ROOT="${IPHI_ROOT:-/root/projects/phi/i-phi}"
    TARGET_VOLUME="iphi-cargo-target"
    ;;
  tag)
    if [[ -z "${IPHI_TAG_DIR:-}" ]]; then
      echo "docker-iphi.sh: IPHI_SOURCE=tag requires IPHI_TAG_DIR to be set" >&2
      echo "  Recommended: git -C /root/projects/phi/i-phi worktree add /root/projects/phi/iphi-worktrees/<tag> <tag>" >&2
      echo "  Then: IPHI_SOURCE=tag IPHI_TAG_DIR=/root/projects/phi/iphi-worktrees/<tag> bash docker-iphi.sh ..." >&2
      exit 1
    fi
    IPHI_ROOT="${IPHI_TAG_DIR}"
    # Isolate cargo target volume by tag-dir basename (so v0.1.0 builds don't
    # interfere with dev builds in iphi-cargo-target volume)
    TAG_BASENAME="$(basename "${IPHI_TAG_DIR}")"
    TARGET_VOLUME="iphi-cargo-target-${TAG_BASENAME}"
    ;;
  *)
    echo "docker-iphi.sh: unknown IPHI_SOURCE=${IPHI_SOURCE} (expected: submodule | tag)" >&2
    exit 1
    ;;
esac

# Custom image extends rust:1.95-slim with pkg-config + libssl-dev (required by
# transitive openssl-sys via reqwest). Built from Dockerfile.iphi-rust alongside.
# Rebuild with: docker build -t iphi-rust:1.95-slim -f /root/projects/phi/.claude/scripts/Dockerfile.iphi-rust /root/projects/phi/.claude/scripts/
RUST_IMAGE="${RUST_IMAGE:-iphi-rust:1.95-slim}"
PROFILE="${IPHI_PROFILE:-debug}"
BIN_REL_PATH="target/${PROFILE}/i-phi"

if [[ ! -d "${IPHI_ROOT}" ]]; then
  echo "docker-iphi.sh: IPHI_ROOT=${IPHI_ROOT} does not exist" >&2
  if [[ "${IPHI_SOURCE}" == "tag" ]]; then
    echo "  Hint: create the tag worktree first via" >&2
    echo "        git -C /root/projects/phi/i-phi worktree add ${IPHI_ROOT} <tag>" >&2
  fi
  exit 1
fi

# Phase 1: build-on-demand if binary missing inside the named target volume
build_flag=""
[[ "${PROFILE}" == "release" ]] && build_flag="--release"

docker run --rm \
  -v "${IPHI_ROOT}:/work" \
  -v "${TARGET_VOLUME}:/work/target" \
  -v "iphi-cargo-registry:/usr/local/cargo/registry" \
  -v "iphi-cargo-git:/usr/local/cargo/git" \
  -w /work \
  "${RUST_IMAGE}" \
  bash -c "test -x ${BIN_REL_PATH} || cargo build ${build_flag}"

# Phase 2: exec the binary
if [[ "${IPHI_AUTO_DAEMON}" == "1" ]]; then
  # Auto-daemon mode: spawn sidecar `iphi daemon start --ipc-listen=tcp:<port>`
  # inside the SAME container, poll /v1/status until ready, then run the user
  # command. SIGTERM / SIGINT / EXIT trap tears down the container.
  AUTO_PORT=$(( RANDOM % 10000 + 50000 ))
  CONTAINER_NAME="iphi-auto-daemon-$$-${AUTO_PORT}"

  # Trap on outer wrapper: stop the named container if signaled/exiting.
  # `docker stop` cleanly SIGTERM's the entrypoint shell which propagates to
  # the daemon sidecar (Rust signal handlers fire); --rm reaps the container.
  trap 'docker stop --time=2 "${CONTAINER_NAME}" >/dev/null 2>&1 || true' EXIT INT TERM

  # Single docker run wrapping a bash entrypoint that:
  #   (a) backgrounds the daemon with --ipc-listen=tcp:${AUTO_PORT}
  #   (b) polls http://127.0.0.1:${AUTO_PORT}/v1/status with 1s/2s/4s/1s backoff
  #   (c) on readiness exec's the user command
  #   (d) on poll-timeout exits 1 with diagnostic
  exec docker run --rm -i \
    --name "${CONTAINER_NAME}" \
    -v "${IPHI_ROOT}:/work" \
    -v "${TARGET_VOLUME}:/work/target" \
    -w /work \
    -e RUST_LOG="${RUST_LOG:-}" \
    -e RUST_BACKTRACE="${RUST_BACKTRACE:-}" \
    -e ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}" \
    -e OPENROUTER_TOKEN="${OPENROUTER_TOKEN:-}" \
    -e IPHI_DAEMON_TCP_PORT="${AUTO_PORT}" \
    -e IPHI_BIN_REL_PATH="${BIN_REL_PATH}" \
    "${RUST_IMAGE}" \
    bash -c '
      set -u
      PORT="${IPHI_DAEMON_TCP_PORT}"
      BIN="/work/${IPHI_BIN_REL_PATH}"
      # Background the daemon sidecar
      "${BIN}" daemon start --ipc-listen=tcp:${PORT} >/tmp/iphi-daemon.log 2>&1 &
      DAEMON_PID=$!
      # Container-side trap: SIGTERM the daemon on entrypoint exit
      trap "kill -TERM ${DAEMON_PID} 2>/dev/null; wait ${DAEMON_PID} 2>/dev/null" EXIT INT TERM
      # Readiness poll: 1s + 2s + 4s + 1s = 8s ceiling
      for sleep_s in 1 2 4 1; do
        sleep "${sleep_s}"
        if curl -sf -m 1 "http://127.0.0.1:${PORT}/v1/status" >/dev/null 2>&1; then
          # Daemon ready — exec user command against it. The top-level
          # --ipc-listen flag doubles as client-side endpoint discovery per
          # R6 back-compat (see src/main.rs:48-51); user-supplied "$@"
          # follows and may include subcommand-form --ipc-listen on
          # `daemon start` (mutual-exclusion validation accepts same values).
          exec "${BIN}" --ipc-listen=tcp:127.0.0.1:${PORT} "$@"
        fi
        # Bail early if daemon process died
        if ! kill -0 "${DAEMON_PID}" 2>/dev/null; then
          echo "docker-iphi.sh: auto-daemon sidecar died before readiness" >&2
          cat /tmp/iphi-daemon.log >&2
          exit 1
        fi
      done
      echo "docker-iphi.sh: auto-daemon readiness poll timed out after 8s (port ${PORT})" >&2
      cat /tmp/iphi-daemon.log >&2
      exit 1
    ' bash "$@"
else
  # Legacy single-exec mode (interactive stdin for prompt subcommand)
  exec docker run --rm -i \
    -v "${IPHI_ROOT}:/work" \
    -v "${TARGET_VOLUME}:/work/target" \
    -w /work \
    -e RUST_LOG="${RUST_LOG:-}" \
    -e RUST_BACKTRACE="${RUST_BACKTRACE:-}" \
    -e ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}" \
    -e OPENROUTER_TOKEN="${OPENROUTER_TOKEN:-}" \
    "${RUST_IMAGE}" \
    "/work/${BIN_REL_PATH}" "$@"
fi
