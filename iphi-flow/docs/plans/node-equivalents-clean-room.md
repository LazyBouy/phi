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

### Amendment 2026-10-13 (a) — Approved; decisions locked; C1 started
- The user approved this plan ("Please continue") after the catalogue and categories plans were sealed. The recommended options are taken:
  - C-F1 (a) new fork-owned pieces only;
  - C-F2 (a) `packages/pieces/custom/`;
  - C-F3 (a) a fork package scope;
  - C-F4 (a) three pieces (list tools, security tokens, compression);
  - C-F5 (a) prove the archive upload path, with dev-only as fallback;
  - C-F6 (a) list tools first;
  - C-F7 (a) rely on community pieces for gaps they already cover.
- **C1 sources:** black-box observation of the running reference app only (its UI and small test workflows with sample data). Public documentation is not fetched, to avoid extra network use; if a behaviour cannot be settled black-box, the gap goes to the user.
- C0 preconditions met. C1 (reference facts) started; C3 (audit extension) runs alongside, since it needs no facts.

### Amendment 2026-10-13 (b) — C3 done
- `tools/clean-room-audit.sh` extended:
  - `CLEAN_ROOM_TARGETS` selects the reference folders scanned for code overlap (default `packages/frontend`; for this plan `packages/frontend packages/nodes-base`);
  - a `CONTROL [TARGET]` mode runs both controls and prints counts only, so no reference content is shown.
- **Controls against `packages/nodes-base`:**
  - positive: one reference node file against its own folder gives 92,440 shared shingles;
  - negative: 49 Activepieces core piece source files (Text Helper, CSV, Data Mapper, Math Helper, Crypto) give 0.
- A normal audit with both targets scans 7,740 reference node files.
- `spec-lint.sh` and `spec-index.mjs` already take a spec folder argument; no change needed for `docs/specs/node-equivalents/`.
- The new folder's `_ref/` is git-ignored (parent `.gitignore`).

### Amendment 2026-10-13 (c) — C1 done; C2 spec drafted, awaiting sign-off
- **C1:** a reference-lane agent observed 14 reference nodes black-box (UI and throwaway workflows; no source, no internet). About 450 facts are in `docs/specs/node-equivalents/_provenance/r1-node-behaviour-facts.md` (reference-only), with 95 screenshots in `_ref/` (git-ignored). All probe workflows and credentials were deleted, and the four Ref workflows are unchanged.
- **Side fix:** appending the new `_ref/` ignore line had joined it to the previous line, so both `_ref/` folders were briefly not ignored. The line was split; nothing was ever committed from them.
- **C2 spec drafted** in `docs/specs/node-equivalents/`: `00-index.md` (scope, never-use list, conventions CNV-01 to CNV-06), `01-list-tools.md` (LST-01 to LST-16), `02-security-tokens.md` (SEC-01 to SEC-07), `03-compression.md` (CMP-01 to CMP-04). `spec-lint.sh` PASS; 27 indexed IDs; 0 forbidden-phrase hits; the one action name that matched a reference node exactly was renamed (Set Fields).
- **Change to C-F4:** four pieces instead of three. Activepieces gives a piece one connection type, and JWT needs a key while TOTP needs a different secret, so the security tokens become "JSON Web Tokens" and "One-Time Passwords". The others are "List Tools" and "Gzip".
- **Design choices that differ from the reference** (all to make behaviour predictable):
  - text comparisons are case-insensitive by default, matching the Activepieces CSV piece;
  - missing fields never stop a step;
  - JWT standard claims are written under their standard names, so expiry works;
  - de-duplication tolerates differently shaped entries;
  - "Keep New Items" forgets the oldest keys instead of failing when full;
  - renames read the original entry, so swaps work;
  - date-only values mean midnight UTC.
- **Set Fields:** Activepieces resolves mapped values once per step, so per-entry values come from "another field of the entry" or a `{path}` text template.
- **Scope:** zip stays with the core Files Helper; tar is out of scope; the JWT piece needs one pinned library (user go at batch 4); TOTP and Gzip use Node built-ins.
- **Spec signed off** by the user ("Freeze and build") and frozen at parent tag `node-equivalents-spec-v1`. C4 (build) starts with List Tools.

### Amendment 2026-10-13 (d) — List Tools built, proven live and committed
- **Batches 1 to 3 in one piece:** all 13 List Tools actions were built together, as the spec defines one piece. Fork commit `5a2d69fda0` on `dev` (`@iphi-flow/piece-list-tools` 0.1.0, 48 files).
- **Install rule (user, 2026-10-13):** "use docker to run. Never install anything in the machine directly always use docker". The workspace link ran as `bun install --ignore-scripts` in `oven/bun:1.4.0` (the repo's pinned version), capped at cores 0–4 and 4 GB, with the repo mounted at its own path. It added no third-party packages; `bun.lock` gained only the new workspace (and recorded the shared 0.203.0 bump already on `dev`).
- **Build-agent choices, reviewed and kept:**
  - mode-dependent options are wrapped in dynamic properties so they show only for their mode (the spec's "shown for" column); live, the wrapper adds no label of its own;
  - `audience: 'human'` on the pure transforms and `'both'` on Keep New Items and Forget Seen Items, as the repo's piece-builder rules say for generic transforms;
  - `minimumSupportedRelease` 0.30.0, as the core pieces that use output schemas (Math Helper, Date Helper);
  - Keep New Items stores keys in 400 KB pages (the store's value limit is 512 KB, measured as JSON bytes) and limits the memory name to 60 characters (store keys stay under the 128-character limit in either scope);
  - "Every combination" stops with a clear error above 100,000 entries;
  - a few extra configuration messages beyond the spec, such as "Add at least one field to sort by." and "A calculation cannot be saved under the name of a group field.", all in plain words (CNV-05).
- **Verified:**
  - 161/161 piece tests (the slowest 10,000-entry run is 491 ms); piece lint and typecheck clean;
  - web typecheck, lint 0 errors, 1624/1624 web tests; shared 574/574;
  - clean-room audit PASS with `CLEAN_ROOM_TARGETS="packages/frontend packages/nodes-base"` (7,740 reference node files scanned, 0 overlap, 0 forbidden-text hits, 0 identical assets).
- **Live proof (C5 for this piece):**
  - three published webhook flows ran all 13 actions in the engine, 26/26 checks;
  - Keep New Items over four runs: all new, then none new, then the key forgotten from another flow plus one new key pass, then all new again after a full clear (project scope shared across flows);
  - the "+" panel shows "Work with lists" second in Transform data with only List Tools, and the 13 actions in spec order with Read/Write/Destructive badges; the Sort List form swaps its options correctly; light and dark, 15/15, no console or network errors.
- **Dev-only finding:** each List Tools step took about 0.8 s on the dev instance. The cause is the engine's dev-piece lookup, which reads every piece folder's `dist/package.json` on each step; production installs pieces normally, and the piece's own work takes milliseconds.
- **Next:** batch 4. JSON Web Tokens needs the user's go on its library: `jsonwebtoken` 9.0.1 with `@types/jsonwebtoken` 9.0.10, the versions seven workspaces already declare (API, CLI and five community pieces: GitHub, LinkedIn, Metabase, Ghost CMS, LeadConnector), so nothing new is downloaded. One-Time Passwords and Gzip use Node built-ins.

### Amendment 2026-10-13 (e) — Batch 4 built, proven live and committed
- **Library:** the user chose `jsonwebtoken` 9.0.1 (with `@types/jsonwebtoken` 9.0.10). The workspace link ran in Docker as before; `bun.lock` gained only the three new workspaces.
- **Fork commit `4412d29360`** on `dev`: JSON Web Tokens, One-Time Passwords and Gzip (0.1.0 each, 67 files), placed in Transform data → "Formats and files" (the section sorts alphabetically, so they sit between Crypto, CSV, Files Helper and the rest rather than right after Crypto).
- **Build-agent choices, reviewed and kept:**
  - JSON Web Tokens:
    - the Algorithm field is optional, and empty means HS256 for a shared secret or RS256 for a key pair (how the spec's "default HS256 or RS256" is met in one dropdown);
    - a key-pair connection may hold only a private key (the public key is derived) or only a public key (it can verify but not create tokens);
    - RSA keys under 2048 bits and passphrase-protected keys are refused with plain messages;
    - PEM text pasted on one line is repaired;
    - `iat` is written by the piece rather than by the library, because the library's no-timestamp option deletes it;
    - a Claims `exp` stays when "Expires in" is empty (standard fields only replace Claims when filled in);
    - `alg` in Extra header fields is ignored, and Key ID wins over a `kid` there;
    - all three actions are `READ`, idempotent and `audience: 'both'`, like the core Crypto piece.
  - One-Time Passwords: digit options read "6 digits" to "8 digits"; the base32 reader accepts spaces, lower case and `=` padding.
  - Gzip:
    - decompression stops at 256 MB of output with a plain message; the server's default file limit is 25 MB and the sandbox's default memory limit is 1 GiB;
    - the header always stores the input's own name;
    - two extra messages: one for damaged gzip content and one for a missing file.
- **Verified:**
  - piece tests 61 + 37 + 20 (all 18 RFC 6238 vectors; every JWT failure message; HMAC, RSA, RSA-PSS and EC keys generated in the tests); piece lint, typecheck and build clean;
  - web typecheck, lint 0 errors, 1626/1626 web tests; shared 574/574;
  - clean-room audit PASS with `packages/frontend packages/nodes-base` (0 overlap, 0 forbidden-text hits, 0 identical assets).
- **Live proof (C5 for these pieces):**
  - connections saved through the API: a shared secret, an ES256 key pair with the private key pasted on one line, and a lower-case spaced TOTP secret;
  - refused with their plain messages: a mismatched key pair, RS256 with a shared secret, and a bad TOTP secret;
  - a published webhook flow, 29/29 checks:
    - tokens created and verified with HS256 and ES256;
    - Read Token without a connection;
    - the signature, audience, expiry and not-valid messages, through continue-on-failure;
    - the code equal to RFC 6238 at run time;
    - a gzip round trip with the stored name;
    - the non-gzip message.
  - UI: the panel section, the three piece views with their logos, the three step forms and the JWT connection dialog, in light and dark.
    - The first light pass logged a burst of browser `ERR_NETWORK_CHANGED` errors (a host network change during the run).
    - The light re-run was 16/16 with no console errors; dark was 8/8.
  - The proof flows and connections were deleted afterwards.
- **Next:** C6 (archive upload to fresh CE and EE instances), then C7 (CE and EE e2e suites, final audit, memory, seal).
