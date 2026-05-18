---
name: chunk-archive-plan
description: Generate the 8-hex cycle ID and create the per-cycle folder structure under the active project's plan-build directory. Copies the plan-mode plan stub into the folder + appends a row to the project's cycle-index. Used by chunk-planner at chunk-open. Project-aware via PROJECT_ROOT (baby-phi default; i-phi when set).
---

# chunk-archive-plan

Open a fresh cycle: generate the hex, create the folder, archive the plan-mode plan to `<cycle folder>/plan.md`, and append the new row to the project's `_cycle-index.md`.

## Project context (v2 — project-aware path resolution; added 2026-05-17 per CH-01-i-phi retro Row 1)

The orchestrator passes `PROJECT_ROOT` in the caller context. Resolve all paths relative to it:

- **Unset / absent** → `/root/projects/phi/baby-phi` (back-compat default; behaviour matches v1 exactly).
- **`/root/projects/phi/i-phi`** → i-phi conventions:
  - Cycle folder: `<PROJECT_ROOT>/docs/v0/proposal/plan/build/<slug>-<8hex>/` (NOT `…/docs/specs/plan/build/…`).
  - Cycle-index path: `<PROJECT_ROOT>/docs/v0/proposal/plan/_cycle-index.md` (NOT `…/docs/specs/plan/build/_cycle-index.md`).
  - Doc-links check: `bash <PROJECT_ROOT>/scripts/check-doc-links.sh` if the script exists; **skip with a paperwork-side note** if it doesn't (i-phi has no `scripts/` at v0).
  - Cycle-index row format: same column shape as baby-phi (`Hex | Slug | Phases | Auditors | Iterations | Status | Retro`); see the project's `_cycle-index.md` header for the canonical "Column semantics" paragraph (added 2026-05-17 per CH-01-i-phi retro Row 3).

For PROJECT_ROOT unset, all baby-phi paths apply unchanged.

## Inputs (caller provides)

1. **Chunk slug** — e.g., `ch-11-per-session-consent-gating`.
2. **Plan-mode plan path** — typically `/root/.claude/plans/<some-name>.md`. Optional; if absent, the planner writes the plan from scratch into `<cycle folder>/plan.md`.
3. **PROJECT_ROOT** (optional) — `/root/projects/phi/baby-phi` (default) or `/root/projects/phi/i-phi`.

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

8. **Locked-fork-details appendix hard-assertion (v3 — added 2026-05-18 per CH-04-i-phi retro P14, cycle hex `8a9c50ea`; belt-and-suspenders to chunk-planner v22 P13)**: BEFORE archiving the plan (step 4 copy / step 6 cycle-index row append), grep the plan body for ≥ 1 occurrence of the pattern `LOCKED at gate-1` (case-insensitive). If matches exist, the planner has user-locked forks; the plan MUST then carry a `### Locked fork details` (or `## Locked fork details`) heading + at least one `#### F<N> = F<N>.<letter>` subsection.

   **Mechanical check**:
   ```bash
   # detect locked forks
   if grep -qiE 'LOCKED at gate-1' <plan-mode plan path>; then
       # then require the appendix heading
       if ! grep -qE '^#{2,3} Locked fork details' <plan-mode plan path>; then
           echo "ERROR: plan has ≥ 1 user-lock but no '### Locked fork details' appendix"
           exit 1
       fi
   fi
   ```

   **If assertion fails**: skill aborts with the error above. The chunk-planner re-emits the appendix; orchestrator does not see the broken plan archived. This is belt-and-suspenders to chunk-planner v22 P13 (planner self-check) — both layers fire. v22 P13 catches the regression at planner-tier (self-correction); P14 catches it at archive-tier (gating).

   **2-of-2-cycle regression context**: CH-03-i-phi (cycle `c542648f`) + CH-04-i-phi (cycle `8a9c50ea`) BOTH had to be patched post-draft because iter-2 planner did NOT emit the appendix natively despite chunk-planner v20 P2 mandate. P14 (this assertion) + P13 (planner self-check) jointly close the regression.

## Output format

```
chunk-archive-plan:
  Project: baby-phi | i-phi (per PROJECT_ROOT)
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