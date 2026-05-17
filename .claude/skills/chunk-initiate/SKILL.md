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
| CI guards | `bash <root>/scripts/check-{doc-links,ops-doc-headers,phi-core-reuse,spec-drift}.sh` | none (no `scripts/` yet) |
| MUST-RUN list | `RUSTFLAGS="-Dwarnings" cargo clippy -j 4 --workspace --all-targets` + the 4 CI guards | (post-CH-01) clippy only; pre-CH-01 chunks have no cargo at all |
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
7. Look up the chunk's forward-scope row. If missing, abort with the file path the user should populate.
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
   - **Approve split** → re-spawn planner with narrowed scope; file the remainder as a new forward-scope row for a later chunk.
   - **Force-proceed** → proceed without splitting; note the deviation in `cycle-audit.md` §6.
   - **Abort** → clean up partial files, exit.
7. Archive the approved plan via the `chunk-archive-plan` sub-skill — produces `<cycle folder>/plan.md` with an 8-hex token, appends a row to the cycle-index.

### Phase 1.5 — Approval gate (skip if `resume_from_phase != plan`)

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

### Phase 6 — Retrospective (skip if `skip_retrospective = yes`)

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

## Follow-up TODOs (deferred to next cycle)

- Create the i-phi forward-scope file structure (currently TBD).
- Decide on i-phi's CI guard set as the project matures past CH-01.