#!/usr/bin/env bash
# live-close-gate — parametric WIRE driver (model-facing surface).
# Usage: bash live-wire-gate.sh <FIXTURE_DIR> "<agent-id-1 agent-id-2 ...>"
#   FIXTURE_DIR must contain .iphi/credentials.toml ([debug] transcript = true,
#   openai-compat OpenRouter provider). Boots the real daemon against the fixture
#   (HOME=FIXTURE_DIR), prompts each agent, captures each turn-1 wire request,
#   and prints the per-agent tools[] catalog + a cross-agent parity check.
# For a filesystem/doctor surface, drive `iphi doctor` / read the on-disk
# artifact directly instead (see SKILL.md).
set -uo pipefail
FIX="${1:?usage: live-wire-gate.sh <FIXTURE_DIR> \"<agent ids>\"}"
AGENTS="${2:?usage: live-wire-gate.sh <FIXTURE_DIR> \"<agent ids>\"}"
set -a; source /root/projects/phi/.env; set +a   # OPENROUTER_TOKEN
IMG="${RUST_IMAGE:-iphi-rust:1.95-slim}"
SRC=/root/projects/phi/i-phi
BINREL="target/debug/i-phi"

# Build the binary on demand into the named volume.
docker run --rm -v "$SRC:/work" -v iphi-cargo-target:/work/target \
  -v iphi-cargo-registry:/usr/local/cargo/registry -v iphi-cargo-git:/usr/local/cargo/git \
  -w /work "$IMG" bash -c "test -x $BINREL || cargo build -j 4"

docker run --rm -v "$SRC:/work" -v iphi-cargo-target:/work/target \
  -v "$FIX:/fixture" -e HOME=/fixture -w /work \
  -e OPENROUTER_TOKEN="$OPENROUTER_TOKEN" -e AGENTS="$AGENTS" "$IMG" bash -c '
    set -u
    BIN=/work/target/debug/i-phi
    PORT=$(( (RANDOM % 9000) + 50000 ))
    rm -rf /fixture/.iphi/sessions /fixture/wire.*.json 2>/dev/null || true
    "$BIN" daemon start --ipc-listen=tcp:$PORT >/tmp/d.log 2>&1 &
    DP=$!
    READY=0
    # IPC readiness probe — the daemon speaks IPC on --ipc-listen, NOT HTTP.
    for i in 1 2 3 4 5 6; do sleep 1; if "$BIN" --ipc-listen=tcp:127.0.0.1:$PORT status >/dev/null 2>&1; then READY=1; break; fi; done
    if [ "$READY" != 1 ]; then echo "DAEMON NOT READY"; cat /tmp/d.log; kill -TERM $DP 2>/dev/null; exit 1; fi
    echo "daemon ready on ipc tcp:$PORT"
    for AG in $AGENTS; do
      echo "----- prompting $AG -----"
      "$BIN" --ipc-listen=tcp:127.0.0.1:$PORT prompt --agent $AG "Introduce yourself in one sentence." >/tmp/p.$AG 2>&1 || true
      tail -1 /tmp/p.$AG
      SID=$(ls -t /fixture/.iphi/sessions 2>/dev/null | head -1)
      W=$(find /fixture/.iphi/sessions/$SID -name "*request*.json" 2>/dev/null | head -1)
      echo "  SESSION=$SID  WIRE=$W"
      if [ -n "${W:-}" ] && [ -f "$W" ]; then
        echo -n "  tool catalog: "; grep -oE "\"name\" *: *\"[a-zA-Z0-9_-]+\"" "$W" | sed -E "s/.*: *//" | sort | tr "\n" " "; echo
        cp "$W" /fixture/wire.$AG.json 2>/dev/null || true
      else echo "  NO WIRE CAPTURED for $AG"; fi
    done
    echo "===== cross-agent parity (identical tool sets have identical sorted names) ====="
    for W in /fixture/wire.*.json; do [ -f "$W" ] && echo "$(basename $W): $(grep -oE "\"name\" *: *\"[a-zA-Z0-9_-]+\"" "$W" | wc -l) tools"; done
    kill -TERM $DP 2>/dev/null; wait $DP 2>/dev/null || true
  '
echo "Captured wires at $FIX/wire.<agent>.json — embed the load-bearing bytes in the committed transcript (Rule 7) before the gate-5 sweep."
