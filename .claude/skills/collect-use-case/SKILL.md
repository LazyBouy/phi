---
name: collect-use-case
description: Discover real-world AI-agent use cases via web research; produce filled `use-case.md` files in the i-phi repo via the `test-product-strategist` agent. Independent upstream skill (not part of `/test-pipeline-initiate`).
---

# collect-use-case

Discover real-world AI-agent use cases via web research; produces 1-N filled `use-case.md` files in `i-phi/docs/e2e-test/use-cases/`. Costs WebSearch + WebFetch budget (capped). No OpenRouter spend.

## Inputs (slash-command style: `key=value`)

| Input | Required? | Default | Notes |
|---|---|---|---|
| `topic` | yes | — | Seed keywords for WebSearch (e.g., `topic="personal-finance AI agent use cases"`) |
| `max_searches` | no | `5` | Hard cap on combined WebSearch + WebFetch invocations |
| `category` | no | (any) | Restrict to `productivity \| research \| coding \| creative \| ops` |
| `target_uc_count` | no | `3` | Soft target |
| `approval` | no | `yes` | `yes` = always prompt user via AskUserQuestion before committing UCs; `no` = auto-commit if all UCs pass §"Verify" |

## Phase 0 — pre-flight

1. Verify `i-phi/docs/e2e-test/use-cases/` exists. If not, invoke `e2e-test-registry-bootstrap` skill.
2. Verify `i-phi` working tree clean OR confirm any pending changes are unrelated (run `git -C /root/projects/phi/i-phi status --short`).
3. Generate cycle hex: `openssl rand -hex 4` → `cycle_hex`.

## Phase 1 — agent dispatch

Spawn `test-product-strategist` agent with prompt:

```
mode=discover
topic="<topic>"
max_searches=<N>
category_filter="<category-or-none>"
target_uc_count=<N>
cycle_hex=<hex>
project_root=/root/projects/phi/i-phi
```

Agent runs WebSearch + WebFetch + authors 1-N use-case.md files.

## Phase 2 — review

After agent returns:

1. Read each new UC file (`git status --short` shows them as untracked at `docs/e2e-test/use-cases/`).
2. Self-check each: (a) frontmatter complete; (b) §2 cites ≥ 2 URLs; (c) §5 i-phi capability mapping matches the canonical inventory; (d) §6 has 3-5 verb-phrased smaller-UC hints; (e) status=`drafted`.
3. Spot-check 1-2 random claims by re-fetching the cited URL via WebFetch (cross-verifies the agent's WebSearch/WebFetch quality).
4. Update `_registry-index.md` §2 with new rows.

## Phase 3 — approval gate (if `approval=yes`)

Surface to user via AskUserQuestion:

> "test-product-strategist drafted N use cases: [<list-of-slugs>]. Approve all → commit, or review individually?"

Options:
- `Approve all → commit to dev (recommended if Phase 2 self-check passed)`
- `Approve subset → user picks specific UCs to commit`
- `Reject all → discard work`

If `approval=no`, skip this phase + auto-commit unless Phase 2 self-check flagged issues.

## Phase 4 — commit

If approved:

```
git -C /root/projects/phi/i-phi add docs/e2e-test/use-cases/<approved-slug>.md
git -C /root/projects/phi/i-phi add docs/e2e-test/_registry-index.md
git -C /root/projects/phi/i-phi commit -m "e2e-test: collect N use cases at cycle <hex>"
```

User reserves push.

## Phase 5 — report

Print a structured summary:

```
collect-use-case: OK
  Cycle hex:           <hex>
  UCs drafted:         N
  UCs approved:        K (of N)
  Sources cited:       avg M per UC
  Budget used:         WebSearch X / WebFetch Y (cap was Z)
  Registry updated:    yes
  Commit hex:          <git-hash> (on i-phi/dev; user reserves push)
```

## Cross-references

- Agent: `[[test-product-strategist]]`
- Template: `i-phi/docs/e2e-test/templates/use-case.md.template`
- Plan: `i-phi/docs/v0/proposal/plan/e2e-test/pipeline-architecture.md` §"Six skills" #1
