---
name: test-pipeline-initiate
description: Master orchestrator skill for the e2e-test pipeline. Modes: `full` (plan → execute → conditional triage), `plan` (test-planner only), `execute` (test-executor only), `triage` (test-issue-fixer only). Consumes accepted strategies + OpenRouter cohorts → produces TC markdown files, per-cycle executions.csv + benchmark-matrix.csv, issues + fix-batches as repo markdown. Enforces budget + max-requests guardrails.
---

# test-pipeline-initiate

Master orchestrator skill for the i-phi e2e-test pipeline. Runs the **downstream** half of the pipeline (test-planner v2 → test-executor v2 → test-issue-fixer v2). The upstream skills (`/collect-use-case`, `/develop-roadmap`, `/granularize-use-case`, `/develop-test-strategy`) run independently outside this skill.

> **v2 (2026-05-28; T3.6 storage architecture pivot — Drive write-path retired)**: per plan `/root/.claude/plans/hi-i-would-like-wobbly-naur.md` P1 lock, all downstream agents write repo markdown / CSV at `i-phi/docs/e2e-test/` (test-cases, issues, fix-batches, cycles/<hex>/executions.csv + benchmark-matrix.csv). Drive MCP pre-flight checks removed from Phase 0. The orchestrator + all 3 dispatched agents (test-planner v2, test-executor v2, test-issue-fixer v2) no longer touch Drive. GitHub Issues mirror unchanged (via `gh-rest.sh`).

## Quality + cost discipline (LOAD-BEARING)

Per [[feedback_quality_then_cost]]:
- **Quality first**: never sacrifice test rigor for budget. If running fewer models in the cohort would keep budget but skip a meaningful comparison, that's a partial cycle worth surfacing — don't silently drop coverage.
- **Cost-sensitive**: enforce `budget_usd` + `max_requests` HARD caps. The test-executor agent halts at 100% budget; the orchestrator should pre-estimate before dispatching execute mode + ask user to confirm if estimate > budget × 0.8.
- **Direct-approval criteria** (no AskUserQuestion gate): budget ≤ $5 AND cohort ≤ 3 models AND TCs in scope ≤ 10 AND expected runtime ≤ 15 min. Outside these bounds → escalate via AskUserQuestion at Phase 1.

## Inputs

| Input | Required? | Default | Notes |
|---|---|---|---|
| `mode` | yes | — | `full` \| `plan` \| `execute` \| `triage` |
| `scope` | yes | — | What to operate on. Format varies by mode: `strategies=[...]` (plan), `tcs=[...]` or `cohort:<name>` (execute), `all-open` or `tcs=[...]` or `use-cases=[...]` (triage) |
| `cohort` | no | `open-source-budget-2026Q2` | Cohort from cohorts.toml; used in `plan` (sets TC `models_in_scope`) + `execute` (overrides TC's cohort) |
| `budget_usd` | no | `5.0` | Hard cap on cycle cost (execute mode) |
| `max_requests` | no | `200` | Hard cap on OpenRouter requests (execute mode) |
| `concurrency` | no | `4` | Parallel TC × model invocations (execute mode) |
| `approval` | no | `yes` | Prompt user at Phase 1 (overrides Direct-approval criteria) |

## Phase 0 — pre-flight

1. **Verify env tokens** — `grep -cE '^(GITHUB_PAT_IPHI|OPENROUTER_TOKEN)=' /root/projects/phi/.env` should return 2.
2. **Verify .env permissions** — `stat -c '%a' /root/projects/phi/.env` should return `600` (warn if looser).
3. **Verify gh-rest.sh** — `bash /root/projects/phi/.claude/scripts/gh-rest.sh self-test` → expect `OK: authenticated`.
4. **Verify i-phi buildable** — `cargo build --manifest-path /root/projects/phi/i-phi/Cargo.toml -j 4` (cached after first build; ~free on warm cargo cache).
5. **Mint cycle folder** — invoke `test-cycle-archive` skill: it generates 8-hex cycle ID + creates `i-phi/docs/e2e-test/cycles/<slug>-<hex>/cycle-plan.md` + appends row to `_registry-index.md` §8.

(Drive MCP pre-flight check removed in T3.6 pivot. Drive is no longer used by any downstream agent.)

## Phase 1 — approval gate

Evaluate Direct-approval criteria:
- budget ≤ $5 AND
- cohort_size ≤ 3 models AND
- TCs in scope ≤ 10 AND
- expected_runtime ≤ 15 min (estimated as `tcs × models × 30s` + 60s daemon startup)

If ALL pass AND `approval=no`: skip prompt + proceed.
Otherwise: AskUserQuestion with summary:

> "test-pipeline-initiate mode=<mode>, scope=<scope>, cohort=<cohort> (N models), TCs=<K>, est_cost=$<X>, est_runtime=<T>min. Proceed?"

Options:
- `Approve → run as-is (recommended)`
- `Reduce scope → user narrows`
- `Reduce cohort → user picks subset of models`
- `Abort`

## Phase 2 — agent dispatch (per mode)

### `mode=full`

Sequential: test-planner v2 → test-executor v2 → conditional test-issue-fixer v2.

1. **test-planner v2**: mint TC markdown files from accepted strategies at `docs/e2e-test/test-cases/TC-NNNN.md`; bind `models_in_scope[]` to `<cohort>`.
2. **test-executor v2**: iterate minted TCs × cohort; append rows to `cycles/<hex>/executions.csv`; generate `benchmark-matrix.csv` + `matrix-summary.md` at close.
3. **Issue threshold check**: count newly-filed D-TEST issue files this cycle (`Grep -l 'cycle_hex: <hex>' docs/e2e-test/issues/*.md | wc -l`). If ≥ 10 global OR ≥ 3 per-UC → dispatch test-issue-fixer v2 with `trigger=threshold-{global|per-uc}`.

### `mode=plan`

Dispatch test-planner v2 only. Inputs: `strategies=<scope>`, `cohort_default=<cohort>`. Output: N new TC files at `docs/e2e-test/test-cases/TC-NNNN.md`.

### `mode=execute`

Dispatch test-executor v2 only. Inputs: `tcs=<scope>`, `cohort_override=<cohort>` (if provided), `budget_usd`, `max_requests`, `concurrency`, `cycle_slug`, `cycle_hex`. Output: `cycles/<slug>-<hex>/executions.csv` + `benchmark-matrix.csv` + `matrix-summary.md` + filed `D-TEST-NNNN.md` issue files. Pre-estimate cost; surface warning if estimate > budget × 0.8.

### `mode=triage`

Dispatch test-issue-fixer v2 only. Inputs: `trigger=user-direct`, `scope=<scope>`. Output: `FB-NNNN.md` files at `docs/e2e-test/fix-batches/` + grouped issue frontmatter flips.

## Phase 3 — per-agent output review

After each agent returns:

1. Read the agent's reported deliverables.
2. Spot-check 1-2 random artifacts (TC files / issue files / fix-batch files / GitHub issues).
3. Verify registry index updated (`_registry-index.md` §4-§7).
4. Verify cycle folder has the appropriate per-mode entry (cycle-plan.md scope reflects what was actually executed).

## Phase 4 — cycle close

1. **Matrix verification** — for `mode=execute` or `mode=full`: read `cycles/<slug>-<hex>/benchmark-matrix.csv` + `matrix-summary.md`; confirm verdict counts + cost match the executor's report.
2. **Issue-count check** — re-count `docs/e2e-test/issues/*.md` files where frontmatter `status: open` AND `cycle_hex: <this>`. If conditional triage fired in Phase 2, verify fix-batches were authored at `docs/e2e-test/fix-batches/FB-*.md`.
3. **Author cycle-audit.md** — in the cycle folder. Sections: §1 deliverables, §2 verdict summary, §3 cost summary (vs budget), §4 issues filed, §5 anomalies (e.g., all-models-same-failure TCs flagged for test-bug vs model-bug review), §6 deviations from plan (if any), §7 routing handoffs (which fix-batches need human routing).
4. **Update `_registry-index.md` §8** — flip the cycle's row from `audit=pending` to `audit=complete` with link to cycle-audit.md.

## Phase 5 — cleanup

1. Clear any `target/test-tmp/` scratch dirs (in case test-executor used local scratch).
2. If daemon was started: kill it (`pkill -f 'iphi daemon'`).
3. No Cargo clean needed for testing pipeline cycles (no Rust artifacts produced beyond the i-phi build that's already cached).

## Phase 6 — commit

```
git -C /root/projects/phi/i-phi add docs/e2e-test/cycles/<slug>-<hex>/ docs/e2e-test/_registry-index.md docs/e2e-test/test-cases/ docs/e2e-test/issues/ docs/e2e-test/fix-batches/
git -C /root/projects/phi/i-phi commit -m "e2e-test: cycle <hex> mode=<mode> close (verdict <pass>/<partial>/<fail>, $<cost> spent)"
```

User reserves push.

## Phase 7 — report

```
test-pipeline-initiate: <mode> OK
  Cycle hex:           <hex>
  Mode:                <mode>
  Scope:               <human-readable>
  Cohort:              <cohort> (<N> models)
  TCs touched:         <K>
  Verdicts:            pass=<a>, partial=<b>, fail=<c>
  Issues filed:        <D-TEST count>
  Fix-batches:         <FB count> (if triage fired)
  Cost spent:          $<X> of $<budget>
  Runtime:             <T>min
  Executions CSV:      docs/e2e-test/cycles/<slug>-<hex>/executions.csv
  Matrix CSV:          docs/e2e-test/cycles/<slug>-<hex>/benchmark-matrix.csv
  Matrix summary:      docs/e2e-test/cycles/<slug>-<hex>/matrix-summary.md
  Audit:               docs/e2e-test/cycles/<slug>-<hex>/cycle-audit.md
  Commit:              <git-hash>
```

## Boundaries

- **DO NOT** run upstream skills (collect-use-case / develop-roadmap / granularize-use-case / develop-test-strategy). Those are independent + user-invoked separately. This skill consumes their output.
- **DO NOT** exceed `budget_usd` or `max_requests`. Hard caps enforced by test-executor v2.
- **DO NOT** auto-route fix-batches. Output is triage proposals; human routes via `/chunk-initiate` or inline.
- **DO NOT** write to Drive (retired post-T3.6).

## Cross-references

- Agents: `[[test-planner]]` v2, `[[test-executor]]` v2, `[[test-issue-fixer]]` v2
- Plan: `i-phi/docs/v0/proposal/plan/e2e-test/pipeline-architecture.md` §"Master orchestrator skill"
- Memory: `[[feedback_quality_then_cost]]` (LOAD-BEARING)
- Companion skills: `/test-fix-triage` (user-direct fixer trigger), `test-cycle-archive` (utility)
- Upstream prerequisites: accepted strategies (via `/develop-test-strategy` v4), populated benchmarks/{models,cohorts}.toml
- T3.6 storage pivot plan: `/root/.claude/plans/hi-i-would-like-wobbly-naur.md`
