# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

This is a **multi-crate workspace** with three git submodules:

- **`phi-core/`** — The core Rust library for building AI agents. Published as `phi-core` on crates.io. This is where most development happens. Has its own detailed `CLAUDE.md` — read it for phi-core-specific architecture, types, and conventions.
- **`baby-phi/`** — A standalone Rust binary that consumes `phi-core` (its own embedded agent implementation in `agent.rs`). Config-driven via `config.toml`. An early consumer/prototype, not the primary focus.
- **`i-phi/`** — Another consumer of `phi-core` used to instantiate agents. Spec to follow; currently scaffolded with README only.

## Build & Development

All cargo commands must use the cargo binary at `/root/rust-env/cargo/bin/cargo`. There is no Docker container.

```bash
# phi-core (the main crate — run from phi-core/)
cd phi-core
/root/rust-env/cargo/bin/cargo build
/root/rust-env/cargo/bin/cargo test
/root/rust-env/cargo/bin/cargo test <test_name>              # single test by name
/root/rust-env/cargo/bin/cargo test --test session_test      # single test file
/root/rust-env/cargo/bin/cargo fmt
/root/rust-env/cargo/bin/cargo fmt -- --check
RUSTFLAGS="-Dwarnings" /root/rust-env/cargo/bin/cargo clippy --all-targets

# baby-phi (run from baby-phi/)
cd baby-phi
/root/rust-env/cargo/bin/cargo build
/root/rust-env/cargo/bin/cargo run
```

CI treats all clippy warnings as errors (`RUSTFLAGS="-Dwarnings"`). Always run clippy before considering work complete.

## phi-core Architecture (Summary)

phi-core is organized as three conceptual layers within one crate (dependencies flow strictly downward):

- **Layer 1 — Core Loop** (`types/`, `agent_loop/`, `provider/traits.rs`): The stateless agent loop, `AgentTool` trait, `StreamProvider` trait, message/event types. Provider-agnostic, tool-agnostic.
- **Layer 2 — Agent + Providers** (`agents/`, `context/`, `provider/*.rs`, `tools/`, `mcp/`): 7 concrete LLM providers, 6 built-in tools, `Agent` trait + `BasicAgent`, MCP client, context management, session persistence.
- **Layer 3 — Orchestration** (planned): Multi-agent coordination, config-driven invocation, WASM plugins.

Key design: `agent_loop()` and `agent_loop_continue()` are **free functions**, not methods. `BasicAgent` is a stateful wrapper that builds `AgentLoopConfig` and calls these functions. The `Agent` trait is the runtime interface (prompting, state, control).

## Specification Documents

Detailed specs live in `phi-core/docs/specs/`:
- `developer/overview.md` — Entity hierarchy, status tags (`[EXISTS]`/`[PLANNED]`/`[CONCEPTUAL]`), core gaps (G1-G9)
- `developer/{agent,session,loop,turn,message,tool,provider,event,compaction,config}.md` — Per-entity deep dives
- `platform/{invocation,plugins,multi-user}.md` — Platform evolution specs (config layer, WASM plugins, multi-user)
- `architecture.md` — Component maps, sequence diagrams
- `roadmap.md` — Requirements tracking (REQ-001+)

Architecture docs in `phi-core/docs/architecture/overview.md` include First Principles for core vs external decisions.

## Key Conventions

- **Submodule awareness**: `phi-core`, `baby-phi`, and `i-phi` are git submodules. Commits happen inside each submodule, then the parent repo tracks the submodule commit reference.
- **Testing**: All tests use `MockProvider` for deterministic LLM simulation. No network calls in unit tests. Integration tests (`tests/integration_anthropic.rs`) require a live API key and are skipped by default.
- **Session persistence**: `Session` → `LoopRecord` → `Turn` hierarchy. `SessionRecorder` materializes `Turn` structs from `TurnStart`/`TurnEnd` event pairs. All session types use `#[serde(default)]` for backward-compatible deserialization.
- **Hook ordering**: Lifecycle callbacks fire strictly before their paired events. `Before*` hooks returning `false` abort the action. This ordering is a system invariant — never break it.
- **Documentation–Code Alignment**: Documentation in `phi-core/docs/` must accurately reflect the current codebase. Code is the source of truth. When making code changes, update all affected documentation in the same commit. Status tags (`[EXISTS]`, `[PLANNED]`, `[CONCEPTUAL]`) must be kept current. Every doc file carries a `<!-- Last verified: YYYY-MM-DD by Claude Code -->` header updated on each review pass.

## Multi-agent chunk pipeline (baby-phi)

baby-phi chunks (CH-NN) run through a 5-agent pipeline orchestrated by Claude. The orchestrator (Claude with full conversation context) is the **reviewer / approver / process-refiner / retrospective-driver**, not a doer in the chunk lane. Specialized agents own their lanes; the orchestrator gates phase transitions, verifies diffs, audits audit reports, and drives retrospectives.

**Agents** at `/root/projects/phi/.claude/agents/`:
- `phase-planner` (opus) — drafts the per-milestone forward-scope document (chunk-level decomposition + dep graph) from a base build-plan section + pre-scoping alignment audit + prior-milestone deferral markers. Sits one tier above `chunk-planner` (shipped v1 at 2026-05-18 post-CH-27 close, per CH-27 retrospective's M6 plan-mode unblock).
- `chunk-planner` (opus) — drafts the 12-section plan from a forward-scope row.
- `chunk-implementer` (opus) — executes phases per the approved plan.
- `chunk-auditor` (opus) — independent post-implementation audit; writes per-iteration audit log.
- `chunk-retrospector` (opus) — consolidated retrospective + standards-update proposals.

**Skills** at `/root/projects/phi/.claude/skills/`:
- `phi-core-leverage-check`, `k8s-readiness-check`, `chunk-template-fill`, `ci-guards-run`, `chunk-archive-plan`, `audit-envelope-size`.

**Cycle artifact layout** under `baby-phi/docs/specs/plan/build/<slug>-<8hex>/`:
- `plan.md` — cycle plan
- `audit-<letter>-iter<N>.md` — per-iteration audit logs
- `cycle-audit.md` — orchestrator's consolidated final audit
- `retrospective.md` — cycle retrospective

Pre-existing chunks (CH-09, CH-10, CH-23) keep their flat-file legacy layout; the folder convention applies to new cycles only. Index at `baby-phi/docs/specs/plan/build/_cycle-index.md`.

**Orchestrator's gates:**
1. **Plan approval.** Read planner's draft. Auto-approve via ExitPlanMode when Direct-approval criteria hold (no locked forks, scope ≤ 1.5× forward-scope, zero phi-core leverage delta, no new K8s blocker class, audit envelope ≤ medium, confidence ≥ 9/10, no new migration). Otherwise escalate to user via AskUserQuestion + ExitPlanMode.
2. **Per-phase implementation review.** Read diff, run cargo test + clippy myself, verify phi-core grep, confirm test count matches plan §8 expected. **Doc-sync sweep after gate-2 inline corrections** (added 2026-05-08 per CH-14 retro Row 3, cycle hex `5803bb94`; **widened 2026-05-08 per CH-15 retro Row 1, cycle hex `c3f46f17`**): when a gate-2 inline correction changes implementation behaviour (e.g., shipping per-AR audit-event emission that the chunk-seal-state had deferred) **OR when a chunk closes a drift with cross-cutting documentary impact** (e.g., D4.1 "advisory at M5" wording scattered across 7 files), grep ALL `docs/specs/v0/implementation/m*/architecture/*.md` + `m*/operations/*.md` + `m*/user-guide/*.md` (NOT just plan §3.C-listed files) for the canonical stale-narrative phrase set: `FOLLOWUP-NN`, `deferred per`, `is NOT emitted`, `not emitted at CH-NN`, `advisory at M5`, `Step 0 only blocking`, `M6+ tightens the gate`, `at M5/P4`, `not blocking at M5`. Patch any matches BEFORE dispatching auditors. Audit-fix-loop iteration cap counts these patches as Trivial-multi if > 1 line, Trivial-1L if ≤ 1 line. **2-cycle pattern**: CH-14 caught this at audit B iter 1 (3 docs had stale "deferred per FOLLOWUP-02" wording); CH-15 caught this at audit B iter 1 (`m5/architecture/authority-templates.md:89-91` had stale "advisory at M5" wording outside plan §3.C map). Applying the widened sweep at gate-2 would have avoided both iter-1 PARTIAL → iter-2 re-spawns. **ADR ↔ open-questions cross-check (added 2026-05-17 per CH-02a-i-phi retro Row 1, cycle hex `1bd3bdd1`)**: for every ADR sub-decision the chunk files that claims to resolve a concept-doc open-question (e.g., `### §D<N>.<M> — <resolution> (resolves F<X>)`), verify the corresponding open-question in the cited concept doc carries an `[ANSWERED at CH-<NN>: <one-line resolution + ADR cite>]` annotation. CH-02a Trivial-1L gate-2 patch caught daemon.md's OS-integration open-question lacking the annotation despite ADR-0002 §D2.5 resolving F5.b (ship systemd template); implementer had annotated SIGHUP + concurrency questions but missed OS integration. Applying the ADR-↔-open-questions cross-check at gate-2 surfaces these omissions as Trivial-1L (≤ 1-line annotation per missing question) before audit dispatch. **Dynamic-pattern derivation for typo / rename / corrective-amendment chunks (added 2026-05-18 per CH-04-i-phi retro P5, cycle hex `8a9c50ea`)**: when a chunk closes a typo correction / rename / corrective-amendment at a definition-site doc (detected by scanning plan §3 F<X>.<letter> lock bodies for phrases like "corrects spec.md line N typo `X` → `Y`", "renames `A` to `B`", "amends `<literal>` to `<corrected-literal>`"), the canonical stale-narrative phrase set above is **extended with the pre-correction literal** for THIS chunk's gate-2 widened sweep. Grep all `docs/<project>/v0/**/*.md` (or project-equivalent) for the pre-correction literal BEFORE auditor dispatch; patch any non-META live usages (excluding plan archives, audit logs, ADR sub-decisions discussing the correction, forward-scope, frozen archive plans). Implementer-side defence is chunk-implementer v14 P6 (P-SEAL typo-cascade grep); both layers fire. **CH-04 evidence**: spec.md line 13 `donAsk` → `dontAsk` typo correction landed at definition site, but 4 cross-cutting live usages went unswept (overview.md:54 / whatsapp.md:22 / telegram.md:26 / bootstrap.md:31). Audit C iter-1 surfaced as Trivial-multi (4-line sweep). Applying the dynamic-pattern derivation at gate-2 would have closed at gate-2 instead of routing through Audit C iter-1 + iter-2 re-spawn.
3. **Audit review.** Read each iteration's audit log; spot-check 1–2 random claims by reading cited file:line. **Audit-prompt-authoring cross-check (added 2026-05-18 per CH-04-i-phi retro P3, cycle hex `8a9c50ea`)**: BEFORE dispatching auditors at gate-3, grep each `F<X>\.<letter>` token in the audit prompt body and cross-check the wording matches the LOCKED variant in plan §3 + ADR §D<N>.<M>. Scriptable: `grep -oE 'F[-A-Za-z0-9]+\.[a-z]' <audit-prompt> | sort -u` produces the prompt-side token set; cross-reference each token against plan §3's `LOCKED at gate-1, planner-rec F<X>.<letter>` rows; the wording in the audit prompt's lock-verification table MUST match the lock-body wording verbatim (not the planner-rec wording when divergent). **CH-04 evidence**: audit prompt for Auditor A wrote `F-empty-scope.a strict EmptyScope error` but the locked F-empty-scope.a body is *graceful* `MergedPermissions::default()` fallback (the "strict" wording came from CH-03 F-empty-dir-fallback.b which is a sibling lock with opposite semantics). Auditor A noted the audit-prompt typo as informational; code was correct per the actual lock. Applying the cross-check before dispatch catches the class as a Trivial-1L pre-dispatch fix.
4. **Final cycle re-audit (mandatory).** After all sub-agent audits go green, I personally re-read every diff, re-run full workspace tests + 4 CI guards, run phi-core-leverage-check + k8s-readiness-check skills, verify all paperwork. Write `cycle-audit.md`. May re-trigger Implementer or Planner re-spawn. Never skipped. **MUST-RUN list (sub-agents cannot execute these reliably):** `RUSTFLAGS="-Dwarnings" cargo clippy -j 4 --workspace --all-targets` + the 4 `bash scripts/check-*.sh` CI guards. Sub-agent auditors will mark these claims `NOT-EXECUTED-IN-AUDIT` (sandbox-blocked) — orchestrator closes them at this gate.
5. **Retrospective review.** Read retrospector's draft; propose standards updates to user; apply approved updates with version bumps logged in `.claude/agents/_changelog.md`.

   **In-M5 carve-out vs M6-DEFERRED routing (NEW CH-26 retro Row 6, cycle hex `d1cb9e1f`)**: when a chunk closes a HIGH/MEDIUM drift at the load-bearing semantic axis but defers a wire-tier-tightening or follow-on-engine-scope-widening axis, route the deferred work via one of two paths:

   | Choice | Criterion | Precedent |
   |---|---|---|
   | In-M5 carve-out (NEW CH-NN+1 chunk) | The deferred work is (a) load-bearing for the current milestone's invariants, (b) ≤ ~10 ed scoped, (c) user-requested explicitly to stay in M5 | CH-26 → CH-27 (M5.3 carve-out) per user direction 2026-05-16 |
   | M6-DEFERRED-NN drift | The deferred work is (a) NOT load-bearing for current milestone invariants, (b) > ~10 ed scoped, or (c) intersects M6+ feature surface | CH-25 F-D59.2/F-D59.3 (M6-DEFERRED) |

   Decision routing belongs to the user; the retrospector's role is to surface the decision + capture the routing in the cycle-audit + the cycle-index Status flip.

   **CH-27 (cycle hex `0edcaba9`) ratifies the criteria via the first successful application** (per CH-27 retro Row 10): within a single chunk, F3.a resolvers wiring routed M6-DEFERRED (architectural design > ~10 ed; not load-bearing for M5 wire-tier closure → `D-CH27-FOLLOWUP-01` filed) while wire-tier blocking + synth-grant widening + F4.b helper routed in-M5 (load-bearing for M5 invariants; user-routed). Both choices applied to the same chunk per their respective criteria.

   **Cargo-clean discipline operates at TWO placements (refined 2026-05-10 per CH-18 retro Row 1, USER DIRECTIVE, cycle hex `c77937bc`)**:

(1) **Immediate-post-test cleanup (NEW per CH-18)**: AFTER each `cargo test --workspace` invocation across the cycle (sub-agent audits A + B, orchestrator gate-4 final test, retrospector permissions-audit script), the invoker MUST run `cargo clean --manifest-path /root/projects/phi/baby-phi/Cargo.toml` BEFORE issuing the next cargo invocation. Per-invocation cleanup ensures the next invocation starts from clean target/ and prevents accumulation across multiple test runs within a single cycle. CH-18 evidence: 2 duplicate cargo-test workspace background runs accumulated target/ to 146 GB → 100% disk → 1h24m hung process → user-directed kill + cargo clean reclaimed 151 GiB. The user directive that codified this: *"tests should be cleaned up immediately after the run as it may block future tests"* (2026-05-10).

(2) **Gate-5 final close cleanup (CH-17 retro Row 1, USER REQUESTED 2026-05-09, cycle hex `40c4d759`)**: after standards updates landed + cycle-index row flipped to `retro-complete`, the orchestrator runs `/root/rust-env/cargo/bin/cargo clean --manifest-path /root/projects/phi/baby-phi/Cargo.toml` as the closing step before user commit. Capture `du -sh /root/projects/phi/baby-phi/target` BEFORE + `df -h /root | head -3` AFTER and log disk reclaimed in the cycle-audit's §7 metrics row.

**Why TWO placements (not just one)**: CH-17 retro Row 1's gate-5-close-only placement was insufficient because target/ can balloon DURING gate-4 if multiple test invocations run concurrently or sequentially without cleanup. CH-18 evidence proved per-invocation cleanup is necessary; gate-5 final close is still mandatory as a final pre-commit cleanup. Both placements together prevent within-cycle disk-pressure incidents AND ensure clean state at chunk release.

**Empirical durability (added 2026-05-18 per CH-27 retro Row 11, cycle hex `0edcaba9`)**: Validated across **7+ consecutive cycles** (CH-18 codified → CH-27 7th-cycle re-validation; ~600+ GiB cumulative reclaimed across all cycles; **0 mid-cycle disk-pressure incidents** post-codification). CH-27 placement-1 alone reclaimed 92.1 GiB at gate-4 close.

**Gate-2.5 PAUSE between P-FIXTURES + P-DOCS (added 2026-05-18 per CH-27 retro Row 9, cycle hex `0edcaba9`)**: when a chunk has a P-FIXTURES (or any cascade-emitting phase that materialises plan §3 cascade predictions into actual cardinality numbers) immediately preceding P-DOCS, the orchestrator inserts a **gate-2.5 PAUSE** between them. The implementer reports a **P-FIXTURES actuals snapshot** (call-site count, file count, LOC added, cascade-band predicted-vs-actual marker COLLAPSE / WITHIN / OVERRUN); orchestrator confirms before P-DOCS opens. **P-DOCS MUST cite the snapshot as authoritative for cardinality assertions, NOT plan §X bands.** Closes the cascade-cardinality-stale-narrative documentation gap surfaced at CH-27 Audit-B side observation (19 fixture-extension sites documented across 4 docs while P-FIXTURES landed 9; orchestrator applied Trivial-multi cardinality cascade patch at gate-3 across 7 doc locations). Paired with chunk-implementer v13 R3.

**Gate-1.5 pre-archival quartet (added 2026-05-19 per CH-05-i-phi retro `f7a354b6` — closes the "iter-N+ refinement architectural-precision" cluster)**: at gate-1.5 plan-archive (immediately BEFORE the orchestrator calls `chunk-archive-plan` to mint the 8-hex token + insert the cycle-index row), the orchestrator runs FOUR pre-archival checks. The first two mirror chunk-planner v23 P-plan-1 + P-plan-2 from the orchestrator side; the third closes a stale-numeric-citation pattern; the fourth codifies the architectural-refinement-at-approval-gate routing precedent.

**(1) P-orch-1 — LOC-cap functional-scope-derivation cross-check (mirror of chunk-planner v23 P-plan-1)**: read plan §3.B per-file LOC caps. For any cap that diverges from precedent baseline by > 2× (e.g., 350 LOC cap vs CH-03 80 LOC baseline), verify the plan §3.B body cites the functional-scope axes that drive the higher cap (field count, helper count, inverse renderer presence, inline test count). If the justification is missing or thin (< 2 sentences citing concrete axes), Trivial-1L plan-edit BEFORE archive to surface the derivation. CH-05 precedent: parser.rs cap was 80 (mirrored from CH-03 baseline) but functional scope warranted ~350-400; the precedent-mirror was the wrong reference frame.

**(2) P-orch-2 — `cargo tree` dependency-cascade verification (mirror of chunk-planner v23 P-plan-2)**: read plan §3 cascade vector B. For any newly-predicted direct-dep add (e.g., `chrono = "0.4"`) or feature flip (e.g., `uuid features = [..., "serde"]`), run `cargo tree -p <crate> | grep <dep>` against the current submodule manifest. Confirm (a) the dep exists transitively (prediction is grounded), (b) is NOT re-exported from the direct dep (so the direct-dep promotion is necessary), and (c) is listed in the plan's predicted Cargo.toml diff section. Flag mismatches as Trivial-1L plan-edit BEFORE archive. CH-05 precedent: uuid `serde` feature add + chrono direct-dep promotion both went un-predicted in plan §3 cascade vector B; impl absorbed silently and surfaced as cycle-audit §6 PASS-with-note.

**(3) P-orch-3 — Pre-archival numeric-citation cross-check (closes CH-05 retro §3 D4 — plan §6 stale "36" → 34 permissions test count)**: at gate-1.5, grep plan §6 carry-forward numeric claims (`\d+ (permissions|identity|daemon|smoke) tests`) and cross-reference against a `cargo test --workspace --no-run` snapshot. The snapshot is the authoritative test count at plan-archive time. Flag mismatches as Trivial-1L plan-edit BEFORE archive. CH-05 precedent: plan §6 stated "36 permissions tests" in the carry-forward block but the actual snapshot at plan-archive time was 34 (CH-04 had been recounted post-CH-04 retro). The stale citation absorbed silently into the archived plan and surfaced as cycle-audit §6 PASS-with-note at gate-4. Scriptable: write a `scripts/numeric-citation-check.sh` that takes the plan path + project root, greps the canonical phrase set, runs `cargo test --no-run`, and prints the mismatch matrix.

**(4) P-orch-4 — Architectural-refinement-at-approval-gate routing precedent (closes CH-05 retro §3 D7 — iter-2 → iter-3 asymmetric tier-layout precedent codification)**: when the user surfaces an architectural insight at gate-1.5 final-approval read that materially **refines a LOCKED variant body** (NOT a fork re-vote — the user accepts the locked option but refines what the option means at the implementation level), the orchestrator routes via a **second planner re-spawn** with the refinement scoped to the affected fork bodies only. Other locks keep their iter-2 status. The re-spawn produces an iter-3 plan that absorbs the refinement; auditors + implementer downstream see only iter-3. **CH-05 precedent**: user surfaced the Claude Code MEMORY.md pattern at gate-1.5 (after iter-2 locked-fork-appendix re-spawn under chunk-initiate Step A); planner re-spawned to iter-3 with asymmetric tier layout (short-term `.md`+detail-files, long-term JSONL, episodic JSONL stub). `F-storage-layout` + `F-retrieval` + `F-write-atomicity` bodies refined; `F-tier-types` + `F-rotation` + `F-incognito` + `F-record-id` kept iter-2 status. Result: zero downstream rework, single PASS-at-iter-1 audit cycle. Process worked — codify as the canonical routing. Companion rule at chunk-initiate v? Phase 1.5 Step C.

**User-directed mid-cycle in-plan amendment exception class (P-orch-1, added 2026-05-20 per CH-06-i-phi retro `da221147` — first activation; codifies plan §3.B-A precedent)**: per-chunk plan archives are normally **immutable** post-archive (`chunk-archive-plan` skill closure). EXCEPTION: when the user explicitly directs a mid-cycle in-plan amendment at any phase boundary (gate-2 / gate-2.5 / gate-3 / gate-4) with a stated rationale (typically code-vs-documentation consistency after a Route B / fork-relaxation / scope-deviation route is selected), the orchestrator MAY append an `### §X.Y-A — Mid-cycle scope-deviation amendment (added YYYY-MM-DD post-archive)` block to the archived plan. The amendment block MUST:
- Open with `> **EXCEPTION to plan-archive immutability — user-directed at YYYY-MM-DD for <stated reason>**` citation header.
- Document what changed in tabular form (original §X.Y row | amended row | reason).
- Cite the cross-references that ratify the amendment (ADR §DN.M + cycle-audit §Z + chunk-implementer P-SEAL deviation log entry).
- Note the precedent class for future cycles citing this as "plumbing-extraction-on-LOC-pressure" or equivalent.

**CH-06 precedent (canonical first activation)**: plan §3.B-A "Mid-cycle scope-deviation amendment" appended at 2026-05-20 to ratify Route B cascade.rs extraction + handle.rs/registry.rs residual LOC overruns. User-directed rationale: code-vs-documentation consistency so future readers see the deviation noted in-plan without cross-referencing ADR + cycle-audit + P-SEAL log separately. Companion precedent: spec-framework-87f86df8.md treated as living index under user direction (CH-01-i-phi).

**Post-mid-cycle-deviation re-citation cross-check at gate-3 (P-orch-2, added 2026-05-20 per CH-06-i-phi retro)**: when a user-directed mid-cycle in-plan amendment lands per P-orch-1, the orchestrator MUST verify bidirectional citation freshness at gate-3 (audit dispatch). Specifically:
- Grep the amendment block for its cited cross-references (ADR §DN.M + cycle-audit §Z + P-SEAL deviation log entry).
- For each cross-reference, verify the cited artifact exists + carries a reciprocal citation back to the amendment.
- If any cite is missing or stale, apply a Trivial-1L pre-audit patch to fix the cite-drift.

**CH-06 evidence**: plan §3.B-A cites ADR-0008 §D8.14 + cycle-audit §6 + chunk-implementer P-SEAL deviation log. ADR-0008 §D8.14 reciprocally cites the §3.B-A amendment. Gate-3 verification passed (auditor B claim 7 included the cross-check; both audit logs PASS).

**Audit-fix loop:**
- **Tactical FAIL** — re-spawn Implementer with audit log path; re-spawn auditors (iter N+1).
- **Architectural FAIL** — re-spawn Planner with audit log path; **always escalate to user**; re-spawn Implementer; re-spawn auditors.
- **Trivial FAIL** — split into two sub-tiers:
  - **Trivial-1L**: ≤ 1-line orchestrator-applied patch on a verified-header / changelog row / index entry → orchestrator verifies in `cycle-audit.md` (no auditor re-spawn). Logged in cycle-audit §"Iteration accounting".
  - **Trivial-multi**: > 1-line trivial patch (small docstring, missed cross-ref, etc.) → re-spawn auditor at iter N+1 as before.
- **Iteration cap**: ≥ 3 iterations on the same finding → STOP, escalate to user.
- **Session-interrupt mid-audit kill (added CH-26 retro Row 5, cycle hex `d1cb9e1f`)**: if the expected audit log file (`audit-<letter>-iter<N>.md`) does NOT appear within reasonable time post-spawn (suggested: 30-60 minutes for a normal audit; longer if the audit involves cargo test/clippy), suspect session-interrupt mid-flight killed the sub-agent. **Re-dispatch with the SAME prompt is safe** (sub-agent is stateless across spawns; no partial-file-state corruption risk for the resumed run; audit log files are written atomically at audit completion). **The re-dispatch is NOT counted as an audit-fix-loop iteration** (iteration counter advances only on FAIL/PARTIAL → tactical/architectural re-spawn). CH-26 Audit-A was re-dispatched once cleanly under this protocol.

**Meta-plan archive**: design rationale lives at `baby-phi/docs/specs/agentic-workflow/multi-agent-chunk-pipeline-0853574c.md`. Read this before extending the system (e.g., adding a `phase-planner` agent for M6+ milestone-to-chunks decomposition).

**Quality is non-negotiable.** The user's locked principle: *quality and thoroughness over cycle completion*. The final cycle re-audit cannot be skipped. Every audit FAIL flows into the retrospective's audit-cycle gaps section with a proposed gap-closing change.

**Telemetry + permissions-audit (added 2026-05-03 per `permissions/tool-use-logging-and-permissions-audit-skill-18564835.md`).** Every tool call is logged to `.claude/tool-use.log` (gitignored, JSONL, 10MB rotation) by the `log-tool-use.sh` hook (PostToolUse + PostToolUseFailure + PermissionRequest). At retro time, the chunk-retrospector (v2) invokes the `permissions-audit` skill which reads the log, cross-references `settings.json` rules, and emits an §A–§H markdown report. Findings (hot allow-rule candidates, dead rules, hook false-positive flags, cross-cycle trends) land in §3.5 of the cycle retrospective with the full report appended. Standards updates from the audit flow through the same retro → user-review → standards-update pipeline as agent-prompt updates.

## Granular Bash discipline

Each Bash tool invocation runs **one logical operation**. Multiple operations = multiple invocations. Source-of-truth: `baby-phi/docs/specs/permissions/granular-bash-discipline-ab19399b.md`.

**Allowed shapes:**
- Single command + flags + paths.
- Single command + 1 trailing viewing/aggregating pipe (`cmd | head -N`, `cmd | wc -l`, `cmd | tail -N`).
- Single command with redirects paired with a downstream pipe (`cargo test 2>&1 | tail -20`).

**Discouraged shapes (break into separate Bash calls):**
- Multi-line bash scripts (newlines split into fragments; ~48% of CH-13 prompts).
- `&&` / `||` / `;` chains (each statement = separate Bash call).
- Pipelines beyond 2 stages.
- Trailing `2>&1` without a downstream pipe (empirical quirk).
- `cd <abs> && <cmd>` compounds (use absolute paths in the command itself).
- **4-stage cardinality-extraction pipelines** (added 2026-05-08 per CH-14 retro Row 4, cycle hex `5803bb94`): `cargo test ... 2>&1 | grep ... | sed ... | awk ...` exceeds the 2-stage cap. CH-14 gate-4 logged 14 PermissionRequests on a 4-stage `cargo test | grep | sed | awk` pipeline (3.5× the 2-stage cap). **Recommended fix**: write the extraction script to a file (`scripts/audit-tmp-cargo-counts.sh`), then run `bash /abs/path/scripts/audit-tmp-cargo-counts.sh` as a single Bash call. The orchestrator's gate-4 cargo-test cardinality-extraction is now refactored to this form (CH-14 retro Row 8).

**Tool-specific absolute-path forms:**
- `git -C /root/projects/phi/baby-phi <subcmd>` instead of `cd ... && git <subcmd>`.
- `cargo --manifest-path /root/projects/phi/baby-phi/Cargo.toml ...` instead of `cd ... && cargo ...`.
- `bash /root/projects/phi/baby-phi/scripts/check-*.sh` instead of `cd ... && bash scripts/...`.
- `grep -rn 'X' /root/projects/phi/baby-phi/modules/crates/` instead of `cd ... && grep -rn 'X' modules/crates/`.

**`cd <abs> && <cmd>` compound reminder (added 2026-05-18 per CH-04-i-phi retro P16, cycle hex `8a9c50ea`)**: even when the working dir feels natural to cd into (e.g., `cd /root/projects/phi/baby-phi && git status` to "be in" the submodule before running git), use the `-C` / `--manifest-path` / `bash <abs>` absolute-path form instead — the compound triggers a permission prompt at `Bash::cd:<path> *` even when `git -C <path> status` would auto-approve. CH-04 permissions-audit captured a 6-prompt `Bash::cd:/root/projects/phi/baby-phi *` cluster (cross-cycle baby-phi M6 forward-scope bleed during this cycle's planner re-spawn) that all originated from `cd && <cmd>` compounds when the equivalent `-C` form is already allow-listed. Workflow discipline, not a permissions issue.

**For multi-step audit/research scripts**: write the script to a file via the Write tool (e.g., `/root/projects/phi/baby-phi/scripts/audit-tmp.sh`), then run `bash /abs/path/audit-tmp.sh` as a single Bash call. Each line of the script runs in the bash process; only the outer `bash <file>` call is matched against allow rules.

This discipline applies to the orchestrator (Claude with full conversation context). chunk-implementer + chunk-auditor agent prompts carry compatible discipline (CH-12 retro Row 6 cd-overuse + CH-13 retro Row 4 replace_all-avoidance, refactored to lead with the granular principle in v4). CH-14 retrospective will validate prompt-count drop (target: < 5 in CH-14, vs CH-13's 312).