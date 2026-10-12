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

### Amendment 2026-10-12 (a) — Approved; decisions locked
- The user approved this plan ("proceed with the first plan"). The recommended options are taken:
  - A-F1 (a): `AP_PIECES_SYNC_MODE=OFFICIAL_AUTO` in the local `.env.dev` only, never committed;
  - A-F2 (a): keep `AP_DEV_PIECES="google-sheets,store"`;
  - A-F3: network use approved for the dev instance (cloud.activepieces.com metadata, registry.npmjs.org on first run, cdn.activepieces.com logos);
  - A-F4 (a): defects found by the at-scale sweep are fixed in this plan.

### Amendment 2026-10-12 (b) — Full sync stopped; new direction: matched set plus on-demand downloads
- **Full sync stopped** at the user's request after about 4 minutes. The cloud registry listed 13,476 piece versions (every version of every piece, each fetched separately). The local database grew from 35 MB to 347 MB. The local `.env.dev` is back to `AP_PIECES_SYNC_MODE=NONE`.
- **New direction (user-directed):** do not download the whole catalogue. Download only the pieces that match the reference product's node set, and let users download anything else they need from a link in the "+" panel.
- **Decisions locked by the user:**
  - B-1: a "Browse more pieces" row in the "+" panel opens the official catalogue (fetched live); picking a piece downloads only its latest version, which then behaves like any other piece.
  - B-2: a selective sync written in the fork. Given a list of piece names, it fetches only the latest version of each. The same code backs the on-demand download. Unset, upstream behaviour is unchanged.
  - B-3: remove the official rows the stopped sync stored. Flows, connections, runs and the two dev pieces are untouched.
- **Revised phases** (they replace A1–A4 above; A0 stays as recorded):
  - **A1′ Clean up:** back up the local PGLITE folder, then delete only `piece_metadata` rows with type OFFICIAL (no other table references them). Confirm the API lists the two dev pieces again.
  - **A2′ Matched list:** observe the running reference app black-box over HTTP (allowed by amendment (d) of the look-and-feel plan) and record its integration node names (service names only) in the git-ignored `.work/`. Match each to an official Activepieces piece by service, using the cloud registry's piece names. The orchestrator reviews ambiguous matches. **Gate:** the user sees the counts (matched, unmatched both ways) and approves the list.
  - **A3′ Server (fork `dev`):**
    - a setting that names the pieces to sync (the matched list). When set, a sync fetches only the latest version of each listed or already-downloaded piece, and never deletes a downloaded piece the cloud still lists;
    - a download of a single piece reusing the existing `POST /v1/pieces/sync` endpoint with an optional piece name, same security as today;
    - a catalogue listing for the panel (names, logos, descriptions of not-yet-downloaded pieces) through the server, using the trusted Activepieces HTTP client, cached;
    - a flag so the web app knows the selective mode is on;
    - unit and integration tests; `@activepieces/shared` version bump if shared types change.
  - **A4′ Web (fork `dev`):** a "Browse more pieces" row at the end of the "+" panel root, and a hint in empty search results. It opens a searchable, virtualised catalogue sub-view; picking a piece downloads it (with progress and error states), then opens its actions or triggers. Shown only in selective mode. Spec: new requirements in `08-piece-panel.md` written in Activepieces terms (an Activepieces feature with no reference counterpart), numbered from PCK-21 so they do not collide with the categories plan, through `spec-lint.sh`, `spec-index.mjs` and a new spec tag.
  - **A5′ Load and verify:** set the matched list locally, restart, and confirm only those pieces download (latest version each). Then run the functional check and the restyle sweep from the original A2 and A3 at this scale, plus an on-demand download from the panel and a run of a downloaded piece.
  - **A6′ Record:** amendment, pointers, memory, parent commit with the spec tag and submodule bump; the user pushes.
- Each phase ends at a gate with a pause for review. All work stays capped at 5 cores.

### Amendment 2026-10-12 (c) — A1′ and A2′ done; matched list awaiting approval
- **A1′ clean-up:** the local PGLITE folder was backed up to `iphi-flow/.work/catalogue/pglite-backup-2026-10-12-before-cleanup`. The stopped sync had stored 8,315 versions of 770 pieces, all OFFICIAL; there were no custom pieces. All 8,315 rows were deleted and the table compacted. Flows (13) and the connection are intact. The live database is 13 MB again, and the API lists only the two dev pieces.
- **The catalogue is 770 pieces.** The sync stores the latest version of every piece before any older version (`listCloudPieces`), so the stopped run had already covered the latest version of each piece for this release.
- **A2′ matched list** (working files in `iphi-flow/.work/catalogue/`, git-ignored):
  - The reference app (`iphi-n8n-ref`, capped, stopped again afterwards) lists 870 visible node types: 448 AI building blocks, 57 core nodes and app integrations, many with a separate trigger node. Folded by service, that is 473 services.
  - 224 services match an Activepieces piece: by name, plus 63 aliases checked by hand (for example AWS S3 → Amazon S3, X → Twitter, Execute Workflow → Sub Flows). They match 200 distinct pieces.
  - 4 map to built-in steps (code, router, loop), and 12 are gaps for `node-equivalents-clean-room.md` (filter, sort, limit, remove duplicates, split out, aggregate, summarize, compare, merge as a data join, rename keys, JWT, TOTP).
  - 34 are skipped: AI building blocks that need sub-node ports, product-specific nodes, shell/disk access, no error trigger.
  - 199 services have no Activepieces piece at all.
  - **Proposed download list:** the 200 matched pieces plus the 27 core pieces (8 of which are already in the 200), giving 208 of 770. The other 562 stay reachable through "Browse more pieces" (A4′).
- **Gate:** the user approves the list before A3′ starts.
- **Approved** by the user on 2026-10-12: download 208 pieces (the 200 matched plus all 27 core pieces), latest version each. The list is in `iphi-flow/.work/catalogue/download-list.json`.

### Amendment 2026-10-12 (d) — A3′ sealed; A4′ in progress
- **A3′ sealed:** fork `dev` commit `66c48d2919` (`feat(pieces): selective piece sync and on-demand piece downloads`).
  - New sync mode `OFFICIAL_SELECTED` with `AP_PIECES_SYNC_LIST`; single-piece download through `POST /v1/pieces/sync` with `{ pieceName }`; `GET /v1/pieces/catalog` for not-yet-downloaded pieces; the admin "Sync from Cloud" button also shows in this mode; docs updated; `@activepieces/shared` 0.202.0.
  - Gate: shared lint and 574/574 tests; API typecheck; lint 0 errors on touched files; 7/7 piece-sync integration tests (5 new); web typecheck; clean-room audit PASS.
  - Live, with the approved list in the local `.env.dev`: the boot sync added 208 pieces in 9.4 s with 0 failures; the catalogue endpoint lists 559 pieces (612 KB; 30 ms when cached); an on-demand download took 0.3 s, an unknown name returns 404, and the downloaded piece leaves the catalogue.
  - Finding: the builder's piece list request is now 6 MB (4.6 s cold), because the stock list endpoint includes every action's properties. The "+" panel still opens in 0.24 s and search answers in about 0.65 s. Recorded, not changed.
- **Spec:** PCK-21 to PCK-24 ("Browse more pieces", catalogue view, downloading, keyboard and announcements) added to `08-piece-panel.md` as an Activepieces extension. `spec-lint.sh` PASS; `00-index.md` regenerated (218 rows). Tag `n8n-vibe-spec-v1.2` is set at this plan's seal; the categories plan then uses `v1.3`.
- **A4′** (the panel UI) is being built by a build-lane agent under the clean-room and 5-core rules.

### Amendment 2026-10-12 (e) — A4′ sealed; add-step key fix; A5′ running
- **A4′ sealed:** fork `dev` commit `b3a810b9fa` (`feat(builder): browse and download more pieces from the piece panel`), SPEC PCK-21 to PCK-24, built by a build-lane agent and re-gated by the orchestrator.
  - Orchestrator gate: web typecheck clean, lint 0 errors (64 warnings), 1595/1595 web tests (16 new); shared lint and 574/574; API lint clean; clean-room audit PASS (1,123 added lines, 0 hits).
  - Agent live proof (1440×900, light and dark): row placement in every mode; catalogue loading, list, search and mode filter; download states; forced failure and retry with no toast; real downloads pushing the actions or triggers view; picks adding the step (checked through the API); the no-results hint and button; keyboard; reduced motion; error and empty states; the e2e Storage → Append path. The orchestrator reviewed the diff and the key screenshots.
  - Choices the spec left open: Arrow Right does nothing on a catalogue row (it has no sub-view until downloaded); the "Download" label is 12px with the icon first; the live region sits at stack level; focus returns to the search box when it would fall to the page body; the catalogue cache refreshes after 5 minutes.
  - The proof downloaded 10 more pieces on demand (209 → 219).
- **Restyle defect fixed (A-F4):** fork `dev` commit `d38b35a599` (`fix(builder): add-step key ignores an auto-selected empty trigger`), SPEC PCK-12, CAN-16. Opening a flow auto-selects its first invalid step or the trigger; with an empty trigger that selection is invisible, so N or the toolbar "+" inserted the new step before the first step. Verified live on a copy of "Base 1 - Linear": the step now lands after the last step.
- **Known, not changed:** for about 200 ms after going back in the piece panel, the closing view still carries `pieces-search-input` (since Phase 9). The e2e page objects never go back, so they are unaffected.
- **A5′:** a flow run with cloud-synced pieces (npm install at run time) and the restyle sweep at this scale are running on a verification agent.

### Amendment 2026-10-12 (f) — A5′ done; plan sealed
- **Run with cloud-synced pieces: PASS.** Webhook → Text Helper → Date Helper → Return Response, none built locally, answered `{"date":"2026-10-12","text":"Hello, probe"}` and both runs SUCCEEDED.
  - The pieces installed when the flow was published (3 bundles through the API redirect, then `bun install`): publish took 3.68 s cold and 179 ms once cached; calls take about 0.1 s.
  - Note for flow authors: a mapped value needs the `output` segment, for example `{{trigger['output']['queryParams']['name']}}`, which is what the data selector writes.
- **Restyle sweep at 219 pieces** (verification agent; screenshots in `iphi-flow/.work/shots/catalogue-sweep/`), light and dark:
  - Covered: the "+" panel (root, Apps, search, 29-action sub-views), 8 step editors, connection pickers and dialogs, the platform pieces page, the New Connection list and canvas logos. Every logo loaded, and logo plates stay legible in dark.
  - Timings: the panel opens in 0.1 s; sub-views and searches answer in under 0.75 s; step editors open in 0.4–1.0 s.
- **Findings and dispositions:**
  - F1, dark focus halo nearly invisible (1.03–1.11:1). The user chose a dark-only fix. Fork `6fbcb9b855` (`fix(web): visible keyboard focus halo in dark mode`): `--focus-halo-dark` is violet-400 at 75%, also applied to light-scoped elements inside dark mode. Measured dark 3.63:1 (icon buttons, canvas controls) and 4.12:1 (accent button); light unchanged at 1.56–1.70:1. Spec TOK-11 row updated (`01-tokens.md`).
  - F2, the "Browse more pieces" description was cut without a tooltip. Fork `5d7afcd0fe`: group-row descriptions now show in full on hover (checked live in both themes).
  - Recorded, not changed: F3 (Tab from the panel search goes to the page body; Tab in a sub-view lands on the list scroller with the browser's thin ring) and F4 (long action descriptions run close to the overlay scrollbar), both from Phase 9.
  - Upstream or outside this repo, recorded only: F5 (search hides pieces that match only by description, such as Gmail for "google"), F6 (two weak logo assets on the CDN), F7 (a required Gmail field without the error colour, from the cloud piece), F8 (two dropdown styles side by side), F9 (New Connection tiles not reachable by keyboard); console errors on the platform pieces and connections pages from upstream code and CE-only 404s.
- **Final gate** (capped): web typecheck clean, lint 0 errors, 1596/1596 web tests; shared lint and 574/574; API lint clean; clean-room audit PASS.
- **Fork commits in this plan:** `66c48d2919`, `b3a810b9fa`, `d38b35a599`, `5d7afcd0fe`, `6fbcb9b855`.
- **Spec:** PCK-21 to PCK-24 and the TOK-11 halo row, frozen at parent tag `n8n-vibe-spec-v1.2`.
- **Local state:** `.env.dev` (never staged) runs `OFFICIAL_SELECTED` with the approved 208-piece list; 219 pieces are downloaded (11 on demand during testing). The database backup from before the clean-up is in `iphi-flow/.work/catalogue/`.
- **Plan complete.** Next, when the user says go: `piece-panel-categories-clean-room.md` (spec tag `v1.3`).
