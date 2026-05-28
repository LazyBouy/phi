#!/usr/bin/env bash
# Docker wrapper for i-phi cargo invocations.
# Mirrors the host `cargo` CLI; runs inside rust:1.95-slim with named-volume
# caches for target/, registry/, and git/. baby-phi is OUT OF SCOPE — it keeps
# its host cargo discipline at /root/rust-env/cargo/bin/cargo.
#
# Usage:
#   bash /root/projects/phi/.claude/scripts/docker-cargo.sh <cargo-subcmd> [args...]
#
# Examples:
#   bash docker-cargo.sh build -j 4
#   RUSTFLAGS="-Dwarnings" bash docker-cargo.sh clippy --all-targets -j 4
#   bash docker-cargo.sh fmt -- --check
#   bash docker-cargo.sh test -j 4
#
# Env passthrough (declared explicitly):
#   RUSTFLAGS, CARGO_TERM_COLOR, RUST_LOG, RUST_BACKTRACE,
#   ANTHROPIC_API_KEY, OPENROUTER_TOKEN
#
# Cargo cache cleanup (replaces `cargo clean`):
#   docker volume rm iphi-cargo-target
#
# Reference: Phase 1.5 plan at
#   /root/projects/phi/i-phi/docs/v0/proposal/plan/e2e-test/dockerize-i-phi-30de6ed2.md

set -euo pipefail

IPHI_ROOT="${IPHI_ROOT:-/root/projects/phi/i-phi}"
# Custom image extends rust:1.95-slim with pkg-config + libssl-dev (required by
# transitive openssl-sys via reqwest). Built from Dockerfile.iphi-rust alongside.
# Rebuild with: docker build -t iphi-rust:1.95-slim -f /root/projects/phi/.claude/scripts/Dockerfile.iphi-rust /root/projects/phi/.claude/scripts/
RUST_IMAGE="${RUST_IMAGE:-iphi-rust:1.95-slim}"

if [[ ! -d "${IPHI_ROOT}" ]]; then
  echo "docker-cargo.sh: IPHI_ROOT=${IPHI_ROOT} does not exist" >&2
  exit 1
fi

# phi-core mounted read-only at the host path: the `test_factory_phi_core_zero_lines_changed`
# integration test shells out to `git -C /root/projects/phi/phi-core diff HEAD` to verify the
# CH-07a cross-submodule invariant (phi-core working tree must be clean).
PHI_CORE_ROOT="${PHI_CORE_ROOT:-/root/projects/phi/phi-core}"

exec docker run --rm \
  -v "${IPHI_ROOT}:/work" \
  -v "${PHI_CORE_ROOT}:${PHI_CORE_ROOT}:ro" \
  -v "iphi-cargo-target:/work/target" \
  -v "iphi-cargo-registry:/usr/local/cargo/registry" \
  -v "iphi-cargo-git:/usr/local/cargo/git" \
  -w /work \
  -e RUSTFLAGS="${RUSTFLAGS:-}" \
  -e CARGO_TERM_COLOR="${CARGO_TERM_COLOR:-always}" \
  -e RUST_LOG="${RUST_LOG:-}" \
  -e RUST_BACKTRACE="${RUST_BACKTRACE:-}" \
  -e ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}" \
  -e OPENROUTER_TOKEN="${OPENROUTER_TOKEN:-}" \
  "${RUST_IMAGE}" \
  cargo "$@"
