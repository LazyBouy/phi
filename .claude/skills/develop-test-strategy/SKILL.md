---
name: develop-test-strategy
description: Authors N sibling test-strategy Docs per granularized smaller UC via `test-strategist mode=develop-strategy`. First Drive-write skill in the e2e-test pipeline. Independent upstream skill.
---

# develop-test-strategy

For each granularized smaller UC, author N=1-3 sibling strategy Drive Docs (each taking a different path to the same smaller UC). This is the first Drive-write skill — it produces the canonical strategy artifacts that downstream `test-planner` reads to mint TCs.

## Inputs

| Input | Required? | Default | Notes |
|---|---|---|---|
| `use_cases` | yes | — | List of UC slugs whose §6 smaller-UCs need strategies (must be granularized) |
| `strategies_per_uc` | no | `2` | Target N sibling strategies per smaller UC |
| `approval` | no | `yes` | Prompt user before commit |

## Phase 0 — pre-flight

1. Verify each UC in scope has `status=accepted` AND a granularized §6 (≥ 1 line matching `UC-<TAG>-<N>` format).
2. Verify Drive MCP responsive via `mcp__claude_ai_Google_Drive__search_files` query.
3. Read `_registry-index.md` §1 for `strategies/` folder ID + ensure subfolder exists.
4. Generate cycle hex.

## Phase 1 — agent dispatch

Spawn `test-strategist` agent with:

```
mode=develop-strategy
use_cases=[<slug-list>]
strategies_per_uc=<N>
cycle_hex=<hex>
project_root=/root/projects/phi/i-phi
drive_parent_folder_id=<strategies-folder-id-from-registry>
```

Agent reads each granularized §6 + authors strategies for each smaller UC + creates Drive Docs.

## Phase 2 — review

After agent returns:

1. For each Strategy Doc URL, fetch via `mcp__claude_ai_Google_Drive__read_file_content`.
2. Self-check per strategy: (a) frontmatter complete; (b) §2 strategy approach is clearly differentiated from siblings (cite differentiator axis: interface / tool-path / multi-turn / permission); (c) §4 task pipeline has ≥ 3 executable steps grounded in actual i-phi surfaces; (d) §5 surfaces list non-empty; (e) §6 TC allocation hints have measurement axes; (f) §3 sibling cross-refs populated (all N sibling URLs included).
3. Spot-check: pick 1 strategy; verify §4 task pipeline step 1 cites a real i-phi command/route.
4. Update `_registry-index.md` §4 with new rows: `slug | parent_UC | smaller_UC | n_of_m | interface | status=drafted | Doc URL`.

## Phase 3 — approval gate

Surface via AskUserQuestion:

> "test-strategist developed N strategies across K smaller UCs. Cohort coverage: <interface distribution + sibling-diversity summary>. Approve all → flip status to `accepted` in registry; or review individually?"

Options:
- `Approve all → commit registry + flip status=accepted`
- `Review per-strategy → user picks individual approvals`
- `Reject → mark in registry as drafted, hold for review`

## Phase 4 — commit

```
git -C /root/projects/phi/i-phi add docs/e2e-test/_registry-index.md
git -C /root/projects/phi/i-phi commit -m "e2e-test: develop N strategies for K smaller UCs at cycle <hex>"
```

Note: strategy bodies live in Drive (not the repo). Only the registry-index update commits to git.

User reserves push.

## Phase 5 — report

```
develop-test-strategy: OK
  Cycle hex:           <hex>
  Smaller UCs covered: K
  Strategies authored: N (Drive Docs)
  Interface dist:      CLI: a, HTTP: b, Telegram: c, Web: d
  Sibling diversity:   avg <N>-of-<M> per smaller UC
  Drive folder:        strategies/ (M total Docs after this cycle)
  Commit hex:          <git-hash> (registry update only; strategy bodies in Drive)
```

## Cross-references

- Agent: `[[test-strategist]]` mode=develop-strategy
- Template: `i-phi/docs/e2e-test/templates/test-strategy.gdoc.template.md`
- Plan: `i-phi/docs/v0/proposal/plan/e2e-test/pipeline-architecture.md` §"Six skills" #4
- Drive folder: `i-phi-e2e-test/strategies/` (ID `1O0VcR_hmGwOOW52KDhJtYcqgaNh4ttVc`)
- Downstream consumer: `/test-pipeline-initiate mode=plan` (test-planner reads accepted strategies)
