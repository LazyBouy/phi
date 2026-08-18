# live-close-gate

Run the orchestrator's gate-4 **live disposition-asserting close-gate** for an i-phi chunk: boot the REAL daemon binary against a purpose-built fixture, drive the product surface, and RENDER + READ the actual artifact where the fix manifests — asserting the intended DISPOSITION, not just "no error". This is the 8-cycle-proven driver (MA-01b/01c/02/04/05/06/07/08), extracted so it stops being hand-rolled per cycle.

**When REQUIRED** (per CLAUDE.md gate-4 + `[[feedback_render_transcript_close_gate]]` Rules 4/6/7/8): whenever the chunk ships a **per-agent / model-facing / storage-isolation** deliverable. It found real gaps 2-of-3 in the MA batch-2 (MA-06 live-overlay non-application; MA-07 table-order reorder) that green deterministic suites were structurally blind to.

---

## The three load-bearing rules (why cycles re-learned these)

1. **Surface selector — render the surface where the fix MANIFESTS** (Rule 8):
   - **Model-facing** (tool catalog, permission filtering, prompt shape, revert disposition) → the **model wire**: boot with `[debug] transcript = true` + a real provider, capture `$HOME/.iphi/sessions/<id>/wire/<id>.turn-1.request.json` (the exact provider request body) and assert on `tools[]` / `messages` / etc.
   - **Storage-isolation** (per-agent memory roots, on-disk credentials, session files) → the **filesystem**: boot the daemon, mutate, and read the on-disk artifact (per-agent memory dir, `credentials.toml`, emitted event, DB row) — NOT the wire.
   - Identify the surface FIRST, then render THAT.

2. **Distinguishing-fixture rule** — the per-agent value MUST **observably differ** from the daemon-wide default, or the gate cannot tell "applied" from "fell back". MA-06 almost mis-PASSed with an `allow=[]` fixture that is INDISTINGUISHABLE from the block-all default. Author the fixture so agent-A's rendered surface is provably different from agent-B's AND from the daemon default (e.g. agent-A DENIES a custom tool, agent-B ALLOWS it → the tool is absent/present in the respective wire catalogs). For a file-vs-inline parity claim, include an inline-equivalent agent and assert byte-identical (identical tool set + identical input-token count).

3. **IPC readiness probe** — the daemon on `--ipc-listen=tcp:<port>` speaks the **IPC protocol, NOT HTTP**. Poll readiness with the IPC client `iphi --ipc-listen=tcp:127.0.0.1:<port> status`, NOT `curl http://127.0.0.1:<port>/v1/status` (that is the HTTP-API mode; it will time out even though the daemon is up). This cost MA-08 a re-run.

---

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
