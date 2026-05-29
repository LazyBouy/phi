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
# Reference: Phase 1.5 plan at
#   /root/projects/phi/i-phi/docs/v0/proposal/plan/e2e-test/dockerize-i-phi-30de6ed2.md

set -euo pipefail

# Source selection (v0-re-seal addition)
IPHI_SOURCE="${IPHI_SOURCE:-submodule}"

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

# Phase 2: exec the binary (interactive stdin for prompt subcommand)
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
