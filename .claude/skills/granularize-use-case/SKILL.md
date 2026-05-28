---
name: granularize-use-case
description: Decompose accepted use cases into 3-5 smaller testable use-cases per UC via `test-strategist mode=granularize`. Independent upstream skill. Writes back into the parent UC's §6 (canonical handoff to develop-test-strategy).
---

# granularize-use-case

Refines accepted UCs by decomposing them into smaller testable units. The output lives in the parent UC's §6 (NOT separate files). The downstream consumer `develop-test-strategy` reads from §6 to author strategies per smaller UC.

## Inputs

| Input | Required? | Default | Notes |
|---|---|---|---|
| `use_cases` | yes | — | List of UC slugs (must be `status=accepted`) |
| `approval` | no | `yes` | Prompt user before commit |

## Phase 0 — pre-flight

1. For each `use_cases[]` slug, verify the file exists + `status=accepted`. Reject the cycle if any UC is `drafted` or `rejected`.
2. Generate cycle hex.

## Phase 1 — agent dispatch

Spawn `test-strategist` agent with:

```
mode=granularize
use_cases=[<slug-list>]
cycle_hex=<hex>
project_root=/root/projects/phi/i-phi
```

Agent reads each UC + decomposes into 3-5 smaller testable UCs + writes back into §6.

## Phase 2 — review

After agent returns:

1. For each updated UC, diff §6 before/after.
2. Self-check: (a) 3-5 smaller UCs per parent; (b) each line has a `UC-<TAG>-<N>` id + verb-phrase + scope; (c) non-overlapping coverage; (d) collectively cover the parent's §3 happy path; (e) any divergence from product-strategist's original hints is documented in `[granularizer rationale: ...]` notes.
3. Update `_registry-index.md` §2 with `granularized at cycle <hex>` annotation per UC.

## Phase 3 — approval gate

Surface via AskUserQuestion:

> "test-strategist granularized N UCs into K smaller testable units. Sample: `UC-PAYBILL-1 — User pays a single bill via Telegram`, `UC-PAYBILL-2 — User schedules a recurring bill`, ... Approve or review?"

Options:
- `Approve all → commit (recommended)`
- `Review per-UC → user inspects each diff individually`
- `Reject → revert §6 changes`

## Phase 4 — commit

```
git -C /root/projects/phi/i-phi add docs/e2e-test/use-cases/*.md docs/e2e-test/_registry-index.md
git -C /root/projects/phi/i-phi commit -m "e2e-test: granularize N use cases at cycle <hex>"
```

User reserves push.

## Phase 5 — report

```
granularize-use-case: OK
  Cycle hex:           <hex>
  UCs processed:       N
  Smaller UCs minted:  K (avg <K/N> per parent)
  Coverage:            all parent §3 happy paths covered
  Commit hex:          <git-hash>
```

## Cross-references

- Agent: `[[test-strategist]]` mode=granularize
- Plan: `i-phi/docs/v0/proposal/plan/e2e-test/pipeline-architecture.md` §"Six skills" #3
- Downstream consumer: `/develop-test-strategy`
