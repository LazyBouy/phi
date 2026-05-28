---
name: e2e-test-registry-bootstrap
description: Bootstrap the e2e-test pipeline registry — verify or create the repo directory tree under i-phi/docs/e2e-test/, ensure the 7 templates exist, and write/refresh _registry-index.md. T3.6 storage pivot (2026-05-28) made the Drive folder/Sheet phases OPTIONAL behind --with-drive=yes (default no). Idempotent: safe to re-run; only creates what's missing.
---

# e2e-test-registry-bootstrap

Bootstrap (or re-verify) the e2e-test pipeline registry on a fresh clone OR an existing checkout. Idempotent.

> **v2 (2026-05-28; T3.6 storage architecture pivot)**: per plan `/root/.claude/plans/hi-i-would-like-wobbly-naur.md` P1 lock, Drive is retired for the pipeline. Phase 3 (Drive folder tree) + Phase 4 (Drive Sheet pre-create) + Phase 5 (Drive ID capture) become OPTIONAL behind `--with-drive=yes`. Default behavior creates repo dirs + verifies templates only. Phase 1 dir list extended with new `strategies/` `test-cases/` `issues/` `fix-batches/` directories. Phase 2 templates list updated to the 4 NEW `.md.template` forms (replaces .gdoc/.gsheet variants).

## When to invoke

- **T1 deliverable**: first-time setup at chunk-CH-TP-01 close
- After cloning the repo to a new machine
- As a sanity sweep at the start of any T-cycle (cheap; touches no test execution)
- After the T3.6 pivot, when verifying repo-side layout integrity

## Inputs

| Input | Required? | Default | Notes |
|---|---|---|---|
| `mode` | no | `bootstrap` | `bootstrap` (create-missing) \| `verify-only` (report-no-create) \| `repair` (replace mismatched IDs in registry) |
| `with_drive` | no | `no` | `yes` runs the legacy Phase 3-6 Drive operations (creates folder tree + Sheets in sandbox account). Default `no` per T3.6 pivot — Drive is retired. |
| `drive_parent` | no | (Drive root "My Drive") | (only if `with_drive=yes`) Drive folder ID to create `i-phi-e2e-test/` inside |

## Pre-flight

1. Confirm working directory is `/root/projects/phi` OR a sibling clone of the outer-phi repo.
2. Confirm i-phi submodule is present + on the `dev` branch.
3. Confirm `/root/projects/phi/.env` exists + chmod is `600` (warn if looser).
4. Confirm `bash /root/projects/phi/.claude/scripts/gh-rest.sh self-test` returns OK (token valid + repo accessible).
5. (Only if `with_drive=yes`) Confirm Drive MCP is authenticated by calling `mcp__claude_ai_Google_Drive__list_recent_files`.

## Phase 1 — Repo directory tree

Idempotent `mkdir -p` of:

```
i-phi/docs/e2e-test/templates/
i-phi/docs/e2e-test/use-cases/
i-phi/docs/e2e-test/roadmap/
i-phi/docs/e2e-test/strategies/       (NEW per T3.6 pivot)
i-phi/docs/e2e-test/test-cases/       (NEW per T3.6 pivot)
i-phi/docs/e2e-test/issues/           (NEW per T3.6 pivot)
i-phi/docs/e2e-test/fix-batches/      (NEW per T3.6 pivot)
i-phi/docs/e2e-test/cycles/
i-phi/docs/e2e-test/benchmarks/
i-phi/docs/v0/proposal/plan/e2e-test/
```

## Phase 2 — Template presence check

Verify these 7 templates exist at `i-phi/docs/e2e-test/templates/` (do NOT recreate; abort with clear message if any are missing — they're hand-authored):

- `use-case.md.template`
- `roadmap-entry.md.template`
- `test-strategy.md.template`        (NEW per T3.6; replaces test-strategy.gdoc.template.md)
- `test-case.md.template`            (NEW per T3.6; replaces test-case.gsheet.columns.md)
- `issue.md.template`                (NEW per T3.6; replaces issue.gsheet-row-and-gdoc.template.md)
- `fix-batch.md.template`            (NEW per T3.6; replaces fix-batch.gdoc.template.md)
- `github-issue-form.yml.template`

Also verify these in-repo artifacts exist (abort + report-missing if not — they're load-bearing):

- `i-phi/docs/e2e-test/_registry-index.md`
- `i-phi/docs/e2e-test/benchmarks/models.toml`
- `i-phi/docs/e2e-test/benchmarks/cohorts.toml`
- `i-phi/docs/v0/proposal/plan/e2e-test/pipeline-architecture.md`
- `i-phi/.github/ISSUE_TEMPLATE/test-pipeline-failure.yml`

## Phase 3 — Drive folder tree (`with_drive=yes` only; OPTIONAL post-T3.6)

> SKIPPED by default. Drive is retired by the e2e-test pipeline post-T3.6. Run only when explicitly bootstrapping a Drive sandbox for parallel/legacy reasons.

For each Drive resource below: search by title under the parent folder; if absent, create via `mcp__claude_ai_Google_Drive__create_file` with `mimeType=application/vnd.google-apps.folder`; if present, reuse the existing folder ID.

```
/i-phi-e2e-test/                                # root folder
  strategies/                                   # subfolder
  issue-bodies/
  fix-batches/
  research-dumps/
  executions/
  benchmark-matrices/
```

## Phase 4 — Persistent Drive Sheets (`with_drive=yes` only; OPTIONAL post-T3.6)

> SKIPPED by default. Drive Sheets are retired (write-once constraint made them unworkable for incremental rows).

For each Sheet below: search by title under root folder; if absent, create via `mcp__claude_ai_Google_Drive__create_file` with `mimeType=application/vnd.google-apps.spreadsheet`; if present, reuse the existing Sheet ID.

- `test-cases-master.gsheet` — columns per (historical) `templates/test-case.gsheet.columns.md`
- `issues-master.gsheet` — columns per (historical) `templates/issue.gsheet-row-and-gdoc.template.md` Part A

## Phase 5 — Capture Drive IDs in `_registry-index.md` (`with_drive=yes` only)

> SKIPPED by default. Post-T3.6 registry §1 is renamed "Drive resources (historical/orphaned — Path A pivot 2026-05-28)".

If `with_drive=yes`, update `i-phi/docs/e2e-test/_registry-index.md` §1 with the new Drive IDs.

## Phase 6 — Drive scope verification (sanity; `with_drive=yes` only)

> SKIPPED by default.

Confirm Drive integration is correctly scoped (no leak to non-Claude-created files):

1. Call `mcp__claude_ai_Google_Drive__search_files` with query `owner = 'me' and not (title contains 'i-phi-e2e-test')`.
2. Expected: empty results array `{}`. Non-empty = scope leak; surface to user.

## Phase 7 — Report

Print a summary:

```
e2e-test-registry-bootstrap: OK (mode=<bootstrap|verify-only|repair>, with_drive=<yes|no>)
  Repo tree:           <created N | verified existing> dirs
  Templates:           7 / 7 present
  Load-bearing files:  <K> / K present
  Drive:               <SKIPPED (default per T3.6 pivot) | created N folders + N Sheets>
  Registry index:      <updated | clean>
```

## Boundaries

- **Does NOT** mint TC-NNNN / D-TEST-NNNN / FB-NNNN counters (those are mint-time concerns of test-planner / test-executor / test-issue-fixer)
- **Does NOT** create the GitHub Issue Template YAML in `i-phi/.github/ISSUE_TEMPLATE/` — that's a one-time human/orchestrator commit at T1; bootstrap only verifies the file's presence
- **Does NOT** install gh-rest.sh dependencies (curl, jq) — assumed present
- **Does NOT** modify .env or any token
- **Does NOT** run Drive ops by default post-T3.6 (Drive retired); only when `with_drive=yes` explicitly passed

## Cross-references

- Plan: `/root/projects/phi/i-phi/docs/v0/proposal/plan/e2e-test/pipeline-architecture.md`
- Memory: `[[feedback_drive_file_scope_unreliable]]` — folder-restriction caveats (relevant only when `with_drive=yes`)
- Memory: `[[feedback_quality_then_cost]]` — agents must respect cost-sensitivity (downstream concern; this skill is free to run)
- T3.6 storage pivot plan: `/root/.claude/plans/hi-i-would-like-wobbly-naur.md`
