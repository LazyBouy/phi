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
2. **Per-phase implementation review.** Read diff, run cargo test + clippy myself, verify phi-core grep, confirm test count matches plan §8 expected.

   **Doc-sync widened sweep at gate-2** (canonical stale-narrative phrase set): when a gate-2 inline correction changes implementation behaviour OR a chunk closes a drift with cross-cutting documentary impact, grep ALL `docs/specs/v0/implementation/m*/{architecture,operations,user-guide}/*.md` (NOT just plan §3.C-listed files) for these phrases:
   - `\b(D-CH[0-9A-Za-z]+-)?FOLLOWUP(-[A-Z]+)?-NN\b` (captures FOLLOWUP-NN, FOLLOWUP-PHICORE-NN, D-CH<NN>(b|c)?-FOLLOWUP-NN planning-time placeholders, future FOLLOWUP-WASM-NN etc.)
   - `deferred per` / `is NOT emitted` / `not emitted at CH-NN` / `advisory at M5` / `Step 0 only blocking` / `M6+ tightens the gate` / `at M5/P4` / `not blocking at M5`
   - **Cycle-bound TBD extension** (post-CH-17): `\bTBD at CH-[0-9]+[a-z]?\b|\bdecided at CH-[0-9]+[a-z]? chunk-plan\b|\(currently TBD|\bis TBD\b|\bdefaults TBD\b`

   Patch matches BEFORE dispatching auditors. Audit-fix-loop iteration cap counts these as Trivial-multi if > 1 line, Trivial-1L if ≤ 1 line.

   **Dynamic-pattern derivation for typo / rename / corrective-amendment chunks**: when a chunk closes a typo / rename / corrective-amendment at a definition-site doc (detected by scanning plan §3 F<X>.<letter> lock bodies for "corrects spec.md line N typo `X` → `Y`" / "renames `A` to `B`" / "amends `<literal>` to `<corrected-literal>`"), extend the phrase set above with the pre-correction literal. Grep all `docs/<project>/v0/**/*.md` for it BEFORE auditor dispatch; patch any non-META live usages (excluding plan archives, audit logs, ADR sub-decisions discussing the correction, forward-scope, frozen archive plans). Implementer-side defence is chunk-implementer v14 P6 (P-SEAL typo-cascade grep); both layers fire.

   **ADR ↔ open-questions cross-check**: for every ADR sub-decision the chunk files claiming to resolve a concept-doc open-question (e.g., `### §D<N>.<M> — <resolution> (resolves F<X>)`), verify the cited concept doc carries an `[ANSWERED at CH-<NN>: <one-line resolution + ADR cite>]` annotation. Apply Trivial-1L (≤ 1-line annotation per missing question) before audit dispatch.

   Precedent cycles: CH-14 + CH-15-baby-phi (initial widening triggers), CH-08 + CH-16b-i-phi (regex generalizations to FOLLOWUP-PHICORE + planning-time placeholder), CH-02a-i-phi (ADR ↔ open-questions cross-check), CH-04-i-phi (dynamic-pattern derivation), CH-17-i-phi (cycle-bound TBD extension) — full narratives at `discipline-archive.md` anchors `#ch-14-baby-phi-doc-sync-widened-sweep-trigger` / `#ch-15-baby-phi-doc-sync-widened-sweep-extension` / `#ch-04-i-phi-dynamic-pattern-derivation` / `#ch-16b-i-phi-non-f-token-paraphrase-extension` / `#ch-17-i-phi-approval-gate-summary-divergence`.
3. **Audit review.** Read each iteration's audit log; spot-check 1–2 random claims by reading cited file:line. **Audit-prompt-authoring cross-check (6-axis script consolidation)**: BEFORE dispatching auditors at gate-3, invoke `bash /root/projects/phi/.claude/scripts/audit-prompt-cross-check.sh <plan.md> <audit-prompt>`. Script runs 6 axes — (1) F-token / (2) lock-body paraphrase / (3) test-name allocation / (4) method-signature paraphrase / (5) arg-shape divergence refinement / (6) literal-count paraphrase (enum variants / struct fields / routes / utoipa paths / middleware-order). Emits `[axis]<name>: PASS|DIVERGENT - <evidence>` per axis; exit 1 if any axis diverges, 0 if all PASS. Surface DIVERGENT axes as Trivial-1L pre-dispatch text-edits OR escalate as Trivial-multi if a delegate method/file is missing; may suppress informational false-positives (e.g., DIVERGENT method-sig where the cited symbol is a phi-core surface name resolved via project context). Heuristic script interpretation still requires manual judgment for PARTIAL cases (semantic equivalence preserved with wording-divergent paraphrase). For axis-4 method-form deliverables specifically, the consolidated `interface-contract-verify` skill provides the 4-axis impl-block-membership verification (method-exists / impl-block-exists / body-inside-impl / signature-match) — invoke via the skill when the axis returns DIVERGENT to disambiguate FAIL (missing delegate) vs PARTIAL (semantic-equivalent with diff arg-shape). Empirical precedent cycles: CH-04-i-phi (F-token), CH-16b-i-phi (lock-body), CH-07a/CH-07b-i-phi (method-sig + test-name), CH-10-i-phi (arg-shape), CH-11a-i-phi (literal-count 6th-axis crystallization), CH-17-i-phi (clean 6-axis pass empirical-stability confirmation) — full narratives at `discipline-archive.md` anchors `#ch-04-i-phi-audit-prompt-authoring-cross-check-trigger` / `#ch-16b-i-phi-non-f-token-paraphrase-extension` / `#ch-07b-i-phi-interface-contract-drift` / `#ch-10-i-phi-arg-shape-divergence` / `#ch-11a-i-phi-literal-count-axis-crystallization`.
4. **Final cycle re-audit (mandatory).** After all sub-agent audits go green, I personally re-read every diff, re-run full workspace tests + 4 CI guards, run phi-core-leverage-check + k8s-readiness-check skills, verify all paperwork. Write `cycle-audit.md`. May re-trigger Implementer or Planner re-spawn. Never skipped. **MUST-RUN list (sub-agents cannot execute these reliably):** `RUSTFLAGS="-Dwarnings" cargo clippy -j 4 --workspace --all-targets` + the 4 `bash scripts/check-*.sh` CI guards. Sub-agent auditors will mark these claims `NOT-EXECUTED-IN-AUDIT` (sandbox-blocked) — orchestrator closes them at this gate.

   **cycle-audit §6 deviation-class row template (added 2026-05-21 per CH-16b-i-phi retro `634ce263` proposal #6)**: when authoring `cycle-audit.md` §6 deviations, surface `audit-prompt-authoring miss` as an explicit deviation-class row WHEN APPLICABLE (orchestrator-side process miss where audit prompt wording diverged from plan §1 lock-body wording or §3 lock variants). Standard row shape:
   ```
   | D-N | Audit-prompt-authoring miss | Audit <letter> iter-N prompt claim <M> | <one-line description of the wording divergence — e.g., "paraphrased <lock-body sentence> as <prompt sentence>; semantically equivalent or different from code">. Code <correct/incorrect> per actual lock at <file:line>. | Per outer CLAUDE.md gate-3 audit-prompt-authoring cross-check extension (CH-16b retro proposal #2 lock-body paraphrases). <Process-side: surface to chunk-retrospector for possible standards update OR Code-side: Trivial-1L pre-dispatch fix>. |
   ```
   CH-16b D-2 cycle-audit row is the canonical precedent. The deviation-class doesn't increment iteration counters (it's an orchestrator-side process observation, not a code defect); only logged in §6 for future trend tracking + standards-update awareness.
5. **Retrospective review.** Read retrospector's draft; propose standards updates to user; apply approved updates with version bumps logged in `.claude/agents/_changelog.md`.

   **chunk-order.md update (i-phi only; added 2026-05-20 per chunk-order-plan cycle `ece2a46a`; EARLY-FLIP CODIFIED 2026-05-24 per CH-07b-i-phi retro `283d3949` proposal #2)**: update `/root/projects/phi/i-phi/docs/v0/proposal/plan/forward-scope/chunk-order.md` — (a) flip the just-closed chunk's §1 state column ⏳ → ✅ + add cycle hex; (b) advance the §2 Serial recommendation `⮕ NEXT` marker to the next pending chunk; (c) collapse / promote §3 Parallel-recommendation groups as members land. **Timing — early-flip canonical**: by default the flip lands **in-chunk at P-ADR / P-DOCS** during the implementer's seal-phase paperwork (ratified by the orchestrator at gate-4) for chunks where the chunk-seal commit reliably lands in-cycle (e.g., split-half chunks like CH-07a/CH-07b; mechanical chunks). **Phase-7 fallback**: retro-close timing applies when retro Phase 6 reaches before chunk-seal commit lands (rare; e.g., user-aborted retro path resuming via `/chunk-initiate resume_from_phase=retro`). **4-cycle empirical precedent**: CH-26 + CH-27 (baby-phi) + CH-07a + CH-07b (i-phi) all converged on in-chunk early-flip vs Phase-7-only — codified 2026-05-24 to align canonical doc with practiced flow. The doc is the canonical "what's the next chunk?" lookup for i-phi; takes ~2-3 minutes per cycle close. **Roles separation**: `_cycle-index.md` is the historical/audit ledger; `chunk-graph.md` is the authoritative dependency graph; `chunk-order.md` synthesises both for forward-looking decisions. Baby-phi has no analogous doc — milestone-level structure (M5/M6) supersedes flat chunk-order for that project.

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

**Empirical durability (added 2026-05-18 per CH-27 retro Row 11; bumped 2026-05-20 per CH-28 retro P-doc-1, cycle hex `0412eb06`)**: Validated across **8+ consecutive cycles** (CH-18 codified → CH-28 8th-cycle re-validation; ~990+ GiB cumulative reclaimed across all cycles; **0 mid-cycle disk-pressure incidents** post-codification). CH-28 placement-1 reclaimed ~390 GiB across 6 invocations in the cycle (5 plan iterations + 8 substantive phases + 3 parallel audits — significant due to iteration-heavy cycle scope).

**Gate-2.5 PAUSE between P-FIXTURES + P-DOCS (added 2026-05-18 per CH-27 retro Row 9, cycle hex `0edcaba9`)**: when a chunk has a P-FIXTURES (or any cascade-emitting phase that materialises plan §3 cascade predictions into actual cardinality numbers) immediately preceding P-DOCS, the orchestrator inserts a **gate-2.5 PAUSE** between them. The implementer reports a **P-FIXTURES actuals snapshot** (call-site count, file count, LOC added, cascade-band predicted-vs-actual marker COLLAPSE / WITHIN / OVERRUN); orchestrator confirms before P-DOCS opens. **P-DOCS MUST cite the snapshot as authoritative for cardinality assertions, NOT plan §X bands.** Closes the cascade-cardinality-stale-narrative documentation gap surfaced at CH-27 Audit-B side observation (19 fixture-extension sites documented across 4 docs while P-FIXTURES landed 9; orchestrator applied Trivial-multi cardinality cascade patch at gate-3 across 7 doc locations). Paired with chunk-implementer v13 R3.

**Gate-1.5 pre-archival quartet / octet (added 2026-05-19 per CH-05-i-phi retro `f7a354b6` — closes the "iter-N+ refinement architectural-precision" cluster; extended through P-orch-7 + P-orch-8 at 2026-05-26 per Chunk D intermediate-stabilization `36caa39f` v32 iter-2 re-arch)**: at gate-1.5 plan-archive (immediately BEFORE the orchestrator calls `chunk-archive-plan` to mint the 8-hex token + insert the cycle-index row), the orchestrator runs EIGHT pre-archival checks (P-orch-1 through P-orch-8). The first two mirror chunk-planner v23 P-plan-1 + P-plan-2 from the orchestrator side; the third closes a stale-numeric-citation pattern; the fourth codifies the architectural-refinement-at-approval-gate routing precedent; the fifth grounds plan-narrative literals against `cargo check` workspace surface; the sixth verifies skeleton-vs-fully-behavioural within-lock-body semantics; the seventh cross-checks approval-gate-summary against plan body §11 values; the eighth (P-orch-8) gates iter-2 planner re-spawn skip when planner-rec-clean AND §1 populated.

**(1) P-orch-1 — LOC-cap functional-scope-derivation cross-check (mirror of chunk-planner v23 P-plan-1)**: read plan §3.B per-file LOC caps. For any cap that diverges from precedent baseline by > 2× (e.g., 350 LOC cap vs CH-03 80 LOC baseline), verify the plan §3.B body cites the functional-scope axes that drive the higher cap (field count, helper count, inverse renderer presence, inline test count). If the justification is missing or thin (< 2 sentences citing concrete axes), Trivial-1L plan-edit BEFORE archive to surface the derivation. CH-05 precedent: parser.rs cap was 80 (mirrored from CH-03 baseline) but functional scope warranted ~350-400; the precedent-mirror was the wrong reference frame.

**(2) P-orch-2 — `cargo tree` dependency-cascade verification (mirror of chunk-planner v23 P-plan-2)**: read plan §3 cascade vector B. For any newly-predicted direct-dep add (e.g., `chrono = "0.4"`) or feature flip (e.g., `uuid features = [..., "serde"]`), run `cargo tree -p <crate> | grep <dep>` against the current submodule manifest. Confirm (a) the dep exists transitively (prediction is grounded), (b) is NOT re-exported from the direct dep (so the direct-dep promotion is necessary), and (c) is listed in the plan's predicted Cargo.toml diff section. Flag mismatches as Trivial-1L plan-edit BEFORE archive. CH-05 precedent: uuid `serde` feature add + chrono direct-dep promotion both went un-predicted in plan §3 cascade vector B; impl absorbed silently and surfaced as cycle-audit §6 PASS-with-note.

**(3) P-orch-3 — Pre-archival numeric-citation cross-check (consolidated to baseline-snapshot skill at Chunk C 2026-05-26)**: at gate-1.5, invoke skill `baseline-snapshot` against the project root + plan body's citation list (struct-field-count / enum-variant-count / route-count / utoipa-path-count / test-count). Skill outputs JSON; orchestrator diffs against plan §1 / §6 / §8 numeric claims; flag mismatches as Trivial-1L plan-edit BEFORE archive. Pairs with chunk-planner v31 P-plan-13-v31 (planner-side struct-field snapshot at iter-2). Empirical precedents: CH-05 plan §6 stale "36 permissions tests" vs actual 34; CH-11a plan §6 §D13.10 cited SessionHandle 7→9 fields vs actual baseline 11 (stale by 4 fields). Full evidence at `discipline-archive.md` `#ch-05-i-phi-pre-archival-quartet-evidence` + `#ch-11a-i-phi-literal-count-axis-crystallization`.

**(4) P-orch-4 — Architectural-refinement-at-approval-gate routing precedent (closes CH-05 retro §3 D7 — iter-2 → iter-3 asymmetric tier-layout precedent codification)**: when the user surfaces an architectural insight at gate-1.5 final-approval read that materially **refines a LOCKED variant body** (NOT a fork re-vote — the user accepts the locked option but refines what the option means at the implementation level), the orchestrator routes via a **second planner re-spawn** with the refinement scoped to the affected fork bodies only. Other locks keep their iter-2 status. The re-spawn produces an iter-3 plan that absorbs the refinement; auditors + implementer downstream see only iter-3. **CH-05 precedent**: user surfaced the Claude Code MEMORY.md pattern at gate-1.5 (after iter-2 locked-fork-appendix re-spawn under chunk-initiate Step A); planner re-spawned to iter-3 with asymmetric tier layout (short-term `.md`+detail-files, long-term JSONL, episodic JSONL stub). `F-storage-layout` + `F-retrieval` + `F-write-atomicity` bodies refined; `F-tier-types` + `F-rotation` + `F-incognito` + `F-record-id` kept iter-2 status. Result: zero downstream rework, single PASS-at-iter-1 audit cycle. Process worked — codify as the canonical routing. Companion rule at chunk-initiate v? Phase 1.5 Step C.

**(5) P-orch-5 — `cargo check`-grounded plan-narrative literal-reconciliation pass (added 2026-05-24 per CH-09-i-phi retro `075c07cf` proposal #1 HIGH; closes D-1+D-2+D-3+D-4 plan-narrative cluster — highest single-cycle plan-narrative deviation count on i-phi to date)**: at gate-1.5 plan-archive, immediately after P-orch-1 through P-orch-4, run:

1. `cargo check --message-format=json --manifest-path /root/projects/phi/<project>/Cargo.toml 2>&1 | head -1000` against the workspace.
2. Grep plan §1 (Locked fork details body) + §4 (phi-core leverage map + method signatures) for citations: `grep -nE 'phi_core::[A-Z][A-Za-z]+' <plan.md>` + `grep -nE '<TypeName>::<method>\(' <plan.md>`.
3. For each cited type, verify it exists in the current `phi-core 0.X.Y` surface via `grep -rn 'pub (enum|struct) <Name>\b' /root/projects/phi/phi-core/src/`. For each cited method signature, verify arg-list + return-type match the predicted implementer-side method.
4. Flag mismatches as Trivial-1L plan-edit BEFORE archive (e.g., update "`phi_core::AgentEnd`" → "`phi_core::AgentEvent::AgentEnd { rejection }` + `phi_core::StopReason`" if the workspace surface differs from the plan-narrative citation).

**CH-09 evidence**: plan §1 + §4 cited `phi_core::AgentEnd` as a 5-variant enum; actual workspace surface = `phi_core::StopReason` enum + `AgentEvent::AgentEnd { rejection: Option<String> }` field. Implementer consolidated into `cli::exit::CliEnd` (semantically equivalent; documented in ADR-0011 §D11.5). Plan-narrative deviations D-1 + D-2 + D-3 + D-4 all preventable at gate-1.5 via `cargo check`-grounded literal-reconciliation pass. Applying P-orch-5 surfaces the class as Trivial-1L pre-archive instead of as cycle-audit §6 deviations.

**(6) P-orch-6 — Skeleton-vs-fully-behavioural within-lock-body verification (added 2026-05-24 per CH-09-i-phi retro `075c07cf` proposal #2 HIGH; closes D-8+D-9 v0-scope-narrowings-within-F-LOCKED-body cluster — 3rd-cycle pattern across CH-07a + CH-07b + CH-09)**: at gate-1.5 plan-archive, for each F-LOCKED.a body that includes phrases like "ship X end-to-end" / "full daemon-side wiring" / "full Y" / "NEW Z with full behaviour", orchestrator AskUserQuestion-style cross-check with the planner:

> For F-<name>.a, list any within-lock sub-decisions that ship as: (a) skeleton/stub (no live consumer wired); (b) signal-only (sender shipped but receiver not yet consumed); (c) store-verify-only (recordkeeping but no business-logic re-build); (d) hardcoded default (e.g., `Incognito::No` at v0 with parent-mode-derivation deferred). Mark each with `[v0 scope-narrowing: <one-line>]` annotation in §1 lock body. If none, mark `[fully behavioural at v0]`.

Trivial-1L plan-edit BEFORE archive to annotate each F-LOCKED body. Result: cycle-audit §6 v0-scope-narrowing rows (Code-class deviations D-8/D-9-style) surface in §1 in-plan instead of as post-hoc ADR §D-bodies.

**CH-09 evidence**: F-pause-resume-harvest-routes.a lock body said "ship 3 NEW daemon IPC routes with full daemon-side wiring in SessionRegistry::{pause,resume,harvest} methods" — implementer documented 4 distinct v0 scope-narrowings within that lock at ADR-0011 §D11.2 (UDS path returns DaemonUnreachable / pause signal-only / resume store-verify-only / harvest with hardcoded Incognito::No). Applying P-orch-6 at gate-1.5 surfaces the 4 narrowings as F-pause-resume-harvest-routes.a body annotations BEFORE archive; chunk-implementer + auditors then read the canonical "skeleton vs fully-behavioural" map up-front. Closes the "lock body wording is ambiguous between skeleton + fully-behavioural ship" class.

**(7) P-orch-7 — Approval-gate-summary-vs-plan-body cross-check (added 2026-05-25 per CH-17-i-phi retro `e764aeca` proposal #2 MEDIUM; closes cycle-audit §6 D-1)**: at gate-1.5 plan-archive, BEFORE the orchestrator composes the Phase 1.5 AskUserQuestion approval-gate summary, the orchestrator MUST re-read plan body §11 verbatim (or equivalent §-section authoritative for audit envelope, phase count, fork-lock disposition, test band). The approval-gate summary text mirrors plan body §11 values literally (envelope size + auditor count + phase count + test band). Any iter-2 absorption that bumps envelope / phase count / test band MUST be reflected in the approval-gate prose; mismatches surface as Trivial-1L pre-dispatch edit to the AskUserQuestion text. **CH-17 evidence**: orchestrator's Phase 1.5 approval-gate AskUserQuestion summary cited "Audit envelope: Medium (2 auditors A+B; re-verified)" but iter-2 plan body §11 (line 619 + §11 delta table at line 776) had bumped to LARGE (3 auditors A+B+C) per chunk-planner v17 P1 absorption rule. The approval-gate prose was authored from iter-1 cache + not refreshed at iter-2 archive. Implementer correctly authored cycle-index row with LARGE / 3-auditors per plan body; user-facing approval-gate summary diverged silently. No code/audit impact at this cycle but next time could mislead user expectation of audit cost. Applying P-orch-7 at gate-1.5 catches the class as a pre-dispatch text refresh.

**(8) P-orch-8 — Iter-2 re-spawn skip-condition for planner-rec-clean cycles (added 2026-05-26 per Chunk D intermediate-stabilization `36caa39f` Deliverable #2 — outer phi chunk-planner v32 iter-2 re-arch; companion to chunk-planner v32 P-plan-1-v32 + chunk-initiate Phase 1.5 Step A flip + chunk-archive-plan v4 hard-assertion)**: at gate-1.5 plan-archive, BEFORE the orchestrator triggers iter-2 planner re-spawn per chunk-initiate Phase 1.5 Step A, evaluate the skip-condition:

> **If ALL gate-1 locks land at planner-rec AND iter-1 plan §1 carries populated bodies for every fork (verified via `chunk-template-validate-locked-appendix` skill returning PASS), SKIP iter-2 re-spawn.** Archive directly at iter-1. The `chunk-archive-plan` skill enforces this via a hard-assertion (v4; invokes `chunk-template-validate-locked-appendix` BEFORE minting the 8-hex cycle-folder + appending the cycle-index row; refuses archive on FAIL).
>
> **USER-DIVERGENT path unchanged**: if ≥ 1 fork locks differently from planner-rec, iter-2 re-spawn fires per chunk-initiate Phase 1.5 Step B material-scope-expansion (the existing mechanic). The ONLY change: at iter-2, the planner re-authors ONLY the F<N> subsections corresponding to USER-DIVERGENT locks; planner-rec subsections preserve their iter-1 draft wording verbatim.

**Conditional structure**:

```
iter-1 §1 populated WITH planner-rec bodies (per chunk-planner v32 P-plan-1-v32)
├─ ALL forks lock at planner-rec → P-orch-8 skip-condition fires; archive at iter-1
└─ ≥ 1 fork USER-DIVERGENT → iter-2 re-spawn fires; ONLY divergent F<N> subsections re-authored
```

**Hold-period — EXITED 2026-05-27 at CH-14 close (P6 ratification per joint-retro `bf1139be-to-8b7e80a3` proposal #6)**: the cross-project 2-3-cycle hold-period that began at v32 ship reached cycle #4 at CH-14 close (CH-11b + CH-13a + CH-13b + CH-14 = 4 cycles since v32 ship). Joint-retro §4 proposal #6 ratified the v32 USER-DIVERGENT narrow-re-author path as durable (battle-tested across CH-13b 1-fork + CH-14 3-fork + CH-15 3-fork + Step C scope-refinement); **v23 P-plan-3 ALWAYS-FIRE iter-2 re-spawn for planner-rec-clean cycles is FORMALLY DEPRECATED**. The `chunk-template-validate-locked-appendix` v4 hard-assertion (invoked by chunk-archive-plan v4 BEFORE minting the cycle-folder + cycle-index row) remains as the single regression-defense layer; chunk-planner v32 P-plan-1-v32 end-of-draft self-check is the planner-tier defense; chunk-initiate Phase 1.5 Step A skip-condition is the orchestrator-tier defense. **Historical hold-period context (pre-deprecation, retained for archive)**: during hold-period (CH-11b → CH-14), v23 P-plan-3 ALWAYS-FIRE iter-2 re-spawn remained available as fallback if any cycle's iter-1 §1 missing/malformed AND not caught by hard-assertion. 4 clean cycles validated; deprecation applied 2026-05-27.

**Cross-references**:

- chunk-planner v32 P-plan-1-v32 — defines the iter-1 §1 template change with planner-rec bodies pre-filled (origin of the skip-condition's predicate).
- chunk-template-validate-locked-appendix skill — mechanical 4-step PASS/FAIL validation invoked by P-orch-8 + by chunk-archive-plan v4 hard-assertion.
- chunk-archive-plan v4 — hard-assertion belt-and-suspenders layer at archive-tier.
- chunk-initiate Phase 1.5 Step A — flipped from "ALWAYS-FIRE iter-2 re-spawn" to "ALWAYS-FIRE iter-2 re-spawn UNLESS planner-rec-clean + §1 populated".
- per-chunk-planning-template.md `## §1 — Locked fork details (per chunk-planner v32 iter-1 template; planner-rec bodies pre-filled)` — canonical template structure.

**Rationale (cross-cycle evidence)**: the 7-of-7 i-phi cycle plan-iteration-count pattern (CH-05/CH-06/CH-08/CH-16a/CH-16b/CH-07a/CH-10/CH-11a/CH-17) showed that iter-2 re-spawn fires reliably for USER-DIVERGENT absorption (sub-classes (i)–(iv)) AND for v22 P13 / v23 P-plan-3 appendix-only-absorption. For planner-rec-clean cycles, the iter-2 re-spawn was almost-entirely the locked-fork-details appendix authoring — a cost the iter-1-populated approach (v32) eliminates. P-orch-8 + chunk-archive-plan v4 hard-assertion jointly preserve the regression-defense while skipping the redundant cycle for the planner-rec-clean cohort.

**Project-agnostic note**: P-orch-8 applies uniformly to `project=baby-phi` AND `project=i-phi` AND any future project. No project-specific path literals in the rule directive.

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

**SurrealDB SCHEMAFULL semantic spot-check at gate-4 (added 2026-05-20 per CH-28 retro P-orch-1, cycle hex `0412eb06` — HIGH; closes iter-4 Architectural-FAIL #2 origin)**: when the cycle's plan references a migration shipping `REMOVE FIELD` / `ALTER TABLE` narrowing / new SCHEMAFULL table / narrowing-UNIQUE-index change, the orchestrator MUST at gate-4 final cycle re-audit verify:

1. The §3.F **SurrealDB SCHEMAFULL Semantic Checklist** (per chunk-planner v25 P-plan-1) was authored at iter-2 plan-draft.
2. Every checklist row's mitigation landed in the diff (`grep -rn '<StructName>WireRow' modules/crates/store/src/repo_impl.rs` for wire-strip mitigation; `grep -rn 'read_<struct>_via_<new_relation>_or_fallback' modules/crates/store/src/repo_impl.rs` for synthesis read-path).
3. Spot-check ≥ 1 compound-tx site (e.g., `apply_org_creation`, `apply_agent_creation`) for wire-row substitution propagation per chunk-implementer v17 P-impl-2.
4. `UPDATE` vs `UPSERT` keyword discipline — `grep -nE 'UPDATE type::thing\(.*\) CONTENT' modules/crates/store/src/repo_impl.rs` returns ZERO matches for any blueprint-class create-or-modify path (SurrealDB 2.x `UPDATE` does NOT create rows; must use `UPSERT`).

Cite ADR-0063 §D63.14 + §D63.15 as the canonical pattern + §D63.5 as the partial-UNIQUE workaround precedent. **CH-28 origin**: iter-4 ADDITIVE-only ⇒ workspace-GREEN claim falsified at P1 close because the implementer-side P-FIXTURES snapshot didn't cover SchemaFULL × in-process-struct mismatch; the read-path + write-path bridges were scoped to a later phase. Gate-4 SCHEMAFULL spot-check would have surfaced the mismatch earlier; codified now.

**ADR-inline-amendment verified-header cross-check at gate-3 (added 2026-05-20 per CH-28 retro P-orch-2, cycle hex `0412eb06` — MEDIUM; closes CH-28 ADR-0057 verified-header miss / Audit-B Claim 9 PASS-with-caveat)**: BEFORE dispatching auditors at gate-3, the orchestrator greps every ADR file that received an inline amendment block in the cycle:

```
git -C /root/projects/phi/<project> diff HEAD -- docs/specs/v0/implementation/m*/decisions/*.md | \
  grep -B 1 "Amended at CH-${CYCLE_CHUNK}"
```

For every ADR file in the matched list, verify its line-1 verified-header carries a `CH-NN` prepend matching this cycle. If absent, apply a Trivial-1L verified-header prepend BEFORE auditor dispatch (defensive layer paired with chunk-implementer v17 P-impl-1's chunk-close-time check).

**CH-28 evidence**: ADR-0057 received §D57.7 inline body amendment at P-DOCS (line 150 — cardinality 72→74 cite) but P-SEAL deliverable 8 missed the top-of-file verified-header prepend. Audit-B Claim 9 + Claim 12 surfaced as PASS-with-caveat; orchestrator-applied Trivial-1L at gate-3 close. P-orch-2 catches the class BEFORE auditor dispatch.

**NEW gate-1.7 cross-lock interaction stress-test (added 2026-05-20 per CH-28 retro P-orch-3, cycle hex `0412eb06` — MEDIUM; proactive mitigation for high-iteration-count 3-of-3 DIVERGENT cycles)**: when ≥ 3 fork-locks are user-DIVERGENT at gate-1, the orchestrator's gate-1.5 plan absorption MUST include a NEW gate-1.7 stress-test pass evaluating each pair-wise lock interaction against:

| Pair-wise interaction | Stress-test question |
|---|---|
| **(F<X>.* × F<Y>.*) compile-time invariants** | Do the two locked variants compile cleanly together at every phase boundary? Or does one lock's struct/trait change conflict with the other's call-site expectation? |
| **(F<X>.* × F<Y>.*) runtime-test invariants** | Do the two locks have a shared dependency that runs RED through a phase ordering choice? (e.g., F1.c new struct + F3.b new migrations: between migration-apply and struct-refactor-land the workspace is RED) |
| **(F<X>.* × F<Y>.*) phase-ordering constraints** | Does landing both locks in the same phase work, or must they split across phases? If they split, what's the dependency-graph topology? |

Hypothesis (CH-28 evidence): combined locks have **multiplicative replanning surface**. Explicit pair-wise stress-testing at gate-1.7 surfaces interactions BEFORE iter-2 plan-archive; would catch iter-3 → iter-4 + iter-4 → iter-5 class of Architectural-FAILs earlier. **Defensive only — does NOT block plan-archive**; surfaces interaction concerns to the user via AskUserQuestion if ≥ 1 RED window is anticipated. Paired with chunk-planner v25 P-plan-4 §7.0 phase-order stress-test (implementer-side equivalent).

**CH-28 evidence**: gate-1 locked F1.c hybrid blueprint + F2.b USES_PROFILE rename + F3.b split migrations all DIVERGENT. Iter-2 plan placed P-EDGE-RENAME at step 5 + P1-BLUEPRINT-STRUCT at step 6 → iter-3 phase swap. Iter-3 ADDITIVE-only ⇒ green claim missed SCHEMAFULL × in-process struct mismatch → iter-4 narrowing → iter-5 P1.5-READ-BRIDGE insertion. Each iteration was downstream of the multiplicative lock interaction; gate-1.7 pair-wise stress-test would have surfaced the F1.c × F3.b × in-process-struct interaction at iter-2.

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

**Plan-iteration-count cross-cycle pattern**: i-phi CH-05/CH-16a/CH-16b/CH-07a/CH-10/CH-11a/CH-17 all ran 2-3 plan iterations driven by **user-direction structural refinement** (NOT Architectural-FAIL re-spawn). All 7 i-phi cycles PASSed at iter-1 audits despite multi-iteration plans. 4 sub-classes within the user-direction parent class: (i) structural § restructure (CH-16a iter-3); (ii) scope-reduction lock-absorption (CH-16b iter-2); (iii) scope-EXPANSION lock-absorption (CH-07a + CH-11a + CH-17 iter-2); (iv) gate-1 lock-revision-on-re-surfacing (CH-10 iter-3). Baby-phi CH-28 5-iter case was Architectural-FAIL-driven (different cause class; track separately). Iter-2 planner re-spawn is the canonical "post-lock plan absorption" mechanic; scope-EXPANSION sub-class (iii) is modal when ≥ 2 USER-DIVERGENT locks land at gate-1. Full narrative at `discipline-archive.md` `#plan-iteration-count-cross-cycle-pattern`.

**Cross-cycle fork-divergence observation**: cumulative divergent-fork count splits materially per project — **baby-phi: 14-of-19 (~74%) divergent** (CH-15/17/18/20/24/25/28); **i-phi: 6-of-54 (~11%) divergent** (CH-05..CH-17 cumulative). User systematically prefers tighter / more-fragmented / more-defensive / wire-format-explicit options at baby-phi gate-1 fork-locks → **treat fork-divergence as modal outcome** in baby-phi planner v9+ recommendation framing. i-phi unanimous-planner-rec remains dominant (~93%) but with 3-axis divergence class crystallized at CH-11a + extended at CH-17: (a) architectural-bridge axis (CH-16b `block_on` safety); (b) process-velocity / deadline-lapse axis (CH-07a 3rd-cycle CI-guard lapse); (c) production-readiness-ship-now axis (CH-11a F-cors-policy.c + F-tls-strategy.c + CH-17 F3.c BrakingConfig + F4.b+F4.c-combined observability) — crystallized at first external-Internet surface chunk on i-phi (CH-11a); extends inward to Surface-0-runtime agent-factory observability/config at CH-17. External-surface chunks (CLI / REPL / HTTP / web / WhatsApp / Telegram) cluster divergence on ship-production-ready-from-day-1 decisions; planner should anticipate higher divergence rate on these vs deeper-cluster chunks (memory / permissions / identity). **High-iteration-count correlation**: 3-of-3 DIVERGENT lock-sets correlate with elevated plan-iteration counts (CH-28 5-iter precedent; multiplicative replanning surface); gate-1.7 cross-lock interaction stress-test (below) is the proactive mitigation. Full evidence narrative + cycle-by-cycle precedent table at `discipline-archive.md` `#cross-cycle-fork-divergence-observation`.

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