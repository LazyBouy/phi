# live-close-gate

Run the orchestrator's gate-4 **live disposition-asserting close-gate** for an i-phi chunk: boot the REAL daemon binary against a purpose-built fixture, drive the product surface, and RENDER + READ the actual artifact where the fix manifests — asserting the intended DISPOSITION, not just "no error". This is the 8-cycle-proven driver (MA-01b/01c/02/04/05/06/07/08), extracted so it stops being hand-rolled per cycle.

**When REQUIRED** (per CLAUDE.md gate-4 + `[[feedback_render_transcript_close_gate]]` Rules 4/6/7/8): whenever the chunk ships a **per-agent / model-facing / storage-isolation** deliverable. It found real gaps 2-of-3 in the MA batch-2 (MA-06 live-overlay non-application; MA-07 table-order reorder) that green deterministic suites were structurally blind to.

---

## The three load-bearing rules (why cycles re-learned these)

1. **Surface selector — render the surface where the fix MANIFESTS** (Rule 8):
   - **Model-facing** (tool catalog, permission filtering, prompt shape, revert disposition) → the **model wire**: boot with `[debug] transcript = true` + a real provider, capture `$HOME/.iphi/sessions/<id>/wire/<id>.turn-1.request.json` (the exact provider request body) and assert on `tools[]` / `messages` / etc.
   - **Storage-isolation** (per-agent memory roots, on-disk credentials, session files) → the **filesystem**: boot the daemon, mutate, and read the on-disk artifact (per-agent memory dir, `credentials.toml`, emitted event, DB row) — NOT the wire.
   - Identify the surface FIRST, then render THAT.

2. **Distinguishing-fixture rule** — the per-agent value MUST **observably differ** from the daemon-wide default, or the gate cannot tell "applied" from "fell back". MA-06 almost mis-PASSed with an `allow=[]` fixture that is INDISTINGUISHABLE from the block-all default. Author the fixture so agent-A's rendered surface is provably different from agent-B's AND from the daemon default (e.g. agent-A DENIES a custom tool, agent-B ALLOWS it → the tool is absent/present in the respective wire catalogs). For a file-vs-inline parity claim, include an inline-equivalent agent and assert byte-identical (identical tool set + identical input-token count). **Also run the consumer's common case** — the default provider kind, the keyless payload the frontend really sends — not only a case that happens to pass (backlog harvest U14: FI-03's gate passed on the easy provider, and the frontend then hit a 400 on the default one).

3. **IPC readiness probe** — the daemon on `--ipc-listen=tcp:<port>` speaks the **IPC protocol, NOT HTTP**. Poll readiness with the IPC client `iphi --ipc-listen=tcp:127.0.0.1:<port> status`, NOT `curl http://127.0.0.1:<port>/v1/status` (that is the HTTP-API mode; it will time out even though the daemon is up). This cost MA-08 a re-run.

---

## Gate-authoring rules (v2 — joint-retro `f4aa7e38`, 2026-09-25; every cycle of that batch had ≥ 1 harness defect, the empty-result trap hit 5 times)

Harness scripts `source /root/projects/phi/.claude/scripts/gate-lib.sh` and use its helpers instead of hand-rolled checks.

- **(a) Counts are numbers; empty is an abort.** Use `count_of <cmd>` — never `grep -c … | grep -qx 0` or `[ "$(grep -c …)" = 0 ]` under `set -o pipefail`: `grep -c` prints `0` AND exits 1 on no match, so the pipeline fails on exactly the zero it exists to confirm (a wrong product finding against correct code). `count_of` prints the number and aborts the harness on empty or non-numeric output, because empty means the harness did not measure.
- **(b) Non-vacuity first.** Every gate row states the precondition that makes it meaningful ("the fixture really contains a bare `~`", "the write really changed the targeted field", "the injected failure really failed") and checks it FIRST, aborting if it does not hold.
- **(c) Dry run first — and know what it cannot see.** Run the whole harness against the pre-change tree (G0): disposition gates must be RED for the right reason, and any gate GREEN pre-change is vacuous → fix the harness before the chunk opens. Classify each gate as *dry-run-exercisable* or *created by the change*. A dry run cannot exercise code the change creates, so a gate of the second kind gets a **harness-shakedown first live run**: triage its failures as harness defects before recording any product finding. Branches gated on live mode must still execute in the dry run.
- **(d) Pin the artefact you test.** `pin_binary <path>` before and after every step that could rebuild; no cargo invocation between `pin_binary` and an assertion (AR-03b: a probe's `cargo test` silently rebuilt the daemon binary between runs). Record the binary sha in every capture's header; with a retained cargo volume, `docker-iphi.sh` always rebuilds so the pinned binary is current.
- **(e) Failure paths too.** For a chunk that re-routes I/O, the gate drives FAILED operations as well as successful ones — inject the failure (a directory at a temp path, a regular file where a directory belongs, a malformed file), assert the message bytes against the pre-change daemon's capture and that nothing half-committed (AR-03b G5/G5b: the only check that caught a garbled message with the suite green, and the half-save live since AR-01a).
- **(f) Render the artefact and read it.** Assert shape as well as content: no ellipsis-truncated text, an even backtick count per rendered line, the exact status and message (AR-03a2: two defects visible only in the rendered file).
- **(g) Permission-gated fixtures** (model-facing gates): place the tested tool on the DEFAULT agent, grant it with a user-scope `permissions.toml` `allow=[…]`, and use a python stdio MCP stand-in when an MCP tool is needed — the recipe that stopped the repeated fixture misplacement.
- **(h) Credentials.** Read bearer tokens from a gitignored file (never on a command line), redact minted token plaintexts in every capture, and scan the evidence before committing it.
- **(i) Record close-gate-only proofs in the ADR's Verification section**, so a later reader can re-run them.

## Mock-provider and offline recipes (joint retro `f4aa7e38` backlog harvest U12, U13, U15)

Proven recipes from the FI cycles. Use them rather than re-deriving:

- **Park an interactive Ask** (FI-04a, FI-06): drive mock tool calls against an **`ask`-only** permissions file, and hold `/v1/attach` open to observe the parked decision. Do not put an `allow` rule alongside: an `allow` auto-approves, so nothing parks. FI-06 lost a run to exactly this. Rule (g) above is for *allow*-gated fixtures; interactive-park fixtures are the opposite.
- **Same-session effect**: put two tool calls in ONE turn — i-phi runs tools sequentially, so the second observes the first's effect (FI-04d).
- **Latency**: measure absolute wall-clock from request to the terminal event. SSE inter-event gaps are corrupted by buffering (FI-08).
- **Offline wire gate, no key and no network** (FI-03): turn on `[debug] transcript = true` and point the provider at an unreachable `base_url` (`http://127.0.0.1:1`). The turn still builds and records its request under `wire/`, so the gate can assert on the recorded request body.
- **Operator-tunable settings**: when a chunk ships a tunable, the gate SETS it to a non-default value and asserts its effect live (FI-02A `max_pending_inputs`) — a default-valued run proves nothing about the knob.

## Procedure

1. **Pick the surface** (rule 1). Wire → provider path; filesystem → on-disk path.
2. **Author the fixture** under a gitignored scratch dir `i-phi/docs/tmp/<chunk>-livegate/` (per `[[feedback_in_transit_scratch_dir]]`):
   - `.iphi/credentials.toml` — hand-authored (keep comments; a `[debug] transcript = true` for the wire path). Provider = `openai-compat` OpenRouter `deepseek/deepseek-chat` (open-source per `[[feedback_openrouter_open_source_only]]`) for the wire path; `mock` is fine for a filesystem/doctor path.
   - Whatever per-agent inputs the chunk needs (external policy files, distinct memory roots, …), authored per the **distinguishing-fixture rule**. Use ABSOLUTE paths into the mounted fixture when a per-agent path resolves against process cwd.
   - A **negative-control** fixture (a second dir) for the fail-loud disposition where applicable (missing file → boot/doctor error).
3. **Run the driver**: `bash /root/projects/phi/.claude/skills/live-close-gate/live-wire-gate.sh <FIXTURE_DIR> "<space-separated agent ids>"`. It builds the binary if needed, boots the daemon (IPC probe), prompts each agent, captures each wire request, and prints the per-agent `tools[]` catalog + a chosen-tool present/absent count + a cross-agent parity diff. For a filesystem/doctor gate, drive `iphi doctor` / read the on-disk artifact directly instead (the driver's Part-1/Part-2 doctor pattern).
4. **Assert the DISPOSITION** against the intended contract (rule 1 of `[[feedback_render_transcript_close_gate]]`): the denied tool is ABSENT from that agent's catalog; the allowed tool PRESENT; file-source ≡ inline-source (identical tool set + identical input tokens); a missing declared file FAILS LOUD (doctor `Severity::Error`), never a silent fallback. A balanced/no-400 wire is necessary but NOT sufficient (Rule 4).
5. **Embed the evidence** (Rule 7) in the committed `<cycle>/live-close-gate-transcript.md` BEFORE the gate-5 `docs/tmp/` sweep deletes the captures: the fixture TOMLs + the per-agent rendered catalog + the differentiating entry + token counts + the disposition table.

## Canonical driver template

The MA-08 runners are the reference: `i-phi/docs/v0/proposal/plan/build/ma-08-per-agent-policy-files-53c7780f/live-close-gate-transcript.md` documents the full wire gate; the parametric driver here (`live-wire-gate.sh`) generalizes its `run-p3.sh`. For the filesystem surface, MA-07's `live-close-gate-transcript.md` (remove/replace `credentials.toml` fidelity) is the reference.

## Notes

- `OPENROUTER_TOKEN` is in `/root/projects/phi/.env` (the driver sources it). The daemon container has network egress; the orchestrator shell's `curl` is hook-blocked but the in-container readiness probe + provider call are not.
- Keep the prompt trivial ("Introduce yourself in one sentence.") — the catalog is captured regardless of whether the model calls a tool.
- This skill file carries NO verified-header (per `[[feedback_no_verified_headers_in_agents]]`); version-tracked via `.claude/agents/_changelog.md`.
