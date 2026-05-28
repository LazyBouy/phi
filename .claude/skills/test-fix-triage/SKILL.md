---
name: test-fix-triage
description: User-direct trigger for test-issue-fixer (the third trigger condition alongside threshold-global ≥10 and threshold-per-uc ≥3). Lets the user batch-triage open issues at any point without waiting for thresholds. Triage-only (no auto-patching).
---

# test-fix-triage

User-direct entrypoint for `test-issue-fixer`. Lets you trigger triage on any subset of open D-TEST issues at any time, bypassing the automatic threshold-based firing inside `/test-pipeline-initiate mode=triage` or `mode=full`.

## When to use this vs `/test-pipeline-initiate mode=triage`

- **`/test-fix-triage`** (this skill): you want to triage a specific subset NOW. Example: "all open issues for TC-0042" or "all open issues against qwen/qwen3-coder" or "the 6 issues filed yesterday I want grouped before tomorrow's exec cycle".
- **`/test-pipeline-initiate mode=triage`**: full triage cycle with the orchestrator's Phase 0-7 gates; produces a cycle folder + audit; appropriate at scheduled triage cadences.

This skill is the lighter-weight path. No cycle folder; no audit. Just: cluster + author FB-NNNN Docs + GitHub-comment the member issues.

## Inputs

| Input | Required? | Default | Notes |
|---|---|---|---|
| `scope` | yes | — | One of: `all-open` (all `status=open` issues) \| `tcs=[<id-list>]` \| `use-cases=[<slug-list>]` \| `models=[<slug-list>]` \| `issues=[<D-TEST-id-list>]` |
| `min_cluster_size` | no | `3` | Below this, members go to a singletons Doc OR get folded into an existing cluster |
| `approval` | no | `yes` | Prompt user before authoring fix-batches |

## Phase 0 — pre-flight

1. Verify Drive MCP responsive.
2. Verify `bash gh-rest.sh self-test` returns OK.
3. Read `issues-master.gsheet` rows matching scope filter; report count to user.
4. Generate cycle hex.

## Phase 1 — agent dispatch

Spawn `test-issue-fixer` with:

```
trigger=user-direct
scope=<scope>
min_cluster_size=<N>
cycle_hex=<hex>
project_root=/root/projects/phi/i-phi
```

Agent clusters issues + drafts FB-NNNN fix-batch Drive Docs + posts GitHub comments linking member issues to the batch.

## Phase 2 — review

After agent returns:

1. For each new FB-NNNN Doc URL, fetch via Drive MCP `read_file_content`.
2. Self-check: (a) §1 cluster theme is evidence-backed; (b) §3 root-cause hypothesis cites specific transcript lines or code patterns (not vague); (c) §4 fix proposals are ranked by quality-impact ÷ effort; (d) §5 human-routing recommendation matches the cluster's character.
3. Confirm member issues' Sheet rows flipped to `status=grouped` with `fix_batch_id` populated.
4. Confirm GitHub issues received the linking comment via `gh-rest.sh issue-pull <issue#>`.

## Phase 3 — approval gate

Surface via AskUserQuestion:

> "test-issue-fixer drafted N fix-batches: [<FB-list>]. Recommended routings: <K> via /chunk-initiate, <M> inline, <P> defer. Approve registry update, or review individually?"

Options:
- `Approve all → commit registry (recommended)`
- `Reject all → revert grouping (flip Sheet rows back to open)`

The fix-batch Docs themselves stay in Drive regardless; the registry-index update is what graduates them from "drafted" to "tracked".

## Phase 4 — commit

```
git -C /root/projects/phi/i-phi add docs/e2e-test/_registry-index.md
git -C /root/projects/phi/i-phi commit -m "e2e-test: user-direct triage at cycle <hex> (N fix-batches, K issues grouped)"
```

User reserves push.

## Phase 5 — report

```
test-fix-triage: OK
  Cycle hex:           <hex>
  Trigger:             user-direct
  Scope:               <human-readable>
  Issues processed:    <K>
  Fix-batches minted:  <N>
  Singletons:          <S> (in misc-singletons-<hex> Doc if any)
  Recommended routing: /chunk-initiate=<a>, inline=<b>, defer=<c>, not-bug=<d>
  Commit hex:          <git-hash>

Next step: human reviews each FB-NNNN Doc and routes per §5 recommendation.
```

## Boundaries

- **DO NOT** auto-route fix-batches (e.g., don't invoke `/chunk-initiate` automatically). Human routes.
- **DO NOT** close GitHub issues. Only `open → grouped` flips here; `closed` flip happens when the routed chunk lands.
- **DO NOT** lower the min_cluster_size to fragment N clusters of 1 — under-clustering wastes triage effort.

## Cross-references

- Agent: `[[test-issue-fixer]]`
- Template: `i-phi/docs/e2e-test/templates/fix-batch.gdoc.template.md`
- Plan: `i-phi/docs/v0/proposal/plan/e2e-test/pipeline-architecture.md` §"Six skills" #6 + L9 trigger conditions
- Companion: `/test-pipeline-initiate mode=triage` (cycle-folder + audit variant)
