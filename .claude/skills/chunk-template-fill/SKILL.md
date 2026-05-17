---
name: chunk-template-fill
description: Read the canonical 12-section per-chunk-planning-template and emit a fully-filled scaffold draft. Every required subsection populated; no stubs or TODO lines. Used by chunk-planner to bootstrap a new cycle plan.
---

# chunk-template-fill

Bootstrap a fresh cycle plan with all 12 sections populated from the chunk's forward-scope row. Used by chunk-planner only.

## Inputs (caller provides)

1. **Forward-scope row** for the chunk — slug, scope summary, drifts closed, concept docs touched, prerequisites, deliverables.
2. **Per-chunk-template path** — `baby-phi/docs/specs/v0/implementation/m5_1/process/per-chunk-planning-template.md`.

## Procedure

1. **Read** the canonical template top-to-bottom. Note every section, every required subsection, every required table column.
2. **For each section §1–§12:**
   - Populate from the forward-scope row + planner's pre-research where possible.
   - For every subsection / table that the template marks "required": fill with concrete content or write `N/A — <one-sentence reason>`.
   - **Never** leave `(stub)`, `(TBD)`, or `TODO` in any section.
3. **Section-specific minimums:**
   - §1: chunk goal in 2–4 sentences + forward-scope row reference.
   - §2: concept-alignment table with at least one row per concept doc the chunk touches.
   - §3: phi-core leverage table — even if delta is zero, the table must show the predicted import counts + cited rule.
   - §3.B: 7-axis K8s table (use skill `k8s-readiness-check`).
   - §3.C: 3-tier user-facing docs evaluation (architecture / operations / user-guide).
   - §4: drifts closed list (or "none" if no drifts close in this chunk).
   - §5: ADR draft skeleton with proposed ADR number + D-numbers.
   - §6: prior-chunk regression invariants — at minimum, the immediate prereq chunks.
   - §7: phase plan with at least 2 phases (planning + delivery) — or 1 if forward-scope row is small.
   - §8: tests summary with explicit expected test count delta.
   - §9: pre-chunk gate — reading list of files the implementer must read before phase 1.
   - §10: close criteria — both code-aspect and docs-aspect, with confidence target ≥ 9/10.
   - §11: audit plan (use skill `audit-envelope-size`).
   - §12: verification recipe — concrete shell commands.

## Output format

A markdown document matching the template exactly. Hand back to chunk-planner for further refinement (verifying claims, deepening citations, identifying forks).

## Quality bar

- All 12 sections present.
- Zero `(stub)` / `(TBD)` / `TODO` strings.
- Every "required" subsection / row / column from the template is populated.
- Forward-scope row's claims are reflected accurately (don't invent).

## Reference

per-chunk-template canonical: `baby-phi/docs/specs/v0/implementation/m5_1/process/per-chunk-planning-template.md`.