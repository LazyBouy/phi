# Plan — New pieces for reference core nodes that Activepieces lacks (clean-room)

**Status:** draft, awaiting approval (written 2026-10-12).
**Follows:** `n8n-look-and-feel-clean-room.md` (phases 0–12 sealed; this item was deferred in its amendment (r)).
**Order:** third of three follow-up plans, after:
- `piece-catalogue-full-load.md`, which makes community pieces that already cover some gaps visible;
- `piece-panel-categories-clean-room.md`, which defines the "Transform data" group the new pieces join.

## Context
- **Goal:** where the reference product has a built-in node that Activepieces has no equivalent for, write a new Activepieces piece from scratch. The main gap is everyday list work: filter, sort, limit, deduplicate, group and summarise, compare and combine lists.
- **This is new feature work,** not a visual change, so it gets its own spec and its own clean-room gate.
- **How Activepieces differs** (verified on the fork's `dev` branch, 2026-10-12):
  - **Data shape:** a step passes one output object to later steps. The reference passes a stream of items between nodes. Here, list operations take a list input, mapped from an earlier step with the "(X)" dynamic toggle and a single `{{step.field}}` token so the type is kept, and return a list. Loop on Items then iterates it.
  - **Built-in step types:** only Code, Piece, Loop on Items, Router and AI Router. There is no no-op, stop or wait step type.
  - **Inputs and outputs:**
    - `Property.Json` accepts arrays and parses strings, and existing core pieces use it for lists.
    - `Property.Array` with sub-properties gives a repeating row editor, which suits per-field rules.
  - **Expressions:** the formula language already has `filter_list` (equality only), `sort_list`, `deduplicate`, `pluck`, `flatten` and aggregates. How much of it the builder exposes is unconfirmed, and it is no substitute for discoverable steps.
  - **Piece layout:** a piece is a package with `src/index.ts`, one file per action, `src/i18n/translation.json`, vitest tests, a `tsconfig.base.json` path alias and a version.
    - Pieces may import only `@activepieces/pieces-framework` and `@activepieces/pieces-common`; per-piece lint forbids `@activepieces/shared` and `core-*`.
    - The repo's piece-builder skill requires `audience`, `aiMetadata` and `classification` on every action, and treats action names as permanent once published.
  - **Distribution:**
    - The Docker image deletes `packages/pieces/core` and `packages/pieces/custom`. Production gets core pieces only as synced metadata plus npm tarballs.
    - A fork-only piece is not in the official registry; if inserted as an OFFICIAL row, the hourly sync deletes it.
    - Workable routes:
      - **Local dev:** `AP_DEV_PIECES`, which loads `packages/pieces/**/dist`.
      - **Upload:** a CUSTOM piece uploaded as an archive (`npm run sync-pieces` uploads every folder under `packages/pieces/custom`). The server accepts it from a platform admin. The upload option in the UI is gated by `managePiecesEnabled`, which is off on the open-source plan. Whether the CE server path works end to end is unverified.

### Coverage today
Provisional list, from general knowledge of the reference product's core nodes; Phase C1 confirms or corrects it from reference facts.

| Reference capability | Activepieces today | Gap? |
|---|---|---|
| Filter items by conditions | Formula `filter_list` (equality only); CSV Filter Rows (CSV text only); community JSONata | **Yes:** list filter with operators and all/any logic |
| Sort items | Formula `sort_list`; CSV Sort Rows | **Yes:** list sort by one or more fields, typed |
| Limit items | Formula first/last/item-at only | **Yes** |
| Remove duplicates | Formula `deduplicate`; CSV Remove Duplicate Rows | **Yes:** list version, whole item or chosen fields |
| Split a nested list into items | Loop; formula `flatten`/`pluck` | **Yes:** expand a nested list, optionally keeping parent fields |
| Aggregate a field across items | Formula aggregates; Data Summarizer (flat numbers only) | **Yes:** collect fields or whole items into one list |
| Group and summarise | Community JSONata only | **Yes:** group by fields with count, sum, average, min, max, unique count, join |
| Compare two lists | Formula `contains_item`; router list operators | **Yes:** by key, giving only-in-A, only-in-B, same, different |
| Combine two lists (data join, not flow merge) | CSV merge (stacking only) | **Yes:** append, join by key (inner/left/outer), zip by position |
| Rename keys | Data Mapper (one static object) | **Yes:** per-item rename |
| Set or remove fields per item | Data Mapper (one static object) | **Yes:** per-item set, keep or remove |
| JWT sign, verify, decode | Nothing | **Yes** |
| TOTP code | Nothing | **Yes** |
| gzip compress and decompress | Files Helper zip/unzip only | **Yes** |
| Stop the run, or fail it with an error | Community Flow Helper (Stop Flow, Fail Flow) | Covered once the catalogue is loaded |
| Run metadata | Community Flow Helper (Get Run Info); core Tags | Covered once the catalogue is loaded |
| RSS | Community RSS | Covered once the catalogue is loaded |
| HTML extract; markdown ↔ HTML | Text Helper | Covered |
| Wait; respond to webhook; sub-flow; date/time; crypto hash and HMAC; XML; CSV; PDF; images; HTTP; GraphQL; SFTP; SMTP; schedule; forms | Core pieces | Covered |
| Execute a shell command, SSH | Nothing in core | Out of scope (security: runs inside the worker sandbox) |
| Merge as a flow join of parallel branches | Not possible: the engine runs a tree | Out of scope; the data join above covers combining two lists |

## Clean-room protocol
- **Reference lane** produces behaviour facts only:
  - what the node does, its modes and options, input and output shapes, and edge cases (empty input, missing fields, type mismatches);
  - sources: black-box observation of the running reference product (`iphi-n8n-ref`, capped as in the look-and-feel plan) and its public documentation;
  - facts are written in its own words;
  - never copied: parameter labels, descriptions, code, or examples.
- **Source code of the reference nodes** is read only if black-box facts cannot settle a behaviour. That needs a separate, user-approved guard-lift task under amendment (d) of the look-and-feel plan, with its own start and end record.
- **Build lane:**
  - reads only the new spec and Activepieces code;
  - names everything in Activepieces' own words;
  - cites spec IDs in every commit.
- **Audit extension:**
  - `iphi-flow/tools/clean-room-audit.sh` today scans overlap against the reference frontend.
  - For this plan it also scans the reference's node implementations (`packages/nodes-base` in the reference tree).
  - The extension gets the same positive and negative controls as the original tool before it is trusted.
- **Licence note** (not legal advice): node behaviour and the idea of a list filter are not protected; code, text and examples are. The audit plus own-words naming is the guard.

## Decisions to lock (recommendation first)

| ID | Decision | Options | Recommendation and why |
|---|---|---|---|
| C-F1 | Where the new actions live | (a) New fork-owned pieces only. (b) Add actions to existing core pieces (Crypto, Files Helper). | **(a).** Real instances get core pieces from the cloud sync and npm, so edits to them would never ship. They would also collide with upstream updates. |
| C-F2 | Folder | (a) `packages/pieces/custom/`. (b) `packages/pieces/core/`. | **(a).** It is the path `npm run sync-pieces` uploads as private pieces, and it marks the code as fork-owned. A piece in `custom/` can still declare the `CORE` category for grouping. |
| C-F3 | Package names | (a) A fork scope, for example `@iphi-flow/piece-list-tools`. (b) `@activepieces/piece-…` names. | **(a).** It avoids looking like an official piece and avoids clashing with a future upstream piece of the same name. |
| C-F4 | Piece split | (a) Three pieces: list tools (all list actions), security tokens (JWT, TOTP), compression (gzip). (b) One piece per action. | **(a).** It gives the "+" panel a short, browsable list with clear groups. |
| C-F5 | Delivery beyond the dev instance | (a) Prove the archive upload path (`sync-pieces`) on a CE and an EE instance and document it. (b) Dev only for now. (c) Bake the pieces into the Docker image. | **(a), with (b) as fallback.** Upload is the supported private-piece path. Changing the Dockerfile is a larger fork divergence. |
| C-F6 | First release scope | (a) List tools first, security and compression after. (b) Everything in one go. | **(a).** List work is the gap users hit most, and it shapes the design of the rest. |
| C-F7 | Gaps the catalogue already covers (Flow Helper, RSS, JSONata) | (a) Rely on the community pieces. (b) Rebuild them in the fork. | **(a).** No duplicate code to maintain. |

## Phase C0 — Preconditions
- `piece-catalogue-full-load.md` and `piece-panel-categories-clean-room.md` are sealed.
- Decisions C-F1 to C-F7 are locked by the user.

## Phase C1 — Reference facts (reference lane)
- **Confirm the candidate list:** for each row marked as a gap, record:
  - the reference node's behaviour, modes, options and output shape;
  - edge-case behaviour, observed by running small workflows in the reference instance with sample data.
- **Also confirm** that the rows marked "covered" really match: same core capability, with differences noted.
- **Output:** facts in `iphi-flow/docs/specs/node-equivalents/_provenance/` (reference-only, never read by the build lane).
- **Gate:** the orchestrator reviews for completeness; any need for source goes to the user.

## Phase C2 — Spec
- **Location:** `iphi-flow/docs/specs/node-equivalents/`, one builder-facing file per piece, written in Activepieces terms:
  - list input, list output;
  - property design following the piece-builder rules: plain-language names, dropdowns instead of typed IDs, sensible defaults, `audience`, `aiMetadata`, `classification`;
  - output shapes with consistent keys, including an `outputSchema` per action;
  - errors and empty-input behaviour;
  - i18n keys;
  - examples written fresh.
- **ID prefixes:**

  | Prefix | Covers |
  |---|---|
  | LST | List tools |
  | SEC | Security tokens (not TOK, which the look-and-feel spec already uses) |
  | CMP | Compression |

- **Action names** in Activepieces' voice. Provisional:

  | Group | Actions |
  |---|---|
  | List tools | Filter List; Sort List; Limit List; Remove Duplicates; Expand Nested List; Collect Values; Group and Summarize; Compare Lists; Combine Lists; Rename Fields; Edit Fields |
  | Security tokens | Create JWT; Verify JWT; Decode JWT; Generate TOTP Code |
  | Compression | Gzip Compress; Gzip Decompress |

- **Tooling:**
  - extend `spec-lint.sh` and `spec-index.mjs` to take a spec folder, then run them;
  - the user reviews;
  - freeze at parent-repo tag `node-equivalents-spec-v1`.
- **Gate:** user sign-off.

## Phase C3 — Audit tool extension
- Add the node-implementation scan to `clean-room-audit.sh` (a target-folder option), keeping today's frontend scan.
- **Controls:**
  - positive: a reference node file against itself;
  - negative: an existing Activepieces core piece.
- Both results are recorded before the build starts.

## Phase C4 — Build (build lane, fork `dev`), in batches
- **Scaffold:**
  - each piece by hand, or by `npm run create-piece` (it offers only `community` or `custom`);
  - `package.json`, both tsconfigs, `.eslintrc.json`, `src/index.ts`, `src/lib/actions/*.ts`, `src/i18n/translation.json`, `test/*.test.ts`;
  - a path alias in `tsconfig.base.json`.
- **Pure helpers:** the logic of each action (filter, sort, group, join and so on) is plain functions, unit-tested with vitest:
  - typed comparisons for text, numbers, dates and booleans;
  - dotted field paths;
  - missing fields;
  - empty lists;
  - large lists (performance smoke at 10,000 items).
- **Batches,** with a gate and a pause for review after each:
  1. Filter, Sort, Limit, Remove Duplicates.
  2. Expand Nested List, Collect Values, Group and Summarize, Rename Fields, Edit Fields.
  3. Compare Lists, Combine Lists.
  4. Security tokens and compression pieces. JWT and TOTP use well-known libraries, pinned and declared in the piece's own `package.json`. The libraries are named in the batch review; adding them is a package install and needs the user's go.
- **Panel grouping:** each new piece joins the "Transform data" or "Core tools" group by a one-line change to the classifier map from `piece-panel-categories-clean-room.md`.

## Phase C5 — Live proof (dev instance)
- Add the new pieces to the local `AP_DEV_PIECES` (local file, never staged) and restart with the pinned scripts.
- **Flows exercising every action**, light and dark screenshots:
  - a Code step produces a list;
  - Filter, then Sort, then Limit;
  - Loop over the result;
  - Group and Summarize into a table;
  - Compare and Combine two lists from two earlier steps, including after a Router join.
- **Checks:**
  - the step editor shows clear properties;
  - the output pane and data selector show the `outputSchema` fields;
  - errors read well.
- **AI and MCP check:** the actions carry `aiMetadata` and appear correctly where Activepieces lists tools for agents.

## Phase C6 — Delivery proof (C-F5)
- Upload the pieces as archives to a fresh CE instance and an EE instance (local, in-memory) with `npm run sync-pieces`.
- Confirm they install and run in a flow.
- Document the steps in `iphi-flow/docs/` with the plan/edition limits found.
- If the CE path fails, record the evidence and fall back to dev-only (C-F5 b) until the user decides.

## Phase C7 — Verification and record
- **Per batch:**
  - piece build and lint (`turbo run build` and `lint` for each new piece, capped);
  - vitest;
  - `iphi-flow/.work/gate-checks.sh` for web changes;
  - the extended clean-room audit.
- **At the end:**
  - CE and EE e2e suites;
  - a final audit of all new pieces against the reference node implementations and frontend;
  - an amendment here, a pointer in the look-and-feel plan, a memory update, and a parent repo commit with the spec tag and the submodule bump. The user pushes.

## Resource and safety rules
- **CPU and memory:**
  - All builds, tests and browsers run under `taskset -c 0-4 nice -n 10`, one heavy process at a time.
  - vitest runs with `--maxWorkers=4`; Node with `NODE_OPTIONS=--max-old-space-size=4096`.
  - The reference container is capped at cores 0–4 and 2 GB, and stopped when not in use.
- **Clean room:**
  - No reference code, text, icons or examples in the fork.
  - The word "n8n" never appears in fork code or commits.
- **Approvals:**
  - Package installs and downloads happen only with the user's go.
  - `.env.dev` is never staged.
  - Pushes are run by the user.

## Out of scope
- Flow-level merge of parallel branches.
- More than one trigger per flow.
- Shell or SSH execution.
- AI sub-node ports.
- Rebuilding capabilities that community pieces already provide (C-F7).
- Publishing the pieces to npm or to the official registry.

## Amendments
Dated entries are appended below; the text above is not rewritten.
