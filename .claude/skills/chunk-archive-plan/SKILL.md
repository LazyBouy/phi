---
name: chunk-archive-plan
description: Generate the 8-hex cycle ID and create the per-cycle folder structure under the active project's plan-build directory. Copies the plan-mode plan stub into the folder + appends a row to the project's cycle-index. Used by chunk-planner at chunk-open. Project-aware via PROJECT_ROOT (baby-phi default; i-phi or phi-core when set).
---

# chunk-archive-plan

Open a fresh cycle: generate the hex, create the folder, archive the plan-mode plan to `<cycle folder>/plan.md`, and append the new row to the project's `_cycle-index.md`.

## Project context (v2 — project-aware path resolution; added 2026-05-17 per CH-01-i-phi retro Row 1; v4 — chunk-template-validate-locked-appendix skill-based hard-assertion added 2026-05-26 per Chunk D intermediate-stabilization `36caa39f` Deliverable #6b; refines v3 inline-grep assertion to invoke the skill so the validation is consistent across planner end-of-draft + archive-tier)

The orchestrator passes `PROJECT_ROOT` in the caller context. Resolve all paths relative to it:

- **Unset / absent** → `/root/projects/phi/baby-phi` (back-compat default; behaviour matches v1 exactly).
- **`/root/projects/phi/i-phi`** → i-phi conventions:
  - Cycle folder: `<PROJECT_ROOT>/docs/v0/proposal/plan/build/<slug>-<8hex>/` (NOT `…/docs/specs/plan/build/…`).
  - Cycle-index path: `<PROJECT_ROOT>/docs/v0/proposal/plan/_cycle-index.md` (NOT `…/docs/specs/plan/build/_cycle-index.md`).
  - Doc-links check: `bash <PROJECT_ROOT>/scripts/check-doc-links.sh` if the script exists; **skip with a paperwork-side note** if it doesn't (i-phi has no `scripts/` at v0).
  - Cycle-index row format: same column shape as baby-phi (`Hex | Slug | Phases | Auditors | Iterations | Status | Retro`); see the project's `_cycle-index.md` header for the canonical "Column semantics" paragraph (added 2026-05-17 per CH-01-i-phi retro Row 3).
- **`/root/projects/phi/phi-core`** → phi-core (kernel lane; added 2026-06-08 per KC-01 retro candidate #1): paths use the **baby-phi shape rooted at phi-core** —
  - Cycle folder: `<PROJECT_ROOT>/docs/specs/plan/build/<slug>-<8hex>/` (identical layout to baby-phi).
  - Cycle-index path: `<PROJECT_ROOT>/docs/specs/plan/build/_cycle-index.md`.
  - Doc-links check: **none** — phi-core has no `scripts/check-*.sh`; **skip with a paperwork-side note**.
  - Cycle-index row format: same column shape; the phi-core `_cycle-index.md` carries its own "Column semantics" header (minted at the first phi-core cycle, KC-01 `a79c7669`).

For PROJECT_ROOT unset, all baby-phi paths apply unchanged.

## Inputs (caller provides)

1. **Chunk slug** — e.g., `ch-11-per-session-consent-gating`.
2. **Plan-mode plan path** — typically `/root/.claude/plans/<some-name>.md`. Optional; if absent, the planner writes the plan from scratch into `<cycle folder>/plan.md`.
3. **PROJECT_ROOT** (optional) — `/root/projects/phi/baby-phi` (default), `/root/projects/phi/i-phi`, or `/root/projects/phi/phi-core`.

## Procedure

1. **Generate the hex:**
   ```bash
   openssl rand -hex 4
   ```
   Capture the output as `<8hex>`.
2. **Resolve project paths** from `PROJECT_ROOT` per the Project context section above.
3. **Create the cycle folder** (project-aware):
   ```bash
   # baby-phi (default):
   mkdir -p /root/projects/phi/baby-phi/docs/specs/plan/build/<slug>-<8hex>/
   # i-phi:
   mkdir -p /root/projects/phi/i-phi/docs/v0/proposal/plan/build/<slug>-<8hex>/
   # phi-core (baby-phi shape rooted at phi-core):
   mkdir -p /root/projects/phi/phi-core/docs/specs/plan/build/<slug>-<8hex>/
   ```
4. **Copy or initialize plan.md:**
   - If the orchestrator passed a plan-mode plan path: `cp <plan-mode plan> <cycle folder>/plan.md`.
   - If not: create an empty file; chunk-planner will Write the full plan content.
5. **Update placeholders** in lines 4–5 of the archived copy if it carries `<8hex>` token-placeholder markers (per chunk-plan convention; the meta-plan archive convention differs).
6. **Append cycle-index row** (project-aware): add a new row to `<cycle-index path>` under the "Active cycles" table with shape:
   ```
   | [`<8hex>`](build/<slug>-<8hex>/plan.md) | <slug> — <one-line summary> | <phase count or n/a> | <auditor count or n/a> | <iter count, default `pending` until first audit> | `in-flight` | TBD |
   ```
   If the planner cannot reliably produce the phase / auditor / iteration counts at chunk-open (the plan body may not be drafted yet), use placeholder values (`pending`, `TBD`) — the implementer / orchestrator fills them in at chunk-seal per the plan's P-SEAL paperwork checklist.
7. **Verify** project-appropriate doc-links script if it exists:
   - baby-phi: `bash /root/projects/phi/baby-phi/scripts/check-doc-links.sh` must exit 0.
   - i-phi: no `scripts/check-doc-links.sh` exists at v0 → skip with a paperwork-side note in the output.
   - phi-core: no `scripts/check-*.sh` exists → skip with a paperwork-side note in the output.

8. **Locked-fork-details appendix hard-assertion (v3 — added 2026-05-18 per CH-04-i-phi retro P14, cycle hex `8a9c50ea`; v4 — skill-based assertion added 2026-05-26 per Chunk D intermediate-stabilization `36caa39f` Deliverable #6b; belt-and-suspenders to chunk-planner v22 P13 + v23 P-plan-3 + v32 P-plan-1-v32 planner end-of-draft self-check)**: BEFORE archiving the plan (step 4 copy / step 6 cycle-index row append), invoke skill `chunk-template-validate-locked-appendix` against the plan path. The skill performs the 4-step mechanical validation (heading exists / subsection count ≥ lock count / each subsection body ≥ 3 sentences) + returns PASS/FAIL.

   **Mechanical (v4)**:
   ```bash
   # Invoke the validation skill (skill body at .claude/skills/chunk-template-validate-locked-appendix/SKILL.md).
   # Skill exit code: 0 on PASS, 1 on FAIL.
   bash -c '<run chunk-template-validate-locked-appendix with PLAN_PATH=<plan-mode plan path>>'

   if [[ $? -ne 0 ]]; then
       echo "ERROR: chunk-template-validate-locked-appendix returned FAIL"
       echo "Plan has ≥ 1 user-lock but §1 Locked fork details is missing or malformed."
       echo "Per chunk-planner v32 P-plan-1-v32, the planner MUST ship §1 populated at iter-1 plan-draft time."
       echo "Per chunk-initiate Phase 1.5 Step A: re-spawn planner at iter-2 to fix (v23 P-plan-3 fallback during the cross-project 2-3-cycle hold-period)."
       exit 1
   fi
   ```

   **If assertion fails (v4 path)**: skill returns FAIL with a specific reason (which subsection is malformed, what's missing). chunk-archive-plan aborts. The orchestrator's chunk-initiate Phase 1.5 Step A skip-condition decision tree branch 2(c) handles the recovery: re-spawn planner at iter-2 to fix the appendix (regression-defense path; the v23 P-plan-3 ALWAYS-FIRE fallback during the cross-project 2-3-cycle hold-period). Orchestrator does not see the broken plan archived.

   **3-layer defense (v32-era)**: chunk-planner v32 P-plan-1-v32 end-of-draft self-check (planner-tier, self-correction); chunk-archive-plan v4 hard-assertion (archive-tier, gating); outer CLAUDE.md gate-1.5 P-orch-8 + chunk-initiate Phase 1.5 Step A skip-condition (orchestrator-tier, routing). All three layers invoke the same `chunk-template-validate-locked-appendix` skill for consistent PASS/FAIL semantics.

   **Historical context (pre-v4)**: v3 used an inline grep for `^#{2,3} Locked fork details` heading only. v4 upgrades to the skill which additionally validates subsection count ≥ lock count + each subsection body ≥ 3 sentences — catching malformed-but-headed appendices that v3 would have passed. The skill body lives at `.claude/skills/chunk-template-validate-locked-appendix/SKILL.md`.

   **2-of-2-cycle regression context (pre-v32)**: CH-03-i-phi (cycle `c542648f`) + CH-04-i-phi (cycle `8a9c50ea`) BOTH had to be patched post-draft because iter-2 planner did NOT emit the appendix natively despite chunk-planner v20 P2 mandate. P14 (v3 archive-tier assertion) + P13 (v22 planner self-check) jointly closed the regression. v32 + chunk-archive-plan v4 + P-orch-8 skip-condition extend the defense to the iter-1-populated regime.

## Output format

```
chunk-archive-plan:
  Project: baby-phi | i-phi | phi-core (per PROJECT_ROOT)
  Slug: <slug>
  Hex: <8hex>
  Cycle folder: <project-appropriate path>/<slug>-<8hex>/
  Plan file: <cycle folder>/plan.md (initialized | copied from <plan-mode path>)
  Cycle-index row: ✅ appended at line <N> | ❌ <error>
  Doc-links check: ✅ exit 0 | ⏭ skipped (project has no script) | ❌ exit <code>
```

## Quality bar

- Hex is exactly 8 hexadecimal characters (lowercase).
- Folder name is `<slug>-<8hex>` per memory `feedback_plan_archive_naming.md` (slug-first, hex suffix).
- Folder path is under the project's canonical plan-build directory — never under baby-phi paths for an i-phi cycle, and never under the meta-plan's `agentic-workflow/` folder.
- Cycle-index row IS appended (was a silent omission in v1; CH-01-i-phi retro Row 1 caught it).

## Reference

- Memory `feedback_plan_archive_naming.md`.
- baby-phi `docs/specs/plan/build/` directory listing for examples (CH-09, CH-10, CH-23 are flat-file legacy; CH-11+ are folder-style).
- i-phi `docs/v0/proposal/plan/build/` directory listing for examples (CH-01-i-phi onwards are folder-style).
- `chunk-initiate/SKILL.md` Per-project configuration table (the orchestrator's source of PROJECT_ROOT semantics).