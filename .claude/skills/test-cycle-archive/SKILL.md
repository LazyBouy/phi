---
name: test-cycle-archive
description: Utility skill (called internally by `/test-pipeline-initiate`). Mints 8-hex cycle ID + creates `i-phi/docs/e2e-test/cycles/<slug>-<hex>/` folder + cycle-plan.md stub + appends row to `_registry-index.md` §8. Mirrors `chunk-archive-plan` for the e2e-test-pipeline cycle convention.
---

# test-cycle-archive

Utility skill: mint cycle folder + index row. Called by `/test-pipeline-initiate` at Phase 0 step 6. Not normally user-invoked directly (but safe to invoke if recovering a partially-set-up cycle).

## Inputs

| Input | Required? | Default | Notes |
|---|---|---|---|
| `slug` | yes | — | Short kebab-case identifier (e.g., `t4-smoke-execute`) |
| `mode` | yes | — | One of: `full` \| `plan` \| `execute` \| `triage` |
| `scope` | yes | — | Human-readable scope summary (free-form) |
| `cohort` | no | (n/a for triage) | Cohort name (for plan/execute/full) |
| `budget_usd` | no | (n/a for plan/triage) | Budget cap (for execute/full) |
| `project_root` | no | `/root/projects/phi/i-phi` | Path to i-phi clone |

## Procedure

1. **Generate cycle hex**: `openssl rand -hex 4` (8 lowercase hex chars).
2. **Mint folder**: `mkdir -p <project_root>/docs/e2e-test/cycles/<slug>-<hex>/`.
3. **Author `cycle-plan.md`** in the folder:

```markdown
# Cycle <slug>-<hex>

**Mode**: <mode>
**Created at**: YYYY-MM-DD
**Scope**: <scope>
**Cohort**: <cohort or "n/a">
**Budget cap**: $<budget_usd or "n/a">
**Audit status**: pending

## §1 — Deliverables expected

(populated by orchestrator after agent dispatch)

## §2 — Drive references

(populated by `drive-references.md` companion file at cycle close)

## §3 — Verdict summary

(populated by orchestrator at Phase 4 close)

## §4 — Cost summary

(populated by orchestrator at Phase 4 close)

## §5 — Audit

See [cycle-audit.md](cycle-audit.md) (written at Phase 4 close).
```

4. **Create `drive-references.md` stub** in the folder (orchestrator + test-executor populate during cycle):

```markdown
# Drive references — cycle <slug>-<hex>

Per-cycle Drive artifacts produced. Populated as agents create resources.

| Resource | Drive ID | View URL | Created at |
|---|---|---|---|
| (rows append as agents create Drive Docs/Sheets) | | | |
```

5. **Append registry row** to `<project_root>/docs/e2e-test/_registry-index.md` §8 (Cycles). Row shape:

```
| <slug>-<hex> | <hex> | YYYY-MM-DD | <mode> | <cohort> | <budget-cap-usd or "-"> | <verdict-counts-placeholder> | pending |
```

6. **Return** the cycle hex + cycle folder path + cycle-plan.md path to the caller (typically `/test-pipeline-initiate` Phase 0).

## Idempotency note

If a cycle folder already exists at the target path (`cycles/<slug>-<hex>/`), abort with a clear error. Cycle hexes are minted fresh each invocation; a collision means someone is invoking this skill twice with the same arg list — which would corrupt the registry. Caller decides whether to re-mint with a fresh hex or pause for investigation.

## Boundaries

- **DO NOT** invoke other agents. This is pure paperwork.
- **DO NOT** write to Drive. Drive resources are minted per-cycle by `test-executor` (executions Sheet, matrix Sheet); this skill only creates the **repo-side** paperwork.
- **DO NOT** copy the approved pipeline-architecture.md into the cycle folder. The plan home is at `docs/v0/proposal/plan/e2e-test/pipeline-architecture.md` (one place; cycles reference it, don't duplicate it).

## Cross-references

- Sibling utility: `chunk-archive-plan` (the analog for chunk-pipeline cycles; T-cycle convention mirrors that one)
- Companion: `/test-pipeline-initiate` (the caller)
- Plan: `i-phi/docs/v0/proposal/plan/e2e-test/pipeline-architecture.md` §"Master orchestrator skill" Phase 0 step 6
