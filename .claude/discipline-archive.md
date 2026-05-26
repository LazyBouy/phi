# Discipline archive — cycle-evidence narrative migration

> **Created 2026-05-26 during Chunk C of the intermediate-stabilization cycle (`36caa39f`)**. Captures per-cycle evidence prose narratives migrated out of live discipline docs (outer CLAUDE.md + agent prompts + sibling skills) to preserve historical context without bloating working-memory footprint. Live discipline docs cite this archive by anchor.
>
> **Scope**: BOTH i-phi precedents (CH-04 / CH-05 / CH-06 / CH-07a / CH-07b / CH-08 / CH-09 / CH-10 / CH-11a / CH-16a / CH-16b / CH-17) AND baby-phi precedents (CH-14 / CH-15 / CH-17 / CH-18 / CH-20 / CH-24 / CH-25 / CH-26 / CH-27 / CH-28) migrate here. Neither set is deprecated — both remain canonical historical references for the live rules.
>
> **Anchor naming**: `#<chunk-id>-<axis-slug>` (kebab-case).

## Index

### i-phi precedents
- [CH-04-i-phi audit-prompt-authoring cross-check trigger](#ch-04-i-phi-audit-prompt-authoring-cross-check-trigger)
- [CH-04-i-phi dynamic-pattern derivation for typo / rename / corrective-amendment](#ch-04-i-phi-dynamic-pattern-derivation)
- [CH-05-i-phi LOC-cap derivation + cargo-tree cascade + numeric-citation pre-archive](#ch-05-i-phi-pre-archival-quartet-evidence)
- [CH-06-i-phi user-directed mid-cycle in-plan amendment first activation](#ch-06-i-phi-mid-cycle-amendment-first-activation)
- [CH-07a-i-phi method-signature paraphrase cross-check](#ch-07a-i-phi-method-signature-paraphrase) (NB: actual surfacing trigger was CH-07b; CH-07a contributed the lock-body extension)
- [CH-07b-i-phi method-form-deliverable + interface-contract drift](#ch-07b-i-phi-interface-contract-drift)
- [CH-09-i-phi cargo-check plan-narrative literal-reconciliation + skeleton-vs-fully-behavioural verification](#ch-09-i-phi-cargo-check-grounded-literal-reconciliation)
- [CH-10-i-phi arg-shape divergence refinement signal](#ch-10-i-phi-arg-shape-divergence)
- [CH-11a-i-phi literal-count paraphrase 6th axis + struct-field-count axis](#ch-11a-i-phi-literal-count-axis-crystallization)
- [CH-16b-i-phi non-F-token paraphrase + drift-ID placeholder cascade](#ch-16b-i-phi-non-f-token-paraphrase-extension)
- [CH-17-i-phi approval-gate-summary-vs-plan-body divergence + cycle-bound TBD extension](#ch-17-i-phi-approval-gate-summary-divergence)

### baby-phi precedents
- [CH-14-baby-phi doc-sync widened sweep + 4-stage pipeline avoidance](#ch-14-baby-phi-doc-sync-widened-sweep-trigger)
- [CH-15-baby-phi doc-sync widened sweep extension](#ch-15-baby-phi-doc-sync-widened-sweep-extension)
- [CH-17-baby-phi cargo-clean discipline + cycle-index row insertion](#ch-17-baby-phi-cargo-clean-discipline-first-activation)
- [CH-18-baby-phi cargo-clean immediate-post-test placement](#ch-18-baby-phi-cargo-clean-immediate-post-test-trigger)
- [CH-25-baby-phi cycle-index verified-header prepend + canonical-script reuse](#ch-25-baby-phi-cycle-index-verified-header-prepend)
- [CH-26-baby-phi cardinality-reference cascade greps](#ch-26-baby-phi-cardinality-reference-cascade)
- [CH-26-baby-phi In-M5 carve-out vs M6-DEFERRED routing first emergence](#ch-26-baby-phi-in-m5-carveout-vs-m6-deferred)
- [CH-27-baby-phi gate-2.5 PAUSE + P-FIXTURES actuals snapshot](#ch-27-baby-phi-gate-2-5-pause-and-p-fixtures-actuals)
- [CH-28-baby-phi SurrealDB SCHEMAFULL semantic spot-check + ADR-inline-amendment verified-header + gate-1.7 cross-lock](#ch-28-baby-phi-schemafull-and-cross-lock-stress-test)

### Cross-cycle observation narratives
- [Cross-cycle fork-divergence observation (full evidence narrative)](#cross-cycle-fork-divergence-observation)
- [Plan-iteration-count cross-cycle pattern (full evidence narrative)](#plan-iteration-count-cross-cycle-pattern)

---

## CH-04-i-phi audit-prompt-authoring cross-check trigger

Cycle hex `8a9c50ea`. Audit prompt for Auditor A wrote `F-empty-scope.a strict EmptyScope error` but the locked F-empty-scope.a body is *graceful* `MergedPermissions::default()` fallback (the "strict" wording came from CH-03 F-empty-dir-fallback.b which is a sibling lock with opposite semantics). Auditor A noted the audit-prompt typo as informational; code was correct per the actual lock. Codified gate-3 F-token cross-check at outer CLAUDE.md.

## CH-04-i-phi dynamic-pattern derivation

Cycle hex `8a9c50ea`. spec.md line 13 `donAsk` → `dontAsk` typo correction landed at definition site, but 4 cross-cutting live usages went unswept (overview.md:54 / whatsapp.md:22 / telegram.md:26 / bootstrap.md:31). Audit C iter-1 surfaced as Trivial-multi (4-line sweep). Applying the dynamic-pattern derivation at gate-2 would have closed at gate-2 instead of routing through Audit C iter-1 + iter-2 re-spawn. Codified gate-2 widened-sweep pre-correction-literal extension at outer CLAUDE.md.

## CH-05-i-phi pre-archival quartet evidence

Cycle hex `f7a354b6`. Three co-located pre-archival deviations surfaced at gate-4:
- **LOC cap functional-scope-derivation**: parser.rs cap was 80 (mirrored from CH-03 baseline) but functional scope warranted ~350-400; precedent-mirror was the wrong reference frame.
- **cargo tree dependency-cascade**: uuid `serde` feature add + chrono direct-dep promotion both went un-predicted in plan §3 cascade vector B; impl absorbed silently and surfaced as cycle-audit §6 PASS-with-note.
- **Numeric-citation cross-check**: plan §6 stated "36 permissions tests" but actual snapshot was 34 (CH-04 recounted post-CH-04 retro); the stale citation absorbed silently into archived plan.

Plus architectural-refinement-at-approval-gate routing precedent: user surfaced the Claude Code MEMORY.md pattern at gate-1.5 after iter-2 locked-fork-appendix re-spawn; planner re-spawned to iter-3 with asymmetric tier layout (short-term `.md`+detail-files, long-term JSONL, episodic JSONL stub). Result: zero downstream rework, single PASS-at-iter-1 audit cycle. Codified gate-1.5 P-orch-1..4 pre-archival quartet at outer CLAUDE.md.

## CH-06-i-phi mid-cycle amendment first activation

Cycle hex `da221147`. Plan §3.B-A "Mid-cycle scope-deviation amendment" appended at 2026-05-20 to ratify Route B cascade.rs extraction + handle.rs/registry.rs residual LOC overruns. User-directed rationale: code-vs-documentation consistency so future readers see the deviation noted in-plan without cross-referencing ADR + cycle-audit + P-SEAL log separately. Companion precedent: spec-framework-87f86df8.md treated as living index under user direction (CH-01-i-phi). ADR-0008 §D8.14 reciprocally cites the §3.B-A amendment; gate-3 verification passed (auditor B claim 7 included the cross-check; both audit logs PASS). Codified P-orch-1/P-orch-2 user-directed mid-cycle in-plan amendment exception class at outer CLAUDE.md.

## CH-07a-i-phi method-signature paraphrase

Cycle hex `5384684d`. CH-07a contributed the lock-body extension; the method-signature paraphrase trigger landed at CH-07b (see below). CH-07a also surfaced 2 audit-discovered scope-narrowings (D-5 `AgentHandle.identity_watcher: None` at build despite F-watcher-scope.a lock body citing per-session instantiation; D-6 `canonicalize_for_check` helper shipped per F-additionalDirectories-canonicalize.a but NOT wire-consumed). Both informed chunk-implementer v19 P-impl-1-v19 lock-body wire-consumption self-check at P-SEAL + chunk-implementer v19 P-impl-2-v19 ADR sub-decision partial-application carve-out at P-DOCS.

## CH-07b-i-phi interface-contract drift

Cycle hex `283d3949`. Plan §8 P-HARVEST deliverable 2 + forward-scope item 10 + ADR-0010a §"For CH-07b" all called for `AgentHandle::harvest_from_subagent_session(...)` method form. Implementer shipped the free function `harvest_from_subagent_session(...)` at `src/agent_factory/harvest.rs:77` correctly but did NOT add an `impl AgentHandle { pub async fn harvest_from_subagent_session(...) }` delegate. Surfaced at gate-3 Audit C iter-1 Claim 5 FAIL; orchestrator-applied Trivial-multi 37-LOC delegate patch (commit `56e53fa`). Codified 3-layer defense for the method-vs-free-function interface-drift class: chunk-implementer v20 P-impl-1-v20 (implementer-tier) + chunk-auditor v13 Audit-A interface-contract claim (auditor-tier) + outer CLAUDE.md gate-3 method-signature paraphrase cross-check (orchestrator-tier).

Orchestrator's Audit C iter-1 prompt cited `AgentHandle::harvest_from_subagent_session(child_session_id, HarvestSelectionSpec) -> Result<HarvestSummary, AgentFactoryError>` as the 2-arg method form (matching forward-scope item 10); actual delegate landed at 4-arg form (passing `session_store` + `extractor`; deriving `parent_memory` + `parent_incognito` from `&self`). Semantic equivalence preserved (AgentHandle doesn't carry `session_store` / `extractor` as fields); wording-divergent.

## CH-09-i-phi cargo-check grounded literal-reconciliation

Cycle hex `075c07cf`. Plan §1 + §4 cited `phi_core::AgentEnd` as a 5-variant enum; actual workspace surface = `phi_core::StopReason` enum + `AgentEvent::AgentEnd { rejection: Option<String> }` field. Implementer consolidated into `cli::exit::CliEnd` (semantically equivalent; documented in ADR-0011 §D11.5). Plan-narrative deviations D-1 + D-2 + D-3 + D-4 all preventable at gate-1.5 via `cargo check`-grounded literal-reconciliation pass.

Plus the skeleton-vs-fully-behavioural cluster D-8/D-9: F-pause-resume-harvest-routes.a lock body said "ship 3 NEW daemon IPC routes with full daemon-side wiring in SessionRegistry::{pause,resume,harvest} methods" — implementer documented 4 distinct v0 scope-narrowings within that lock at ADR-0011 §D11.2 (UDS path returns DaemonUnreachable / pause signal-only / resume store-verify-only / harvest with hardcoded Incognito::No). Codified P-orch-5 + P-orch-6 at outer CLAUDE.md gate-1.5.

## CH-10-i-phi arg-shape divergence

Cycle hex `281cb58d`. Plan §4 cited `commands::dispatch(cmd, client, state) -> CliResult<DispatchResult>` with `state: &mut ReplState`; F-steering-input-lane.a Code-binding (plan §1 line 50) mandates `Arc<Mutex<ReplState>>` for tokio task-safe coordination. Audit A Claim 4 PASS-with-note surfaced the arg-shape refinement. Codified 5-axis (extended from 4-axis) at outer CLAUDE.md gate-3 method-signature paraphrase cross-check.

## CH-11a-i-phi literal-count axis crystallization

Cycle hex `86e2f4ae`. Five Audit A PASS-with-note findings (claim 1 daemon_state→session_registry / claim 2 String→Arc<String> / claim 3 10 vs 12 utoipa paths / claim 5 cors_layer→build_cors_layer / claim 7 5- vs 7-variant TlsLoadError) + 1 Audit C PASS-with-caveat (middleware order body-limit↔CORS swap; plan §1 line 108 was authoritative, prompt diverged). All informational (no code defects); literal-count axis would surface them as Trivial-1L pre-dispatch fix instead of post-fact PASS-with-note.

Plus P-orch-3 struct-field-count axis extension: plan §6 §D13.10 cited "SessionHandle field-set extended from 7 to 9"; actual baseline at plan-archive time was 11 fields (post-CH-09 + post-CH-07a additions of interrupt_tx + parent_session_id + registry not reflected in plan-time snapshot); new total post-CH-11a was 13 fields. The +2 delta was correct; the 7→9 cite was stale by 4 fields. Codified P-orch-3 struct-field-count axis at outer CLAUDE.md.

6-axis trigger threshold reached (6 axes warranted consolidation); CH-17's clean 6-axis pass (cycle-audit §6 D-5) was the empirical-stability confirmation that motivated the `audit-prompt-cross-check.sh` script consolidation.

## CH-16b-i-phi non-F-token paraphrase extension

Cycle hex `634ce263`. Orchestrator's Audit A claim 5 paraphrased super-episode `parent_episode_id` semantic as "last-collapsed child" but the locked ADR-0017 §D17.4 + `recursive.rs:169` code semantic is "pre-collapse parent of oldest collapsed leaf" — semantically equivalent for tree-walk but wording-divergent. Code correct, prompt wording diverged.

Plus drift-ID placeholder cascade: 2 `D-CH16b-FOLLOWUP-NN-*` placeholders in forward-scope file authored at CH-16 split-decision time surviving to chunk-seal — caught by Audit B widened sweep as PASS-with-caveat + orchestrator-applied Trivial-1L 2-line patch at gate-4. Codified gate-2 widened-sweep regex extension to capture planning-time placeholders.

Also 4-cycle unanimous-planner-rec streak CH-05/CH-06/CH-08/CH-16a ENDED at CH-16b gate-1.5 with **F-async-bridge.b user-DIVERGENT** — `block_on`-safety architectural-bridge cause class.

## CH-17-i-phi approval-gate-summary divergence

Cycle hex `e764aeca`. Orchestrator's Phase 1.5 approval-gate AskUserQuestion summary cited "Audit envelope: Medium (2 auditors A+B; re-verified)" but iter-2 plan body §11 (line 619 + §11 delta table at line 776) had bumped to LARGE (3 auditors A+B+C) per chunk-planner v17 P1 absorption rule. The approval-gate prose was authored from iter-1 cache + not refreshed at iter-2 archive. Implementer correctly authored cycle-index row with LARGE / 3-auditors per plan body; user-facing approval-gate summary diverged silently. No code/audit impact at this cycle but next time could mislead user expectation of audit cost.

Plus cycle-bound TBD extension: `braking-layer.md` had 3 stale TBD lines outside the §-anchor that was correctly replaced at P-DOCS — lines 12 + 39 caught by Audit B Claim 6 PASS-with-caveat; line 6 §Status box caught by orchestrator widened-sweep at gate-3. Codified gate-2 widened-sweep cycle-bound TBD regex extension at outer CLAUDE.md.

---

## CH-14-baby-phi doc-sync widened sweep trigger

Cycle hex `5803bb94`. Three docs had stale "deferred per FOLLOWUP-02" wording outside plan §3.C-listed files; audit B iter 1 PARTIAL routed through iter-2 re-spawn. Applying the widened sweep at gate-2 would have avoided the iter-1 PARTIAL → iter-2 re-spawn.

Plus 4-stage cardinality-extraction pipeline: gate-4 logged 14 PermissionRequests on a 4-stage `cargo test | grep | sed | awk` pipeline (3.5× the 2-stage cap). Recommended fix: write the extraction script to a file (`scripts/audit-tmp-cargo-counts.sh`), then run `bash /abs/path/scripts/audit-tmp-cargo-counts.sh` as a single Bash call.

Also ADR-vs-drift contradiction surfaced: implementer narrowed plan §3.B A7 + ADR-0053 §D53.7 (per-cascaded-AR emission) and silently filed `D-CH14-FOLLOWUP-02` — orchestrator caught the contradiction at gate 2 and re-spawned the implementer to ship per the plan + ADR verbatim. Codified scope-narrowing-decision-must-escalate at chunk-implementer + chunk-seal cross-check (ADR ↔ drift) at chunk-implementer v5.

## CH-15-baby-phi doc-sync widened sweep extension

Cycle hex `c3f46f17`. `m5/architecture/authority-templates.md:89-91` had stale "advisory at M5" wording outside plan §3.C map. Audit B iter 1 surfaced as PARTIAL → iter-2 re-spawn. Applying the widened sweep at gate-2 would have closed it as a Trivial-multi pre-audit patch.

Plus cd-overuse drift: sub-agent telemetry showed 8% of Bash signatures used `cd <abs> && <cmd>` compounds. Codified at chunk-implementer + chunk-auditor v4 granular Bash discipline refactor.

## CH-17-baby-phi cargo-clean discipline first activation

Cycle hex `40c4d759`. User-requested 2026-05-09: after standards updates landed + cycle-index row flipped to `retro-complete`, the orchestrator runs `cargo clean` as the closing step before user commit. Capture `du -sh` BEFORE + `df -h` AFTER and log disk reclaimed in cycle-audit's §7 metrics row. First placement-only (gate-5 final close); CH-18 added the second (per-test-invocation) placement.

Plus cycle-index row insertion at chunk-close (later refined at CH-25 to include verified-header prepend) — first surfaced as Trivial-1L gap that orchestrator caught at gate-3.

Plus MUST-SHIP-tests-are-blocking: CH-17 first implementer-spawn dropped `sse_live_stream_test.rs` (the named MUST-SHIP file) per band-floor surrogate substitution; user-driven gate-3 re-dispatch closed the gap with +4h scope. Codified at chunk-implementer v7 MUST-SHIP-tests-are-blocking rule.

## CH-18-baby-phi cargo-clean immediate-post-test trigger

Cycle hex `c77937bc`. 2 duplicate cargo-test workspace background runs accumulated target/ to 146 GB → 100% disk → 1h24m hung process → user-directed kill + cargo clean reclaimed 151 GiB. User directive that codified this: *"tests should be cleaned up immediately after the run as it may block future tests"* (2026-05-10).

CH-17 retro Row 1's gate-5-close-only placement was insufficient because target/ can balloon DURING gate-4 if multiple test invocations run concurrently or sequentially without cleanup. CH-18 evidence proved per-invocation cleanup is necessary; gate-5 final close is still mandatory as a final pre-commit cleanup. Both placements together prevent within-cycle disk-pressure incidents AND ensure clean state at chunk release.

## CH-25-baby-phi cycle-index verified-header prepend

Cycle hex `1e01618e`. Implementer-spawn that runs the seal phase forked attention to scope-expansion phases (P-FLIP-RECENT-SESSIONS / P-R5-INVESTIGATE etc.) and skipped the verified-header prepend — orchestrator-applied Trivial-1L closed inline at gate-3. NOT an implicit follow-on of plan §7 P-seal; explicit MANDATORY paperwork item. CH-25 was the 1st cycle to surface this Trivial-1L since CH-17 (3-cycle delta). Codified the two-step verification at chunk-implementer v9 so future cycles never re-incur the Trivial-1L for this surface.

Plus canonical-script reuse strengthening: implementer authored 2 ephemeral scripts (`audit-tmp-ch25-permissions.sh`, `audit-tmp-tally-counts.sh`) that orchestrator cleaned up at gate-5; the v9 mandate slows future cumulative growth. Codified at chunk-auditor v8 + chunk-implementer v9.

## CH-26-baby-phi cardinality-reference cascade

Cycle hex `d1cb9e1f`. Audit-B Side Observation 1 surfaced `_concept-audit-matrix.md:25` "8 Composite" → "10 Composite" as Trivial-1L; cardinality refs frequently live in `_concept-audit-matrix.md` matrix-table rows that are NOT in plan §3.C's touch map. Audit-B Side Observation 2 surfaced `permissions/01-resource-ontology.md:189` `#composite-classes-8` cross-ref stale post-cardinality-flip; orchestrator-applied Trivial-multi (2-line patch). v12 catches both at P-SEAL.

Plus session-interrupt mid-audit kill protocol: Audit-A was re-dispatched once cleanly under this protocol when the expected audit log file did NOT appear within reasonable time post-spawn. Re-dispatch with the SAME prompt is safe (sub-agent is stateless across spawns; no partial-file-state corruption risk for the resumed run); re-dispatch is NOT counted as an audit-fix-loop iteration. Codified at outer CLAUDE.md audit-fix-loop session-interrupt mid-audit kill bullet.

## CH-26-baby-phi In-M5 carveout vs M6-DEFERRED

Cycle hex `d1cb9e1f`. First emergence of the In-M5-carveout-vs-M6-DEFERRED routing decision: when a chunk closes a HIGH/MEDIUM drift at the load-bearing semantic axis but defers a wire-tier-tightening or follow-on-engine-scope-widening axis. CH-26 → CH-27 M5.3 carve-out per user direction 2026-05-16. CH-25 F-D59.2/F-D59.3 contrasts as the M6-DEFERRED case. Codified at outer CLAUDE.md retrospective-review gate-5.

## CH-27-baby-phi gate-2.5 PAUSE and P-FIXTURES actuals

Cycle hex `0edcaba9`. P-FIXTURES landed 9 `seed_owner_grants` call-sites (vs plan §3 Artifact C band [12, 18] — COLLAPSE -3). Implementer wrote P-DOCS doc-fragments citing "19 fixture-extension sites" across 4 docs (composite-resources-model.md L153 + composite-resources-operations.md L100 + D-CH26-FOLLOWUP-01.md L73 + _concept-audit-matrix.md L1+L28). Audit-B iter 1 surfaced as Side Observation; orchestrator applied Trivial-multi cardinality cascade patch at gate-3 across 7 doc locations. Codified gate-2.5 PAUSE at outer CLAUDE.md + P-FIXTURES actuals snapshot at chunk-implementer v13.

Plus ADR-body-strict-reading: RESUME-NOTE's deviation #2 stated *"Documented prominently in ADR-0062 §D62.4 body"*. Implementer documented the SCOPE-NARROWING note at 3 sites: ADR verified-header L1 + `owner_grants.rs:36-53` helper file doc-comment + `composite-resources-model.md` §"Test-fixture pattern" L196 — but missed inlining the note **inside the §D62.4 body itself** (between L149 helper-signature code-block and L151). Audit-B iter 1 surfaced as PARTIAL; orchestrator applied Trivial-multi inline patch at gate-3. Codified at chunk-implementer v13.

Plus Audit-C scaffold framed M3/M4/M5 edits as "fixture-seeding-only", but plan §7 P2 deliverable 8 explicitly called out wire-canonical adjustments. Audit C surfaced `acceptance_m5_orgs.rs:140-160` `ORG_ACCESS_DENIED` → `NO_GRANTS_HELD` flip as PASS-with-caveat with an inline scope-ambiguity note. The flip was load-bearing-correctness-following per ADR-0062 §D62.1; 403-isolation invariant preserved. Codified at chunk-auditor v11 Audit-C allowed-edit envelope cross-check.

## CH-28-baby-phi SCHEMAFULL and cross-lock stress test

Cycle hex `0412eb06`. 5 plan iterations (highest count to date; iter-1→2 3-of-3 forks user-locked DIVERGENT + iter-2→3 gate-2.5 phase swap + iter-3→4 Architectural-FAIL #1 P1-vs-P2 internal-inconsistency + iter-4→5 Architectural-FAIL #2 ADDITIVE-green-claim falsified). Iter-3 ADDITIVE-only ⇒ workspace-GREEN claim falsified at P1 close because migration 0019 REMOVE FIELDs were already shipped (P-MIGRATION-SCHEMA) + the in-process AgentProfile struct still carried the 3 fields per §D63.13. The write-path (create_agent_profile + upsert_agent_profile + compound-tx sites in apply_org_creation/apply_agent_creation) had no wire-strip mitigation; the read-path (get_agent_profile_for_agent) had no synthesis bridge. 9 test targets RED; iter-5 inserted P1.5-READ-BRIDGE as a dedicated bridge phase. Codified gate-4 SurrealDB SCHEMAFULL semantic spot-check at outer CLAUDE.md.

Plus ADR-0057 received §D57.7 inline body amendment at P-DOCS (line 150 — cardinality 72→74 cite) but P-SEAL deliverable 8 missed the top-of-file verified-header prepend. Audit-B Claim 9 + Claim 12 surfaced as PASS-with-caveat; orchestrator-applied Trivial-1L at gate-3 close. Codified ADR-inline-amendment verified-header cross-check at gate-3 at outer CLAUDE.md + chunk-implementer v17.

Plus the F1.c × F2.b × F3.b combination's multiplicative replanning surface manifested as iter-3 phase-swap + iter-4 P1/P2 inconsistency + iter-5 ADDITIVE-green falsification. Each iteration was downstream of the multiplicative lock interaction. Codified gate-1.7 cross-lock interaction stress-test at outer CLAUDE.md (3-of-3-DIVERGENT lock sets warrant pair-wise interaction evaluation against compile-time + runtime-test + phase-ordering constraints).

Plus the P1.5 implementer discovered 4 ADDITIONAL compound-tx sites (`apply_org_creation` system-agent profile rows × 2 + `apply_agent_creation` optional payload profile × 2) needing wire-strip propagation to satisfy the load-bearing workspace-RED → GREEN flip. The discovery was fortunate, not enforced. Codified at chunk-implementer v17 P-impl-2 wire-row cascade propagation check.

Cumulative cross-cycle divergent-fork count 14-of-19 (~74%) at the baby-phi side. CH-28 P1.5 actual 340 LOC vs predicted 80 = 4.25× overrun empirical (informs chunk-planner v25 P-plan-3 latent-defect-discovery cushion).

---

## Cross-cycle fork-divergence observation

Empirical evidence across cycles (cumulative 2026-05-20 → 2026-05-25):

**baby-phi: 14-of-19 (~74%) divergent** across baby-phi CH-15/17/18/20/24/25/28. The user systematically prefers tighter / more-fragmented / more-defensive / wire-format-explicit options at baby-phi gate-1 fork-locks. Treat fork-divergence as the modal outcome in v9+ planner recommendation framing.

**i-phi: 6-of-54 (~11%) divergent** across i-phi CH-05/CH-06/CH-08/CH-16a/CH-16b/CH-07a/CH-07b/CH-09/CH-10/CH-11a/CH-17. Within the i-phi posture:

- **4-cycle unanimous-planner-rec streak CH-05/CH-06/CH-08/CH-16a ENDED at CH-16b gate-1.5** with F-async-bridge.b user-DIVERGENT — `block_on`-safety architectural-bridge cause class.
- **CH-07a F-iphi-ci-guards-deadline.b USER-DIVERGENT** is the SECOND within-cycle DIVERGENT lock — cause class differs from CH-16b: process-velocity decision (ship-the-carve-out-NOW vs defer 3rd lapse).
- **CH-11a F-cors-policy.c + F-tls-strategy.c USER-DIVERGENT** are the THIRD + FOURTH within-cycle DIVERGENT locks — production-readiness-ship-now axis (first external-Internet surface chunk on i-phi).
- **CH-17 F3.c BrakingConfig + F4.b+F4.c-combined observability USER-DIVERGENT** extend the production-readiness-ship-now axis to Surface-0-runtime agent-factory observability/config.

**3-axis class hypothesis crystallized at CH-11a with extension at CH-17**:
- (a) architectural-bridge axis (CH-16b `block_on` safety);
- (b) process-velocity / deadline-lapse axis (CH-07a 3rd-cycle CI-guard lapse);
- (c) **production-readiness-ship-now axis** (CH-11a F-cors-policy.c + F-tls-strategy.c + CH-17 F3.c BrakingConfig + F4.b+F4.c-combined observability) — crystallized at first external-Internet surface chunk on i-phi (CH-11a); extends to Surface-0-runtime agent-factory observability/config at CH-17.

Axis (c) now spans 4 divergent locks across 2 chunks (CH-11a × 2 + CH-17 × 2). External-surface chunks (CH-09 CLI → CH-10 REPL → CH-11a HTTP API → CH-11b web → CH-12 WhatsApp → CH-13 Telegram) cluster divergence on ship-production-ready-from-day-1 decisions; production-readiness-ship-now also extends inward to agent-factory observability/config surfaces (CH-17 BrakingConfig + tracing emit + CLI/REPL render).

**i-phi-specific planner work should NOT treat divergence as modal**; unanimous-planner-rec remains the dominant pattern (~93% planner-rec across the 14-fork window), but the streak-end at CH-16b establishes that architectural-bridge surfaces (`block_on`, FFI, etc.) carry a divergence signal even within the otherwise-unanimous i-phi posture.

**High-iteration-count correlation**: cycles with 3-of-3 DIVERGENT lock-sets correlate with elevated plan-iteration counts — CH-28 ran 5 plan iterations (highest to date) with 3-of-3 DIVERGENT + 2 Architectural-FAIL re-spawns; the F1.c + F2.b + F3.b combination's multiplicative replanning surface manifested as iter-3 phase-swap + iter-4 P1/P2 inconsistency + iter-5 ADDITIVE-green falsification.

## Plan-iteration-count cross-cycle pattern

Empirical evidence across cycles (cumulative 2026-05-21 → 2026-05-25):

- **CH-16a (`066799f3`)** — **3 plan iterations** (iter-1 full CH-16 → iter-2 narrowed via Split A USER-DIVERGENT → iter-3 §13→§1 structural restructure; all user-direction-driven)
- **CH-16b (`634ce263`)** — **2 plan iterations** (iter-1 pre-lock + iter-2 post-fork-lock absorption; user-direction-driven NOT Architectural-FAIL)
- **CH-07a (`5384684d`)** — **2 plan iterations**
- **CH-10 (`281cb58d`)** — **3 plan iterations** (iter-1 pre-lock + iter-2 post-crossterm-lock + iter-3 post-rustyline-revision at user re-surfacing)
- **CH-11a (`86e2f4ae`)** — **2 plan iterations** (iter-1 pre-lock + iter-2 post-fork-lock absorbing 2 USER-DIVERGENT locks F-cors-policy.c + F-tls-strategy.c per gate-1.5 Step A ALWAYS-FIRE + Step B material-scope-expansion)
- **CH-17 (`e764aeca`)** — **2 plan iterations** (iter-1 pre-lock + iter-2 post-fork-lock absorbing 2 USER-DIVERGENT locks F3.c BrakingConfig + F4.b+F4.c-combined per gate-1.5 Step A ALWAYS-FIRE + Step B material-scope-expansion — envelope bumped Medium→Large + NEW phase P3 inserted)

**Cause class**: user-direction structural refinement at all seven data points (CH-05/16a/16b/07a/CH-10/CH-11a/CH-17 = each user-direction-driven, NOT Architectural-FAIL re-spawn — the baby-phi CH-28 5-iter case was Architectural-FAIL-driven; different cause classes; track separately).

**Hypothesis CONFIRMED-7-of-7 at i-phi**: user-direction iterations are "decision refinements" not "technical defect corrections" — iter-N plan is sound by construction, just adjusted to user-preferred routing.

**Sub-class refinement** now 4 sub-classes within 1 parent class:
- (i) structural § restructure (CH-16a iter-3);
- (ii) scope-reduction lock-absorption (CH-16b iter-2);
- (iii) scope-EXPANSION lock-absorption (CH-07a iter-2 + CH-11a iter-2 + CH-17 iter-2 — CH-17 fits this sub-class via Step B material-scope-expansion: 2 USER-DIVERGENT locks added NEW `[braking]` BrakingConfig schema-reservation-only file + NEW CLI/REPL render arm + NEW tracing-emit wrap + 1 new phase P3 + envelope Medium→Large);
- (iv) gate-1 lock-revision-on-re-surfacing (CH-10 iter-3).

**Empirical**: ALL SEVEN i-phi cycles (CH-05/16a/16b/07a/CH-10/CH-11a/CH-17) audits PASSed at iter-1 (0 re-spawns) despite the multi-iteration plans. Pattern is strongly durable: iter-2 planner re-spawn is the canonical "post-lock plan absorption" mechanic; CH-17 adds a 7th confirmation that scope-EXPANSION sub-class (iii) is the modal outcome when ≥ 2 USER-DIVERGENT locks land at gate-1.