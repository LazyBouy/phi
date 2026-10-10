# Plan — n8n look-and-feel for the Activepieces fork (clean-room)

## Context
- Goal: make the Activepieces (AP) web app look and behave like n8n across the whole app.
- Hard constraint: copy nothing from n8n. That means no code, CSS, SVG, icons, font files, illustrations or UI copy.
  - n8n's source is under the Sustainable Use License, plus a commercial licence for `.ee.` files. Copied material would contaminate AP's MIT core.
  - The AP fork is MIT, except `packages/ee/` and `server/api/src/app/ee/`.
- Method: clean room.
  - A **reference lane** reads n8n and writes a facts-only spec.
  - A **build lane** implements from that spec and never opens n8n.
- Decisions the user locked on 2026-10-09:
  - **Canvas:** free-form draggable nodes, laid out left to right. Positions are persisted, so the flow schema and backend change.
  - **Colors:** a hard-coded n8n-like palette. Platform brand colors stop overriding the UI. Logos and the product name stay white-label.
  - **Scope:** the whole web app: tokens, primitives, shell, dashboard pages, auth and builder.
  - **Step editor:** a three-pane modal with INPUT, parameters and OUTPUT.
  - **Router merge:** a small 16px join dot closes Router and continue-on-failure branches. It is not draggable, and it shows AP's implicit merge before the next step.
- Repos:
  - `iphi-flow/activepieces` is the fork we change. It is on `main`; we branch from it.
  - `iphi-flow/n8n` is reference only.
- Research done this session (read-only), with key facts:
  - **AP UI layer:**
    - React 19, Tailwind v4 with no config file (the theme lives in `packages/web/src/styles.css`), shadcn/Radix, lucide-react, @xyflow/react 12.3.5.
    - A left-to-right canvas mode with 80×80 nodes already exists.
  - **n8n tokens:**
    - Its color ramps equal the stock **Tailwind v4 palette** (MIT). Primary is orange-500 `#ff6900`.
    - Fonts are Inter and Commit Mono (both OFL). Icons are Lucide (ISC).
  - **n8n editor:**
    - 96×96 nodes, 16px dot grid, Bézier edges, a right slide-in node panel.
    - A three-pane step modal, a 42/200px sidebar and a 64px header.
  - These three reports are the seed for the spec (Phase 1).

## Clean-room protocol (applies to every phase)
- **Spec rules.**
  - Allowed: prose and tables of facts: px, hex, ms, easing numbers, layout, states, behaviour.
  - Forbidden: code blocks, CSS/SCSS text, selectors, n8n class or token names, SVG path data, copied files, verbatim n8n UI strings.
- **Naming.** Keep AP's own token architecture: `gray-1..12`, `accent-1..12`, `success/warning/danger-1..12`. Only the values change.
- **Color source.** Take values from the Tailwind v4 default palette (MIT) and cite Tailwind as the source, not n8n.
- **Fonts.**
  - Inter is already self-hosted in AP (`packages/web/src/assets/fonts/`).
  - Commit Mono comes from its upstream release (OFL), never from n8n's assets folder.
- **Icons.**
  - Use lucide-react, already in AP.
  - Draw the few custom glyphs (trigger bolt, plus-box, tidy-up) from scratch, or use Lucide equivalents.
- **Never use:**
  - The n8n name or logo.
  - n8n node icons or the `N8nIcon/custom/` and `nodes/` artwork.
  - n8n illustrations.
  - The coral `#ff6d5a` (the logo color).
  - The AI-assistant gradient.
  - n8n UI copy. AP keeps its own words, e.g. "Test flow", not "Execute workflow".
- **Enforcement in the build lane:**
  - Build sessions run with cwd `iphi-flow/activepieces`.
  - `.claude/settings.local.json` (git-ignored globally, verified) denies `Read`, `Grep` and `Glob` on `/root/projects/phi/iphi-flow/n8n/**`.
  - A PreToolUse hook blocks any Bash command that names `iphi-flow/n8n`. The audit script is the only exception.
  - Build-agent prompts get only the spec path and AP paths.
- **Provenance.** Every build commit cites the spec IDs it implements, e.g. `SPEC NOD-03, EDG-01`.
- **Audit gate.** At the end of every phase, an auditor with access to both trees runs one script with three checks:
  - sha256 of every added or changed AP asset against all n8n files: 0 matches.
  - A clone/n-gram scan (jscpd) of changed AP files against `n8n/packages/frontend`: 0 clones above threshold.
  - A grep of the diff for `n8n`, n8n token names, `#ff6d5a` and n8n UI strings: 0 hits.
- **Legal note** (not legal advice).
  - Copyright covers code and assets. Trademark covers the name and logo.
  - A near-identical overall look can raise trade-dress questions if the product is distributed commercially. Get counsel before any external release.
  - Running n8n locally as a reference is internal use under its licence.

## Phase 0 — Setup
- **Archive this plan, first step after approval** (user-directed).
  - Create `/root/projects/phi/iphi-flow/docs/plans/`.
  - Copy this file into it unchanged, as `n8n-look-and-feel-clean-room.md`.
  - The copy is the reference record of the approved scope.
  - Later scope changes are appended at the end as dated `## Amendment YYYY-MM-DD` sections; the original text is never rewritten.
  - It is committed in the parent repo together with the submodule commit below.
- **Parent repo.** The new `.gitmodules` entry and the `iphi-flow/*` submodule additions are staged but not committed. Commit them first, with user approval.
- **AP branch.** Create `n8n-vibe` from `main` in `iphi-flow/activepieces`.
- **AP dev environment:**
  - `node tools/scripts/install-bun.js` (the repo pins bun 1.4.0, which is not installed here).
  - `docker-compose.dev.yml` for Postgres and Redis.
  - `npm start`. The web app runs on :4200 and the API on :3000.
- **Reference instance.** Run n8n's Docker image `n8nio/n8n:2.43.0`, which matches the submodule's `packages/cli` version, on :5678 (local only). Seed 5–6 workflows: linear, IF/Switch, loop, error, with notes.
- **Baseline.** A Playwright script captures AP's key screens, light and dark, at 1440×900. These are the "before" set.
- Install the clean-room deny rules and the Bash hook (above).

## Phase 1 — Spec (reference lane)
- **Location:** `iphi-flow/docs/specs/n8n-vibe/` in the parent repo, next to the archived plan. Reference screenshots go in `_ref/`, which is git-ignored and never committed.
- **Seed:** the three research reports from this session, restructured into the files below. Each requirement gets an ID, values, states and the AP target file.
  - Strip n8n file paths and n8n token names from the files builders read.
  - Keep them only in `_provenance.md`. It is for the reference lane and the auditor; builders never get it.
  - `00-index.md`: the ID scheme, the never-use list, and a table mapping each spec ID to its AP file.
  - `01-tokens.md` (TOK): each role mapped onto AP's 12-step scales, light and dark.
    - Gray roles: canvas `#f5f5f5`, page `#fafafa`, surface white, text `#262626`/`#444`/`#999`.
    - Accent = Tailwind orange (step 9 `#ff6900`). Success green-600, danger red-600, warning gold `#b57617`.
    - Focus = violet. Radius base 4 and lg 8. Shadows, spacing, type ramp (13/14px workhorse), weights 400/500/600.
    - Motion durations and z-index layers.
  - `02-primitives.md` (PRM): button, input, select, tabs, segmented control, tooltip, dropdown, dialog, badge, tag, card, table, switch, checkbox, callout, notice, toast, scrollbar.
  - `03-shell.md` (SHL): sidebar, the 64px header, page layout.
  - `04-pages.md` (PAG): automations list, runs, connections, tables, settings, empty states, auth.
  - `05-canvas.md` (CAN): background, viewport, controls, minimap, toolbars, test bar, empty placeholder, keyboard.
  - `06-graph.md` (NOD/HDL/EDG): node shapes, states, handles, plus-stubs, edges, back-edges, item labels.
  - `07-step-modal.md` (NDV): the three-pane step editor.
  - `08-piece-panel.md` (PCK): the right slide-in piece selector.
  - `09-logs.md` (LOG): bottom run/logs panel.
  - `10-motion.md` (MOT).
- **AP mappings decided in the spec:**

  | n8n concept | AP equivalent |
  |---|---|
  | deactivate node | AP "skip step" (`operations/skip-action.ts`) |
  | pinned data | AP saved sample data |
  | Executions tab | AP runs |
  | "N items" edge label | shown only when a step's output is an array |

  AI sub-node diamonds and the Evaluations tab are left out (no AP equivalent).
- **Gate:** the orchestrator and the user review the spec, then freeze it with a commit and tag. Any later change goes back through the reference lane.

## Phase 2 — Theme tokens and hard-coded palette
- `packages/web/src/styles.css`: rewrite the `:root, [data-theme='light']` and `[data-theme='dark']` blocks.
  - Change the gray, accent, success, warning and danger values plus radius, shadows and the focus ring. AP's danger `#e7000b` and success `#00a63e` already match.
  - Add the mono font `@font-face` (Commit Mono from upstream, placed in `src/assets/fonts/`).
- **Hard-code the palette:**
  - Set `DEFAULT_ACCENT_SOLID` to `#ff6900` in `packages/core/shared/src/lib/core/common/brand-colors.ts`, and bump `@activepieces/shared`'s patch version.
  - Change the primary in `defaultTheme` in `packages/server/api/src/app/flags/theme.ts`.
  - `packages/web/src/lib/brand-seed.ts`: stop applying the accent and status overrides. Favicon, title and logos stay white-label.
  - `routes/platform/setup/general/appearance-section.tsx` and `color-preview.tsx`: remove the color picker and keep the logo fields.
  - Out of scope: email templates keep using `{{primaryColor}}`.
- **Tests:** `test/styles/status-scales.test.ts`, `test/lib/brand-seed.test.ts`, `appearance-section.test.tsx`.
- **Guard:** `scripts/check-tailwind-classes.mjs` already runs in `npm run lint`.

## Phase 3 — Primitives (`packages/web/src/components/ui/`, 46 files)
- Keep the variant and size names, so call sites stay unchanged; change only the values.
- **Button:**
  - Heights 24/28/32/36/40, radius 4/6/8, weight 500.
  - `default` becomes solid orange. `outline`/`secondary` become subtle (inset 1px ring plus xs shadow). Also `ghost` and `destructive`.
- **Input, select, textarea:** default height 36, radius 6, inset ring, violet focus ring.
- **Tabs:** an orange 2px underline.
- **New** `segmented-control.tsx`, used for the header tabs and the data view modes.
- **Tooltip:** black bubble, 13px/500 text, 8px radius, no arrow.
- **Dropdown, context menu, popover:** 8px radius, md shadow plus outline ring, 32px items with 6px radius.
- **Dialog:** widths 360–780, 30% overlay with 8px blur, 200ms rise.
- **Others:** badge, card, table, switch (on = green), checkbox (checked = orange), alert (callout style), sonner toasts, scrollbars.
- **Custom components:** `components/custom/data-table/` (36px header, 48px rows), `page-header.tsx`, empty states.

## Phase 4 — App shell
- **Sidebar.** Rebuild `app/components/primary-rail/index.tsx` (808 lines) as an n8n-like sidebar.
  - 42px collapsed. Expanded defaults to 200px and resizes from 200 to 500px in 8px steps.
  - Neutral-50 background with a 1px right border.
  - Header row: platform logo, then create/search/collapse buttons.
  - 32px items, an active-item fill, and a bottom block with help and settings.
  - Navigation items stay AP's own.
- **Builder layout.** `app/components/builder-layout/index.tsx`: remove the inset rounded card and make the canvas full-bleed under a 64px header.
- **Page layout.** `app/components/project-layout/*` and `dashboard-page-header.tsx`:
  - Maximum width 1280px, padding 24/48px.
  - Title and subtitle, an orange "Create" button with a dropdown, underline tabs.

## Phase 5 — Dashboard pages and auth
- **Automations list** (`features/automations/components/`):
  - Each row becomes a card: 8px radius, hover shadow, a meta line, tag chips, a status dot and a "⋯" menu.
  - Filter row: 196px search, sort, filter.
- **Runs, connections, tables, settings:** restyle `DataTable`, plus the tables grid CSS (`routes/tables/id/react-data-grid.css`).
- **Empty states:** action cards with a staggered entrance.
- **Auth** (`features/authentication/components/auth-landing/`): replace the animated backdrop and drawer with a simple centred card form.
  - Keep the `sign-in-*`, `sign-up-*` and `auth-*` test ids.

## Phase 6 — Canvas chrome
- **Canvas root** `builder/flow-canvas/index.tsx`:
  - 16px dot grid in `#999` on `#f5f5f5` (dark mode: `#444` on `#171717`).
  - Zoom from 0.05 to 4. d3-zoom cannot use a minimum of 0, so 0.05 stands in for the spec's 0.
  - Fit the view with `fitView({ padding: 0.2, maxZoom: 1 })`. This replaces `canvas-controls/use-fit-to-view.ts`, whose maths assume the vertical canvas.
  - Remove `translateExtent`.
  - Pan on scroll, zoom with Space/Ctrl+wheel, pan with middle-drag, draw a selection rectangle with left-drag, and set the cursors.
- **Controls** (`canvas-controls/`):
  - Bottom-left group: fit, zoom in, zoom out, tidy-up.
  - The orientation toggle buttons are removed.
- **Minimap** (`widgets/minimap.tsx`): 200×120, shown only while panning, hidden 1s after panning stops.
- **Top-right vertical toolbar:** add step, search, add note.
- **Bottom-centre "Test flow" bar** with a stop button, adapted from `widgets/test-flow-widget.tsx` and `above-trigger-button.tsx`.
  - `builder-banner.tsx` publish reminder → moves into the header's Publish button (Phase 10).
- **Empty trigger:** a dashed 100×100 "add first step" placeholder.
  - Watch the e2e "Select Trigger" text and the `rf__node-trigger` id.
- **Notes:** sticky-note look in `nodes/note-node/`; the existing `NoteColorVariant` enum maps onto it.
  - Existing note coordinates were placed for the vertical canvas. Re-anchor them in the event-destination sample flow (`handler-flow-builder.ts`).
- **Keyboard** (`builder/shortcuts.ts`):
  - `1` fit, `0` 100%, `N` piece panel, Shift+S note, `D` skip, Enter opens the step modal.
  - Shift+Alt+T tidy-up: match on `e.code === 'KeyT'`, because macOS Option+T produces "†".

## Phase 7 — Graph: free-form positions, layout, nodes, edges, drag
Design produced this session; the facts below were spot-checked in code.

**7.0 Spike first (main risk).**
- Prove that React Flow 12.3.5 controlled `onNodesChange` works with the following, all on one canvas:
  - selection,
  - the selection rectangle,
  - the context menu,
  - note dragging, which stays on dnd-kit.

**7.1 Model** (`packages/core/execution/src/lib/flows/`):
- Store positions in a version-level map, `stepPositions`, keyed by step name. This is chosen over a per-step field for these reasons:
  - Step operations rebuild steps field by field and would drop a per-step field.
  - The 1s step-settings autosave would overwrite fresher drag positions.
  - The release diff ignores the map automatically.
  - Published versions can be updated in place, exactly as notes are today. Verified at `flow.service.ts:428-430`.
- `flow-version.ts`:
  - `StepCanvasPosition {x,y}`.
  - `StepPositions = record<string, StepCanvasPosition>`.
  - `stepPositions: StepPositions.default({})`. The default keeps old payloads and old templates parsing.
  - A position is the node box's top-left, snapped to 16.
- New operation `UPDATE_STEP_POSITIONS { positions }`, which merges into the map. Code goes in `operations/index.ts` plus a new `operations/step-positions-operations.ts`.
- **Tail prune in `apply`:** remove map keys whose step no longer exists. This is needed for two reasons:
  - Deletes, branch deletes and type changes leave orphaned keys.
  - `findUnusedName` reuses deleted names, so a new step would otherwise inherit an old position.
- `MOVE_ACTION` snapshots the moved subtree's positions before applying and restores them after.
- `IMPORT_FLOW` takes `stepPositions` (add it to `ImportFlowRequest`).
- Treat the map as possibly undefined at runtime (`?? {}`). Git-sync and release snapshots load flows with a bare `JSON.parse` cast.
- **No flow JSON schema bump** (it stays at v28): the change is additive and lies outside `trigger`. Legacy flows have an empty map and render with auto-layout.
- New `util/flow-layout-util.ts` (`flowLayoutUtil`), shared by the web and the server:
  - Constants: GRID 16, NODE 96, column pitch 224, ROW_GAP 96, +32px height per output beyond 2, JOIN 16, back-edge drop 130, clearance 40, corner radius 16.
  - `getStepOutputs(step)`:

    | Step | Outputs |
    |---|---|
    | Trigger / action | 1 |
    | Loop | `done` and `loop` |
    | Router / AI router | one per branch, labelled, with "otherwise" for the fallback branch |
    | Continue-on-failure (when on) | `success` and `error` |

  - `computeAutoLayout` lays the tree out left to right:
    - Branches stack and centre on their router.
    - Each router or continue-on-failure group closes with a **join dot** (16px, never draggable).
    - A loop body sits below the main row.
  - `resolveStepPositions`: a stored position wins. A step without one is placed at its anchor (previous step or parent) plus the auto-layout offset, so a new step after X lands at X + 224. An empty map reproduces the auto-layout exactly.
  - `tidyUp` = auto-layout, translated so the trigger stays where it is.
- Version bumps: `@activepieces/core-execution` minor, `@activepieces/shared` minor (new exports and an audit case).

**7.2 Server** (`packages/server/api/`):
- **Migration:** new file `src/app/database/migration/postgres/<ts>-AddStepPositionsToFlowVersion.ts`.
  - `ADD COLUMN IF NOT EXISTS "stepPositions" jsonb NOT NULL DEFAULT '{}'`.
  - A constant default is a metadata-only change, so there is no table rewrite.
  - Register it in `postgres-connection.ts` and add the column to `flow-version-entity.ts`.
- `flow/flow.service.ts`: add `UPDATE_STEP_POSITIONS` to the note case group. It never forks a draft.
- Skip `flowSideEffects.onOperationApplied` for this type, so a drag does not send `FLOW_UPDATED` audit or event-destination events. Also skip the `lastModified` bump.
- Add the type to the WRITE_FLOW lists in `rbac-service.ts` and `rbac-middleware.ts`.
- Add an audit description case in `core/shared/src/lib/ee/audit-events/index.ts`.
- **Import and export plumbing.** Pass `stepPositions` through:
  - `flow-version.service.ts`, `project-state-helper.ts`, `clean-flow-state.ts`, `migrations/index.ts` (templates → `{}`), `template-validator.ts`.
  - Web: `flow-hooks.tsx`, `use-automations-mutations.ts`, `flow-actions-menu.tsx`, `create-template-dialog.tsx`.
- **MCP:** in `mcp/tools/ap-flow-structure.ts`, place notes with `flowLayoutUtil.resolveStepPositions`, and pass the map through in `ap-duplicate-flow.ts`. Then delete `computeStepPositions` and the `FLOW_CANVAS_*` constants.
- **Project-release diff:** it ignores position-only changes, as it already does for note positions.

**7.3 Web graph model** (`builder/flow-canvas/utils/`):
- Rewrite `flow-canvas-utils.ts`: `createFlowGraph` = resolve positions, then compute outputs, edges and join nodes.
- Node types: STEP, JOIN, NOTE. Edge type: one FLOW edge (`types.ts`, `consts.ts`).
- Include `stepPositions` in the hand-built graph key, `createGraphKey`, or drags will not repaint.
- Delete:
  - the orientation code: `layout-consts.ts`, `transposeGraphPositions`, the `canvas-state.ts` orientation field and its localStorage key;
  - `svg-path-utils.ts` and `use-edge-layout-space.ts`;
  - the big-add, loop-return and end-widget nodes;
  - the five old edge types.

**7.4 Nodes and edges:**
- **Step node** (`nodes/step-node/*`):
  - An action is 96×96 with 8px radius. A trigger has a 36px left radius, plus a bolt that swaps to a "Test flow" button on hover.
  - The label (16px name and 13px subtitle) sits 8px below the node.
  - Handles are 16px circles. Outputs sit at (i+1)/(n+1) of the height, with labels 20px to their right. Keep the duplicate/delete-branch menu from `branch-label.tsx`.
  - Status: 2px borders and corner icons, and a rotating ring while running.
  - A skipped step gets the strike-through line.
  - Hover toolbar: test, skip, delete, more.
  - Selected state: a 6px halo.
  - Call `useUpdateNodeInternals` when the output count changes.
- **Output stub** (new `nodes/step-node/output-stub.tsx`): a 2px line ending in a 24px "+" box. It lives inside the node, so it moves during a drag.
- **Join dot** (new `nodes/join-node.tsx`).
- **Edge** (new `edges/flow-edge.tsx`, with geometry in a new `utils/edge-path-utils.ts`):
  - Forward edges: Bézier, 2px grey, arrowhead.
  - Back-edge when the target is more than 20px left of the source: drop to 130px below, run back, rise into the target, with 16px corners and 40px clearance.
  - Hover toolbar: "+" only. A tree has no detachable connection, so there is no trash button; deleting a branch stays in the output-label menu.
  - The "+" opens the piece panel with `flowCanvasUtils.createAddOperationFromAddButtonData(insertLocation)`. Every edge kind maps onto the existing ADD_ACTION locations (`AFTER`, `INSIDE_BRANCH i`, `INSIDE_LOOP`, `INSIDE_ON_*`).
  - After a run: green on success, plus an "N items" label on `loop` edges and array outputs.

**7.5 Drag** (`flow-canvas/index.tsx`, new `state/layout-state.ts`, `state/flow-state.ts`):
- Canvas props: `nodesDraggable` when not readonly, `snapToGrid` at 16×16, drag threshold of about 4px.
- `onNodesChange` writes transient `dragPositions`.
- `onNodeDragStop` / `onSelectionDragStop` send **one** `UPDATE_STEP_POSITIONS` for the whole selection.
- **No debounce:** the keyed `debounce` in `core/utils/src/lib/utils.ts:53-66` drops an earlier call when the key repeats. A drag-end is already a natural commit point.
- **Materialize on first write:** if the map is empty, the first drag also sends the resolved positions of every visible step.
- **After an insert, duplicate, paste or move:** send one follow-up operation with the new step's position, shifting overlapping downstream steps by +224.
- **Re-parenting keeps `MOVE_ACTION`,** so execution semantics do not change.
  - Dropping a single dragged step onto an edge "+" or a stub (within a 32px target) re-parents it. Its own edges and descendants are excluded as targets.
  - A drop anywhere else is a position-only update.
- Retire dnd-kit for steps: `useDraggable` in step-node, the droppables in `add-button.tsx`, `step-drag-overlay.tsx`, and `handleStepDragEnd` in `flow-drag-layer.tsx`. Keep it for notes.
- Readonly mode (viewing a run, or another editor holds the lock) disables dragging entirely.

**7.6 Tests:**
- **core-execution:**
  - New `test/flow/step-positions.test.ts`: merge, every prune path, name reuse, `MOVE_ACTION` preservation, import with and without positions, parsing without the field.
  - New `test/flow/flow-layout-util.test.ts`: pitch, snapping, router heights and handle spacing, join placement, loop body, continue-on-failure on and off, all resolve cases, tidy-up anchoring.
- **web:**
  - Rewrite `flow-canvas-utils.test.ts`.
  - New `edge-path-utils.test.ts` and `layout-state` tests (one operation per drag, materialization, re-parent → `MOVE_ACTION`).
  - Delete `svg-path-utils.test.ts`, `layout-consts.test.ts` and `step-drag-overlay.test.tsx`.
- **server:**
  - `flow-operations.test.ts`: positions persist and prune; no draft is forked on a published version; a later edit forks a draft that carries the positions; `IMPORT_FLOW` and `USE_AS_DRAFT` carry positions.
  - `flow-diff.test.ts`: a position-only change gives no diff.
  - Run the migration up and down.
- **Brain:** add the gotchas to `brain/knowledge/flows-execution/flows.md` (the debounce key, name reuse, the join dot).

## Phase 8 — Three-pane step modal
- New `builder/step-modal/`.
  - Opens on double-click or Enter. A single click only selects.
  - Inset 24px from the window, 60% overlay.
  - Header: icon, editable name, docs link, close.
- **Center:** the existing `step-settings/index.tsx` forms (piece, code, loop, router, branch, AI router, agent).
  - Tabs: Parameters | Settings.
  - An orange "Test step" button at the top right, reusing the `test-step/` logic. The `test-trigger-button` test id and the "Test Step Ctrl + G" name stay.
- **Left INPUT pane:** the previous steps' outputs, using the `data-selector/` tree logic.
  - View modes: Schema | Table | JSON.
  - Dragging a field onto a `piece-properties/text-input-with-mentions/` input inserts the same mention token the data selector inserts today.
- **Right OUTPUT pane:** test or run output, using `test-step/test-sample-data-viewer.tsx` and `data-display/`. Table and Schema views are new; JSON reuses `components/custom/json-viewer.tsx`.
- **Columns** resize with react-resizable-panels (already in AP). The layout is saved per piece in localStorage, with try/catch.
- **Run view:** the same modal, read-only, with the run's input and output.
- The side panel keeps only the runs list and version history.

## Phase 9 — Piece panel
- `builder/pieces-selector/index.tsx`: the Radix popover becomes a right slide-in panel.
  - 385px wide, placed below the header, sliding in over 200ms.
  - A title in AP's own words, through i18n keys. A 40px search box, list rows, categories, and a sliding push/pop for sub-views.
- **Openers:** plus-stub, the edge "+", the toolbar "+", the `N` key, the empty placeholder.
- Keep the `pieces-search-input` test id and the piece display-name test ids.

## Phase 10 — Builder header and logs panel
- **Header** `builder/builder-header/builder-header.tsx`, 64px tall:
  - Left: breadcrumbs and the editable name.
  - Centre: a segmented control "Editor | Runs", straddling the bottom border.
  - Right: collaborators, a Publish split button with a status dot (from AP version state), and the on/off toggle.
  - Also fix the invalid `height` template string.
- **Logs panel:** a bottom panel for the current or last test run.
  - 32px when collapsed, 30% of the height when open.
  - Lists the steps with status and duration; selecting one shows its input and output.
  - Reuses `builder/run-details/`.

## Phase 11 — Motion, dark mode, accessibility
- Apply the motion table from `10-motion.md`, and honour reduced-motion.
- Check every screen in dark mode.
- Keep focus rings visible and keyboard paths working.

## Phase 12 — Tests and e2e
- **Vitest** (`packages/web/test/`): update the layout, path and theme tests. Add tests for the new graph geometry and the step modal.
- **Playwright** (`packages/tests-e2e/pages/builder.page.ts`, `automations.page.ts`, `authentication.page.ts`): update selectors only where the UI changed, e.g. the popover becoming a panel and the settings moving into the modal.
- **API integration tests** for the new flow operation (see Phase 7).

## Execution model
- **Orchestrator (this session):**
  - Gates each phase, reads every diff and runs the checks.
  - Has seen only fact reports from n8n, never its code.
- **Reference lane** (Phase 1): 1–2 agents that may read n8n and write only to `iphi-flow/docs/specs/n8n-vibe/`.
- **Build lane** (Phases 2–12): agents run in the AP fork under the deny rules, one phase per commit series.
  - Follow AP's conventions:
    - No code comments.
    - Destructured params.
    - Exports at the end of the file.
    - i18n keys for all text.
    - Bump the `@activepieces/shared` version when it changes.
  - Run `npm run lint-dev` before every commit.
- **Order:** P0 → P1 → P2 → P3 → P4 → P5 → P6 → P7 → P8 → P9 → P10 → P11 → P12.
  - Start with the P7.0 spike right after P1, because it is the biggest technical risk.
  - P8 and P9 depend on P7's new node and edge components.
- **Rough size:**
  - P7 is the largest: core, server, migration and about 30 web files.
  - P3, P4, P5 and P8 are medium.
  - The rest are small.
- **Pushes.** The user runs all pushes. After each phase seals, the parent repo's gitlink is bumped.

## Verification
- **Every phase:**
  - `npm run lint-dev` (eslint plus the Tailwind class checker).
  - `npm run test-unit` and the web vitest suite.
  - `npm run test-api` when the backend changes.
  - Then the clean-room audit script.
- **Visual check:**
  - A Playwright script captures the same screens in AP (:4200) and the reference n8n (:5678) at 1440×900, light and dark.
  - The orchestrator and the user review them side by side. The images stay local and are never committed.
- **Computed-style probes** (Playwright `getComputedStyle`) for the load-bearing values:
  - node box 96×96, radius 8px;
  - canvas background `rgb(245,245,245)`, grid gap 16px;
  - button heights and the accent `#ff6900`.
- **Behaviour** (Phase 7):
  - Drag a node, reload, and confirm the position persists.
  - Tidy-up re-lays the graph.
  - Legacy flows with no positions still render.
  - Publishing and running a flow still execute the same steps in the same order.
- **Edition paths** (an AP rule): CE and EE locally (`AP_EDITION`). Cloud via `--mode=cloud` for the frontend only.
- **e2e:** `packages/tests-e2e` CE scenarios pass.

## Out of scope
- Arbitrary connections or merges between steps. The AP engine runs a tree, so dragging from an output handle adds a step; it does not connect to an existing step.
- n8n features with no AP equivalent: AI sub-node ports, Evaluations, node groups.
- Email template colors, the docs site, marketing pages.

## Amendment 2026-10-09
- **Working branch is `dev`** (user-directed). It replaces `n8n-vibe` everywhere above. It was created from `main` in `iphi-flow/activepieces` and has no commits yet.
- **No Postgres or Redis containers.** The fork's `.env.dev` sets `AP_DB_TYPE=PGLITE` and `AP_QUEUE_MODE=MEMORY`, so `npm start` runs with an embedded database and an in-memory queue. The `docker-compose.dev.yml` step in Phase 0 is dropped.
- **Local work area** `iphi-flow/.work/` (git-ignored) holds helper scripts, the n8n reference instance's data, and screenshots. The spec's `_ref/` folder is also git-ignored.
- **Gate tools** live in `iphi-flow/tools/` (committed):
  - `spec-lint.sh` is the spec-freeze gate. It rejects code fences, n8n paths, token and component names, the logo colour and SVG path data in builder-facing spec files.
  - `clean-room-audit.sh`, with `clean-room-overlap.mjs` and `clean-room-forbidden.txt`, is the per-phase audit: asset hashes, 30-token shingle overlap (overlap already on the base commit is excluded), and forbidden text.
  - The overlap scan passed a positive control (n8n file vs itself: 3000 shared shingles) and a negative control (AP primitives: only 3 generic CSS idioms, all pre-existing on `main`).
- **Guard:** `/root/projects/phi/.claude/hooks/clean-room-guard.sh` is wired from `iphi-flow/activepieces/.claude/settings.local.json` (git-ignored), with deny rules for n8n paths. It passes an 11-case self-test.
- **Reference instance:** `n8nio/n8n:2.43.0` runs as container `iphi-n8n-ref` on `127.0.0.1:5678`, with volume `iphi-n8n-ref-data`.
  - The owner account is the user's; its API key is read at runtime from `/root/projects/phi/.env`.
  - Captures use a separate local member, `reference@local.test`, invited through the API.
  - Seeded workflows are named "Ref 1–4" (linear, branching, loop, error).
- **AP dev:** `npm run dev`, web on :4200 and API on :3000. The baseline uses AP's own seeded dev user (`dev@ap.com`), with flows named "Base 1–4".
- **Screenshots:**
  - n8n reference: about 40 in `iphi-flow/docs/specs/n8n-vibe/_ref/n8n/`.
  - AP before-baseline: 20 in `iphi-flow/.work/shots/ap-baseline/`.
  - Both sets cover light and dark at 1440×900, captured with the system Chromium at `/snap/bin/chromium` driven by AP's Playwright 1.54.1.

## Amendment 2026-10-09 (b) — Phase 1 spec drafted, awaiting freeze
- **Spec:** `iphi-flow/docs/specs/n8n-vibe/`, 214 requirements:

  | File | IDs |
  |---|---|
  | `01-tokens.md` | TOK-01–23 |
  | `02-primitives.md` | PRM-01–27 |
  | `03-shell.md` | SHL-01–26 |
  | `04-pages.md` | PAG-01–27 |
  | `05-canvas.md` | CAN-01–16 |
  | `06-graph.md` | NOD-01–14, HDL-01–07, EDG-01–09 |
  | `07-step-modal.md` | NDV-01–21 |
  | `08-piece-panel.md` | PCK-01–13 |
  | `09-logs.md` | LOG-01–12 |
  | `10-motion.md` | MOT-01–19 |

  - `00-index.md` carries the ID → AP file map, generated by `iphi-flow/tools/spec-index.mjs`.
  - Builder-facing design notes are in `design/`. Provenance traces are in `_provenance/`.
  - `spec-lint.sh`: PASS on all 13 builder-facing files.
- **Spec decisions that refine or depart from this plan** (sign-off at the freeze gate):
  1. **Warning colour:** Tailwind yellow (step 9 yellow-500 `#f0b100`; text and marks at `#9b5500` / `#c77e00`), not the gold `#b57617`. Amber was rejected because it sits too close to the orange accent.
  2. **Light quiet text** (`gray-11`) is `#737373`, not `#999`. `#999` gives 2.85:1 contrast across about 986 uses (TOK-22 contrast ledger).
  3. **Focus ring:** solid violet-500 edge plus an indigo-700 25% halo (the nearest Tailwind value to the reference halo).
  4. **Ramp generator** (TOK-09): drop the accent exact-anchor exclusion, so the accent ramp is pure Tailwind orange. `--on-accent` stays a fixed white. All swatches are regenerated.
  5. **Default button height** becomes 32px.
  6. **Sidebar background** is white (the surface colour), as measured in the reference; this replaces the "neutral-50" in Phase 4.
  7. **Logs bar** is 36px when collapsed (measured), not 32px.
  8. **Publish status dot:** `success-9` published, `warning-9` unpublished changes, `danger-9` issues.
  9. **Automations page:**
     - "Create New" becomes a header split button: the main part is "New Flow", the chevron opens AP's create menu. The separate Import button folds into that menu.
     - The five filters move into one filter popover.
     - Sorting moves to a sort select.
  10. **Canvas:**
      - Step labels drop the "N." number.
      - The piece logo sits on a 56px plate.
      - The "pinned" visual is used only for a trigger running on saved sample data.
      - The stop button shows only for QUEUED/PAUSED test runs, because the AP server cannot cancel RUNNING runs.
      - Skip moves to `D` and delete to Delete/Backspace; the old keys stay as aliases.
      - Download-as-image moves into the canvas right-click menu.
  11. **Graph visuals win over `design/graph-positions.md`:**
      - stub length 46/66/80px;
      - green edge = source succeeded and target ran;
      - a mid-run arrowhead on back-edges;
      - no arrowhead into the join dot.
      - Reconciled in that document.
  12. **New AP pieces the spec requires:**
      - `segmented-control.tsx`;
      - a `tag` badge variant;
      - a notice `layout` on alert;
      - a 13px `text-xsm` type token;
      - badge sizes and dialog sizes;
      - easing theme keys;
      - a 2px popover-offset keyframe.
- **e2e impact** (Phase 12):
  - "Create New" and "Publish" move into headers; their accessible names are kept.
  - Only one "Test Flow" button may exist in the page at a time.
  - `addAction` and `publishFlow` must close the step modal (Escape) after a piece is picked.
  - `addAction`'s `.nth(1)` may need `.last()`.

## Amendment 2026-10-09 (c) — Spec frozen
- The user accepted the spec as drafted, including every decision in amendment (b).
- It is frozen at parent-repo tag `n8n-vibe-spec-v1`. Any later change goes through the reference lane, a re-run of `spec-lint.sh` and `spec-index.mjs`, and a new tag.
- **Next:** the build lane starts with the Phase 7.0 spike and Phase 2 (tokens) on the fork's `dev` branch, in sessions started from `iphi-flow/activepieces` so the clean-room guard applies.

## Amendment 2026-10-10 (d) — Build lane from the parent session
- The user asked to continue in the existing session, whose working directory is the parent repo.
- To keep the build lane clean, the same guard is installed at parent level in `/root/projects/phi/.claude/settings.local.json`, which is git-ignored:
  - deny `Read`, `Grep` and `Glob` on `/root/projects/phi/iphi-flow/n8n/**`;
  - the PreToolUse `clean-room-guard.sh` hook on `Bash|Read|Grep|Glob`.
- Verified live: a Read of an n8n file was refused by permissions, and `ls` of the n8n tree was refused by the hook. Every agent spawned from this session inherits both.
- Remove them only if a new reference-lane task needs n8n again; that task then runs as a separate, recorded step.
- The build lane may still look at the n8n reference UI over HTTP, and at the `_ref/` screenshots. That is black-box observation, not source.

## Amendment 2026-10-10 (e) — Spike 7.0 done, Phase 2 sealed
- **Phase 7.0 spike: GO with changes.** Commit `3c57040414` on the fork's `spike/rf-drag`; it will not be merged.
  - Controlled node dragging works with selection, the selection rectangle and chevron, both context menus, note dragging, and pan/zoom.
  - The pattern is a local copy of the nodes with `applyNodeChanges`, re-seeded when the graph key changes. The design's position-only overlay lost selection.
  - `design/graph-positions.md` §5 is corrected. Findings are in `design/spike-7.0-findings.md`.
- **Phase 2 sealed:** fork `dev` commit `9eb3dfe9c6` (`feat(web): new theme tokens and a fixed default palette`).
  - Requirements: TOK-01–10, 12, 13, 15, 16, 23.
  - Generated ramps match the spec: 96 of 96 values.
  - Gate run by the orchestrator:
    - web typecheck and lint: 0 errors;
    - web tests 1238/1238; shared tests 574/574; api lint: 0 errors;
    - clean-room audit (`dev WORKTREE`): PASS, 16 files, 0 overlap, 0 forbidden text;
    - visual check done.
  - Includes a generator fix: contrast is checked on the rounded colour; no stock value changes.
- **TOK-14 (Commit Mono) deferred:** the upstream font file needs a download, which the project's hook policy reserves for the user. JetBrains Mono stays until the user decides.
- **Audit tool fixes,** found while gating:
  - read the audited ref from git rather than the working tree;
  - add a `WORKTREE` mode for uncommitted changes;
  - use `--` separators, because the fork's dev server creates a `dev/` folder that made `dev` ambiguous;
  - fail loudly on git errors.
- **Dev servers** now start detached with `setsid` (`iphi-flow/.work/start-ap-dev.sh`). A background-task restart had killed esbuild's helper processes.

## Amendment 2026-10-10 (f) — Phase 3 sealed
- **Phase 3 sealed:** fork `dev` commit `a9ea598bd2` (`feat(web): restyle the shared ui primitives`).
  - Requirements: PRM-01–27, TOK-11, TOK-18, TOK-19, TOK-20, MOT-01–17, MOT-19.
  - New pieces: the `segmented-control` primitive, a badge `tag` variant and sizes, an alert `notice` layout, a dialog `size` prop.
  - `cn()` now knows the `text-xss` / `text-xsm` sizes and the custom shadow names (this closes the Phase 2 gap).
  - Gate run by the orchestrator:
    - typecheck and lint: 0 errors;
    - web tests 1253/1253 (15 new); shared tests 574/574;
    - clean-room audit: PASS, 44 files, 0 overlap, 0 forbidden text;
    - visual check of dialog and menus done.
- **Partial items** (spec gaps, carried forward):
  - PRM-03 input affixes;
  - PRM-06 unread dot;
  - PRM-09 bottom fade;
  - ellipsis for long badge labels (PRM-13).
- **Interim side effect:** outline buttons whose call sites pass their own `border-*` colour lose that border, because the variant now draws an inset ring. Affected:
  - the data-table filter triggers (rebuilt in Phase 5, PAG);
  - `config-detail`;
  - `test-sample-data-viewer` (rebuilt in Phase 8, NDV).
  - Re-check in Phase 12.
- **Phase split:** Phase 4 covers SHL-01–18, SHL-25 and SHL-26. The builder header (SHL-19–24) stays with Phase 10.
