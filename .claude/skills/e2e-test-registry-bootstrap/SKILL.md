---
name: e2e-test-registry-bootstrap
description: Bootstrap the e2e-test pipeline registry — verify or create the repo directory tree under i-phi/docs/e2e-test/, ensure the 7 templates exist, mint the Drive root folder /i-phi-e2e-test/ + sub-tree + persistent Sheets, and write/refresh _registry-index.md with the resulting Drive IDs. Idempotent: safe to re-run; only creates what's missing.
---

# e2e-test-registry-bootstrap

Bootstrap (or re-verify) the e2e-test pipeline registry on a fresh clone OR an existing checkout. Idempotent.

## When to invoke

- **T1 deliverable**: first-time setup at chunk-CH-TP-01 close
- After cloning the repo to a new machine and the local Drive sandbox account is re-authenticated
- When the user manually deletes/moves Drive resources and the `_registry-index.md` Drive-IDs need re-discovery
- As a sanity sweep at the start of any T-cycle (cheap; touches no test execution)

## Inputs

| Input | Required? | Default | Notes |
|---|---|---|---|
| `mode` | no | `bootstrap` | `bootstrap` (create-missing) \| `verify-only` (report-no-create) \| `repair` (replace mismatched IDs in registry) |
| `drive_parent` | no | (Drive root "My Drive") | Drive folder ID to create `i-phi-e2e-test/` inside; default = sandbox account root |
| `skip_drive` | no | `no` | `yes` skips Drive ops entirely (useful for fresh-clone repo-only setup before Drive auth) |

## Pre-flight

1. Confirm working directory is `/root/projects/phi` OR a sibling clone of the outer-phi repo.
2. Confirm i-phi submodule is present + on the `dev` branch.
3. Confirm `/root/projects/phi/.env` exists + chmod is `600` (warn if looser).
4. If `skip_drive=no`: confirm Drive MCP is authenticated by calling `mcp__claude_ai_Google_Drive__list_recent_files` (any non-error response confirms auth). If `mcp__claude_ai_Google_Drive__authenticate` surfaces as a deferred tool again, auth has lapsed → abort + tell the user to re-auth (see [pipeline-architecture.md](../../../../i-phi/docs/v0/proposal/plan/e2e-test/pipeline-architecture.md) § "Google Drive setup").
5. Confirm `bash /root/projects/phi/.claude/scripts/gh-rest.sh self-test` returns OK (token valid + repo accessible).

## Phase 1 — Repo directory tree

Idempotent `mkdir -p` of:

```
i-phi/docs/e2e-test/templates/
i-phi/docs/e2e-test/use-cases/
i-phi/docs/e2e-test/roadmap/
i-phi/docs/e2e-test/cycles/
i-phi/docs/e2e-test/benchmarks/
i-phi/docs/v0/proposal/plan/e2e-test/
```

## Phase 2 — Template presence check

Verify these 7 templates exist at `i-phi/docs/e2e-test/templates/` (do NOT recreate; abort with clear message if any are missing — they're hand-authored):

- `use-case.md.template`
- `roadmap-entry.md.template`
- `test-strategy.gdoc.template.md`
- `test-case.gsheet.columns.md`
- `issue.gsheet-row-and-gdoc.template.md`
- `fix-batch.gdoc.template.md`
- `github-issue-form.yml.template`

Also verify these in-repo artifacts exist (abort + report-missing if not — they're load-bearing):

- `i-phi/docs/e2e-test/_registry-index.md`
- `i-phi/docs/e2e-test/benchmarks/models.toml`
- `i-phi/docs/e2e-test/benchmarks/cohorts.toml`
- `i-phi/docs/v0/proposal/plan/e2e-test/pipeline-architecture.md`
- `i-phi/.github/ISSUE_TEMPLATE/test-pipeline-failure.yml`

## Phase 3 — Drive folder tree (`skip_drive=no` only)

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

## Phase 4 — Persistent Drive Sheets

For each Sheet below: search by title under root folder; if absent, create via `mcp__claude_ai_Google_Drive__create_file` with `mimeType=application/vnd.google-apps.spreadsheet`; if present, reuse the existing Sheet ID. Initial column-header row should be paste-loaded from the respective `templates/*.columns.md` file's "Initial header row" section.

- `test-cases-master.gsheet` — columns per `templates/test-case.gsheet.columns.md`
- `issues-master.gsheet` — columns per `templates/issue.gsheet-row-and-gdoc.template.md` Part A

## Phase 5 — Capture Drive IDs in `_registry-index.md`

Update `i-phi/docs/e2e-test/_registry-index.md` §1 "Drive resources" table:
- Each row's `Drive ID` column ← immutable Drive ID from MCP response
- Each row's `View URL` ← `https://drive.google.com/drive/folders/<ID>` for folders OR `https://docs.google.com/spreadsheets/d/<ID>/edit` for Sheets
- `Created at` ← today's date (or original creation date for already-existing resources)

## Phase 6 — Drive scope verification (sanity)

Confirm Drive integration is correctly scoped (no leak to non-Claude-created files):

1. Call `mcp__claude_ai_Google_Drive__search_files` with query `owner = 'me' and not (title contains 'i-phi-e2e-test')`.
2. Expected: empty results array `{}`. Non-empty = scope leak; surface to user + recommend the sandbox-account re-auth procedure.

## Phase 7 — Report

Print a summary:

```
e2e-test-registry-bootstrap: OK
  Repo tree:           <created N | verified existing>
  Templates:           7 / 7 present
  Drive root:          <Drive ID> (<created | reused>)
  Drive sub-folders:   6 / 6 (<N created, N reused>)
  Drive Sheets:        2 / 2 (<created | reused>)
  Scope verification:  PASS  (Claude sees only e2e-test files)
  Registry index:      updated with N Drive IDs
```

## Boundaries

- **Does NOT** mint TC-NNNN / D-TEST-NNNN / FB-NNNN counters (those are mint-time concerns of test-planner / test-executor / test-issue-fixer)
- **Does NOT** create the GitHub Issue Template YAML in `i-phi/.github/ISSUE_TEMPLATE/` — that's a one-time human/orchestrator commit at T1; bootstrap only verifies the file's presence
- **Does NOT** install gh-rest.sh dependencies (curl, jq) — assumed present
- **Does NOT** modify .env or any token

## Cross-references

- Plan: `/root/projects/phi/i-phi/docs/v0/proposal/plan/e2e-test/pipeline-architecture.md`
- Memory: `[[feedback_drive_file_scope_unreliable]]` — folder-restriction caveats
- Memory: `[[feedback_quality_then_cost]]` — agents must respect cost-sensitivity (downstream concern; this skill is free to run)
