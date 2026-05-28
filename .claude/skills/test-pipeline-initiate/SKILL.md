---
name: test-pipeline-initiate
description: Master orchestrator skill for the e2e-test pipeline. Modes: `full` (plan → execute → conditional triage), `plan` (test-planner only), `execute` (test-executor only), `triage` (test-issue-fixer only). Consumes accepted strategies + OpenRouter cohorts → produces TCs, executions, matrix, issues, fix-batches. Enforces budget + max-requests guardrails.
---

# test-pipeline-initiate

Master orchestrator skill for the i-phi e2e-test pipeline. Runs the **downstream** half of the pipeline (test-planner → test-executor → test-issue-fixer). The upstream skills (`/collect-use-case`, `/develop-roadmap`, `/granularize-use-case`, `/develop-test-strategy`) run independently outside this skill.

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
3. **Verify Drive MCP** — call `mcp__claude_ai_Google_Drive__search_files` with a benign query.
4. **Verify gh-rest.sh** — `bash /root/projects/phi/.claude/scripts/gh-rest.sh self-test` → expect `OK: authenticated`.
5. **Verify i-phi buildable** — `cargo build --manifest-path /root/projects/phi/i-phi/Cargo.toml -j 4` (cached after first build; ~free on warm cargo cache).
6. **Mint cycle folder** — invoke `test-cycle-archive` skill: it generates 8-hex cycle ID + creates `i-phi/docs/e2e-test/cycles/<slug>-<hex>/cycle-plan.md` + appends row to `_registry-index.md` §8.

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

Sequential: test-planner → test-executor → conditional test-issue-fixer.

1. **test-planner**: mint TCs from accepted strategies; bind `models_in_scope` to `<cohort>`.
2. **test-executor**: iterate minted TCs × cohort; produce executions Sheet + benchmark-matrix.
3. **Issue threshold check**: count newly-filed D-TEST issues this cycle. If ≥ 10 global OR ≥ 3 per-UC → dispatch test-issue-fixer with `trigger=threshold-{global|per-uc}`.

### `mode=plan`

Dispatch test-planner only. Inputs: `strategies=<scope>`, `cohort_default=<cohort>`. Output: N new TC rows in `test-cases-master.gsheet`.

### `mode=execute`

Dispatch test-executor only. Inputs: `tcs=<scope>`, `cohort_override=<cohort>` (if provided), `budget_usd`, `max_requests`, `concurrency`. Output: executions Sheet + matrix + filed issues. Pre-estimate cost; surface warning if estimate > budget × 0.8.

### `mode=triage`

Dispatch test-issue-fixer only. Inputs: `trigger=user-direct`, `scope=<scope>`. Output: FB-NNNN Drive Docs + grouped issue rows.

## Phase 3 — per-agent output review

After each agent returns:

1. Read the agent's reported deliverables.
2. Spot-check 1-2 random artifacts (Sheet rows / Drive Docs / GitHub issues).
3. Verify registry index updated.
4. Verify cycle folder has the appropriate per-mode entry (cycle-plan.md scope reflects what was actually executed).

## Phase 4 — cycle close

1. **Matrix verification** — for `mode=execute` or `mode=full`: read `benchmark-matrices/<cycle-hex>.gsheet` _summary tab; confirm verdict counts + cost match the executor's report.
2. **Issue-count check** — re-count `issues-master.gsheet` rows where `status=open` AND `cycle_hex=<this>`. If conditional triage fired in Phase 2, verify fix-batches were authored.
3. **Author cycle-audit.md** — in the cycle folder. Sections: §1 deliverables, §2 verdict summary, §3 cost summary (vs budget), §4 issues filed, §5 anomalies (e.g., all-models-same-failure TCs flagged for test-bug vs model-bug review), §6 deviations from plan (if any), §7 routing handoffs (which fix-batches need human routing).
4. **Update `_registry-index.md` §8** — flip the cycle's row from `audit=pending` to `audit=complete` with link to cycle-audit.md.

## Phase 5 — cleanup

1. Clear any `target/test-tmp/` scratch dirs (in case test-executor used local scratch).
2. If daemon was started: kill it (`pkill -f 'iphi daemon'`).
3. No Cargo clean needed for testing pipeline cycles (no Rust artifacts produced beyond the i-phi build that's already cached).

## Phase 6 — commit

```
git -C /root/projects/phi/i-phi add docs/e2e-test/cycles/<slug>-<hex>/ docs/e2e-test/_registry-index.md
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
  Matrix:              <Sheet URL>
  Audit:               <cycle-audit.md path>
  Commit:              <git-hash>
```

## Boundaries

- **DO NOT** run upstream skills (collect-use-case / develop-roadmap / granularize-use-case / develop-test-strategy). Those are independent + user-invoked separately. This skill consumes their output.
- **DO NOT** exceed `budget_usd` or `max_requests`. Hard caps enforced by test-executor.
- **DO NOT** auto-route fix-batches. Output is triage proposals; human routes via `/chunk-initiate` or inline.

## Cross-references

- Agents: `[[test-planner]]`, `[[test-executor]]`, `[[test-issue-fixer]]`
- Plan: `i-phi/docs/v0/proposal/plan/e2e-test/pipeline-architecture.md` §"Master orchestrator skill"
- Memory: `[[feedback_quality_then_cost]]` (LOAD-BEARING)
- Companion skills: `/test-fix-triage` (user-direct fixer trigger), `test-cycle-archive` (utility)
- Upstream prerequisites: accepted strategies (via `/develop-test-strategy`), populated benchmarks/{models,cohorts}.toml
