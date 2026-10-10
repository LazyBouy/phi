# Spike 7.0: controlled React Flow node dragging on AP's canvas (builder-facing)

Produced 2026-10-10 from the Activepieces fork and the `@xyflow/react` / `@xyflow/system` 12.3.5 sources only. Answers `design/graph-positions.md` §7 step 0 and §9 hard spot 5.

## Result

**Go with changes.** React Flow node dragging works next to AP's selection, the selection rectangle and its chevron, the step and canvas context menus, note dnd-kit dragging, panning and zoom. It works only with pattern (b) below. Pattern (a), which §5 of the design describes, loses React Flow selection on every moved node. §5 needs the edits listed under "Implications".

## Pattern to use

Candidate (b): local node state, every change applied with `applyNodeChanges`, re-seeded when the graph key changes.

How it is wired (the exact code is in the spike commit, `flow-canvas/index.tsx`):
- A memoised set of STEP node ids, derived from `graph.nodes`.
- A local state object holding `{ key, nodes }`, seeded with the current graph key and `graph.nodes`.
- The nodes passed to React Flow are the local nodes when the local key equals the current graph key; otherwise they are `graph.nodes`.
- `onNodesChange` first drops position changes for any id that is not a STEP. It then applies the remaining changes with `applyNodeChanges`, either to the local nodes (same key) or to `graph.nodes` (key changed), and stores the result under the current graph key.

ReactFlow props that worked together:

| Prop | Value | Why |
|---|---|---|
| `nodes` | `nodes` (above) | controlled |
| `onNodesChange` | handler above | applies `position`, `select` and `dimensions` changes alike |
| `onNodeDragStop` | `(event, node, draggedNodes) => commit(draggedNodes)` | one commit per drag |
| `onSelectionDragStop` | `(event, draggedNodes) => commit(draggedNodes)` | one commit per selection drag |
| `snapToGrid` / `snapGrid` | `true` / `[16, 16]` | positions in the stop handlers are already multiples of 16 |
| `nodeDragThreshold` | `4` | see the threshold quirk below |
| `nodeClickDistance` | `4` | a click with a few pixels of jitter still reaches AP's step `onClick` |
| `nodesDraggable` | `false` (unchanged) | node-level `draggable` decides; see below |
| `selectNodesOnDrag`, `selectionOnDrag`, `selectionMode`, `onSelectionChange`, `onSelectionEnd`, `onContextMenu`, `onPaneClick` | unchanged | AP's existing selection code works as is |

Node flags:
- STEP nodes: `draggable: true`, already set in `createStepGraph`. This is where readonly has to be enforced (`draggable: !readonly`).
- NOTE nodes: `draggable: false` **and** `className: 'nopan'`. dnd-kit keeps dragging them.
- BIG_ADD_BUTTON, GRAPH_END_WIDGET, LOOP_RETURN_NODE: `draggable` left undefined, so they follow `nodesDraggable={false}`. A DOM census confirmed they are not draggable.

Spike-only part: dragged positions went into an in-memory `committedPositions` map. It was overlaid on the graph nodes before seeding, standing in for `UPDATE_STEP_POSITIONS` + `flowVersion.stepPositions`. With that map, a dragged step kept its position when the graph was rebuilt by a later step click, because `selectedStep` is part of `createGraphKey`. Nothing was persisted.

dnd-kit for steps: switched off with `useDraggable({ disabled: true })` in `flow-canvas/nodes/step-node/index.tsx`; it was `isTrigger || readonly`. Nothing else was touched. The droppables in `edges/add-button.tsx` and `nodes/big-add-button-node.tsx`, `step-drag-overlay.tsx` and `handleStepDragEnd` in `flow-drag-layer.tsx` stay in place but are inert. `FlowDragLayer` still drives notes.

## What broke and how it was fixed

1. **Candidate (a) loses React Flow selection on moved nodes.** (a) keeps `graph.nodes` and overrides positions from a `dragPositions` map.
   - What happens: after a selection drag, the selection rectangle and the chevron disappear (rectangle bounding box `null`, chevron count 0). After a single drag, AP's `selectedNodes` falls back to `selectedStep` instead of the dragged step.
   - Cause, part 1: AP never applies changes to its node objects. Its selection works only because React Flow mutates its internal node records: `getSelectionChanges(..., mutateItem = true)` sets `selected` on the `nodeLookup` entries.
   - Cause, part 2: whenever a node object's identity changes, `adoptUserNodes` rebuilds the internal record from that object. Each override is a new object, so the internal `selected` flag and `measured` are reset. A node without `measured` renders hidden and loses its handle bounds until it is measured again.
   - Fix: candidate (b). With `applyNodeChanges`, `selected` and `measured` live on the node objects themselves. After the fix, the rectangle and chevron stay and follow the drag, `.react-flow__node.selected` is set on the three steps, and right-click on the moved rectangle opens the step menu.
2. **Candidate (c), uncontrolled `defaultNodes`, was not tried.** (b) passed all checks. (c) would need imperative `setNodes` calls for every AP graph change (operations, notes, `selectedStep`).
3. **Notes with `draggable: false` break note dragging in grab mode.** React Flow adds the `nopan` class only to draggable nodes. Without it, pressing on a note pans the canvas while dnd-kit drags the note: the viewport moved and the note landed elsewhere. Fix: `className: 'nopan'` on note nodes, after which the viewport stayed still and the position persisted.
4. **Node-level `draggable: true` overrides `nodesDraggable={false}`.** React Flow computes `isDraggable = node.draggable || (nodesDraggable && node.draggable === undefined)`. On `dev`, step and note nodes were already React Flow-draggable; React Flow emitted position changes that nothing applied. So `nodesDraggable = !readonly` cannot stop step dragging, and setting `nodesDraggable` to true would make the add-button, end-widget and loop-return nodes draggable.
5. **A click with 2px jitter does not open the step panel.** This is already true on `dev`: d3-drag swallows the click after any pointer movement, because the click distance defaults to 0. Fix: `nodeClickDistance={4}`, after which the jittered click opened the panel.
6. **The drag threshold is measured against the snapped pointer.** In `XYDrag`, the threshold test is `pointerPos.xSnapped − start.x`, the snapped pointer minus the unsnapped start (`getPointerPosition` in `@xyflow/system`). With a 16px grid, the effective threshold is anywhere from 0 to about 8 flow px, so a 2px jitter can start a drag.
   - On a grid-aligned node this causes no visible move, since snap(position + small delta) = position. `onNodeDragStop` still fires, so the commit must skip unchanged positions.
   - On AP's current off-grid layout (steps at y 120/240/360), the node jumps to the grid.
7. **Off-grid starting positions snap one by one.** In a selection drag every node moved dx 128, but dy was 8/0/8, because each node snaps to the grid independently. The new layout snaps every position to 16, so this disappears.
8. **Selected nodes are now raised.** `elevateNodesOnSelect` (default `true`) now applies because nodes carry `selected`: selected steps render at z-index 1050 instead of 50 on `dev`. Nothing overlapped badly in the test flows. Set `elevateNodesOnSelect={false}` if today's stacking must be kept.

## Interactions verified

Setup: Playwright driving system Chromium at 1440×900, AP dev user, vertical orientation, default zoom 1.25. The turbo Vite on 4200 had lost its esbuild service, so the web app ran from a second Vite on 4201 against the same API. The script is `.work/spike/spike-test.mjs`. Results are in `.work/spike/results-final.json` (spike) and `results-baseline-dev.json` (`dev`, step drags skipped). Screenshots are `.work/spike/shots/final-*.png`.

| # | Check | Result | Evidence |
|---|---|---|---|
| 1 | Drag a step ~160px right; it moves and snaps to 16 | PASS | `step_1` transform (0,120) → (128,128). 160px ÷ zoom 1.25 = 128. No flow write during the drag. |
| 1b | Same on Branching / Loop / Error | PASS | (156,450)→(240,496), (156,420)→(224,464), (0,120)→(80,160); all multiples of 16 |
| 2 | Plain click selects the step and opens the settings panel, no drag | PASS | `step_2` did not move. Sidebar 400px wide with "3. Transform", `border-accent-9` set. The earlier dragged step kept (128,128) after the graph rebuild. |
| 2b | Click with 2px jitter | PASS with `nodeClickDistance={4}` | Opened "4. Done". On `dev` the same click is swallowed. |
| 3 | Rectangle selection in select mode; chevron; selection drag | PASS | Rectangle 290×375 and chevron present. Selection drag moved `step_1..3` by dx 128 (dy 8/0/8, see item 7). Rectangle and chevron still present after the drop. |
| 3b | Right-click on the moved selection rectangle | PASS | Menu: Copy, Skip, Delete |
| 4 | Right-click step → step menu; empty canvas → canvas menu | PASS | Step menu: Replace, Copy, Duplicate, Skip, Copy reference, Paste After, Delete. Canvas menu: Paste After Last Step. |
| 5 | Note dnd-kit drag persists after reload (grab mode) | PASS | (300,−40) → (−96,144), still (−96,144) after reload. One `UPDATE_NOTE`; viewport unchanged during the drag. |
| 6 | Pan (grab drag, scroll) and zoom | PASS | Grab drag moved the viewport exactly (+120,+60). The wheel panned y. Ctrl+wheel zoomed 1.25 → 1.5. |
| 7 | No new console errors | PASS | 24 errors, all 404s from `/api/v1/platform-billing/info` and `/api/v1/pieces/@activepieces/piece-ai`. `dev` shows the same 24 from the same two URLs. |
| 8 | Do AP's current custom edges follow a dragged node? | No (as expected) | Only the dragged step's outgoing edge changed: its start moved, but it is still drawn straight down to the old end-widget node. Incoming edges, router edges and "+" buttons stay at the old layout. |

Not verified: readonly (no gating in the spike), horizontal orientation, touch input.

## Implications for design/graph-positions.md §5

Change these lines in §5:
- "`nodesDraggable` = not readonly" → "keep `nodesDraggable={false}`; STEP nodes `draggable: !readonly`; every other node type leaves `draggable` undefined (or `false`)". Node-level `draggable` overrides the global flag.
- Add `nodeClickDistance={4}` next to `nodeDragThreshold ≈ 4`. Note that with `snapToGrid` the threshold is measured against the snapped pointer (effectively 0–8 flow px), so a click can produce a drag that changes no position.
- "`onNodesChange` applies only STEP `position` changes into a transient store map `dragPositions`; nodes = `graph.nodes` with overrides; edges follow" → "nodes are local state seeded from `graph.nodes` and re-seeded when the graph key changes; `onNodesChange` applies **all** change types with `applyNodeChanges` and drops `position` changes for non-STEP ids; edges follow". Drop `dragPositions`.
- "`onNodeDragStop(e, node, nodes)` / `onSelectionDragStop` → snap → skip if unchanged → one `UPDATE_STEP_POSITIONS` → clear `dragPositions`" → "… skip if unchanged → one `UPDATE_STEP_POSITIONS`". Positions in the stop handlers are already snapped, so the snap is a safety no-op. Nothing needs clearing: the optimistic `flowVersion.stepPositions` update changes the graph key, which re-seeds the local nodes with the committed positions.
- "Notes explicitly `draggable: false` (keep their dnd-kit path)" → "Notes `draggable: false` **plus** `className: 'nopan'`". Without `nopan`, grab mode pans the canvas under a note drag.
- Keep "`createGraphKey` must include `stepPositions`"; the re-seed depends on it.
- Add a decision on `elevateNodesOnSelect`: default `true` raises selected steps to z-index +1000; `false` keeps today's stacking.

Knock-on edits elsewhere in that document:
- §7 step 5: `state/layout-state.ts` no longer needs `dragPositions`.
- §9 item 5: resolved by this pattern.
- §5 "Retire dnd-kit for steps" is unchanged. The spike only disabled `useDraggable` and confirmed the rest is inert.

## Spike commit

`3c57040414` on branch `spike/rf-drag` of the Activepieces fork (`chore(builder): spike controlled node dragging, not for merge`). Three files changed: `flow-canvas/index.tsx`, `flow-canvas/nodes/step-node/index.tsx` and `flow-canvas/utils/flow-canvas-utils.ts`. The working tree is back on `dev`.
