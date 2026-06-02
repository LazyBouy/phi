---
name: propagate-fixes
description: Propagate i-phi runtime defect fixes from the phi-e2e worktree (dev-v0-e2e) to the phi-v05 worktree (dev-v0.5) as a reviewed GitHub PR on LazyBouy/i-phi. On-demand backport orchestrator — dispatches the backport-propagator agent to judge relevance, prepares + CI-gates the cherry-pick, pushes + opens a PR (no auto-merge), then optionally bumps the parent gitlink after merge.
---

# propagate-fixes

Two-stage, i-phi-PR-first backport flow. **Stage 1** opens a reviewed PR; **stage 2** bumps the parent
gitlink after a human merges it. You (the orchestrator) drive the remote-mutating steps so they are
visible to the user; the `backport-propagator` agent owns only relevance judgment.

The fix lives in i-phi *code* → only an i-phi PR shows a reviewable diff + runs CI. The parent `phi`
repo stores only a gitlink; bumping it is a thin downstream consequence (stage 2).

## Artifacts

- `backport-propagate.sh --scan|--prepare` — deterministic driver (filters, cherry-pick, CI). Never pushes.
- `backport-push.sh` — stage-1 remote step (push base+head, open PR). Allow-listed; no auto-merge.
- `backport-bump.sh` — stage-2 parent gitlink bump (local commit). Allow-listed.
- `backport-propagator` agent — judgment-only; returns per-candidate verdicts + PR drafts.
- `gh-rest.sh pr-create` — the GitHub PR call (curl wrapper; repo pinned LazyBouy/i-phi).
- `report.md.template` — skeleton for the run report.
- `.last-scan` (gitignored) — last-seen drift-ids, for the scheduled scan-notifier.

## Stage 1 — open the backport PR (the default `/propagate-fixes` run)

1. **Scan + judge.** Dispatch the `backport-propagator` agent (it runs `--scan`, reads each
   candidate's diff + drift doc, returns a JSON verdict block). If `candidates: []`, render the report
   with the "no portable candidates" outcome and STOP — this is a normal result, not a failure.

2. **Confirm scope.** Surface the portable candidates (sha, drift-id, rationale) to the user. Because
   the run is fully autonomous through PR-open, give the user a chance to deselect any candidate
   before preparing. (Default: proceed with all `portable: true`.)

3. **Prepare + CI-gate**, per selected candidate (key on its `primary_drift_id`):
   ```bash
   bash /root/projects/phi/.claude/scripts/backport-propagate.sh --prepare <primary-drift-id>
   ```
   - Runs the cherry-pick in a throwaway worktree (the user's dev-v0.5 checkout is never touched) +
     the 4 CI guards + clippy + test under the v05 cargo tag.
   - Exit `0 GREEN <branch> <sha>` → continue. Exit `20/21/22/23` → this candidate failed
     (conflict / guard / clippy / test); record the stderr diagnostic in the report and SKIP it (no PR).
   - **Tip:** run once with `--dry-run` appended first if you want to preview the cherry-pick plan.

4. **Write the PR body.** Write the agent's `pr_body` markdown to a temp file under this skill dir,
   e.g. `/root/projects/phi/.claude/skills/propagate-fixes/.pr-body-<drift-id>.md` (gitignored).

5. **Push + open PR** (fully autonomous; no merge):
   ```bash
   bash /root/projects/phi/.claude/scripts/backport-push.sh \
     --branch backport/<primary-drift-id> \
     --title "<agent pr_title>" \
     --body-file /root/projects/phi/.claude/skills/propagate-fixes/.pr-body-<drift-id>.md
   ```
   Base-before-head push order is handled inside the script (bootstraps `dev-v0.5` on origin on first
   run). On success it prints the created PR's JSON (capture `html_url`).

6. **Report.** Render `report.md.template`: per candidate — prepared/green | conflict | red-CI |
   skipped-not-portable, with the PR URL for opened ones. Hand the PR URL(s) to the user to review +
   merge.

## Stage 2 — bump the parent gitlink (after the human merges the PR)

Run once the i-phi PR is merged on GitHub:
```bash
bash /root/projects/phi/.claude/scripts/backport-bump.sh --drift-id <primary-drift-id>
```
Advances the parent phi-v05 worktree's i-phi submodule to the merged `origin/dev-v0.5` tip and records
a local `i-phi submodule bump: backport <id> to v0.5 (<sha>)` commit. Local commit, not a PR (the
parent v0.5 line is local-only today).

## Preconditions

- The phi-v05 worktree's `dev-v0.5` should be in sync with `origin/dev-v0.5` before backporting, so
  the PR diff stays clean. (`backport-push.sh` fetches origin but does not rebase your local base.)
- `gh-rest.sh self-test` should pass (token + repo access) before the first PR of a session.

## Scheduled scan-notifier (secondary trigger)

A read-only watcher, set up via `/schedule` or `/loop`, that only nudges the user when new work appears:
1. `bash /root/projects/phi/.claude/scripts/backport-propagate.sh --scan` (read-only).
2. Diff the emitted drift-ids against `.last-scan`. If a NEW drift-id appears, notify the user to run
   `/propagate-fixes`; otherwise stay silent.
3. Overwrite `.last-scan` with the current drift-id set.
Never runs `--prepare`/push — discovery only.

## Failure handling (summary)

| Outcome | Action |
|---|---|
| scan empty | report "no portable candidates" — normal, stop |
| `portable: false` | record in report; no prepare |
| prepare exit 20 | cherry-pick conflict — report conflicting files; no PR |
| prepare exit 21 | CI guard fail — report guard name + output; no PR |
| prepare exit 22/23 | clippy/test red — report failing tail; no PR |
| prepare GREEN | write PR body → `backport-push.sh` → record PR URL |

Never auto-merge. Never force the parent bump before the PR is merged.