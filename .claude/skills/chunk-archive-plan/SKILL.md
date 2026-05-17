---
name: chunk-archive-plan
description: Generate the 8-hex cycle ID and create the per-cycle folder structure under baby-phi/docs/specs/plan/build/. Copies the plan-mode plan stub into the folder. Used by chunk-planner at chunk-open.
version: 1
---

# chunk-archive-plan

Open a fresh cycle: generate the hex, create the folder, archive the plan-mode plan to `<cycle folder>/plan.md`.

## Inputs (caller provides)

1. **Chunk slug** — e.g., `ch-11-per-session-consent-gating`.
2. **Plan-mode plan path** — typically `/root/.claude/plans/<some-name>.md`. Optional; if absent, the planner writes the plan from scratch into `<cycle folder>/plan.md`.

## Procedure

1. **Generate the hex:**
   ```bash
   openssl rand -hex 4
   ```
   Capture the output as `<8hex>`.
2. **Create the cycle folder:**
   ```bash
   mkdir -p /root/projects/phi/baby-phi/docs/specs/plan/build/<slug>-<8hex>/
   ```
3. **Copy or initialize plan.md:**
   - If the orchestrator passed a plan-mode plan path: `cp <plan-mode plan> baby-phi/docs/specs/plan/build/<slug>-<8hex>/plan.md`.
   - If not: create an empty file; chunk-planner will Write the full plan content.
4. **Update placeholders** in lines 4–5 of the archived copy if it carries `<8hex>` token-placeholder markers (per chunk-plan convention; the meta-plan archive convention differs).
5. **Verify** `bash /root/projects/phi/baby-phi/scripts/check-doc-links.sh` exits 0 — relative-link integrity preserved.

## Output format

```
chunk-archive-plan:
  Slug: <slug>
  Hex: <8hex>
  Cycle folder: baby-phi/docs/specs/plan/build/<slug>-<8hex>/
  Plan file: <cycle folder>/plan.md (initialized | copied from <plan-mode path>)
  Doc-links check: ✅ exit 0 | ❌ exit <code>
```

## Quality bar

- Hex is exactly 8 hexadecimal characters (lowercase).
- Folder name is `<slug>-<8hex>` per memory `feedback_plan_archive_naming.md` (slug-first, hex suffix).
- Folder path is under `baby-phi/docs/specs/plan/build/` — never the meta-plan's `agentic-workflow/` folder.

## Reference

Memory `feedback_plan_archive_naming.md`. baby-phi `docs/specs/plan/build/` directory listing for examples (CH-09, CH-10, CH-23 are flat-file legacy; CH-11+ are folder-style).