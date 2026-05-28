---
name: publish-to-drive
description: Publish a curated subset of e2e-test pipeline artifacts (use-cases, roadmap, per-cycle audit + matrix-summary, registry index) to Google Drive Docs under `/i-phi-e2e-test/publish/` via the test-publish-curator agent. On-demand only (no post-cycle hook). Idempotent + supersede-safe via in-place markdown updates. Repo stays canonical + transactional; Drive is a non-blocking read-only mirror for non-technical stakeholders.
---

# publish-to-drive

On-demand skill that mirrors specific human-readable pipeline artifacts to Google Drive. Repo + GitHub remain the transactional source of truth (per T3.6 storage pivot 2026-05-28); Drive is a read-only stakeholder-facing mirror, refreshed when you say so.

## When to invoke

- After a cycle closes and you want stakeholders to see the matrix-summary + cycle-audit.
- After a UC or roadmap entry lands and you want the new artifact published.
- After multiple cycles have closed without a publish (batch catch-up via `scope=all-cycles`).
- On-demand for any other reason. **No automatic post-cycle hook fires** — by design.

## Quality + cost discipline

- **Quality first** ([[feedback_quality_then_cost]]): every published Doc must render cleanly for a non-technical reader. If the smoke run surfaces markdown-conversion issues, fix the source markdown OR escalate; don't ship noisy Docs.
- **Cost-sensitive**: sonnet model for the publish-curator + free Drive personal-account quota. Typical run: 1-10 Docs created/updated + 4-6 folders ensured = ~30-60 MCP calls.
- **Non-blocking**: this skill never blocks pipeline cycles. It's invoked separately + completes independently.

## Inputs

| Input | Required? | Default | Notes |
|---|---|---|---|
| `scope` | yes | — | `latest` \| `all-cycles` \| `cycle=<hex>` \| `artifact-types=<csv>` (e.g. `use-cases,roadmap` only) |
| `dry_run` | no | `no` | `yes` returns manifest preview without writing |
| `approval` | no | `yes` | When `yes`, AskUserQuestion the manifest preview before dispatching |
| `project_root` | no | `/root/projects/phi/i-phi` | Path to i-phi clone |

## Phase 0 — pre-flight

1. **Verify env vars exist** in `.env`: `grep -cE '^GOOGLE_DOCS_MCP_(CLIENT_ID|CLIENT_SECRET|ROOT_FOLDER_ID)=' /root/projects/phi/.env` → expect ≥ 3.
2. **Verify launch wrapper exists**: `test -x /root/projects/phi/.claude/scripts/launch-google-docs-mcp.sh`.
3. **Verify MCP reachable**: invoke a trivial `mcp__a-bonus-google-docs__listDriveFiles` (or `listDocuments` — pick whichever the MCP exposes per `claude mcp get a-bonus-google-docs`) with `pageSize=1`. If the call fails with auth error → tell user to run `claude mcp` UI's OAuth flow + retry. **First-run case**: the OAuth browser flow lands on first MCP call; user completes consent, refresh token persists at `~/.config/google-docs-mcp/token.json`.
4. **Verify i-phi working tree is clean on dev**: `git -C /root/projects/phi/i-phi status --porcelain | wc -l` → expect 0. If dirty, abort + tell user to commit or stash first (publishing uncommitted state creates non-reproducible stakeholder artifacts).
5. **Verify scope resolves to non-empty manifest** via a Glob preview (no MCP calls yet).

## Phase 1 — manifest preview (always, even if `approval=no`)

Dispatch `test-publish-curator` agent with `dry_run=yes`. Agent returns a manifest. Orchestrator renders it as a table to the user:

```
SCOPE: <scope-arg>
Manifest (would-publish):
  use-cases/research-brief-synthesis.md          → publish/use-cases/research-brief-synthesis.gdoc          [CREATE]
  cycles/t4-openrouter-smoke-e436c4c9/cycle-audit.md → publish/cycles/t4-openrouter-smoke-e436c4c9/cycle-audit.gdoc [CREATE]
  ...

Summary: would-create=6, would-update=0, would-skip=0, total=6
```

If `approval=yes` (default), AskUserQuestion with options: **Approve / Edit scope / Cancel**.

## Phase 2 — agent dispatch (real publish)

Re-dispatch `test-publish-curator` agent with `dry_run=no` and the approved scope. Agent runs Phase A-D of its own procedure. Returns the executed manifest with per-row status (`published|updated|skipped|error`) + Doc URLs.

If the agent reports `error` rows (e.g., 429 abort with partial state), surface them to the user + offer to re-run (the agent is idempotent; re-run skips already-published rows by hash).

## Phase 3 — registry update

For every `published` or `updated` row in the executed manifest, append/update a row in `_registry-index.md` §10:

```markdown
| <repo_path> | <drive_doc_url> | <content_hash> | <ISO-8601-timestamp> | <scope-tag> |
```

If the row already exists for that `repo_path`, REPLACE it with the new content_hash + timestamp (don't accumulate duplicates).

Atomic via `Read` + `Edit` (or `MultiEdit` if many rows).

## Phase 4 — commit

```
git -C /root/projects/phi/i-phi add docs/e2e-test/_registry-index.md
git -C /root/projects/phi/i-phi commit -m "e2e-test: publish to Drive — <scope-tag> (<N> created, <M> updated)"
```

User reserves push. outer-phi has no diff in publish runs (the launcher + .mcp.json are unchanged at this point).

## Phase 5 — report

```
publish-to-drive: OK
  Scope:                <scope-arg>
  Folders ensured:      <N>
  Docs created:         <count>
  Docs updated:         <count>
  Docs skipped:         <count>
  Docs errored:         <count>
  Drive root URL:       https://drive.google.com/drive/folders/<root-id>/publish/
  Commit:               <git-hash>
```

If any rows errored, INCLUDE a re-run hint: `bash /root/projects/phi/.claude/scripts/launch-google-docs-mcp.sh # verify MCP reachable` + `/publish-to-drive scope=<same>` (idempotent — already-published rows skip).

## Boundaries

- **DO NOT** run any other pipeline skill (collect-use-case / develop-roadmap / etc.) as part of publish. This skill is strictly publish-only.
- **DO NOT** edit or delete repo artifacts. Read-only against repo.
- **DO NOT** auto-publish post-cycle. The user invokes this skill explicitly.
- **DO NOT** publish a dirty working tree (Phase 0 step 4).
- **DO NOT** publish CSVs (`executions.csv` / `benchmark-matrix.csv`) — they stay in repo. The human-readable `matrix-summary.md` is the publish target.

## Cross-references

- Agent: `[[test-publish-curator]]`
- MCP server config: `/root/projects/phi/.mcp.json`
- MCP launcher: `/root/projects/phi/.claude/scripts/launch-google-docs-mcp.sh`
- Memory: `[[feedback_quality_then_cost]]`, `[[feedback_drive_mcp_write_once]]`, `[[feedback_drive_file_scope_unreliable]]`, `[[feedback_publish_agent_supersede_semantics]]`
- e2e-test pipeline plan: `/root/projects/phi/i-phi/docs/v0/proposal/plan/e2e-test/pipeline-architecture.md`
- Publish-agent build plan: `/root/.claude/plans/hi-i-would-like-wobbly-naur.md`
