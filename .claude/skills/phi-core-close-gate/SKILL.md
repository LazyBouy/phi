---
name: phi-core-close-gate
description: Run the live DISPOSITION-asserting close-gate for a phi-core kernel cycle (KC-NN) — release-rebuild i-phi against the patched phi-core, drive both strongest open-source drivers through the fix's representative scenario, READ the rendered wire, and assert each rule of the intended contract (not merely no-400). phi-core has no daemon of its own, so the kernel close-gate borrows the i-phi HTC harness in the dev-v0-e2e worktree.
---

# phi-core-close-gate

The kernel lane's only end-to-end acceptance surface. phi-core is a library — it has no daemon — so a phi-core model-facing fix is validated live by building i-phi (which consumes phi-core via `[patch.crates-io]`) against the patched kernel and driving real providers through the fix's representative scenario, then **reading the rendered wire and asserting the disposition**.

Promoted from the hand-rolled KC-02 (`d835a363`) + KC-03 (`24de5309`) close-gates (5 live cells, two drivers) at the KC-01+KC-02+KC-03 joint retro (2026-06-09).

## When to run

At a phi-core kernel cycle's close, for any fix whose effect is **what the model sees** (revert/braking disposition, context shape, tool catalog, denial semantics). Unit-green is necessary but NOT closure — this gate is.

## The load-bearing rule (cite `[[feedback_render_transcript_close_gate]]` Rule 4)

**Assert the DISPOSITION against the intended contract, not merely no-400 / well-formed.** A balanced wire (no provider 400, no orphan) can carry the *wrong* disposition — this is the KC-02 wrong-PASS. Enumerate the contract's rules up front (e.g. R1 shrink-tail / R2 replace-vs-add / R2a append-order / R3 orphan-removed), then assert **each one** shows the intended behavior in the model's exact input.

## Procedure

1. **Seal phi-core first** (the `[patch.crates-io]` path in `worktrees/phi-e2e/i-phi/Cargo.toml` points at `/root/projects/phi/phi-core`; the release build picks up the working tree, but commit so the close-gate references a sealed hex).
2. **Release-rebuild i-phi** against the patched phi-core:
   ```bash
   IPHI_ROOT=/root/projects/phi/worktrees/phi-e2e/i-phi bash /root/projects/phi/.claude/scripts/docker-cargo.sh build --release -j 4
   ```
   Confirm the tail shows `Compiling phi-core` + `Compiling i-phi`.
3. **Set up the cycle folder** under `worktrees/phi-e2e/i-phi/docs/e2e-test/cycles/<slug>-<hex>/` with `scripts/ events/ stdout-stderr/ assertions/ sessions/ transcripts/ configs/ fixtures/`. Reuse the KC-03 reference scripts:
   - `run-harness-htc.sh` — the parameterized runner. **Patch `CYCLE_HEX`**; it reads the driver from **`IPHI_MODEL_OVERRIDE`** (so one fixture runs against multiple drivers without per-driver test-case files).
   - `setup-kc0X-*.sh` + `prompt-kc0X-*.txt` — the per-cell fixture (system prompt that drives the model into the fix's representative scenario; seeded memory/skill; `permissions.toml` allowing the exercised tools) + the user prompt. Author one per *disposition* you must assert.
4. **Run each cell on BOTH strongest open-source drivers** (`[[feedback_htc_cohort_strongest_open_source]]` — `deepseek/deepseek-chat-v3-0324` + `minimax/minimax-m2.7`). The harness derives the setup-script name from the HTC-ID, so alias the setup per driver (`setup-<id>-mm.sh`):
   ```bash
   IPHI_MODEL_OVERRIDE=deepseek/deepseek-chat-v3-0324 bash <cycle>/scripts/run-harness-htc.sh <HTC-ID> <prompt-file> <cycle>
   ```
5. **Read the wire + ASSERT THE DISPOSITION** (the load-bearing step). The authoritative model-input record is `fixtures/<id>/fixture/sessions/<sid>/wire/*.turn-N.request.json` (the exact captured HTTP request — per `[[feedback_test_model_visibility]]`). For each contract rule, assert it against the relevant turn's request. Also scan `*.response.json` + the daemon log for `400`/`error`/`dangling`/`orphan` → expect zero.
6. **Wire-reader = a SCRIPT, not an inline `python3 -c` heredom (#8).** Per the granular-bash-discipline, multi-line inline `python3 -c` / heredocs fragment into per-line permission prompts (~70 prompts in the KC-03 window). Write the wire-reader to a file (`<cycle>/scripts/assert-disposition.py`) and run `python3 <abs>` as a single call. The reader takes the contract rules + the wire dir and emits PASS/FAIL per rule.
7. **Write `close-gate-result.md`** in the phi-core cycle folder: the per-rule × per-driver assertion table + evidence paths. If the gate validated only no-400 (not the disposition), it is NOT a pass — fix the assertions.
8. **Commit** the harness + artifacts to `dev-v0-e2e` (gitignore strips `events.jsonl` + fixture `credentials.toml`; secret-scan the wire for `sk-or-`/`authorization` before committing). Then close the GitHub issue citing the disposition table + the wire.

## Quality bar

- Every contract rule is asserted on the rendered wire, on both drivers. "No-400 / well-formed" alone is a FAIL of this gate (the KC-02 lesson).
- The wire-reader is a file, invoked once (not inline heredocs).
- Secret-safe: no `sk-or-`/auth token in committed artifacts; `events.jsonl` + `credentials.toml` gitignored.
- Harness nondeterminism is expected (a driver may multi-revert or stop early); the unit matrix is the exhaustive net, the live grid is opportunistic acceptance — but at least one cell per disposition must show the rule on the wire.

## Reference

- KC-03 close-gate: `worktrees/phi-e2e/i-phi/docs/e2e-test/cycles/kc03-close-gate-24de5309/` (the canonical reference scripts + `close-gate-result.md` disposition table).
- Memory `[[feedback_render_transcript_close_gate]]` (Rule 4 = assert the disposition), `[[feedback_htc_cohort_strongest_open_source]]` (both drivers), `[[feedback_test_model_visibility]]` (the wire is the captured exact request).
- The i-phi HTC runner template (`run-harness-htc.sh.template`) this borrows from.