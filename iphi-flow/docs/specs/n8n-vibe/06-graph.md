# 06 — Graph: steps, handles, edges (NOD, HDL, EDG)

Builder-facing spec for everything drawn in flow coordinates: step boxes, the trigger, the join dot, handles, output labels, "+" stubs and edges. Positions, outputs per step type, insert locations and drag/re-parent rules are defined in `design/graph-positions.md`; this file defines how those things look and behave. Colours use the canvas palette `P-NN` from `05-canvas.md` CAN-01; conventions are listed at the top of `05-canvas.md`.

Plan phase: 7 (7.4 nodes and edges, 7.5 drag visuals).

Terms: **step** = an AP trigger or action on the canvas. **Box** = the step's measured rectangle (its label is outside it). **Output** = one of the step's outgoing handles from the design doc's `getStepOutputs`. **Run loaded** = the builder state holds a run (a test run, or a run opened from the runs list).

## Steps (NOD)

### NOD-01 — Action step box

- **Values:**

  | Property | Value |
  |---|---|
  | Width | 96px |
  | Height | 96px for 0–2 outputs; 96 + 32 × (n − 2) for n outputs above 2 |
  | Corner radius | 8px on all corners |
  | Fill | P-06 |
  | Border | 1.5px solid P-07; the fill stops inside the border |
  | Content | The piece logo, centred (NOD-03) |
  | Position | The stored or resolved position is the box's top-left, snapped to 16 (design doc §1) |

- **States:** Idle; hovered (no change to the box itself; the hover toolbar appears, NOD-05); selected (NOD-06); skipped (NOD-07); run and draft statuses (NOD-08, NOD-09); sample-data (NOD-10).
- **Light/Dark:** P-06, P-07 per mode.
- **Motion:** Border colour and width changes are instant; status changes have no transition.
- **AP target file(s):** `BUILDER/flow-canvas/nodes/step-node/index.tsx`, `BUILDER/flow-canvas/utils/consts.ts` (node sizes), `packages/core/execution/src/lib/flows/util/flow-layout-util.ts` (sizes are layout constants).
- **Notes:** Keep the `data-step-context-menu` attribute on the box so AP's right-click menu still finds the step. The current card content (logo, "N. name", piece name, chevron) and the "Trigger" tab are removed. The box no longer wraps the piece-selector popover trigger (the piece panel is not anchored to elements, `08-piece-panel.md`).

### NOD-02 — Trigger step shape, bolt and hover test button

- **Values:**
  - Box as NOD-01, but the two left corners have a 36px radius and the two right corners 8px. The trigger has no input handle.
  - Bolt: Lucide Zap, filled, 16px, accent-9. It sits outside the box on the left, vertically centred, with 16px of empty space between the bolt and the box's left edge.
  - Hover zone (flow coordinates, w and h = box size): a rectangle starting 2w left of the box's left edge and h above its top edge, 4w wide and 3h tall.
  - While the pointer is in the hover zone, the bolt is replaced by a test button: solid accent, 36px tall, radius 6, 14px/500 label, 12px horizontal padding, Lucide Play 16px leading icon in white. Its right edge sits 16px left of the box's left edge; vertically centred on the box.
  - Button label and action are the same as the test bar's main button (`05-canvas.md` CAN-12): "Test Flow", "Run Flow" for a manual trigger, "Open Chat" (Lucide MessageCircle icon) for a chat trigger.
- **States:**

  | State | Look |
  |---|---|
  | Pointer outside zone | Bolt visible, button hidden |
  | Pointer in zone | Bolt hidden, button visible |
  | Trigger has no sample data | Button at 50% opacity, not clickable, tooltip "Please test the trigger first" (existing key) |
  | Test running | Button disabled at 50% |
  | Read-only canvas, empty trigger | No button; bolt stays (empty trigger: no bolt, see `05-canvas.md` CAN-14) |

- **Light/Dark:** Accent in both modes.
- **Motion:** Bolt slides 12px to the left and fades out; the button starts 12px left of its rest position at opacity 0 and slides to rest while fading in. Both 100ms, ease-in; the reverse on leave.
- **AP target file(s):** `BUILDER/flow-canvas/nodes/step-node/index.tsx`, `BUILDER/flow-canvas/nodes/step-node/trigger-widget.tsx` (replaced by the bolt and button), `BUILDER/flow-canvas/widgets/above-trigger-button.tsx` (the run logic to reuse).
- **Notes:** Pressing on the button must not select or start dragging the trigger. The step hover toolbar (NOD-05) appears only when the pointer is over the box itself, not over the wider zone. Mount the button only while the pointer is in the zone (do not keep it in the DOM at opacity 0): e2e uses `getByRole('button', { name: 'Test Flow' })`, which must match exactly one element, and an invisible-but-present second "Test Flow" button would break it.

### NOD-03 — Piece logo inside the box

- **Values:** AP's `LogoPlate`, centred in the box: plate 56 × 56px, radius 8, no border, no tint, the plate's own light-theme island fill (white). The logo image is 40 × 40px inside it (8px padding). The plate keeps its `data-theme="light"` island.
- **States:** Normal; skipped (logo greyscale at 50% opacity); metadata loading (a 40 × 40px skeleton, radius 4); custom step logo (AP's per-step custom logo URL wins over the piece logo, as today).
- **Light/Dark:** In light mode the white plate blends into the white box and reads as a bare 40px logo. In dark mode it reads as a white rounded tile on the #2b2b2b box, which keeps dark single-colour logos visible.
- **Motion:** none.
- **AP target file(s):** `BUILDER/flow-canvas/nodes/step-node/step-node-logo.tsx`, `WEB/components/custom/logo-plate.tsx` (use with `border` and `tint` off; add a 56px size variant if none fits).
- **Notes:** Do not draw any other icon artwork on the box face.

### NOD-04 — Label below the box

- **Values:**

  | Part | Value |
  |---|---|
  | Placement | Outside the box, 8px below its bottom edge, centred on the box's centre line |
  | Text block width | At least 192px (two box widths); centred text |
  | Name line | The step's display name only (no step number), 16px/500, line-height 1.25, gray-12; wraps onto at most 2 lines and then ends with an ellipsis; may break inside long words |
  | Subtitle | The piece display name (for example "Code", "Gmail", "Loop on Items"), 4px below the name, 13px/400, line-height 1.25, gray-11 (reference #999999 light / #bbbbbb dark); one line, ellipsis |
  | Skipped line | When skipped, a line "(Skipped)" (new key) in name style is added below the name, above the subtitle |
  | Pointer events | None (the label never blocks canvas drags or clicks) |

- **States:** Normal; skipped; empty trigger (`05-canvas.md` CAN-14 owns its label).
- **Light/Dark:** gray-12 and gray-11 per mode.
- **Motion:** none.
- **AP target file(s):** `BUILDER/flow-canvas/nodes/step-node/step-node-display-name.tsx`, `step-node-run-duration-and-piece-name.tsx` (duration display removed from the canvas; it lives in the logs panel).
- **Notes:** The step number prefix ("3. Transform") is dropped on the canvas; the step modal's INPUT tree and AP's data references keep the number. The label is excluded from the box's measured size, so fit-to-view relies on the 0.2 padding.

### NOD-05 — Step hover toolbar

- **Values:**

  | Property | Value |
  |---|---|
  | Placement | Centred above the box; its bottom edge is 12px above the box's top edge (the 12px gap is part of the toolbar's hover area, so moving the pointer up from the box keeps it open) |
  | Strip | Background P-01 (it reads as icons floating on the canvas), radius 4, no border, no shadow |
  | Buttons | Ghost, 28 × 28px, 14px Lucide icons in gray-12, no gaps; hover background black 5% (dark white 10%) |
  | Tooltips | Above each button (`05-canvas.md` CAN-10 style) |

  | Order | Button | Lucide icon | Tooltip (key) | Shown on |
  |---|---|---|---|---|
  | 1 | Test this step | Play | "Test Step" (existing) | Actions and testable piece triggers |
  | 2 | Skip / unskip | RouteOff | "Skip" / "Unskip" (existing) + chip D | Actions only |
  | 3 | Delete | Trash2 | "Delete" (existing) + chip Del | Actions only |
  | 4 | More | Ellipsis | "More" (existing) | All steps; opens AP's step context menu anchored to the button |

- **States:** Shown while the pointer is over the box or the toolbar, or focus is inside the step. Stays open while its More menu is open. Hidden while the step is being dragged, on a read-only canvas, on the empty-trigger placeholder and on the join dot. Test button disabled (with tooltip "Fill in the required fields first", existing key) when the step is invalid or a test is running.
- **Light/Dark:** P-01 strip and gray-12 icons per mode.
- **Motion:** Fades in over 100ms (ease-in).
- **AP target file(s):** new `BUILDER/flow-canvas/nodes/step-node/step-node-toolbar.tsx`; `BUILDER/flow-canvas/utils/bulk-actions.ts` (skip, delete); `BUILDER/flow-canvas/context-menu/canvas-context-menu-content.tsx` (More); `BUILDER/test-step/test-runner-context.tsx` (test).
- **Notes:** The test runner currently lives inside the step-settings context. If it cannot be called from the canvas, the Test button may open the step modal and start the test there (acceptable fallback). `step-node-chevron.tsx` is retired; its menu moves to More.

### NOD-06 — Selected halo

- **Values:** A 6px ring drawn outside the box in P-08, following the box's corner radii (trigger: 36px left corners). No layout shift; the border keeps its state colour.
- **States:** Every selected step shows it (single click, Shift + click, rectangle selection). The step whose modal is open also shows it.
- **Light/Dark:** P-08 per mode.
- **Motion:** none.
- **AP target file(s):** `BUILDER/flow-canvas/nodes/step-node/index.tsx`.
- **Notes:** Replaces AP's accent border on the selected step. A single click selects and does not open anything (`07-step-modal.md` NDV-01).

### NOD-07 — Skipped step

- **Values:**
  - Border 1.5px in P-33.
  - Logo greyscale at 50% opacity (NOD-03).
  - "(Skipped)" label line (NOD-04).
  - Corner icon bottom-right, 6px inset: Lucide RouteOff 16px in P-32.
  - Strike-through: a 2px horizontal line in P-31 across the box's vertical centre, running from 4px left of the box's left edge to 8px past its right edge. It is drawn only for a plain step with exactly one input and one output connection (not on routers, loops, steps with continue-on-failure on, or the trigger).
- **States:** Skipped overrides success, failed, draft and sample-data visuals; it never shows the running ring (a skipped step does not run).
- **Light/Dark:** P-31, P-32, P-33 per mode.
- **Motion:** none.
- **AP target file(s):** `BUILDER/flow-canvas/nodes/step-node/step-node-skipped-status.tsx` (rewritten: no pill), `BUILDER/flow-canvas/nodes/step-node/index.tsx`.
- **Notes:** AP's grey box fill for skipped steps (gray-4) is removed; the box keeps P-06. Skipping uses `operations/skip-action.ts` (unchanged).

### NOD-08 — Run status visuals

Applies when a run is loaded (test run or run view).

- **Values:**

  | AP step status in the run | Border | Bottom-right corner (6px inset, 16px icon) |
  |---|---|---|
  | SUCCEEDED, STOPPED | 2px P-25 | Lucide Check in P-25; when the step ran more than once, the run count follows the icon, 14px/600, 2px gap |
  | FAILED | 2px P-26 | Lucide CircleX in P-26 |
  | RUNNING | Transparent; the running ring is shown | none |
  | PAUSED | Transparent; the ring at the slow speed | Lucide Pause in P-27 |
  | No output in this run (not reached, or branch not taken) | Idle border | none |

  - Running ring: drawn behind the box, 3px outside its edge on every side, with the box's corner radii plus 2px (10px; trigger 38px / 10px). It is a rotating conic sweep in P-29: fully opaque for roughly the first fifth of the turn, fading to 20% opacity by about a third, staying at 20% until about two thirds, and returning to fully opaque by about nine tenths.
  - Run count: a loop step shows its iteration count; a step inside a loop body shows the number of iterations in which it produced output. The border colour reflects the iteration currently selected (AP's `loopsIndexes`).
  - Precedence when several apply (later wins): idle < success < needs-test < failed < sample-data < skipped < running < paused. The selection halo is independent and combines with any of them.
  - Tooltip on the failed icon: the step's error message, shown 500ms after hover, below the icon.
- **States:** As the table.
- **Light/Dark:** P-25, P-26, P-27, P-29 per mode.
- **Motion:** Ring: one full turn per 1.5s for RUNNING and per 4.5s for PAUSED, linear, infinite.
- **AP target file(s):** `BUILDER/flow-canvas/nodes/step-node/step-node-status-in-run.tsx` (rewritten as border + corner icon), `step-node-badge-container.tsx` (retired), `BUILDER/flow-canvas/utils/flow-canvas-utils.ts` (`getStepStatus`), `WEB/features/flow-runs/utils/flow-run-utils.ts`.
- **Notes:** The ring is accent orange only; never the logo coral on the never-use list in `00-index.md`. AP's status pills above the box and the run-duration timer on the box are removed. The loop iteration picker that sits on the loop step today (`BUILDER/run-details/loop-iteration-input.tsx`) moves off the canvas into the logs panel tree and the step modal's data panes (`07-step-modal.md` NDV-17, `09-logs.md` LOG-07).

### NOD-09 — Draft status visuals

Applies to a draft version with no run loaded (AP's current draft-badge rules: hidden for the empty trigger, the manual trigger and skipped steps).

- **Values:**

  | AP draft status | Border | Bottom-right corner (6px inset, 16px icon) | Tooltip (500ms, below) |
  |---|---|---|---|
  | Incomplete (step not valid) | Idle | Lucide TriangleAlert in P-26 | "Incomplete" (existing key) |
  | Testing | Transparent; running ring (NOD-08) | none | — |
  | Last test failed | 2px P-26 | Lucide CircleX in P-26 | The test error |
  | Changed since the last test | 2px P-27 | Lucide History in P-27 | "This step has been updated since the last test" (existing key) |
  | Tested | Idle | Lucide Check in P-25 | — |
  | Never tested | Idle | none | — |

- **States:** As the table. A published (non-draft) version shows none of these.
- **Light/Dark:** Palette per mode.
- **Motion:** Ring as NOD-08.
- **AP target file(s):** `BUILDER/flow-canvas/nodes/step-node/step-node-status-in-draft.tsx` (rewritten as border + corner icon).
- **Notes:** AP's "Test me" pills are removed. The "Complete N steps" button in the test bar (`05-canvas.md` CAN-12) remains the flow-level nudge.

### NOD-10 — Sample-data ("pinned") visual

- **Values:** 2px border in P-28; bottom-right corner Lucide Pin 16px in P-28; outgoing edges in P-28 (EDG-03).
- **States:** Applies only to the **trigger**, only while a loaded run has environment TESTING, and only when the trigger is a piece trigger that is neither the manual trigger nor the chat trigger. In that run the trigger's output is its saved sample data, which is AP's equivalent of pinned data. It overrides the success visual.
- **Light/Dark:** P-28 per mode.
- **Motion:** none.
- **AP target file(s):** `BUILDER/flow-canvas/nodes/step-node/step-node-status-in-run.tsx`, `BUILDER/state/run-state.ts`.
- **Notes:** Actions: not mapped (AP never substitutes saved sample data for an action's output during a run).

### NOD-11 — Settings badges

- **Values:** Top-right corner of the box, 6px inset; a row of 20 × 20px boxes 1px apart, each holding a 12px Lucide icon in gray-11.

  | Step setting | Icon | Tooltip title | Tooltip body |
  |---|---|---|---|
  | Retry on failure on | RotateCw | "Retry on Failure" (existing) | "Retries up to 4 times before failing the step." (existing) |
  | Continue on failure on | ShieldAlert | "On failure" (existing) | "When this step fails, the flow continues down its Failure branch." (new key) |

- **States:** Hidden on skipped steps.
- **Light/Dark:** gray-11 per mode.
- **Motion:** none.
- **AP target file(s):** `BUILDER/flow-canvas/nodes/step-node/index.tsx` (new small part file allowed), reading the action's error-handling options.
- **Notes:** Tooltip title bold, body regular, per primitives.

### NOD-12 — Join dot

- **Values:**
  - A 16 × 16px circle at the join position the layout engine computes (design doc §3: right of the widest branch, on the router's centre line). Fill P-12, 1px border P-11 — it looks like a stand-alone handle.
  - It is the target of every branch exit (and of every empty branch output) and the source of the edge to the router's next step.
  - When the router or continue-on-failure step has no next step, the dot's right side carries a "+" stub (HDL-05) whose insert location is AFTER that step.
  - Hit area 24 × 24px.
- **States:** Never draggable, never selectable (no halo), no hover toolbar, no label. Run loaded and at least one incoming branch ran: border becomes 1.5px P-25. Optional tooltip on hover: "Branches join here before the next step" (new key).
- **Light/Dark:** P-11, P-12, P-25.
- **Motion:** none.
- **AP target file(s):** new `BUILDER/flow-canvas/nodes/join-node.tsx`; `BUILDER/flow-canvas/utils/types.ts`, `consts.ts`.
- **Notes:** The join is computed, never stored (design doc §3).

### NOD-13 — Zoom-dependent contrast (OPTIONAL)

- **Values:** Below 100% zoom, thin lines get stronger so the graph stays legible when zoomed out. For a zoom z, let t = (1 − z) / 0.8, clamped to 0…1, and weight = t raised to the power 2.2. Each value moves from its 100% value toward its 20%-zoom value by that weight (no change at z ≥ 1; full change at z ≤ 0.2).

  | Element | At 100% zoom | At 20% zoom |
  |---|---|---|
  | Step border opacity (P-07), light | black 10% | black 70% |
  | Step border opacity, dark | white 20% | white 70% |
  | Edge and stub line grey (P-09), light | #cacaca | #808080 |
  | Edge grey, dark | #4d4d4d | #929292 |
  | Handle border (P-11), light | #9b9b9b | #2e2e2e |
  | Handle border, dark | #636363 | #9e9e9e |

  Interpolate the greys in a perceptual lightness space (OKLab L: edge light 0.84 → 0.60, dark 0.42 → 0.66; handle light 0.68 → 0.30, dark 0.50 → 0.70). Edge hover stays relative: light hovered = current L − 0.30, dark hovered = current L + 0.20.
- **States:** Applies continuously while zooming.
- **Light/Dark:** Per table.
- **Motion:** Follows zoom; no extra transition.
- **AP target file(s):** a small hook in `BUILDER/flow-canvas/` that reads the viewport zoom and writes the values as CSS variables on the canvas root; consumed by step, handle, stub and edge components.
- **Notes:** Ship with fixed 100%-zoom values first.

### NOD-14 — Drag and re-parent visuals

- **Values:**
  - Dragging a step: grabbing cursor; the box, its label, its handles, output labels and "+" stubs move together; connected edges follow live; the hover toolbar is hidden. Positions snap to 16 during the drag.
  - Re-parent targets (single-step drag only, design doc §5): every eligible edge shows a drop indicator at its label anchor — the edge "+" button (EDG-05 look) at 60% opacity — and every eligible "+" stub stays visible. The dragged step's own edges and its descendants show none.
  - When the pointer is within 32px of a target's centre, that target is armed: its "+" box gets fill accent-3, glyph accent-9 and a 2px accent-9 ring; the other indicators stay at 60%.
  - Release on an armed target → `MOVE_ACTION` (design doc §5); release elsewhere → position-only update.
- **States:** Multi-step drags show no targets. Read-only: no dragging.
- **Light/Dark:** accent-3 / accent-9 per mode.
- **Motion:** Indicators fade in over 100ms when the drag starts and out on release.
- **AP target file(s):** `BUILDER/flow-canvas/index.tsx`, new `BUILDER/state/layout-state.ts` (`dropTargetId`), `BUILDER/flow-canvas/edges/flow-edge.tsx`, `BUILDER/flow-canvas/nodes/step-node/output-stub.tsx`; retire `step-drag-overlay.tsx` and the step droppables in `edges/add-button.tsx` and `flow-drag-layer.tsx`.
- **Notes:** Notes keep their own dnd-kit drag.

## Handles and outputs (HDL)

### HDL-01 — Input handle

- **Values:** 16 × 16px circle, centred on the box's left edge at half its height (half of it outside the box). Fill P-12, 1px border P-11. Hit area 24 × 24px.
- **States:** Not interactive (no hover change, cannot start a drag; default cursor). The trigger has none.
- **Light/Dark:** P-11, P-12.
- **Motion:** none.
- **AP target file(s):** `BUILDER/flow-canvas/nodes/step-node/index.tsx` (React Flow `Handle`, target, left), `BUILDER/flow-canvas/utils/consts.ts` (today's handles are invisible, opacity 0; they become visible).
- **Notes:** Edges end at the handle's left edge (React Flow computes the target point there), so the arrow tip touches the circle.

### HDL-02 — Output handle

- **Values:** Same circle as HDL-01 on the box's right edge, at the vertical position given by HDL-03. Hit area 24 × 24px.
- **States:**

  | State | Look |
  |---|---|
  | Idle | Fill P-12, 1px border P-11 |
  | Hovered | Scaled to 1.5×, border 1.5px P-14, fill P-13; crosshair cursor |
  | Read-only | Idle look, no hover change, default cursor |

- **Light/Dark:** Palette per mode.
- **Motion:** Scale and fill 200ms ease; border width 100ms ease.
- **AP target file(s):** `BUILDER/flow-canvas/nodes/step-node/index.tsx`.
- **Notes:** Pressing and dragging from it starts HDL-07.

### HDL-03 — Several outputs on one step

- **Values:** For n outputs, output i (counting from 0, top to bottom) sits at height × (i + 1) / (n + 1) from the box top. With the NOD-01 growth rule, outputs on a 2+-output step are exactly 32px apart and on the 16px grid (n = 2 on a 96px box: 32 and 64).

  | Step | Outputs, top to bottom |
  |---|---|
  | Trigger, plain action | 1, unlabelled |
  | Loop | "Done", then "Loop" |
  | Router / AI router | One per branch in settings order, labelled with the branch name; the fallback branch last, labelled "Otherwise" |
  | Continue-on-failure on | "Success", then "Failure" |

- **States:** Output count changes when branches are added or removed, or continue-on-failure is toggled.
- **Light/Dark:** n/a.
- **Motion:** none.
- **AP target file(s):** `BUILDER/flow-canvas/nodes/step-node/index.tsx` (one `Handle` per output, ids per the design doc), call React Flow's update-node-internals when the output count changes.
- **Notes:** Output order follows the design doc's `getStepOutputs`.

### HDL-04 — Output labels

- **Values:**
  - Shown only on steps with 2 or more outputs.
  - Text: the branch name; "Otherwise" (existing key) for the fallback branch; "Done" (existing key) and "Loop" (new key) for loops; "Success" and "Failure" (existing keys) for continue-on-failure.
  - 12px/400, colour P-04, on a P-05 backdrop that fits the text tightly.
  - Placement: the label's left edge is 12px right of the box's right edge (that is, 20px right of the handle's left edge); vertically centred on its handle; one line with an ellipsis.
  - Width: at most 96px when the output is connected; when it has a "+" stub, it never overlaps the "+" box.
- **States:**

  | State | Look |
  |---|---|
  | Idle | As above |
  | Hovered (router branches only) | Text gray-12 on a 4px-radius black 5% background; pointer cursor |
  | Click (router branches, not "Otherwise") | Opens AP's branch menu (Duplicate branch, Delete branch — existing items and keys) anchored below the label |
  | Double-click (router branches) | Opens the router's step modal with that branch selected |

- **Light/Dark:** P-04 / P-05 per mode.
- **Motion:** none.
- **AP target file(s):** `BUILDER/flow-canvas/edges/branch-label.tsx` (becomes the in-node output label; keeps its menu).
- **Notes:** The label belongs to the step node, so it moves with the step during a drag.

### HDL-05 — "+" stub on an unconnected output

- **Values:**

  | Part | Value |
  |---|---|
  | Where | On every output with nothing connected: the end of a chain, an empty loop body, the loop's "Done" output with no next step, a join dot with no next step, and the trigger of a flow with no actions |
  | Line | Starts at the handle's right edge and runs right; 2px; colour P-09 |
  | Line length | 46px when every output label on the step is at most 2 characters (or there are none); 66px when the longest is at most 6 characters; 80px otherwise; always 80px when the output produced data in the loaded run |
  | Box | Directly after the line: a 24 × 24px hit area holding a 22 × 22px rounded square (radius 4) filled P-15 |
  | Glyph | A plus with 8px arms, 1.5px stroke, round caps, colour P-17, centred in the box |
  | Hover | Box P-16, glyph P-18, pointer cursor |
  | Click | Opens the piece panel in next-step mode with this output's insert location (design doc §4 table) |
  | Test id | `data-testid="add-action-button"` on the box |

- **States:** Hidden on a read-only canvas. Hidden while a live line is being dragged out of the same handle (HDL-07), unless the pointer is over the stub. With run data: HDL-06.
- **Light/Dark:** P-09, P-15 to P-18 per mode.
- **Motion:** Appear and disappear by scaling from 0 (origin at the handle) and fading, 200ms ease.
- **AP target file(s):** new `BUILDER/flow-canvas/nodes/step-node/output-stub.tsx` (inside the node, so it moves during a drag); retire `nodes/big-add-button-node.tsx` and `nodes/flow-end-widget-node.tsx`.
- **Notes:** e2e: `BuilderPage.addAction` clicks `add-action-button`; on a new flow the only rendered one is the trigger's stub, so the test id must be on the stub box.

### HDL-06 — Stub with run data

- **Values:** When the output produced data in the loaded run: line colour P-25 and length 80px. If the output value is an array, an item-count label (EDG-06 text and look) is centred horizontally over the line with its bottom edge about 6px above it.
- **States:** Run loaded only.
- **Light/Dark:** P-25, P-04, P-05.
- **Motion:** Colour change 300ms ease.
- **AP target file(s):** `BUILDER/flow-canvas/nodes/step-node/output-stub.tsx`.
- **Notes:** —

### HDL-07 — Dragging out of an output handle

- **Values:** Pressing on an output handle and dragging draws a live line from the handle to the pointer (EDG-08). Releasing over empty canvas opens the piece panel in next-step mode for that output; the new step is placed with its box's top-left at the release point, snapped to 16. Releasing over a step, a handle or the panel does nothing. Releasing without moving is a click on the handle (no action).
- **States:** Not available on a read-only canvas or on the join dot.
- **Light/Dark:** See EDG-08.
- **Motion:** See EDG-08.
- **AP target file(s):** `BUILDER/flow-canvas/index.tsx` (connection start / end handlers with `nodesConnectable` kept off for step-to-step connections), `BUILDER/state/layout-state.ts` (pending position for the next added step).
- **Notes:** There are no arbitrary connections (plan, out of scope): a drag only ever adds a new step after the output.

## Edges (EDG)

### EDG-01 — Forward edge

- **Values:** A cubic Bézier from the source output handle's right edge to the target input handle's left edge, with React Flow's default curvature (0.25), source leaving to the right and target entering from the left. Stroke 2px, square line caps, no fill. Used whenever the target is not more than 20px left of the source.
- **States:** See EDG-03.
- **Light/Dark:** See EDG-03.
- **Motion:** none on geometry; edges follow dragged steps live.
- **AP target file(s):** new `BUILDER/flow-canvas/edges/flow-edge.tsx` (one edge type for every connection); retire `straight-line-edge.tsx`, `loop-start-edge.tsx`, `loop-return-edge.tsx`, `router-start-edge.tsx`, `router-end-edge.tsx`, `use-edge-layout-space.ts`, `BUILDER/flow-canvas/utils/svg-path-utils.ts`.
- **Notes:** —

### EDG-02 — Back-edge

- **Values:** When the target's x is more than 20px left of the source's x (a loop body returning to its loop):

  | Part | Value |
  |---|---|
  | Bottom line | y_low = max(source y, target y) + 130 |
  | Clearance | 40px horizontally from each handle |
  | Corner radius | 16px on every turn |
  | Route | Right from the source by 40px, down to y_low, left to 40px before the target, up to the target's y, right into the target |
  | Arrowheads | Two: one at the end of the route at the target, and one at the midpoint of the bottom line pointing left (in the direction of travel) |
  | Label / toolbar anchor | The midpoint of the bottom line, ((source x + target x) / 2, y_low) |

- **States:** As EDG-03.
- **Light/Dark:** As EDG-03.
- **Motion:** none.
- **AP target file(s):** new `BUILDER/flow-canvas/utils/edge-path-utils.ts` (`buildBackEdgePath`), `BUILDER/flow-canvas/edges/flow-edge.tsx`.
- **Notes:** The middle arrowhead can be drawn by rendering the route as two paths that meet at the bottom midpoint, each ending in an arrowhead, or as one path with a marker at its midpoint.

### EDG-03 — Edge colours by state

- **Values:**

  | State | Colour | Rule |
  |---|---|---|
  | Idle | P-09 | Default |
  | Hovered | P-10 | Only idle edges darken on hover |
  | Success | P-25 | Run loaded, the source step is SUCCEEDED or STOPPED, and the edge's target ran in this run (any status). For an edge from a router output, the branch was taken. For an edge into the join dot, the branch it closes ran |
  | Sample-data | P-28 | The source is the trigger in the NOD-10 state |
  | Running, failed, not reached | P-09 | Edges never show red or orange |

  Priority: sample-data, then success, then idle/hover. Coloured edges do not change on hover. Stroke width is 2px in every state.
- **States:** As the table.
- **Light/Dark:** Palette per mode (P-09 and P-10 may follow NOD-13).
- **Motion:** Colour changes over 300ms (ease).
- **AP target file(s):** `BUILDER/flow-canvas/edges/flow-edge.tsx`, `BUILDER/flow-canvas/utils/flow-canvas-utils.ts` (edge data needs the source and target run status), `WEB/styles.css` (drop the gray-7 edge stroke override).
- **Notes:** See the conflict note at the end about "both endpoints succeeded".

### EDG-04 — Arrowheads

- **Values:** A small closed triangle with rounded joins, about 7px long and 10px wide at the 2px stroke (it scales with the stroke). Filled and outlined in the edge's current colour, so it changes colour with the edge. The tip sits exactly at the end of the path, touching the target handle's left edge.
- **States:** On every edge that ends at a step. Not on edges that end at the join dot. Two on a back-edge (EDG-02). On the live drag line (EDG-08).
- **Light/Dark:** Follows the edge colour.
- **Motion:** Colour follows EDG-03.
- **AP target file(s):** `BUILDER/flow-canvas/edges/flow-edge.tsx` (one marker definition per colour state, or a marker that inherits the stroke colour).
- **Notes:** Draw the triangle from scratch; do not reuse any reference marker data.

### EDG-05 — Edge hover and the "+" toolbar

- **Values:**
  - Hover is detected on an invisible 40px-wide stroke along the path.
  - On hover the edge turns P-10, and its label (if any) is replaced by a toolbar centred on the label anchor (path midpoint; bottom midpoint for back-edges).
  - The toolbar holds **one** button, "+": 28 × 28px, radius 4, no border, fill P-15, Lucide Plus 14px in P-17; hover fill P-16 and glyph P-18. The toolbar has 8px padding around the button so the pointer can travel from the edge onto it.
  - Tooltip above: "Add step" (new key, shared with `05-canvas.md` CAN-11).
  - Click: opens the piece panel in next-step mode with the edge's insert location (design doc §4 table: AFTER the source, INSIDE_BRANCH i, INSIDE_LOOP, INSIDE_ON_SUCCESS_BRANCH / INSIDE_ON_FAILURE_BRANCH, or AFTER the router for the edge leaving a join dot).
  - Test id: `data-testid="add-action-button"` on the button (it exists in the DOM only while the edge is hovered).
  - There is **no** delete button: AP flows are a tree, so a connection cannot be removed on its own; deleting a branch stays in the output-label menu (HDL-04).
- **States:** Idle; hovered; leaving (the toolbar stays for 150ms after the pointer leaves both the edge and the toolbar, then the label returns). Read-only canvas: no darkening, no toolbar.
- **Light/Dark:** Palette per mode.
- **Motion:** Toolbar appears immediately; disappears after the 150ms delay.
- **AP target file(s):** `BUILDER/flow-canvas/edges/flow-edge.tsx` (rendered through React Flow's edge label renderer), `BUILDER/flow-canvas/utils/flow-canvas-utils.ts` (`createAddOperationFromAddButtonData`), `WEB/styles.css` (remove the rule that turns pointer events off on selectable edge paths), retire `BUILDER/flow-canvas/edges/add-button.tsx`.
- **Notes:** The toolbar is drawn above steps so it is never hidden under a box.

### EDG-06 — Item-count labels

- **Values:**
  - Shown only while a run is loaded.
  - Text: "N items" through a new ICU plural key: `{count, plural, =1 {1 item} other {# items}}`.
  - When: the edge's source output value in the run is an array (N = its length), or the edge is a loop's "Loop" output (N = the loop's iteration count in the run). Not shown when N is 0 or the output is not an array.
  - Look: 13px/400, P-04, on a P-05 backdrop, one line.
  - Placement: centred horizontally on the label anchor. On a curved edge the label is centred 12px above the anchor. On a straight horizontal edge (source y equals target y) the whole label sits above the line, its bottom edge about 6px above the stroke.
- **States:** Replaced by the toolbar while the edge is hovered.
- **Light/Dark:** P-04, P-05 per mode.
- **Motion:** none.
- **AP target file(s):** `BUILDER/flow-canvas/edges/flow-edge.tsx`, `BUILDER/flow-canvas/utils/flow-canvas-utils.ts`, `WEB/features/flow-runs/utils/flow-run-utils.ts` (`extractStepOutput`).
- **Notes:** Inside loops, the source output is the one for the selected iteration (AP `loopsIndexes`).

### EDG-07 — Edges at the join dot

- **Values:** Edges from branch exits and from empty branch outputs end at the dot's left side, flush with its circle, without an arrowhead. The edge leaving the dot starts at its right side and ends at the next step with a normal arrowhead. All of them carry the insert locations from the design doc table and get the EDG-05 toolbar.
- **States:** As EDG-03 (an edge into the dot is success-coloured when the branch it closes ran).
- **Light/Dark:** As EDG-03.
- **Motion:** none.
- **AP target file(s):** `BUILDER/flow-canvas/edges/flow-edge.tsx`, `BUILDER/flow-canvas/nodes/join-node.tsx`.
- **Notes:** Leaving the arrowheads off keeps several branches from crowding a 16px target.

### EDG-08 — Live drag line

- **Values:** While dragging out of an output handle (HDL-07): the same routing as EDG-01 / EDG-02 from the handle to the pointer; 2px; colour P-22; round caps and joins; an arrowhead at the pointer end.
- **States:** Shown only once the drag has lasted 300ms.
- **Light/Dark:** P-22 per mode.
- **Motion:** After the 300ms delay it fades in over 300ms.
- **AP target file(s):** `BUILDER/flow-canvas/index.tsx` (custom connection line component).
- **Notes:** —

### EDG-09 — Layering

- **Values:** Bottom to top: notes, edges, steps (with labels and stubs), edge toolbars and hover toolbars. A hovered edge is raised above other edges.
- **States:** n/a.
- **Light/Dark:** n/a.
- **Motion:** none.
- **AP target file(s):** `BUILDER/flow-canvas/index.tsx` (`elevateEdgesOnSelect` stays off; z-order through node and edge z-indexes).
- **Notes:** Edges do not animate (no moving dashes) in any state; the running state lives on the step ring.

## Conflicts with design doc

1. **Stub length.** The design doc uses a fixed STUB of 40px. This spec uses 46 / 66 / 80px depending on the longest output label and on run data (HDL-05), with the line starting at the handle's right edge. The layout engine does not depend on the stub length (column pitch 224 leaves room for 96 + 80 + 24), so only the stub component changes.
2. **Success colouring of edges.** The design doc says an edge turns green "when both endpoints succeeded". The reference turns an edge green when its source succeeded and its target ran, even if the target then failed (the edge into a failed step is green). EDG-03 follows the reference. If the orchestrator prefers the design doc's rule, only EDG-03's rule text changes.
3. **Back-edge arrowheads.** The design doc describes one back-edge path. The reference shows a second arrowhead at the midpoint of the bottom line. EDG-02 requires it (additive; geometry unchanged).
4. **Arrowheads into the join dot.** The design doc gives every forward edge an arrowhead. EDG-07 omits it on edges that end at the join dot.
5. **Output label offset.** The design doc says labels sit "20px right of the handle". HDL-04 makes this precise: 20px from the handle's left edge, which is 12px from the box edge. Clarification, not a change.
6. **Output label text.** The design doc names the continue-on-failure outputs `success` / `error` and the loop outputs `done` / `loop`. Those stay the output ids; the visible labels are AP's existing "Success" / "Failure" and "Done" plus a new "Loop" key.
7. **Empty-trigger placeholder size.** The design doc's NODE is 96px; the plan asks for a 100px placeholder. `05-canvas.md` CAN-14 draws 100px centred on the 96px layout box, so layout maths are unchanged.
