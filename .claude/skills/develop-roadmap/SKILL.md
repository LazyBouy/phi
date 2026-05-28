---
name: develop-roadmap
description: Drafts triaged v1+ roadmap entries from accepted use-cases via the `test-roadmap-curator` agent. Independent upstream skill. Sketch-only (no design); produces `roadmap-entry.md` files for human triage.
---

# develop-roadmap

Convert accepted use cases into triaged v1+ roadmap entries proposing i-phi feature additions. Sketch-only — does NOT design the feature, only triages it. Costs no LLM spend.

## Inputs

| Input | Required? | Default | Notes |
|---|---|---|---|
| `scope` | yes | — | One of: `all` \| `category=X` \| `use_cases=[<slug-list>]` |
| `triage_pass` | no | `draft` | `draft` mints new entries; `review` re-triages existing ones |
| `approval` | no | `yes` | Prompt user before commit |

## Phase 0 — pre-flight

1. Verify `i-phi/docs/e2e-test/roadmap/` exists.
2. Verify each in-scope UC has `status=accepted` (entries with `drafted` are not yet ready).
3. Generate cycle hex.

## Phase 1 — agent dispatch

Spawn `test-roadmap-curator` agent with prompt:

```
scope=<scope>
triage_pass=<draft|review>
cycle_hex=<hex>
project_root=/root/projects/phi/i-phi
```

Agent reads scoped UCs + clusters gaps + drafts roadmap-entry.md files.

## Phase 2 — review

After agent returns:

1. Read each new roadmap-entry file at `docs/e2e-test/roadmap/`.
2. **Block-statement check (LOAD-BEARING per [[feedback_roadmap_only_for_blocking_gaps]])**: every entry's §4 MUST contain a concrete "Without this feature, parent UC `<slug>` cannot complete step `<N>`..." sentence. If ANY entry lacks this, reject the entry + ask the curator to either rewrite with a concrete block-statement OR drop the candidate. Aspirational improvements without a blocking-statement are NOT roadmap entries.
3. Self-check: (a) frontmatter complete; (b) ≥ 1 parent UC cited with block-statement; (c) §4 gap delta concrete + cross-checked against today's i-phi surface; (d) §5 effort estimate has T-shirt size + chunk count + risk axes; (e) §6 priority matches rubric (P0 = ≥2 UCs unblocked AND ≤M effort, etc.); (f) `triage_status=proposed`.
4. Spot-check: pick 1 entry; manually verify the §4 gap is real (grep i-phi source for the cited missing capability).
5. Update `_registry-index.md` §3.

## Phase 3 — approval gate (if `approval=yes`)

Surface via AskUserQuestion:

> "test-roadmap-curator drafted N roadmap entries: P0 [<list>], P1 [<list>], P2 [<list>]. Approve all → commit + flip status to `accepted`, or review individually?"

Options:
- `Approve all P0+P1+P2 → commit with status=accepted`
- `Approve subset → user picks; rest stay status=proposed`
- `Reject all → discard`

`triage_status=accepted` is what graduates an entry from "proposal" to "ready for v1 implementation cycle". The human owns this flip.

## Phase 4 — commit

```
git -C /root/projects/phi/i-phi add docs/e2e-test/roadmap/*.md docs/e2e-test/_registry-index.md
git -C /root/projects/phi/i-phi commit -m "e2e-test: develop roadmap (N entries, K accepted) at cycle <hex>"
```

User reserves push.

## Phase 5 — report

```
develop-roadmap: OK
  Cycle hex:           <hex>
  Entries drafted:     N (P0: a, P1: b, P2: c)
  Entries accepted:    K (post-approval)
  Parent UC coverage:  M of total accepted UCs touched
  Registry updated:    yes
  Commit hex:          <git-hash>
```

## Cross-references

- Agent: `[[test-roadmap-curator]]`
- Template: `i-phi/docs/e2e-test/templates/roadmap-entry.md.template`
- Plan: `i-phi/docs/v0/proposal/plan/e2e-test/pipeline-architecture.md` §"Six skills" #2
- Decision precedent: L8 (develop-roadmap is its own skill, not folded into collect-use-case)
