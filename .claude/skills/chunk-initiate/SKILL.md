---
name: chunk-initiate
description: Orchestrate an end-to-end chunk implementation cycle (plan → user-approval gate → implement → audit → final cycle re-audit → cleanup → optional retrospective) for either baby-phi or i-phi. Wraps the chunk-planner / chunk-implementer / chunk-auditor / chunk-retrospector agents under the orchestrator gates documented in CLAUDE.md.
---

# chunk-initiate

Run an end-to-end chunk implementation cycle on either **baby-phi** or **i-phi**. The skill plays the orchestrator role: it spawns `chunk-planner`, gates plan approval, spawns `chunk-implementer`, dispatches one or more `chunk-auditor` agents, runs the mandatory final cycle re-audit, cleans up `target/`, and optionally runs `chunk-retrospector`.

When invoked, follow the procedure in this file step-by-step. **Do not skip phases.** The orchestrator gates (especially Phase 4) are non-negotiable; sub-agent auditors cannot fully cover them from sandbox.

---

## Inputs

Caller provides (slash-command style: `key=value`):

| Input | Required? | Type / values | Default | Notes |
|---|---|---|---|---|
| `chunk` | yes | `CH-NN` or `NN` | — | Normalise to `CH-NN`. Must correspond to a forward-scope row in the project. |
| `project` | yes | `baby-phi` \| `i-phi` | — | Determines paths, CI guards, MUST-RUN list. |
| `approval` | yes | `yes` \| `no` | — | `yes` = always prompt the user via AskUserQuestion before implementation. `no` = auto-approve **only when the Direct-approval criteria hold** (else fall back to `yes`). |
| `resume_from_phase` | no | `plan` \| `implement` \| `audit` \| `retro` | `plan` | Skip earlier phases when resuming an interrupted cycle. Reads on-disk artifacts only. |
| `skip_retrospective` | no | `yes` \| `no` | `no` | Skip Phase 6 (chunk-retrospector). |
| `audit_envelope` | no | `small` \| `medium` \| `large` \| `auto` | `auto` | Override the auditor-count recommendation. `small`=1, `medium`=2, `large`=3. |
| `dry_run` | no | `yes` \| `no` | `no` | Run plan + impl + audit but skip git commits and the gate-5 cargo-clean. For testing the skill itself. |

If a required input is missing or malformed, abort immediately with a clear error.

---

## Per-project configuration

Resolve these values from `project`:

| Field | baby-phi | i-phi |
|---|---|---|
| Project root | `/root/projects/phi/baby-phi` | `/root/projects/phi/i-phi` |
| Cargo manifest | `<root>/Cargo.toml` (exists) | `<root>/Cargo.toml` (does **not** exist before CH-01) |
| Cycle folder root | `<root>/docs/specs/plan/build/` | `<root>/docs/v0/proposal/plan/build/` |
| Cycle-index path | `<cycle root>/_cycle-index.md` | `<root>/docs/v0/proposal/plan/_cycle-index.md` |
| Forward-scope source | `<root>/docs/specs/plan/forward-scope/*.md` | TBD — i-phi will need a forward-scope file once CH-01 is on deck |
| CI guards | `bash <root>/scripts/check-{doc-links,ops-doc-headers,phi-core-reuse,spec-drift}.sh` | `bash <root>/scripts/check-{doc-links,verified-headers,phi-core-reuse,spec-drift}.sh` (shipped at CH-07a per F-iphi-ci-guards-deadline.b USER-DIVERGENT lock; ADR-0010a §D10.13) |
| MUST-RUN list | `RUSTFLAGS="-Dwarnings" cargo clippy -j 4 --workspace --all-targets` + the 4 CI guards | clippy + the 4 CI guards (CH-07a onwards) |
| Cargo-clean target | `<root>/target` | `<root>/target` |
| Default branch | `dev` | `dev` |

Reuse absolute paths in commands (e.g. `cargo --manifest-path /root/projects/phi/<project>/Cargo.toml ...`) per granular Bash discipline.

---

## Sibling agent project-awareness

The four `chunk-*` agents currently encode baby-phi paths. They will be updated in a follow-up cycle to honour a `$PROJECT_ROOT` parameter (defaulting to baby-phi for backward compatibility):

- `chunk-planner` v14 → v15
- `chunk-implementer` v9 → v10
- `chunk-auditor` v8 → v9
- `chunk-retrospector` v4 → v5

Until those updates ship, running `/chunk-initiate project=i-phi` requires passing project paths **explicitly in each agent invocation prompt**. The skill body's Phase-1/2/3/6 sections list the exact context to include.

---

## Execution flow

### Phase 0 — Pre-flight

1. Parse inputs. Normalise `chunk` to `CH-NN` (left-pad single digits).
2. Look up project paths from the configuration table.
3. Verify `project` root exists at the expected path.
4. **i-phi special case**: if `project=i-phi` AND `chunk=CH-01` AND no `Cargo.toml` exists yet → expected, proceed.
5. Check the project's working tree is clean (`git -C <root> status` returns clean) unless `dry_run=yes` or `resume_from_phase != plan`.
6. Confirm current branch is `dev`. If not, abort with instructions to switch.
7. Look up the chunk's forward-scope row. If missing, do **not** abort outright — first surface an inline-draft offer via `AskUserQuestion` (added 2026-05-17 per CH-01-i-phi retro Row 2; the strict-abort behaviour was the v1 default and forced an extra orchestrator-side draft cycle on every new project's chunk-zero):
   - **Option A — Draft inline (Recommended)**: orchestrator drafts the forward-scope file (mirroring baby-phi's row shape + adapted to the project's conventions) and surfaces it for user review. On user approval, commits the forward-scope as a prerequisite artifact (so the chunk's own diff stays scoped to chunk deliverables), then resumes Phase 0 step 8.
   - **Option B — Pause for user-authored draft**: aborts the current invocation; user authors the forward-scope file out-of-band, then re-invokes `/chunk-initiate`. (This was the v1 strict-abort behaviour.)
   - **Option C — Use chunk-graph row as stand-in**: treat the upstream chunk-graph's one-liner as a forward-scope substitute; planner runs on thinner inputs. Logs the deviation in `cycle-audit.md` §6.
   - **Option D — Abort the whole cycle**.

   On Option A: the inline-draft sub-step writes the file to `<PROJECT_ROOT>/docs/specs/plan/forward-scope/<slug>.md` (baby-phi) or `<PROJECT_ROOT>/docs/v0/proposal/plan/forward-scope/<slug>.md` (i-phi), per the project's convention. The draft includes the standard sections (Purpose, Inputs consumed, Drifts closed, Prerequisites, Deliverables, Acceptance criteria, Forks for the planner, Audit envelope hint, Unblocks, Risks, Direct-approval criteria fit). Use the canonical reference: `/root/projects/phi/baby-phi/docs/specs/plan/forward-scope/22035b2a-remaining-scope-post-m5-p7.md` as the baby-phi shape; `/root/projects/phi/i-phi/docs/v0/proposal/plan/forward-scope/ch-01-phi-core-consumption-foundation.md` as the i-phi shape. **CH-09-i-phi reference (newer, post-CH-07a/CH-07b)**: `/root/projects/phi/i-phi/docs/v0/proposal/plan/forward-scope/ch-09-headless-cli.md` covers a richer 7-fork surface (Surface-1 CLI client over daemon IPC + 3 NEW IPC routes); useful template for Surface-N chunks that consume existing daemon-side primitives.

   **Inline-draft codified procedure (added 2026-05-24 per CH-09-i-phi retro `075c07cf` proposal #3 MEDIUM; codifies CH-01-i-phi + CH-09-i-phi 2-of-2 inline-draft pattern producing Direct-approval-clean lock-sets)**: when forward-scope file is absent at Phase 0 step 7 + user picks Option A:
   1. Orchestrator reads adjacent chunk forward-scopes (e.g., direct-dep predecessors) + relevant concept-doc skeletons + chunk-order.md row + chunk-graph.md entry for context.
   2. Drafts inline using the canonical 12-section template body (size target: 200-500 LOC depending on chunk surface; CH-09 = 350 LOC; CH-01 = ~250 LOC).
   3. Surfaces draft via AskUserQuestion with options **Approve / Request changes / Pause for user-authored / Abort the cycle**.
   4. On Approve: orchestrator writes file + updates `chunk-order.md` "FS Doc" cell from `NEEDS DRAFT` to `[exists](<slug>.md) (drafted inline <date>; <chunk> <state>)` citation + commits BOTH as a single prerequisite commit with message `<chunk> prerequisite: forward-scope file + chunk-order.md row flip` (NOT part of the cycle's chunk diff).
   5. On Request changes: orchestrator absorbs free-text feedback + re-presents the draft.
   6. On Pause / Abort: exit per Option B / Option D respectively.
   7. After Approve + commit: resume at Phase 0 step 8 (disk-space verification) → Phase 1 (planner dispatch) with the now-existing forward-scope path.

   **2-of-2 i-phi precedent**: CH-01 `95c96df7` (framework-setup forward-scope drafted inline at chunk-initiate Phase 0 step 7 on 2026-05-17; landed Direct-approval-clean) + CH-09 `075c07cf` (headless CLI forward-scope drafted inline 2026-05-24; landed Direct-approval-clean with 7-of-7 planner-rec locks). Both produced clean cycles with zero auditor re-spawns; codify as durable.
8. Verify ≥ 30 GB free on the volume holding `<root>/target/` (`df -h /root | head -3`). If less, prompt the user before continuing.
9. If `resume_from_phase != plan`, verify the expected cycle-folder + plan.md exist (or fail).

### Phase 1 — Plan (skip if `resume_from_phase != plan`)

1. Spawn the `chunk-planner` agent (opus). Prompt MUST include:
   - `chunk` (normalised `CH-NN`).
   - `project` and absolute project root.
   - The relevant forward-scope row contents.
   - The cycle folder path the planner should target.
   - The project-specific cargo + CI guard expectations.
2. Read the draft plan returned by the planner.
3. Run sub-skill `phi-core-leverage-check` on the diff prediction (relevant for both projects since both consume phi-core).
4. Run sub-skill `k8s-readiness-check` **only if** `project = baby-phi` (skip for i-phi — no K8s posture yet).
5. Run sub-skill `audit-envelope-size` **unless** `audit_envelope != auto`.
6. **Split decision** — evaluate the triggers (see "Split decision" below). If two-or-more fire, surface a split proposal via AskUserQuestion. User options:
   - **Approve split** → re-spawn planner with narrowed scope; file the remainder as a new forward-scope row for a later chunk. **Split-decision routing protocol (added 2026-05-21 per CH-16a-i-phi retro `066799f3` proposal #2)**: when user chooses Split: (a) orchestrator drafts NEW chunk's forward-scope file inline (mirroring the current chunk's forward-scope shape; cite the locked outcomes that bind to the new chunk); (b) orchestrator updates `chunk-order.md` to insert a NEW row for the new chunk + advance §2 serial ⮕ NEXT to the narrowed current chunk + update §3 parallel groups; (c) orchestrator commits both new forward-scope + chunk-order.md update as a **prerequisite commit** with message `<current-chunk> split-decision prerequisite: <NNa>/<NNb> forward-scopes + chunk-order`; (d) iter-2 planner re-spawn proceeds against the narrowed slice with explicit cross-reference to the new chunk's forward-scope file path. **Precedents**: CH-16a `066799f3` (Split A: CH-16 → CH-16a + CH-16b); CH-02a `1bd3bdd1` (multi-chunk split into CH-02a/02b/02c).
   - **Force-proceed** → proceed without splitting; note the deviation in `cycle-audit.md` §6.
   - **Abort** → clean up partial files, exit.
7. Archive the approved plan via the `chunk-archive-plan` sub-skill — produces `<cycle folder>/plan.md` with an 8-hex token, appends a row to the cycle-index.

### Phase 1.5 — Approval gate (skip if `resume_from_phase != plan`)

**Gate-1 fork-lock decision flow (added 2026-05-18 per CH-03-i-phi retro P1, cycle hex `c542648f`; STRENGTHENED 2026-05-19 per CH-05-i-phi retro P-skill-1, cycle hex `f7a354b6` — mandatory iter-2 re-spawn after fork-locks regardless of divergence)**:

**Step A (ALWAYS-FIRE iter-2 re-spawn UNLESS planner-rec-clean + §1 populated; updated 2026-05-26 per Chunk D intermediate-stabilization `36caa39f` Deliverable #6a — outer phi chunk-planner v32 iter-2 re-arch)**: the iter-2 planner re-spawn is mandatory AFTER fork-locks land at gate-1.5 with one EXCEPTION — when ALL forks lock at planner-rec AND iter-1 plan §1 carries populated bodies for every fork (verified via `chunk-template-validate-locked-appendix` skill returning PASS), iter-2 re-spawn is SKIPPED + the orchestrator proceeds directly to chunk-archive-plan with iter-1 plan.

**Skip-condition decision tree**:

```
1. Read gate-1 lock-set (from AskUserQuestion answers).
2. If ALL forks locked at planner-rec:
   a. Run chunk-template-validate-locked-appendix skill on iter-1 plan.md.
   b. If skill returns PASS → skip iter-2 re-spawn; proceed to chunk-archive-plan with iter-1 plan.
   c. If skill returns FAIL (iter-1 §1 missing/malformed) → re-spawn planner at iter-2 to fix the appendix (regression-defense path; same as the v23 P-plan-3 ALWAYS-FIRE fallback during the cross-project 2-3-cycle hold-period).
3. If ≥ 1 fork USER-DIVERGENT:
   a. Re-spawn planner at iter-2 with the divergent locks + per-fork pause-threshold re-derivation if Step B material-scope-expansion triggers (the existing mechanic; unchanged).
   b. At iter-2, ONLY the F<N> subsections corresponding to USER-DIVERGENT locks are re-authored; planner-rec subsections preserve their iter-1 draft wording verbatim.
```

The locked-fork-details section sits at **`## §1 — Locked fork details`** front-of-plan (UPDATED 2026-05-21 per CH-16a-i-phi retro `066799f3` proposal #1 user-direction: was `### Locked fork details` appendix at end-of-plan / §13; user-direction at CH-16a iter-3 codified the §1 front-of-plan position because locked outcomes provide essential context for §2-§13 reading; placing at end-of-plan forced top-down re-read). All H4 `#### F<N> = F<N>.<letter>` subsection structure with 3-sentence Code-level binding / Rationale / Defers per option blocks unchanged.

**Hold-period (2-3 cycles AFTER v32 ships; cross-project)**: cycles count across baby-phi AND i-phi. During hold-period, v23 P-plan-3 ALWAYS-FIRE iter-2 re-spawn fallback remains active when chunk-archive-plan v4 hard-assertion catches a regression (iter-1 §1 missing/malformed). The chunk-archive-plan v4 hard-assertion is the primary archive-tier defense; chunk-planner v32 P-plan-1-v32 end-of-draft self-check is the planner-tier defense.

**Cross-references**:

- chunk-planner v32 P-plan-1-v32 — defines the iter-1 §1 template change with planner-rec bodies pre-filled (origin of the skip-condition's predicate).
- Outer CLAUDE.md gate-1.5 P-orch-8 — orchestrator-side skip-condition mirror.
- chunk-archive-plan v4 hard-assertion — invokes chunk-template-validate-locked-appendix BEFORE archiving (belt-and-suspenders to planner end-of-draft self-check).
- chunk-template-validate-locked-appendix skill — mechanical 4-step PASS/FAIL.
- per-chunk-planning-template.md `## §1 — Locked fork details` template structure.
- User memory `feedback_locked_fork_details_appendix.md` — original directive; v32 satisfies it via iter-1-populated bodies (NOT iter-2 re-spawn) for the planner-rec-clean cohort.

**Historical context (pre-v32)**: Step A was previously ALWAYS-FIRE iter-2 re-spawn regardless of divergence — to close the 3-cycle CH-03 + CH-04 + CH-05 i-phi regression pattern where the appendix did NOT auto-fire at iter-1 archive under chunk-planner v22's optional-self-check. CH-05 evidence: all 7 forks were planner-rec (zero divergence) but the appendix was still missing at iter-1; orchestrator surfaced + user codified the always-fire rule. v32 eliminates the iter-2 cost for planner-rec-clean cycles by pre-filling §1 at iter-1; the hard-assertion preserves the regression-defense.

**Step B (conditional on divergence) — Material-scope-expansion gate**: if the locks introduce divergences from planner-rec that **materially expand scope** (defined as **≥ +5 deliverables** beyond iter-1 plan's count OR an **audit-envelope tier bump** Medium→Large / Large→XL), the iter-2 re-spawn ALSO re-derives per-fork pause-thresholds + surfaces any new sub-decisions. Surface the re-spawn decision to the user via AskUserQuestion with these options:

- **Re-spawn planner with locked forks for revised plan (Recommended)** — produces an iter-2 plan that absorbs the divergent locks + per-fork pause-thresholds re-derived + new sub-decisions surfaced if any + the mandatory locked-fork-details appendix.
- **Force-proceed with original plan + deviations** (escape hatch) — implementer prompt carries the divergent locks; cycle-audit §6 logs the gate-1 deviation. CH-02c (cycle `81f0c24e`) precedent for force-proceed; CH-03 (`c542648f`) precedent for re-spawn — re-spawn produced 0 audit re-spawns + 0 Trivial-multi patches vs CH-02c's 4 deviations surfaced at gate-2.

Below-threshold divergence (e.g., 1 fork divergent with no scope expansion, like CH-02b F4.b RwLock) still re-spawns the planner under Step A for the appendix; the prompt simply omits the "re-derive thresholds" line.

**Step C (architectural-refinement-at-approval-gate, added 2026-05-19 per CH-05-i-phi retro P-orch-4)**: when the user surfaces an architectural insight at gate-1.5 final-approval read that **materially refines a LOCKED variant body** (NOT a fork re-vote — the user accepts the locked option but refines what the option means), route via a SECOND planner re-spawn (iter-3) with the refinement scoped to the affected fork bodies only. Other locks keep their iter-2 status. CH-05 iter-2 → iter-3 (asymmetric tier layout: `F-storage-layout` + `F-retrieval` + `F-write-atomicity` bodies refined while `F-tier-types` + `F-rotation` + `F-incognito` + `F-record-id` kept iter-2 status) is the canonical precedent.

**AskUserQuestion fork-template requirement (added 2026-05-19 per CH-05-i-phi retro P-skill-2; extended 2026-05-20 per CH-28 retro plan archive `chunk-decomposition-and-fork-framing-76e04080.md` to a STRICT 4-line template + TECHNICAL FORK release)**: every fork option presented at gate-1 (or gate-1.5 sub-fork) via AskUserQuestion MUST include in the option's `description` field the 4 lines below, IN ORDER:

```
**User-visible:** <what users perceive if this option lands>
**Product trajectory:** <how this affects overall product trajectory — what becomes easier/harder downstream>
**Cycle scope:** <effort + cascade scope — engineering tradeoff for this chunk>
**Defers (if chosen):** <features NOT shipping this chunk; allocation chunk-IDs OR "none deferred">
```

**Disciplines**:

- **User-visible** line: states what the END USER perceives — NOT the implementation layer. Avoid architectural jargon (e.g., "wire-format-explicit", "auditability", "operator inspection window"). Frame in user-perceivable behavior. Example: *"User sees a strict error when no identity layers found at any of the 3 scopes."* (Better than *"strict EmptyScope error per F-empty-dir-fallback.b lock"*.)
- **Product trajectory** line: states the long-term product impact (better/worse for which downstream capabilities) — DISTINCT from this chunk's engineering tradeoff.
- **Cycle scope** line: engineering tradeoff for THIS chunk (effort, cascade scope, audit envelope tier, NEW migrations, etc.).
- **Defers (if chosen)** line: enumerates features that will NOT ship this chunk IF this option is chosen; cite the allocation chunk-IDs (e.g., `M6-DEFERRED-04 / CH-36`). If no features are deferred for this option, write `none deferred`. Closes the "perception that essential features will be lost" gap.

**TECHNICAL FORK release**: when a fork is labeled `**TECHNICAL FORK** (no user-visible delta — pick on engineering merit only)` in the plan §"Forks for orchestrator" section (per chunk-planner v26 P-plan-1-v26 + per-chunk-planning-template Pre-§1 Forks-section format rules), the AskUserQuestion `description` field MAY collapse to the **2-line minimal template**:

```
**Cycle scope:** <effort + cascade scope — engineering tradeoff>
**Defers (if chosen):** <features NOT shipping; allocation chunk-IDs OR "none deferred">
```

The 2-line release applies ONLY to forks the planner labeled `TECHNICAL FORK`. Forks without that label MUST use the full 4-line template.

**Project-agnostic**: applies uniformly to `project=baby-phi` AND `project=i-phi` AND any future project. No project-specific path literals in template text.

**Why the 4-line template** (rationale only): CH-28 retro observed that the v23 2-line template (`user-impact` + `pros/cons`) was being interpreted as **architectural-impact** ("hybrid Blueprint table = wire-format-explicit") rather than user-perceived behavior. The user reading gate-1 forks could not assess product trajectory or trace what features would be deferred under each option. The 4-line template structurally surfaces all four perspectives.

Codifies + extends the user's standing rule (saved as `feedback_locked_fork_details_appendix.md`): *"When the fork options are presented, there must be at least these two things (in a brief summary of course): how the fork affects the high level requirement from the user standpoint, and what are the pros and cons for the fork."* The CH-28 retro extension adds **Product trajectory** + **Defers (if chosen)** as separately-required lines so the dual "best for chunk + best for product" framing the user explicitly asked for at the 2026-05-20 plan-mode session is structurally enforced.

1. If `approval=yes`: produce the inline plan summary (template below in "Approval gate UX") and call AskUserQuestion with options:
   - **Approve** → proceed to Phase 2.
   - **Request changes** → accept user free-text feedback; re-spawn planner with feedback in context; repeat the gate.
   - **Abort** → clean up partial files, exit.
2. If `approval=no`: evaluate the **Direct-approval criteria** (all must hold):
   - No locked forks at plan-time.
   - Scope ≤ 1.5× forward-scope row's deliverables.
   - Zero phi-core leverage delta (or change is purely additive).
   - No new K8s blocker class (baby-phi only).
   - Audit envelope ≤ medium.
   - Confidence ≥ 9/10.
   - No new migration.

   If **all** hold → auto-approve. Otherwise → fall back to `approval=yes` flow above.

### Phase 2 — Implement (skip if `resume_from_phase` is `audit` or `retro`)

1. Spawn `chunk-implementer` agent. Prompt MUST include:
   - The approved plan path.
   - `project` and absolute project root.
   - Explicit instruction to use the cargo-clean discipline (see "Cargo-clean discipline" below).
   - For `project = baby-phi`: instruction to run the 4 CI guards at phase boundaries.
   - For `project = i-phi`: instruction that CI guards / cargo may not apply yet for the very first chunk.
2. At **each phase boundary** the implementer hits, the skill:
   - Reads the diff (`git -C <root> diff` or staged equivalent).
   - Runs the cargo invocations enumerated in the "Cargo-clean discipline" section below.
   - For `project = baby-phi`: runs the 4 CI guards.
   - For `project = i-phi`: runs clippy + tests **iff** `Cargo.toml` exists; otherwise skip.
3. **Doc-sync widened sweep** (per CH-15 retro): after any gate-2 inline correction OR drift closure with cross-cutting impact, grep the canonical stale-narrative phrase set across `<root>/docs/specs/v0/implementation/m*/architecture/*.md` + `…/operations/*.md` + `…/user-guide/*.md` (baby-phi paths; adapt to `<root>/docs/v0/**/*.md` for i-phi). The phrase set: `FOLLOWUP-NN`, `deferred per`, `is NOT emitted`, `not emitted at CH-NN`, `advisory at M5`, `Step 0 only blocking`, `M6+ tightens the gate`, `at M5/P4`, `not blocking at M5`. Patch any matches **before** dispatching auditors. Trivial-multi tier if > 1 line; Trivial-1L if ≤ 1 line.
4. **Mid-implementation route-selection on v15 P-impl-1 LOC-cap pause (added 2026-05-20 per CH-06-i-phi retro `da221147` P-skill-1; codifies Route A / Route B / Route C named routing classes after first activation)**: when the implementer pauses at a >2× LOC cap breach per chunk-implementer v15 P-impl-1, the orchestrator surfaces THREE named routing classes via AskUserQuestion (the v23 fork-template applies: each option's `description` field includes user-impact + pros/cons). The 3 named classes:

   - **Route A — Deviation-acceptance**: ship the overrunning file(s) at their actual LOC + log per v15 P-impl-2 cap-to-1.5×-ceiling deviation entry at P-SEAL. Use when functional scope is load-bearing for the locked fork semantic + further extraction would break cohesion + actual LOC stays within 1.5× ceiling. **CH-05 precedent (parser.rs 5× overrun)** — functional scope (9 frontmatter fields + render_memory_md inverse + 5 robustness tests) cannot be shrunk; deviation accepted.

   - **Route B — Module-split (plumbing-extraction-on-LOC-pressure)**: extract the cascading/plumbing/wiring body to a NEW sibling module file (e.g., `cascade.rs`, `bridge.rs`, `wiring.rs`). The locked fork semantic ships unchanged; only the code organization changes. ADD 1 NEW file vs plan §3.B file-count cap = deviation logged + ratified in ADR. **CH-06 precedent (cascade.rs)** — extract BFS cascade walk + per-handle command-send-and-aggregate helper out of handle.rs + registry.rs into NEW `src/daemon/sessions/cascade.rs` (~138 LOC). Residual handle.rs + registry.rs LOC overruns fall within v15 P-impl-2 cap-to-1.5×-ceiling band; logged + ratified in plan §3.B-A user-directed amendment + ADR §D8.14. Suitable when extraction is functionally clean (helper boundary is natural) + extracted body is ≥ 50 LOC to justify a separate file.

   - **Route C — Fork-relaxation / re-vote**: ship the locked fork at a relaxed semantic OR re-vote the fork via planner re-spawn iter-N+1. Use when the LOC overrun reveals the locked semantic was scoped too aggressively. Rare; always escalates to user re-vote AskUserQuestion. **NOT recommended** unless cap-derivation gap is so severe that the locked semantic cannot ship within ANY reasonable LOC envelope (e.g., > 5× cap with no extraction path).

   The orchestrator selects + names the route in the AskUserQuestion prompt; the user picks. Selected route lands in:
   - cycle-audit §6 deviations (as D-NN entry citing route class + functional driver).
   - ADR §DN.M (ratifies the route + functional driver + cross-references).
   - Plan §X.Y-A user-directed mid-cycle amendment (per outer CLAUDE.md P-orch-1 exception class) when Route B/C; Route A typically does NOT need plan amendment (deviation-log + ADR cite suffices unless user explicitly directs).

### Phase 3 — Audit (skip if `resume_from_phase = retro`)

1. Resolve auditor count:
   - `audit_envelope = small` → 1 auditor (letter A).
   - `audit_envelope = medium` → 2 auditors (letters A + B).
   - `audit_envelope = large` → 3 auditors (letters A + B + C).
   - `audit_envelope = auto` → use the value derived by `audit-envelope-size` skill in Phase 1.
2. Spawn the auditors **in parallel** (single message, multiple Agent tool calls). Each gets a distinct prompt focus:
   - **Letter A** — code-correctness + phi-core leverage + tests.
   - **Letter B** — docs / paperwork / verified-headers / cycle-index row / ADR / drift entries.
   - **Letter C** (only at `large`) — cross-cutting concerns: cross-file consistency, interface contracts, security implications.
3. Each auditor writes `<cycle folder>/audit-<letter>-iter1.md` and returns the file path + a one-line verdict.
4. Read all audit logs.
5. **Triage findings per CLAUDE.md tiers**:
   - **Trivial-1L** (≤ 1-line patch on a verified-header / changelog row / index entry): orchestrator applies the patch; **no auditor re-spawn**. Log the patch in `cycle-audit.md` §"Iteration accounting".
   - **Trivial-multi** (> 1-line trivial patch like a small docstring or cross-ref): orchestrator applies the patch; re-spawn the **same auditor** at iter N+1 to confirm.
   - **Tactical FAIL**: re-spawn `chunk-implementer` with the audit log path. Then re-spawn all auditors at iter N+1.
   - **Architectural FAIL**: re-spawn `chunk-planner` with the audit log path. **Always escalate to the user** via AskUserQuestion before re-spawning. Then re-spawn implementer + auditors.
6. **Iteration cap**: if any finding hits iter ≥ 3 → STOP, escalate to the user via AskUserQuestion.

### Phase 4 — Final cycle re-audit (mandatory, never skipped)

This is the orchestrator's gate-4. **Sub-agent auditors cannot run the MUST-RUN list reliably from sandbox** — they will mark those claims `NOT-EXECUTED-IN-AUDIT`. This phase closes those.

1. Re-read every diff in the cycle (`git -C <root> log --oneline <cycle-start>..HEAD` plus the staged set).
2. Run the **MUST-RUN list** authoritatively:
   - `RUSTFLAGS="-Dwarnings" cargo clippy -j 4 --manifest-path <root>/Cargo.toml --workspace --all-targets`.
   - For `project = baby-phi`: `bash <root>/scripts/check-doc-links.sh`, `…/check-ops-doc-headers.sh`, `…/check-phi-core-reuse.sh`, `…/check-spec-drift.sh`.
   - For `project = i-phi`: clippy only (no CI guard scripts exist yet — note this in the cycle-audit).
3. Run `cargo fmt --manifest-path <root>/Cargo.toml -- --check` (if cargo exists).
4. Verify all paperwork:
   - Cycle-index row exists and Status is correct.
   - Plan archive at `<root>/docs/v0/proposal/plan/<slug>-<hex>.md` (i-phi) or `<cycle folder>/plan.md` (baby-phi).
   - All touched docs have updated verified-headers (baby-phi convention; i-phi currently skips verified-headers).
   - ADR / drift / FOLLOWUP entries present where the plan called for them.
5. Write `<cycle folder>/cycle-audit.md` with these sections:
   - §1 audit-pipeline summary (one row per auditor letter × iteration).
   - §2 diff review (high-level summary of code + doc changes).
   - §3 MUST-RUN evidence (paste the clippy + CI-guard outputs or their tail).
   - §4 iteration accounting (Trivial-1L / Trivial-multi / Tactical / Architectural counts).
   - §5 paperwork ledger (one row per required artifact: cycle-index / plan archive / drift / ADR / FOLLOWUP / verified-headers).
   - §6 deviations (force-proceed split decisions, mid-cycle scope expansions, etc.).
   - §7 metrics (test count delta, phi-core import baseline, disk reclaimed at gate-5).
6. If anything new surfaces → re-trigger implementer or planner re-spawn, then re-run this phase. **Never skip.**

### Phase 5 — Cleanup

1. Skip entirely in `dry_run = yes` mode.
2. Capture `du -sh <root>/target` (before).
3. Run `cargo clean --manifest-path <root>/Cargo.toml`.
4. Capture `df -h /root | head -3` (after).
5. Log "disk reclaimed" into `cycle-audit.md` §7 metrics row.

### Phase 6 — Retrospective (DEFAULT: batched joint-retro per CH-11b 2026-05-26 user directive)

**Per-cycle retrospector dispatch SUSPENDED (user-locked 2026-05-26 at CH-11b cycle `bf1139be` Phase 5→6 transition gate)**. Each chunk-close lands a tight `<cycle folder>/retro-context.md` capturing retro-thoughts; every 3-4 chunks a **joint-retro session** reads the accumulated `retro-context.md` files + cycle-audits and proposes consolidated standards updates. Goal: prevent unchecked growth of outer CLAUDE.md + agent prompts + chunk-initiate skill + save tokens on per-cycle retrospectives.

**Phase 5 → Phase 6 transition gate (mandatory pause; updated 2026-05-26)**: orchestrator presents the transition summary via AskUserQuestion with 4 options:

- **Land retro-context.md + skip retrospector (Recommended; new default 2026-05-26)** → orchestrator writes `<cycle folder>/retro-context.md` capturing observations worth carrying (process gaps + hypothesis updates + standards-update candidates + cycle stats). Status stays `audited-pending-retro`. Joint-retro pending. **No retrospector dispatched; no standards updates applied this cycle.**
- **Dispatch chunk-retrospector now (legacy per-cycle path)** → spawn the retrospector per the steps below; produces full `retrospective.md` + proposes standards updates surfaced one-by-one via AskUserQuestion. Status flips to `retro-complete` if proposals applied.
- **Joint-retro session NOW (batched mode)** → spawn the retrospector with the **list of accumulated `retro-context.md` paths** + cycle-audit references from the prior 2-4 chunks; produces a single consolidated `retrospective.md` covering the batch. Use this when 3-4 retro-context.md files have accumulated. All batch chunks' Status flips to `retro-complete` together.
- **Pause / abort** → stop at Phase 5; paperwork stays complete; Status stays `audited-pending-retro` for batched-retro path or `in-flight` for abort.

**Retro-context.md shape** (canonical CH-11b precedent at `i-phi/docs/v0/proposal/plan/build/ch-11b-web-chat-ui-bf1139be/retro-context.md`): Cycle context block + Observations worth carrying (process gaps / hypothesis updates / notable wins / code observations / plan-narrative inconsistencies / LOC absorption) + Standards-update proposals drafted (NOT applied; joint-retro decides) + Cycle-folder artifacts + Status.

**Joint-retro batch sizing**: 3-4 chunks per batch is the user-locked window. Smaller batches (2) acceptable when the cycle surface is large + retro-contexts are dense; larger batches (5+) discouraged because cross-chunk pattern detection degrades.

#### Legacy per-cycle path (selected via option 2 above)

1. Spawn `chunk-retrospector` agent. Prompt MUST include:
   - The cycle hex.
   - Paths to `plan.md`, every `audit-<letter>-iter<N>.md`, `cycle-audit.md`.
   - `project` and absolute root.
2. The retrospector reads all those files plus diffs, runs the `permissions-audit` skill (the §A–§H report lands in §3.5 of the retrospective), and writes `<cycle folder>/retrospective.md`.
3. The retrospector returns a list of **proposed standards updates** (agent prompts, per-chunk-planning-template, CLAUDE.md, skill checklists).
4. Surface each proposal to the user via AskUserQuestion. For each, options:
   - **Apply** → orchestrator applies the change; bump the affected file's version; append a row to `.claude/agents/_changelog.md`.
   - **Defer** → log the proposal in the retrospective with a "deferred — revisit next cycle" tag.
   - **Reject** → log the proposal with a "rejected — <reason>" tag.

#### Joint-retro batch path (selected via option 3 above)

1. Identify the batch window: accumulated `retro-context.md` files since the last joint-retro (typically 2-4 chunks).
2. Spawn `chunk-retrospector` agent with batch-mode prompt including: every batch chunk's `retro-context.md` path + corresponding `cycle-audit.md` + `plan.md` + diffs across the batch window.
3. The retrospector reads ALL inputs, identifies cross-cycle patterns + recurring process gaps + load-bearing standards-update candidates, runs `permissions-audit` skill once across the batch window's tool-use log, and writes a single consolidated `retrospective-joint-<first-hex>-to-<last-hex>.md` at `i-phi/docs/v0/proposal/plan/retros/` (NEW directory) or equivalent baby-phi path.
4. Surface each consolidated proposal one-by-one via AskUserQuestion (Apply / Defer / Reject).
5. ALL batch chunks' cycle-index Status flips to `retro-complete` together; joint-retro link recorded in EACH batch chunk's Retro cell.

### Phase 7 — Summary

Print a final report containing:

- **Cycle hex** and slug.
- **Commits landed** (links to git refs if available).
- **Test count delta** (before → after).
- **Files changed** (count + top 10 paths).
- **Iteration count** per auditor letter and audit verdicts.
- **Disk reclaimed** at gate-5.
- **Standards updates applied** (if any).
- **Next chunk's forward-scope row** reference (if known).

Then update the cycle-index row's `Status`:
- `retro-complete` if Phase 6 ran.
- `audited-pending-retro` if `skip_retrospective = yes` was chosen at the Phase 5 → Phase 6 transition gate or via initial input.

### Phase 8 — Temp-folder cleanup (added 2026-05-18 per CH-03-i-phi retro P5c, cycle hex `c542648f`)

Between cycles `/tmp` accumulates planner outputs, audit outputs, scratch files (e.g., `/tmp/ch03-planner-output.md`, `/tmp/ch03-planner-output-iter2.md`, `/tmp/claude-0/.../tasks/<id>.output`). Without cleanup the folder grows unboundedly. Phase 8 sweeps cycle-related temp files with a **backup-only-if-deemed-necessary** clause.

1. **Identify cycle-related temp files**: scan `/tmp/` for files matching cycle-related patterns:
   - `/tmp/<chunk-slug>-*` (e.g., `/tmp/ch03-planner-output*`).
   - `/tmp/<cycle-hex>-*` (e.g., `/tmp/c542648f-*`).
   - `/tmp/claude-*/...../tasks/<id>.output` files (sub-agent transcripts from this session).
   - Any other files modified in `/tmp` during the cycle window (orchestrator session start → Phase 7 close).
2. **Triage for backup**: for each identified file, decide whether content is **deemed necessary** to preserve for future cycles or post-mortem:
   - **YES (backup needed)**: file carries unique signal NOT already captured in `<cycle folder>/{plan.md, audit-*.md, cycle-audit.md, retrospective.md}`. Examples: intermediate planner-iteration drafts that informed a re-spawn but didn't land in the archive; long sub-agent transcripts with diagnostic detail the audit log condensed.
   - **NO (no backup)**: file content is already mirrored in cycle-folder artifacts (default — most cases). Examples: `/tmp/ch03-planner-output-iter2.md` is already at `<cycle folder>/plan.md` (iter-2 archive); raw `cargo test` output is already summarized in `cycle-audit.md` §3.
3. **Backup mechanism** (only if step 2 returns YES): copy file to `<cycle folder>/scratch/<filename>` (create scratch/ subdir if absent); add a one-line note in `cycle-audit.md` §6 deviations explaining what was preserved + why.
4. **Delete identified temp files**: `rm /tmp/<matched-files>`. Be careful with the patterns; never `rm -rf /tmp/*` blanket-style. Use explicit per-file `rm` calls or narrow globs (`rm /tmp/<chunk-slug>-*.md`).
5. **Skip in `dry_run = yes` mode**: leave temp files in place.

The default expectation is **NO backup needed** for most files — cycle artifacts (`plan.md` / `audit-*.md` / `cycle-audit.md` / `retrospective.md`) capture all load-bearing signal. The backup-only-if-deemed-necessary clause exists for the rare case where a temp file carries unique diagnostic value (e.g., a planner re-spawn iteration that didn't land verbatim in the archive). This phase runs AFTER Phase 7 final summary printed + cycle-index Status flipped — temp files needed for any prior phase (e.g., retrospector reading planner-iter-1 from `/tmp`) are still in place when those phases ran.
- `audited-pending-retro` if `skip_retrospective = yes`.

---

## Approval gate UX

When `approval = yes` (or fallback from `approval = no`), present this inline summary before AskUserQuestion:

```
## Plan summary — <chunk> on <project>

Cycle hex: <8-hex>
Slug: <chunk slug>
Scope: <one paragraph from plan §3>
Deliverables:
  - <bullet from §6>
  - <…>
Files touched (predicted): <count + top 5 paths>
Audit envelope: <small | medium | large>  →  <N> auditors
Predicted test delta: <Δ tests>
Direct-approval criteria: <pass/fail summary, one line per criterion>
Locked forks (if any): <list, or "none">
Plan path: <absolute path to <cycle folder>/plan.md>
```

Then AskUserQuestion with options:
- **Approve** → proceed to Phase 2.
- **Request changes** → accept free-text feedback; re-spawn planner; repeat.
- **Abort** → cleanup, exit.

---

## Split decision

Auto-detect split candidacy from these triggers. **Two-or-more triggers** required to surface a split prompt:

| Trigger | Source |
|---|---|
| Scope > 1.5× forward-scope deliverable count | plan §3 vs forward-scope row |
| Audit envelope = `large` | `audit-envelope-size` skill output |
| Confidence < 9/10 | plan §12 |
| Deliverables span > 5 surfaces | plan §6 |
| New architectural surface (new module / crate) | plan §3.A scope-classification |

**What "confidence" means in plan §12.** The chunk-planner self-rates 1–10 in §12 "Confidence and risks". Score reflects scope-boundedness, deliverable-to-forward-scope mapping clarity, assumption count, risk of mid-cycle re-plan, audit-envelope-sizing quality. **9–10** = implementable as drafted without surprises. **< 9** = unresolved aspects; signal the chunk may be too large or too fuzzy.

On a split-prompt, AskUserQuestion options:
- **Approve split** → narrow the chunk; file the remainder as a new forward-scope row; re-run Phase 1.
- **Force-proceed** → continue with the wide chunk; note the deviation in `cycle-audit.md` §6.
- **Abort** → cleanup, exit.

---

## Cargo-clean discipline (two placements)

Per CH-18 retro and the outer CLAUDE.md:

**Placement 1 — Immediate-post-test.** After **every** `cargo test --workspace` invocation inside the cycle (sub-agent audits A + B, orchestrator gate-4 test, retrospector permissions-audit script), run:

```
cargo clean --manifest-path <root>/Cargo.toml
```

before the next cargo invocation. Per-invocation cleanup ensures the next invocation starts from a clean `target/` and prevents accumulation.

**Placement 2 — Gate-5 final close.** After standards updates land + cycle-index row flipped to `retro-complete` (or `audited-pending-retro`), run the same `cargo clean` as the closing step before user commit. Capture `du -sh <root>/target` BEFORE + `df -h /root | head -3` AFTER and log disk reclaimed in `cycle-audit.md` §7.

Both placements are mandatory.

---

## MUST-RUN list

Always run at Phase 4 (orchestrator gate-4), authoritatively:

- `RUSTFLAGS="-Dwarnings" cargo clippy -j 4 --manifest-path <root>/Cargo.toml --workspace --all-targets`
- For `project = baby-phi`:
  - `bash <root>/scripts/check-doc-links.sh`
  - `bash <root>/scripts/check-ops-doc-headers.sh`
  - `bash <root>/scripts/check-phi-core-reuse.sh`
  - `bash <root>/scripts/check-spec-drift.sh`
- For `project = i-phi`: clippy only (no CI guards yet).

Sub-agent auditors mark these `NOT-EXECUTED-IN-AUDIT`. Phase 4 closes them.

---

## Doc-sync widened sweep — phrase set

Run after any gate-2 inline correction OR drift closure with cross-cutting documentary impact. Grep across all `<root>/docs/specs/v0/implementation/m*/architecture/*.md` + `…/operations/*.md` + `…/user-guide/*.md` (baby-phi) or `<root>/docs/v0/**/*.md` (i-phi) for:

- `FOLLOWUP-NN`
- `deferred per`
- `is NOT emitted`
- `not emitted at CH-NN`
- `advisory at M5`
- `Step 0 only blocking`
- `M6+ tightens the gate`
- `at M5/P4`
- `not blocking at M5`

Patch matches **before** dispatching auditors. Iteration accounting: > 1 line = Trivial-multi; ≤ 1 line = Trivial-1L.

---

## Failure handling

- **Pre-flight failure** (dirty tree, wrong branch, missing forward-scope row): abort with a clear remediation message. Do not create any cycle-folder artifacts.
- **Planner timeout or invalid output**: re-spawn once. If second attempt fails, escalate to user via AskUserQuestion with the planner's last output.
- **Implementer crash or test regression**: re-spawn with the failure log. If second attempt fails, escalate.
- **Auditor crash**: re-spawn the same letter. If second attempt fails, demote to one fewer auditor and continue with a note in `cycle-audit.md` §6.
- **Iteration cap hit** (≥ 3 on same finding): STOP, escalate to user.
- **Cargo-clean failure** (e.g. permission error): log and continue; manual intervention required post-cycle.
- **User-initiated abort** at any AskUserQuestion: clean up any partial cycle folder created so far, leave the cycle-index in its pre-cycle state, exit.

---

## Outputs

On a successful run, the skill produces:

- `<cycle folder>/plan.md` — approved plan (via chunk-archive-plan sub-skill).
- `<cycle folder>/audit-<letter>-iter<N>.md` — one per auditor × iteration.
- `<cycle folder>/cycle-audit.md` — orchestrator's gate-4 audit.
- `<cycle folder>/retrospective.md` — chunk-retrospector's output (if Phase 6 ran).
- Updated cycle-index row reflecting final status.
- Approved standards-update commits (if any).
- A final Phase-7 summary printed to the user.

---

## Reference

- `/root/projects/phi/CLAUDE.md` — outer orchestrator conventions (gates 1–5, audit-fix tiers, cargo-clean two-placement, doc-sync widened sweep, granular Bash discipline).
- `/root/projects/phi/baby-phi/CLAUDE.md` — baby-phi-specific overlay.
- `/root/projects/phi/.claude/agents/chunk-planner.md` (v15) — planner contract + sub-skills it invokes.
- `/root/projects/phi/.claude/agents/chunk-implementer.md` (v10) — implementer contract.
- `/root/projects/phi/.claude/agents/chunk-auditor.md` (v9) — auditor contract.
- `/root/projects/phi/.claude/agents/chunk-retrospector.md` (v5) — retrospector contract.
- `/root/projects/phi/.claude/skills/chunk-archive-plan/SKILL.md` — produces `<cycle folder>/plan.md` + cycle-index row.
- `/root/projects/phi/.claude/skills/chunk-template-fill/SKILL.md` — used by planner to bootstrap the 12-section plan.
- `/root/projects/phi/.claude/skills/audit-envelope-size/SKILL.md` — sizes the auditor count.
- `/root/projects/phi/.claude/skills/phi-core-leverage-check/SKILL.md` — phi-core reuse compliance check.
- `/root/projects/phi/.claude/skills/k8s-readiness-check/SKILL.md` — K8s posture check (baby-phi only).
- `/root/projects/phi/.claude/skills/ci-guards-run/SKILL.md` — runs the 4 CI guards (baby-phi).
- `/root/projects/phi/.claude/skills/permissions-audit/SKILL.md` — used by retrospector at §3.5.
- `/root/projects/phi/baby-phi/docs/specs/v0/implementation/m5_1/process/per-chunk-planning-template.md` — canonical 12-section plan template.
- `/root/projects/phi/baby-phi/docs/specs/plan/build/_cycle-index.md` — baby-phi cycle-index format reference.
- `/root/projects/phi/baby-phi/docs/specs/plan/build/ch-17-*/cycle-audit.md` — example cycle-audit shape.
- `/root/projects/phi/i-phi/docs/v0/proposal/plan/_cycle-index.md` — i-phi cycle-index.

## Three-update bundle from CH-07a-i-phi retro `5384684d` (2026-05-23)

### Update #1 — Mandatory P-orch-3 numeric-citation cross-check at Phase 1.5 plan-archive

Per CH-07a retro proposal #2: P-orch-3 (pre-archival numeric-citation cross-check, specified at outer CLAUDE.md 5 consecutive cycles ago) is now MANDATORY at chunk-initiate Phase 1.5 plan-archive (step 7 chunk-archive-plan invocation). The orchestrator MUST run:

```bash
bash /root/projects/phi/.claude/scripts/numeric-citation-check.sh <plan-path> <project-root>
```

The script (TBD-authored at follow-up commit; minimum-viable shape: greps canonical phrase set `\d+ (workspace tests|permissions tests|integration tests|baseline tests|carry-forward tests)`; runs `cargo test --no-run --manifest-path <root>/Cargo.toml -j 4`; prints mismatch matrix between plan §6 cited numbers and the snapshot). If mismatches surface, apply Trivial-1L plan-edit BEFORE archive. Closes the 5-cycle non-application gap (CH-05 + CH-06 + CH-08 + CH-16a + CH-16b + CH-07a all specified P-orch-3 but none applied; CH-07a evidence: plan §6 cited baseline 173 vs actual 176 — D-7 in cycle-audit §6).

### Update #2 — Gate-3 audit-prompt-test-allocation cross-check for split-decision chunks

Per CH-07a retro proposal #3: BEFORE dispatching auditors at gate-3, extend the audit-prompt-authoring cross-check to ALSO cross-reference each `test_<name>` token in the audit prompt against the cycle's plan §8 per-Tier MUST-SHIP test cardinality + the split-decision allocation (when the chunk is one half of a split). Scriptable as:

```bash
# Extract every test_<name> token from the audit prompt body
grep -oE 'test_[a-z_0-9]+' <audit-prompt-text> | sort -u > /tmp/audit-prompt-tests.txt
# Cross-reference against plan §8 test list
grep -oE 'test_[a-z_0-9]+' <plan-path> | sort -u > /tmp/plan-tests.txt
comm -23 /tmp/audit-prompt-tests.txt /tmp/plan-tests.txt  # tests in prompt but not in plan
```

Any test name in the prompt but NOT in plan §8 = Trivial-1L pre-dispatch fix (prompt-side typo / sibling-chunk-territory bleed). CH-07a evidence: orchestrator's Audit A prompt cited `test_factory_sub_agent_default_mode_incognito` + `test_factory_assembles_initial_context_per_compaction_md_section_4` as required-PASS — but both are CH-07b territory (sibling chunk post-split). Auditor handled gracefully but the orchestrator-side miss is the deviation class (D-8 in cycle-audit §6).

### Update #3 — Gate-5 paperwork-sweep step for NEW recurring executables

Per CH-07a retro proposal #10: at Phase 5 close (cargo-clean gate-5), the orchestrator's paperwork-sweep step gains a NEW question:

> Did this cycle ship NEW recurring executables (scripts under `<root>/scripts/`, binaries under `<root>/src/bin/`, hook scripts under `<root>/hooks/`)? If yes, propose corresponding `.claude/settings.json` Bash allow-list rules as part of the standards updates surfaced at Phase 6.

Worked example: CH-07a Tier P shipped 4 NEW `scripts/check-*.sh` that the orchestrator immediately invoked 35× in the same cycle, generating 35 PermissionRequest prompts. Had the gate-5 paperwork-sweep caught this, the corresponding 4 allow-list rules would have shipped in the same chunk-close commit (zero prompts on first re-use). The CH-07a retrospector picked this up at §3.5 hot-allow-rule candidate cluster #1; the gate-5 sweep would catch it earlier.

The companion outer CLAUDE.md "Cargo-clean discipline" section is amended to add this paperwork sweep as a parallel concern (settings.json hygiene at chunk-close).

## Follow-up TODOs (deferred to next cycle)

- ~~Create the i-phi forward-scope file structure (currently TBD).~~ **Resolved**: CH-01 onward established the structure at `docs/v0/proposal/plan/forward-scope/` + per-chunk `_cycle-index.md` row + `build/<slug>-<8hex>/plan.md` archive convention.
- ~~Decide on i-phi's CI guard set as the project matures past CH-01.~~ **Resolved at CH-07a (cycle `5384684d`)**: per F-iphi-ci-guards-deadline.b USER-DIVERGENT lock, 4 CI guards now ship at `i-phi/scripts/check-{doc-links,verified-headers,phi-core-reuse,spec-drift}.sh` + `tests/scripts_test.rs` bash harness + MUST-RUN list in `i-phi/CLAUDE.md`. See `chunk-auditor.md` v13 update (CH-07a retro proposal #9) — i-phi's CI guards execute in sub-agent audit sandbox post-CH-07a (no longer "skip for i-phi" permanently-skip override).
- Author the minimum-viable `numeric-citation-check.sh` script body at `/root/projects/phi/.claude/scripts/numeric-citation-check.sh` per Update #1 above (mandatory-at-Phase-1.5 hook is now in place; only the script body is TBD).
- Author the optional `audit-prompt-test-allocation-check.sh` script body per Update #2 (inline-grep procedure works today; script form is a convenience).