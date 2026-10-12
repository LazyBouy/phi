# Plan — Load the full piece catalogue in the local Activepieces fork

**Status:** draft, awaiting approval (written 2026-10-12).
**Follows:** `n8n-look-and-feel-clean-room.md` (phases 0–12 sealed; this item was deferred in its amendment (r)).
**Order:** first of three follow-up plans. The other two are `piece-panel-categories-clean-room.md` and `node-equivalents-clean-room.md`; both are verified against the full catalogue this plan loads.

## Context
- **What the user saw:** the builder's "+" panel lists only two pieces (Google Sheets and Storage), while the reference product offers hundreds of nodes.
- **Cause (verified in code on 2026-10-12):**
  - `AP_PIECES_SYNC_MODE=NONE` in the fork's local `.env.dev` means the server never writes official piece rows into `piece_metadata` (`packages/server/api/src/app/pieces/piece-sync-service.ts:41-44`).
  - `AP_DEV_PIECES="google-sheets,store"` then adds those two locally built pieces on top of an empty table.
  - `AP_DEV_PIECES` does **not** filter the list. It adds dev builds and replaces official pieces of the same name (`piece-metadata-service.ts:430-446`). The "[WARNING] This is only shows pieces specified in AP_DEV_PIECES" log line in dev mode is misleading.
- **Production is different.** With the variable unset, the mode defaults to `OFFICIAL_AUTO` (`packages/server/api/src/app/helper/system/system.ts:30`). A normal self-hosted instance already shows the full catalogue. The two-piece view only happens in this dev setup.
- **What `OFFICIAL_AUTO` does:**
  - **On every boot**, the server starts a sync and schedules one every hour.
  - **Source:** it calls the hard-coded `https://cloud.activepieces.com/api/v1/pieces`. It fetches `/registry?edition=<edition>&release=<root package version, 0.92.0>`, then fetches each missing `name:version` in batches of 5. It does not wait for the sync to finish.
  - **Storage:** rows go into `piece_metadata`. Official rows that are no longer listed are deleted; CUSTOM rows are never touched.
  - **Manual trigger:** a "Sync from Cloud" button and `POST /v1/pieces/sync` exist.
- **Running a synced piece:**
  - The worker downloads the piece tarball through the API. The API redirects to `registry.npmjs.org` by default.
  - The worker then runs `bun install`, which also needs npm for the piece's own dependencies.
  - So the first run of each piece needs outbound network access. The install is cached afterwards.
- **Logos** of official pieces are loaded by the browser straight from `cdn.activepieces.com`.
- **Untested at this scale:**
  - The restyled UI (phases 2–11) was verified with about ten pieces.
  - The builder fetches the whole piece list in one unpaginated request that includes every action's properties. The response size grows with the catalogue.
  - The panel rows are virtualised, so rendering should be fine; the payload and the first sync time are unmeasured.

## Decisions to lock (recommendation first)

| ID | Decision | Options | Recommendation and why |
|---|---|---|---|
| A-F1 | How the full catalogue is enabled | (a) Set `AP_PIECES_SYNC_MODE=OFFICIAL_AUTO` in the local `.env.dev` only, never committed. (b) Commit a fork default. | **(a).** Upstream ships `NONE` in `.env.dev` on purpose, for fast dev boots, and production already defaults to `OFFICIAL_AUTO`. A committed change would only alter every developer's dev boot. |
| A-F2 | Keep `AP_DEV_PIECES="google-sheets,store"` | (a) Keep: those two stay local builds, the rest come from the sync. (b) Clear it: everything comes from the sync. | **(a).** It keeps the fast local edit loop for the two pieces already used in dev data. With the full catalogue present, it no longer hides anything. |
| A-F3 | Network use | Approve, for the dev instance only: metadata from `cloud.activepieces.com`, piece tarballs and dependencies from `registry.npmjs.org` on first run, logos from `cdn.activepieces.com` in the browser. | **Approve.** Without it the catalogue cannot load. Telemetry stays off (`AP_TELEMETRY_ENABLED=false`). Approving this plan approves this network use; nothing else is downloaded. |
| A-F4 | Defects the at-scale sweep finds in the restyle | (a) Fix them in this plan as look-and-feel follow-ups, each citing the spec ID. (b) Only list them. | **(a).** These are gaps in work already approved, and the sweep is the first chance to see them. |

## Resource and safety rules
- **CPU and memory:**
  - The dev servers start only through `iphi-flow/.work/start-ap-dev.sh`, which pins them to cores 0–4 at nice 10.
  - Every check runs under `taskset -c 0-4 nice -n 10`, one heavy process at a time.
  - vitest runs with `--maxWorkers=4`; Node with `NODE_OPTIONS=--max-old-space-size=4096`.
- **Git:**
  - `.env.dev` is never staged.
  - Fork changes go on the fork's `dev` branch only.
  - Pushes are run by the user.
- **Rollback:**
  - Setting `NONE` again stops future syncs but keeps the synced rows.
  - Returning to the two-piece view also needs those rows removed, or the local PGLITE data folder reset. Both are destructive, so they happen only on the user's explicit go.

## Phase A0 — Baseline (no network)
- Record the following:
  - the `piece_metadata` row count (through the API piece list);
  - the size of the PGLITE data folder;
  - free disk space;
  - the builder's piece list response size and the time to open the "+" panel.
- Confirm the dev data is intact: flows "Base 1–4", the "Phase 7b1" flows and "Phase 12 - Empty".

## Phase A1 — Switch on the sync
- Edit the local `.env.dev`: `AP_PIECES_SYNC_MODE=OFFICIAL_AUTO`, keeping `AP_DEV_PIECES` (A-F2).
- Restart with `stop-ap-dev.sh`, then `start-ap-dev.sh`.
- Watch the API log for the sync start and finish, and for errors: network, rate limits, release incompatibility.
- Record:
  - the duration;
  - the number of pieces and versions inserted (the registry lists older versions too, each fetched separately);
  - PGLITE size after the sync;
  - peak API CPU (it is pinned, so it cannot exceed 5 cores).
- **Gate:** the sync finishes without errors, and the API piece list returns the catalogue: hundreds of pieces, with Google Sheets and Storage still served from the local builds.

## Phase A2 — Functional check
- **The "+" panel lists the catalogue in every mode:**
  - Explore, Apps, Utility and search, in next-step and trigger mode.
  - Explore in a dev environment puts every piece under "Popular" (`pieces-hooks.ts:538-542`). This is upstream behaviour and is noted, not changed. The categories plan replaces this grouping.
- **Searches return the expected pieces:** Slack, Gmail, OpenAI, HTTP, Schedule, Webhook, Code.
- **Pick from synced pieces:** a trigger, then an action. The step editor opens with each piece's properties, and dropdowns that need no connection load.
- **Connection dialogs:** open one for an API-key app and one for an OAuth app. Stop before any third-party sign-in.
- **Run a flow** that uses an official core piece that is not built locally: Schedule or Webhook as the trigger, then Text Helper and Date Helper.
  - The first run installs the pieces from npm.
  - The run succeeds and shows in the logs panel.
  - Record the install time.
- **Measure:** piece list response size and time, "+" panel open time, and search latency.
- **Gate:** every item passes, or a finding is recorded with evidence.

## Phase A3 — Restyle sweep at catalogue scale
- **Screens** at 1440×900, light and dark:
  - "+" panel: root, Apps list, long piece names, many actions under one piece, search with many results;
  - logos on the 56px plates on the canvas and in lists, including logos with transparent or dark artwork in dark mode;
  - the step editor for 6–8 pieces with varied property types: dynamic dropdowns, arrays, JSON, files, markdown notes, connection-required states;
  - the platform admin pieces page (`/platform/setup/pieces`) with every row, including the "Sync from Cloud" button;
  - the connection picker and the "New connection" piece list.
- **Accessibility spot checks** on the long lists: keyboard movement through the virtualised rows, and focus visibility.
- **Fixes (A-F4):**
  - Each defect gets a short entry: screen, expected (spec ID), actual.
  - Fixes are fork commits on `dev` citing the spec IDs.
  - Each fix batch passes `iphi-flow/.work/gate-checks.sh` (web typecheck, lint, tests, shared checks, clean-room audit).
- **Gate:** the orchestrator reviews the screens. The user sees a short list of findings, and a few before/after images if fixes landed.

## Phase A4 — Record
- **Plan record:** append a dated amendment to this file with the measurements, findings, fixes and commit ids.
- **Look-and-feel plan:** add a one-line pointer in `n8n-look-and-feel-clean-room.md`.
- **Memory:** update the deferred-scope memory: catalogue done, how to roll back.
- **Parent repo:** bump the submodule pointer only if fork commits landed.

## Verification summary
- The catalogue is visible in the panel, and its count matches the API.
- A flow using synced pieces runs end to end.
- The restyled screens hold up at scale in light and dark, or defects are fixed and gated.
- The clean-room audit passes for any fork change.

## Out of scope
- Regrouping the "+" panel (see `piece-panel-categories-clean-room.md`).
- New pieces (see `node-equivalents-clean-room.md`).
- Air-gapped installs, an npm mirror, or bundling pieces into the Docker image.
- Changing upstream sync behaviour: the hard-coded cloud host, syncing every version, the hourly schedule.

## Amendments
Dated entries are appended below; the text above is not rewritten.
