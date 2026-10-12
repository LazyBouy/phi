# Plan — Task categories in the "+" piece panel (clean-room)

**Status:** draft, awaiting approval (written 2026-10-12).
**Follows:** `n8n-look-and-feel-clean-room.md` (phases 0–12 sealed; this item was deferred in its amendment (r)).
**Order:** second of three follow-up plans. It runs after `piece-catalogue-full-load.md`, because the new grouping can only be judged with the full catalogue loaded. `node-equivalents-clean-room.md` later adds its new pieces to the data-transformation group defined here.

## Context
- **Goal:** the "+" panel should group what can be added by task, the way the reference product's node panel does, instead of by Activepieces' current tabs.
- **What the reference shows:** the Phase 1 screenshot (`docs/specs/n8n-vibe/_ref/n8n/23-piece-panel.png`) lists roughly seven task rows at the root:
  - AI;
  - doing something in an app;
  - transforming data;
  - flow control;
  - core tools;
  - human review;
  - adding another trigger.
  Each row has an icon, a title, a one-line description and an arrow.
- **What Activepieces does today** (verified on the fork's `dev` branch, 2026-10-12):
  - **Root rows** are selector tabs, in the order Explore, AI & Agents, Apps, Utility, Approvals, followed by any custom groups a platform admin defined.
    - AI & Agents shows only when adding or replacing an action and an AI provider plus the AI piece are available.
    - Approvals shows only when adding or replacing an action.
    - Trigger mode shows Explore, Apps and Utility.
  - **Grouping logic:**
    - Category classifiers in `features/pieces/utils/piece-search-utils.ts`: `isFlowController`, `isAiAndAgentPiece`, `isUtilityPiece`, `isAppPiece`.
    - Hard-coded name lists: Popular, Highlights, and the six approval-capable apps in `approvals-tab-content.tsx`.
    - Fixed positions for the built-in steps (Router, AI Router, Code, Loop) inside Explore.
  - **Known gaps in today's grouping:**
    - Pieces tagged only `ARTIFICIAL_INTELLIGENCE`, such as OpenAI, fall through every group and appear only in search.
    - The core Approval piece sits under Utility → Flow Controller, not under Approvals.
  - **The data:**
    - `PieceCategory` has 17 values, with nothing for "data transformation" or "human in the loop".
    - Every core piece is `CORE`; Approval, Delay and Sub Flows are also `FLOW_CONTROL`.
  - **Admin customisation:**
    - Platform admins can rename, reorder, re-icon, hide and add groups through `platform.pieceSelectorConfig`.
    - The schema is in `@activepieces/shared` (`PIECE_SELECTOR_BUILTIN_TABS` in `management/platform/platform.model.ts`). The editor is `routes/platform/setup/pieces/customize-selector-dialog.tsx`.
    - Configured built-ins that are not available are dropped silently.
  - **Search** at the root ignores the groups: the server does the search and returns a flat list.
  - **Tests:** `test/app/builder/pieces-selector/piece-panel-utils.test.ts` asserts the root row keys. The classifiers, name lists and tab resolution have no tests.
  - **e2e** needs only `pieces-search-input`, the piece display-name test ids and the action text in the pushed sub-view. It never clicks a root row.
  - **The engine allows one trigger per flow**, so the reference's "add another trigger" row has no equivalent.
- **The spec today:** `docs/specs/n8n-vibe/08-piece-panel.md` PCK-05 says the root lists "AP's selector groups (today's tabs)". This plan changes PCK-05 through the reference lane and a new spec tag, as amendment (c) of the look-and-feel plan requires.

## Clean-room protocol
- **Same rules as the look-and-feel plan:**
  - the spec holds facts only;
  - Activepieces' own words for every label and description;
  - no reference code, strings, icons or assets;
  - the build lane reads only the spec and Activepieces code;
  - every build commit cites spec IDs;
  - the clean-room audit runs at every gate.
- **Black-box first.** The reference lane observes the running reference product over HTTP: container `iphi-n8n-ref` on `127.0.0.1:5678`, signed in as the local member account. Amendment (d) allows this without lifting the source guard.
  - Facts to record:
    - the root rows in each mode and their order;
    - what each row contains: sub-groups, item counts, sorting;
    - when rows appear or disappear;
    - how search behaves at the root and inside a group;
    - what happens on pick;
    - keyboard behaviour;
    - layout metrics not already in PCK-01 to PCK-13.
- **Source only if black-box is not enough.** If a fact cannot be observed, the gap is listed and the user decides on a separate, recorded guard-lift task. That task follows amendment (d) and has its own start and end entry.
- **Wording:**
  - Category names and descriptions are written fresh in Activepieces' voice. The reference wording is never copied.
  - Provisional names, to be settled in the spec: AI; Apps; Transform data; Flow; Core tools; Human in the loop.
- **Reference container caps:** `docker update --cpuset-cpus 0-4 --memory 2g --memory-swap 2g iphi-n8n-ref` after starting it. It is stopped again at the end of B1.

## Decisions to lock (recommendation first)

| ID | Decision | Options | Recommendation and why |
|---|---|---|---|
| B-F1 | What the root shows | (a) Task categories replace Explore, AI & Agents, Apps, Utility and Approvals; admin custom groups stay after a separator. (b) Task categories are added under the existing tabs. (c) An Explore row stays on top of the task categories. | **(a).** It is the reference behaviour and removes the current fall-through gaps. Popular pieces can still lead the Apps group. |
| B-F2 | How pieces are assigned to categories | (a) A web-side classifier: `PieceCategory` rules plus an explicit name map for core pieces. (b) New `PieceCategory` values declared in each piece. | **(a).** Core pieces come from the cloud sync, so editing their declared categories would never reach a real instance. A tested map covers all 27 core pieces and the built-in steps. |
| B-F3 | Saved admin configuration | (a) Add new built-in keys to the shared schema, keep the old keys as aliases that map to the new ones, and update the admin dialog. (b) Drop the old keys. | **(a).** It keeps existing `pieceSelectorConfig` rows valid; dropping keys silently loses an admin's order. Needs a minor bump of `@activepieces/shared`. |
| B-F4 | Trigger mode | (a) Trigger-kind rows: app events, schedule, webhook, form, chat, manual, called by another flow, table changes, each mapped to Activepieces trigger pieces. (b) Keep today's trigger rows. | **(a), confirmed by the B1 facts.** It mirrors the reference's trigger list with Activepieces' own triggers. |
| B-F5 | The reference's "add another trigger" row | (a) Leave it out. (b) Show it disabled with an explanation. | **(a).** The engine runs a single trigger; a dead row adds noise. |
| B-F6 | Dead code found during research | (a) Remove the unmounted `PieceSelectorTabsProvider` and the unreachable AI & Agents and Approvals branches in `usePiecesSearch` while regrouping. (b) Leave it. | **(a).** It sits in the files being rewritten and would otherwise confuse the new logic. |

## Phase B0 — Preconditions
- `piece-catalogue-full-load.md` is sealed, with the full catalogue in the dev instance.
- Decisions B-F1 to B-F6 are locked by the user.

## Phase B1 — Reference facts (reference lane, black-box)
- **Session setup:**
  - Start `iphi-n8n-ref` and apply the caps.
  - Sign in as `reference@local.test`.
  - The owner API key is read at runtime from `/root/projects/phi/.env` and never printed.
- **Capture** the node panel in each opener and mode, light and dark, into `_ref/` (git-ignored):
  - first trigger;
  - next step from a node's plus;
  - step on an edge;
  - replacing a node.
- **Write facts** into `docs/specs/n8n-vibe/_provenance/` (reference-only).
  - **Root:** row order, row anatomy, and conditions for each row.
  - **Inside each group:** sub-group structure, ordering rule, whether built-in nodes and app nodes mix, and how items are labelled.
  - **Search:** at the root and inside a group, and what a result row shows.
  - **Trigger mode:** the rows and what each opens.
  - **Pick behaviour:** what opens next.
- **Stop** the container at the end.
- **Gate:** the orchestrator reviews the facts for completeness. Any gap that needs source goes to the user (guard-lift decision).

## Phase B2 — Spec change
- **Revise `08-piece-panel.md`:**
  - replace PCK-05;
  - add new IDs from PCK-14 onward. Candidates:

    | ID | Covers |
    |---|---|
    | PCK-14 | Root category rows and conditions per mode |
    | PCK-15 | Category membership rules in Activepieces terms (a table that assigns every core piece, every built-in step and each piece-category rule to exactly one category) |
    | PCK-16 | Group contents: sections, ordering, popular apps first |
    | PCK-17 | Trigger-mode rows |
    | PCK-18 | Search behaviour with categories |
    | PCK-19 | Admin customisation and saved-config compatibility |
    | PCK-20 | i18n keys and fresh wording |

- **Membership rules,** resolving today's gaps. Draft, to be settled in the spec:

  | Category | Contents |
  |---|---|
  | AI | Every piece tagged `ARTIFICIAL_INTELLIGENCE` or `UNIVERSAL_AI`, the AI piece's actions, and the AI Router step |
  | Apps | Every other non-core piece, popular ones first |
  | Transform data | Text Helper, Date Helper, Math Helper, Data Mapper, Data Summarizer, CSV, XML, Crypto and Files Helper, plus the list pieces from `node-equivalents-clean-room.md` once they exist |
  | Flow | Router, Loop, Delay and Sub Flows |
  | Core tools | Code, HTTP, GraphQL, Webhook responses, Storage, Tables, SMTP, FTP/SFTP, PDF, Image Helper, QR Code, Tags and Connections |
  | Human in the loop | Approval, Forms ("respond on UI"), and the approval actions of the six apps listed today |

- **Tooling:**
  - run `spec-lint.sh` and `spec-index.mjs` (regenerates `00-index.md`);
  - the user reviews;
  - freeze at parent-repo tag `n8n-vibe-spec-v1.2`.
- **Gate:** user sign-off on the spec.

## Phase B3 — Build (build lane, fork `dev`)
- **`@activepieces/shared`** (B-F3):
  - new built-in tab keys, with the old keys accepted and mapped;
  - minor version bump;
  - the audit, flag and platform tests that touch the schema stay green.
- **Web:**
  - a pure classifier module replacing `isFlowController`, `isAiAndAgentPiece`, `isUtilityPiece` and `isAppPiece`, unit-tested over all 27 core pieces, the built-in steps, AI-tagged pieces and app pieces;
  - `getTabsList` and `useRootTabs` build the new rows per mode;
  - `usePiecesSearch` gets one case per category, plus the trigger-mode rows;
  - `getTabDescription`, icons (Lucide only) and new ICU keys in `public/locales/en/translation.json`;
  - `buildResolvedTabs` handles old-key aliases; the admin customize dialog lists the new built-ins;
  - the dead code from B-F6 is removed.
- **Tests:**
  - update the root-key assertions in `piece-panel-utils.test.ts`;
  - add tests for the classifier, the alias mapping and per-mode rows.
- **Batches,** with a gate after each and a pause for review between them:
  1. Classifier and shared schema.
  2. Root rows and group contents.
  3. Trigger mode.
  4. Admin customisation.

## Phase B4 — Verification
- **Gate script:** `iphi-flow/.work/gate-checks.sh` (web typecheck, lint, tests, shared lint and tests, API lint, clean-room audit).
- **Server:** API tests for platform settings if the shared schema changed, run with the 5-core caps.
- **Live proof** with the full catalogue, light and dark, every opener and mode:
  - each category's contents match the PCK-15 table;
  - every core piece appears in exactly one category;
  - AI-tagged pieces are reachable;
  - search works at the root and inside a group;
  - keyboard navigation works;
  - an admin custom group still shows after the separator;
  - a saved config with old keys still applies.
- **e2e:** CE and EE suites through `iphi-flow/.work/run-e2e.sh`.
- **Visual comparison** with the reference screenshots.
- **Gate:** the orchestrator re-reads every diff, then the clean-room audit (`dev WORKTREE`) runs.

## Phase B5 — Record
- Amendment in this file with commits, results and deviations.
- Pointer in the look-and-feel plan.
- Memory update.
- Parent repo commit with the spec tag and the submodule bump; the user pushes.

## Out of scope
- More than one trigger per flow, and the "add another trigger" row.
- Reference node kinds with no Activepieces equivalent: AI sub-node ports, evaluation nodes.
- Server-side search ranking.
- New pieces (see `node-equivalents-clean-room.md`).

## Amendments
Dated entries are appended below; the text above is not rewritten.

### Amendment 2026-10-12 (a) — Spec tag shifts to v1.3
- `piece-catalogue-full-load.md` adds PCK-21 to PCK-24 to `08-piece-panel.md` and takes tag `n8n-vibe-spec-v1.2`. This plan's spec change therefore freezes at `n8n-vibe-spec-v1.3`, and its new IDs stay within PCK-14 to PCK-20.
