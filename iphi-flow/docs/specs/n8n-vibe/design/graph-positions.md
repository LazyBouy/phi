# Graph design: free-form step positions + left-to-right graph on AP's tree (builder-facing)

Design for plan Phase 7. Produced 2026-10-09 from Activepieces code only (no n8n material).

> **Precedence:** where this design and `06-graph.md` disagree on a *visual* detail, `06-graph.md` wins. The section "Spec reconciliation" at the end lists the known differences. The data model, operations, layout engine and drag rules here are unaffected.
Visual numbers come from the spec (`06-graph.md`, `05-canvas.md`). User decisions: draggable, persisted positions; left-to-right; router/continue-on-failure branches close with a small **join dot**.

## Summary
- **Storage:** flow-version-level map `stepPositions: Record<stepName, {x,y}>` in a new jsonb column. TypeORM migration yes; flow JSON schema bump **no** (stays v28). Empty map → auto-layout.
- **Operation:** `UPDATE_STEP_POSITIONS` merges a batch; sent once per drag-end, selection drag or tidy-up; no debounce; applied in place on the latest version without forking a draft (same path as note operations).
- **Layout engine:** new pure module in `core-execution`, shared by web canvas and the MCP tool. Tree → multi-output nodes; loop bodies close with a back-edge; routers and continue-on-failure close with a join dot.
- **Rendering:** one edge type (Bézier forward, rounded-step back-edge) + "+" stubs inside nodes for unconnected outputs.
- **Move/re-parent:** React Flow dragging for positions; dnd-kit retired for steps; re-parenting keeps `MOVE_ACTION`, triggered by dropping on an edge "+" or a stub.

## 1. Where positions live — option B (version-level map)

| Concern | A: `position` on each step | B: `flowVersion.stepPositions` (chosen) |
|---|---|---|
| Survives operations | `createAction` (`operations/add-action.ts`), `_updateAction` (`update-action.ts`), `createTrigger` (`update-trigger.ts`) rebuild steps field by field; zod request schemas strip unknown keys → dropped on ADD/UPDATE/IMPORT/MOVE | outside `trigger`; untouched |
| Race with settings autosave | `UPDATE_ACTION` autosaves (1s debounce keyed by step name) and would overwrite fresher drags | none |
| Schema cost | recursive hand-written union + zod union (`z.infer` OOMs tsc); 5 action variants + trigger | one field |
| Published versions | drag forks a draft or rewrites a LOCKED version's executable `trigger` | updated in place like notes (`flow.service.ts` note case group) |
| Release diff | `flow-diff.service.ts` would flag layout; `cleanAction` (`clean-flow-state.ts`) whitelists and drops it | ignored automatically, like note positions |
| Import/export/templates | automatic | thread through ~8 explicit builders; a miss degrades to auto-layout |
| Delete / name reuse | disappears with step | needs pruning (`findUnusedName` reuses the lowest free `step_N`) |

Schema (`packages/core/execution/src/lib/flows/flow-version.ts`):
- `StepCanvasPosition = z.object({ x: z.number(), y: z.number() })`
- `StepPositions = z.record(z.string(), StepCanvasPosition)`
- In `FlowVersion`: `stepPositions: StepPositions.default({})` — the default lets older `ProjectReplaceRequest.flows` payloads and old JSON templates parse; the output type is still required, so the compiler flags every hand-built version (`createEmptyVersion`, `migrateFlowVersionTemplate`, `createMinimalFlowVersion`, `cleanFlowVersion`, fixtures).
- The field must be in the zod schema: the server's response serializer returns only `schema.safeParse` data (unknown keys stripped).
- Position = top-left of the node box (label excluded), snapped to 16 by the client.
- `ImportFlowRequest`: add `stepPositions: Nullable(StepPositions)`.

DB migration (yes): `packages/server/api/src/app/database/migration/postgres/<ts>-AddStepPositionsToFlowVersion.ts` — `ALTER TABLE "flow_version" ADD COLUMN IF NOT EXISTS "stepPositions" jsonb NOT NULL DEFAULT '{}'` (constant default = metadata-only on PG 11+; do **not** copy the notes migration's backfill `UPDATE`, which rewrites every row); `down` drops the column; `breaking = false`; `release = '0.93.0'`; register in `postgres-connection.ts`; entity `stepPositions: { type: 'jsonb', nullable: false }` in `flow-version-entity.ts`. Check the PGLITE dev path too.

Flow JSON schema migration (no): additive and outside `trigger`; a v28→v29 bump would make `flowVersionMigrationService.migrate` write a backup file per version read and is a one-way door for rollbacks.

## 2. Operation `UPDATE_STEP_POSITIONS`
- Request `UpdateStepPositionsRequest = z.object({ positions: StepPositions })`; merge into the map.
- `flowOperations.apply` (`operations/index.ts`) + new `operations/step-positions-operations.ts`:
  - `UPDATE_STEP_POSITIONS`: `stepPositions = { ...(stepPositions ?? {}), ...request.positions }`.
  - **Tail prune for every operation:** reuse the `getAllSteps` list `apply` already builds (for `valid`) and drop keys with no step (covers DELETE_ACTION with descendants, DELETE_BRANCH, ROUTER→PIECE type change, name reuse).
  - `MOVE_ACTION` = DELETE + ADD internally → snapshot the moved subtree's positions before, restore after.
  - `IMPORT_FLOW`: after its sub-operations, `stepPositions = request.stepPositions ?? {}`.
  - Treat `stepPositions ?? {}` as possibly undefined at runtime (git-sync `git-sync-helper.ts` and release snapshots `project-state.service.ts` load with bare `JSON.parse` casts).
- Server:
  - `flow.service.ts update()`: add the type to the `ADD_NOTE`/`UPDATE_NOTE`/`DELETE_NOTE` case group (latest version, never `createNewDraftIfVersionIsPublished`).
  - Skip `flowSideEffects.onOperationApplied` for this type (no `FLOW_UPDATED` audit/event-destination per drag); optionally skip `updateLastModified` in `flowVersionSideEffects.preApplyOperation`.
  - RBAC WRITE_FLOW lists: `rbac-service.ts`, `rbac-middleware.ts`.
  - Audit description case: `packages/core/shared/src/lib/ee/audit-events/index.ts`.
- Client (`BUILDER/state/flow-state.ts`):
  - Readonly → refuse (do not even apply locally).
  - Switch case → `flowUpdatesQueue.add(updateRequest)` directly, **no debounce**: the keyed `debounce` in `packages/core/utils/src/lib/utils.ts` cancels a pending call whenever the same key repeats, so two drags under one key would lose the first.
  - Stays optimistic: keep the local `flowVersion`, take only `id` and `state` from the response.
- Batching:
  - One operation per `onNodeDragStop` / `onSelectionDragStop` (all dragged steps); one per tidy-up (all visible steps).
  - **Materialize on first write:** if the map is empty, the first drag sends the resolved positions of all visible steps plus the drag result (otherwise un-stored steps would move with their parents).
  - **Insert follow-ups** (only when the map is non-empty): after `ADD_ACTION`, `DUPLICATE_*`, paste batch or `MOVE_ACTION`, one follow-up operation with the new names' resolved positions, shifting an overlapped next step and everything after it by +224.
- Undo/collaboration: AP has no undo; single editor via `useResourceLock` (others readonly, cannot drag). Steps added by AI chat / MCP arrive without positions and are placed relative to their parent.

## 3. Layout engine
- New `packages/core/execution/src/lib/flows/util/flow-layout-util.ts` → `flowLayoutUtil` (separate module: the engine imports `flowCanvasUtils.getStepBranchRelativeTo`; core-execution must stay tree-shakeable). Keep `getContinueOnFailureBranchPair` and `getStepBranchRelativeTo` in `flow-canvas-util.ts`; delete `computeStepPositions`, `computeRouterChildOffsets` and `FLOW_CANVAS_*` once unused.
- Constants: GRID 16, NODE 96, COL_GAP 128 (pitch 224), ROW_GAP 96, OUTPUT_GROWTH 32, JOIN 16, STUB 40, BACK_EDGE_DROP 130, CLEARANCE 40, RADIUS 16.
- `getStepOutputs(step)` → `{ id: 'out-i', label?, location }`:

| Step | Outputs |
|---|---|
| Trigger, plain action | 1: `AFTER` |
| Loop | `done` (`AFTER`), `loop` (`INSIDE_LOOP`) — fixed order so the body sits below the main row |
| Router / AI router | one per `settings.branches[i]` (`INSIDE_BRANCH`, `branchIndex i`), labelled `branchName`; fallback branch = "otherwise" |
| Continue-on-failure on | `success` / `error` (`INSIDE_ON_SUCCESS_BRANCH` / `INSIDE_ON_FAILURE_BRANCH`); hidden when off (as `hasContinueOnFailureBranches` today) |

- Node height `96 + 32 × max(0, n − 2)`; output i at `h × (i+1)/(n+1)` — for n ≥ 2 the spacing is exactly 32px, on the grid.
- `computeAutoLayout({ trigger })` (two-pass bounding boxes, rotated to left-to-right):
  - Chain left to right at pitch 224, all centres on one y.
  - Router / continue-on-failure: branch blocks start at `x + 224`, stacked in output order with ROW_GAP, group centred on the router's centre y; empty branch → 32px slot; join at `max(branch right edges) + 64` on the router's centre y; `nextAction` after the join on the same y.
  - Loop: `done` chain continues on the main row at `x + 224`; body block starts at `x + 224` with top at `max(loop bottom, done-chain bottom) + ROW_GAP` (skyline packing can come later).
  - Snap everything to 16.
- `resolveStepPositions({ trigger, stepPositions })`, depth-first: stored wins; else `resolved[anchor] + (auto[step] − auto[anchor])` with anchor = previous step in the chain, or parent for the first step of a branch/body (gives "new step after X at X + 224"); empty map = auto-layout exactly; optional collision push-down one row pitch at a time; join positions always computed (not stored, not draggable).
- `tidyUp` = auto-layout translated so the trigger keeps its current position.
- Replaced / removed: `BIG_ADD_BUTTON` → stubs; `LOOP_RETURN_NODE` → back-edge from the body exit to the loop input; `GRAPH_END_WIDGET` / `FlowEndWidget` → removed (chain end = unconnected output with stub); all five edge types → one; delete `use-edge-layout-space.ts`, `svg-path-utils.ts`, `transposeGraphPositions`, `ORIENTATION_LAYOUT`, `canvasOrientation`, orientation buttons; add a `JOIN` node type; `branch-label.tsx` becomes the in-node output label (keeps duplicate/delete-branch menu).
- Join wiring (AP runs `router.nextAction` once after the branches):
  - non-empty branch: output i → first branch step; branch exit → join;
  - empty branch: output i → join;
  - join → `nextAction`, or the join shows a "+" stub (insert after the router);
  - "exit" of a chain = last step's output; if that step is a router / continue-on-failure step → its join; if a loop → its `done` output.

## 4. Edge rendering
- `edges/flow-edge.tsx` (`ApEdgeType.FLOW`), data `insertLocation: ApButtonData`.
- Forward: `getBezierPath` (source right, target left), 2px grey, `markerEnd` arrow.
- Back-edge if `targetX < sourceX − 20`; pure helper `utils/edge-path-utils.ts` → `buildBackEdgePath` with `yLow = max(sy, ty) + 130`, `c = 40`, `r = 16`: right from the source by `c`, down to `yLow`, back left to `tx − c`, up to `ty`, right into the target, all corners radius `r`. Label/toolbar anchor `((sx + tx)/2, yLow)`.
- Hover toolbar via `EdgeLabelRenderer`: "+" opens `PieceSelector` with `flowCanvasUtils.createAddOperationFromAddButtonData(insertLocation)` (reused); **no trash** (a tree has no detachable connection; branch delete stays in the output-label menu).
- Run state: green when both endpoints succeeded; "N items" on the `loop` edge (iteration count) or when the source output is an array.

| Edge | ADD_ACTION location / parent |
|---|---|
| step → `nextAction`; trigger → first step; loop `done` | `AFTER` source |
| router output i → first step | `INSIDE_BRANCH`, i |
| empty output i → join | `INSIDE_BRANCH`, i |
| `loop` → first body step | `INSIDE_LOOP` |
| `success` / `error` → first step | `INSIDE_ON_*` |
| branch exit → join; body exit → loop (back-edge) | `AFTER` the exit step |
| join → `nextAction` | `AFTER` the router / continue-on-failure step |

- Stub `nodes/step-node/output-stub.tsx` (inside the node so it moves during drag): 2px line `STUB` long → 24px "+" box; opens `PieceSelector` with id `${step}-${outputId}`; output label 20px right of the handle.

## 5. Drag
Corrected after the Phase 7.0 spike (`design/spike-7.0-findings.md`, spike commit `3c57040414` on `spike/rf-drag`). The original "position-only `dragPositions` overlay" loses React Flow's selection on every moved node, so it is replaced.
- **Pattern:** the canvas keeps a local copy of the nodes, `{ key: graphKey, nodes }`, seeded from `graph.nodes`. `onNodesChange` applies **every** change type with `applyNodeChanges` to that copy. Position changes are applied only for STEP node ids. Whenever the graph key changes, the copy re-seeds from the graph. No `dragPositions` slice in `layout-state.ts`.
- **ReactFlow props:**
  - `snapToGrid`, `snapGrid={[16,16]}`, `nodeDragThreshold={4}`, `nodeClickDistance={4}` (without it a click with 2px jitter does not open settings);
  - `elevateNodesOnSelect={false}`, which keeps today's stacking;
  - keep `nodesDraggable={false}`;
  - AP's selection props and handlers stay unchanged.
- **Readonly is per node:** a node-level `draggable` overrides `nodesDraggable`. So STEP nodes get `draggable: !readonly`, and every other node type stays non-draggable.
- `onNodeDragStop(e, node, nodes)` / `onSelectionDragStop(e, nodes)` → skip unchanged positions → one `UPDATE_STEP_POSITIONS`.
  - The positions they receive are already on the 16px grid, so no extra snapping is needed.
  - They also fire after a tiny click-drag: React Flow compares the snapped pointer with the unsnapped start, so the effective threshold is 0–8px. The skip-unchanged check covers that.
- After the commit, the optimistic `stepPositions` change alters the graph key, which re-seeds the local copy. `createGraphKey` (the hand-built string key) must include `stepPositions`.
- **Notes:** `draggable: false` **and** `className: 'nopan'`, so they keep their dnd-kit path. Without `nopan`, grab mode pans the canvas under a note drag.
- **Until the new layout lands:** today's computed positions are off the 16px grid, so a first drag jumps by up to 8px. This disappears once `flowLayoutUtil` snaps everything to 16.
- Replace `use-fit-to-view.ts` with `fitView({ padding: 0.2, maxZoom: 1 })`; drop `translateExtent`; call `useUpdateNodeInternals` when the output count changes without a size change (1 ↔ 2 outputs).
- Re-parenting (keeps `MOVE_ACTION`): while a single step drags, show drop indicators on every edge midpoint and stub, excluding its own edges and descendants (`flowStructureUtil.isChildOf`); release within a 32px target → `MOVE_ACTION { name, newParentStep, stepLocationRelativeToNewParent, branchIndex }`, then position the node at the drop point; elsewhere → position-only; multi-select drags never re-parent; `MOVE_ACTION` carries the step and children, not its `nextAction` chain.
- Retire dnd-kit for steps: `useDraggable` in `step-node/index.tsx`; droppables in `add-button.tsx` and `big-add-button-node.tsx`; `step-drag-overlay.tsx`; `handleStepDragEnd` in `flow-drag-layer.tsx`. Keep `FlowDragLayer` for notes.

## 6. Server-side impacts
- MCP `packages/server/api/src/app/mcp/tools/ap-flow-structure.ts`: place notes with `flowLayoutUtil.resolveStepPositions({ trigger, stepPositions })`; pass the map in `ap-duplicate-flow.ts`.
- Must pass `stepPositions`: `flow-version.service.ts` (`USE_AS_DRAFT`, `createEmptyVersion`), `project-state-helper.ts` (`updateFlowInProject`), `clean-flow-state.ts`, `migrations/index.ts` (`migrateFlowVersionTemplate` → `{}`), `template-validator.ts`; web `flow-hooks.tsx`, `use-automations-mutations.ts`, `flow-actions-menu.tsx`, `create-template-dialog.tsx`.
- Already covered (whole version passed): `createNewDraftIfVersionIsPublished`, `app-connection.handler.ts`, `getTemplate` export.
- Release diff ignores positions.
- Version bumps: `@activepieces/core-execution` minor, `@activepieces/shared` minor.
- Sample flows/templates: no positions → auto-layout. Notes in the event-destination sample flow (`handler-flow-builder.ts`) need new coordinates.

## 7. Implementation order
0. Spike React Flow 12.3.5 controlled `onNodesChange` with selection, selection rectangle + chevron, context menu and note dnd-kit together (main risk).
1. core-execution: schema, operation (enum, request, union, apply cases, tail prune), `step-positions-operations.ts`, `ImportFlowRequest`, `flow-layout-util.ts`, exports, version bumps.
2. Server: migration + entity, `flow.service.ts` routing + side-effect gating, RBAC (2 files), audit case, import sites, MCP.
3. Web model: `utils/types.ts` (STEP, JOIN, NOTE; FLOW edge), `utils/consts.ts`, rewrite `utils/flow-canvas-utils.ts` (`createFlowGraph` = resolve + outputs + edges + joins), delete orientation code (`layout-consts.ts`, `canvas-state.ts` field, toggle).
4. Web components: step node (96×96, trigger left radius 36, label 8px below, handles, output labels, stubs), `nodes/join-node.tsx`, `edges/flow-edge.tsx`, `utils/edge-path-utils.ts`; delete old edges and big-add / loop-return / end-widget nodes.
5. Web interaction: local-nodes pattern in the canvas (§5); `state/layout-state.ts` (`commitStepPositions`, `tidyUp`, `dropTargetId`, insert follow-ups) registered in `builder-hooks.ts`; `flow-state.ts` queue case; canvas props/handlers; re-parent targets; trim `flow-drag-layer.tsx`; tidy-up button + `Shift+Alt+T` (`shortcutHandler` has no Alt support; match `e.code === 'KeyT'` — macOS Option+T yields "†").
6. Import/export plumbing; brain gotchas in `brain/knowledge/flows-execution/flows.md` (also still says schema '27').

## 8. Tests
- core-execution `test/flow/step-positions.test.ts`: merge; prune of unknown names; DELETE_ACTION prunes descendants and a reused name gets no leftover; DELETE_BRANCH; ROUTER→PIECE; MOVE_ACTION preserves the subtree; IMPORT_FLOW with/without positions and on an undefined map; `FlowVersion`, `UpdateActionRequest`, `ImportFlowRequest` parse without the field.
- core-execution `test/flow/flow-layout-util.test.ts`: pitch 224 + shared centre y; snapping; router heights (n=2 → 96, n=5 → 192) + 32px handle spacing; branch stacking/centring; join placement; loop body below; continue-on-failure on/off; resolve (stored wins, anchored fallback, empty = auto, partial); tidy-up anchoring; stub detection for empty router/loop outputs.
- web: rewrite `flow-canvas-utils.test.ts` (only STEP/JOIN/NOTE; insert locations per table; stored positions verbatim; AI-router cases); new `edge-path-utils.test.ts` (back-edge geometry, 20px threshold); `layout-state` tests (one snapped op per drag, no-op when unmoved, materialization, follow-up shift, readonly, re-parent → MOVE_ACTION); `flow-state` test (two quick position ops both queued); delete `svg-path-utils.test.ts`, `layout-consts.test.ts`, `step-drag-overlay.test.tsx`; run `tsconfig.spec.json` (nothing else typechecks `web/test`).
- server: `flow-operations.test.ts` (persist + prune; no draft fork on LOCKED; later edit forks a draft carrying positions; IMPORT_FLOW and USE_AS_DRAFT carry positions); `flow-diff.test.ts` (position-only → no diff; `cleanFlowState` keeps positions); migration up/down.

## 9. Known hard spots
1. Keyed `debounce` drops same-key calls.
2. `findUnusedName` reuses deleted names → prune.
3. Response serializer strips unknown fields; `JSON.parse`-cast loads bypass zod defaults.
4. AP routers merge implicitly → join dot.
5. Canvas nodes are controlled with no `onNodesChange`, memoized by a hand-built string key.
6. Steps in disabled continue-on-failure branches stay in the tree but are hidden.
7. Existing note positions were placed for the vertical canvas (optional remap: anchor each note to its nearest step in the old layout).
8. Position operations would otherwise emit `FLOW_UPDATED` and bump `lastModified`.
9. d3-zoom cannot use a minimum of 0 → use 0.05.
10. Labels sit outside the measured 96px box → `fitView` relies on padding 0.2.

## Spec reconciliation (2026-10-09, after `06-graph.md` landed)
`06-graph.md` is authoritative for these visual details:

| Topic | This design said | Use instead (06-graph.md) |
|---|---|---|
| Stub length | fixed `STUB` 40px | 46 / 66 / 80px depending on the longest output label (80px when the output has run data), measured from the handle's right edge. `STUB` stays a layout constant only. |
| Green edge rule | green when both endpoints succeeded | green when the source succeeded **and** the target ran, so the edge into a failed step is also green |
| Back-edge arrowheads | `markerEnd` only | also a mid-run arrowhead at the midpoint of the bottom segment; route geometry unchanged |
| Edges into the join dot | arrowhead | no arrowhead |
| Output label offset | 20px right of the handle | 20px from the handle's left edge, i.e. 12px from the node box edge; texts are AP's "Success" / "Failure", "Done", and a new "Loop" key |
| Empty-trigger placeholder | — | 100px dashed box centred on the 96px layout box; layout maths unchanged |
