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
# Networking note: no -p port forwarding. Daemon-mode HTTP (TC-0003/0004)
# needs port mapping; those TCs are deferred to T5.
#
# Reference: Phase 1.5 plan at
#   /root/projects/phi/i-phi/docs/v0/proposal/plan/e2e-test/dockerize-i-phi-30de6ed2.md

set -euo pipefail

IPHI_ROOT="${IPHI_ROOT:-/root/projects/phi/i-phi}"
# Custom image extends rust:1.95-slim with pkg-config + libssl-dev (required by
# transitive openssl-sys via reqwest). Built from Dockerfile.iphi-rust alongside.
# Rebuild with: docker build -t iphi-rust:1.95-slim -f /root/projects/phi/.claude/scripts/Dockerfile.iphi-rust /root/projects/phi/.claude/scripts/
RUST_IMAGE="${RUST_IMAGE:-iphi-rust:1.95-slim}"
PROFILE="${IPHI_PROFILE:-debug}"
BIN_REL_PATH="target/${PROFILE}/i-phi"

if [[ ! -d "${IPHI_ROOT}" ]]; then
  echo "docker-iphi.sh: IPHI_ROOT=${IPHI_ROOT} does not exist" >&2
  exit 1
fi

# Phase 1: build-on-demand if binary missing inside the named target volume
build_flag=""
[[ "${PROFILE}" == "release" ]] && build_flag="--release"

docker run --rm \
  -v "${IPHI_ROOT}:/work" \
  -v "iphi-cargo-target:/work/target" \
  -v "iphi-cargo-registry:/usr/local/cargo/registry" \
  -v "iphi-cargo-git:/usr/local/cargo/git" \
  -w /work \
  "${RUST_IMAGE}" \
  bash -c "test -x ${BIN_REL_PATH} || cargo build ${build_flag}"

# Phase 2: exec the binary (interactive stdin for prompt subcommand)
exec docker run --rm -i \
  -v "${IPHI_ROOT}:/work" \
  -v "iphi-cargo-target:/work/target" \
  -w /work \
  -e RUST_LOG="${RUST_LOG:-}" \
  -e RUST_BACKTRACE="${RUST_BACKTRACE:-}" \
  -e ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}" \
  -e OPENROUTER_TOKEN="${OPENROUTER_TOKEN:-}" \
  "${RUST_IMAGE}" \
  "/work/${BIN_REL_PATH}" "$@"
