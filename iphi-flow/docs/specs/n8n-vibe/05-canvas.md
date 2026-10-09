# 05 — Canvas (CAN)

Builder-facing spec for the flow-builder canvas chrome: background, viewport, interactions, minimap, floating toolbars, the test bar, the empty-trigger placeholder, sticky notes and the keyboard map. Graph elements (steps, handles, edges) are in `06-graph.md`; the step modal is in `07-step-modal.md`; the piece panel is in `08-piece-panel.md`; the logs panel is in `09-logs.md`.

Plan phase: 6. Layout and position rules come from `design/graph-positions.md`; this file agrees with it (see the closing section).

## Conventions used in 05–09

- `BUILDER/` = `iphi-flow/activepieces/packages/web/src/app/builder/`. `WEB/` = `iphi-flow/activepieces/packages/web/src/`.
- Sizes are CSS pixels at 100% canvas zoom unless a block says the value stays constant on screen.
- Colours: AP token steps (`gray-N`, `accent-N`, `success-N`, `warning-N`, `danger-N`) are used where `01-tokens.md` defines the role (accent = Tailwind orange, step 9 = orange-500 #ff6900; success-9 = green-600 #00a63e; danger-9 = red-600 #e7000b; warning-9 = gold #b57617; focus = violet). Canvas-only colours are defined once, as the **canvas palette** in CAN-01, and every later file refers to them by palette ID (`P-NN`). Where a measured value is not a Tailwind v4 step, the nearest Tailwind step is listed; builders use the exact value unless `01-tokens.md` says off-palette greys are not allowed, in which case they use the listed Tailwind step.
- Implement canvas palette entries as theme variables in the light and dark blocks of `WEB/styles.css` (AP forbids `dark:` colour utilities outside that file and `components/ui/`). Variable names are the builder's choice; a `canvas-` prefix is suggested.
- Every user-visible string goes through an i18n key in `packages/web/public/locales/en/translation.json`. Where a block says "existing key", the key already exists with that English text. Where it says "new key", add it with the English text given.
- Motion values are listed per block; `10-motion.md` (MOT) is the master table, and reduced-motion turns all of them off.

## Requirements

### CAN-01 — Canvas palette

- **Values:**

  | ID | Role | Light | Dark | Source / note |
  |---|---|---|---|---|
  | P-01 | Canvas background | #f5f5f5 | #171717 | Tailwind neutral-100 / neutral-900. AP role: gray-2 ("flow canvas") |
  | P-02 | Grid dot | #999999 | #444444 | Plan values. Nearest Tailwind: neutral-400 #a1a1a1 / neutral-700 #404040 |
  | P-03 | Read-only stripe | #e5e5e5 at 50% | #262626 at 50% | Tailwind neutral-200 / neutral-800 |
  | P-04 | Canvas label text | #737373 | #999999 | Tailwind neutral-500 / nearest neutral-400 |
  | P-05 | Canvas label backdrop | P-01 at 85% opacity | P-01 at 85% opacity | Hides grid dots and edges behind small labels |
  | P-06 | Step fill | #ffffff | #2b2b2b | White / nearest Tailwind neutral-800 #262626 |
  | P-07 | Step border (idle) | black at 10% | white at 20% | Renders ≈ #dcdcdc on P-01 (light), ≈ #454545 (dark) |
  | P-08 | Selection halo | Tailwind slate-700 #314158 at 10% | white at 40% | Renders ≈ #e0e3e7 on P-01 (light), ≈ #747474 (dark) |
  | P-09 | Edge, idle | #cacaca | #4d4d4d | Nearest Tailwind neutral-300 #d4d4d4 / neutral-600 #525252 |
  | P-10 | Edge, hovered | #6f6f6f | #868686 | Nearest Tailwind neutral-500 #737373 in both modes |
  | P-11 | Handle border | #9b9b9b | #636363 | Nearest Tailwind neutral-400 / neutral-600 |
  | P-12 | Handle fill | #ffffff | #2b2b2b | Same as P-06 |
  | P-13 | Handle fill, hovered | #f5f5f5 | #444444 | Tailwind neutral-100 / nearest neutral-700 |
  | P-14 | Handle border, hovered | #d9d9d9 | #d9d9d9 | Nearest Tailwind neutral-300 |
  | P-15 | "+" box | #e5e5e5 | #2b2b2b | Tailwind neutral-200 / as P-06 |
  | P-16 | "+" box, hovered | #e0e0e0 | #323232 | Nearest Tailwind neutral-200 / neutral-800 |
  | P-17 | "+" glyph | #444444 | #e0e0e0 | Nearest Tailwind neutral-700 / neutral-200 |
  | P-18 | "+" glyph, hovered | #2b2b2b | #f0f0f0 | Nearest Tailwind neutral-800 / neutral-100 |
  | P-19 | Floating chrome surface (controls, toolbars) | #ffffff | #262626 | White / Tailwind neutral-800 |
  | P-20 | Floating chrome shadow | 0 1px 3px −1px, black at 10% | same geometry, black at 25% | Equals the tokens "xs" shadow |
  | P-21 | Empty-trigger placeholder fill | #ffffff | #171717 | White / Tailwind neutral-900 |
  | P-22 | Placeholder dash and icon | #999999 | #bbbbbb | Nearest Tailwind neutral-400 #a1a1a1 |
  | P-23 | Minimap background | #fafafa | #171717 | Tailwind neutral-50 / neutral-900 |
  | P-24 | Minimap step block | #e0e0e0 | #444444 | Nearest Tailwind neutral-200 / neutral-700 |
  | P-25 | Success | success-9 #00a63e | success-9 #00a63e | Tailwind green-600 |
  | P-26 | Danger | danger-9 #e7000b | #ff6467 | Tailwind red-600 / red-400 |
  | P-27 | Warning | warning-9 #b57617 | warning-9 #b57617 | Plan gold (not a Tailwind colour) |
  | P-28 | Sample-data ("pinned") | #7f22fe | #8e51ff | Tailwind violet-600 / violet-500 |
  | P-29 | Running ring | accent-9 #ff6900 | accent-9 #ff6900 | Tailwind orange-500. Never the logo coral on the never-use list in `00-index.md` |
  | P-30 | Selection rectangle | fill #155dfc at 8%, border 1px dotted #155dfc at 80% | same | Tailwind blue-600 |
  | P-31 | Skipped strike line | #e0e0e0 | #444444 | Nearest Tailwind neutral-200 / neutral-700 |
  | P-32 | Muted canvas icon (skipped, placeholder) | #999999 | #bbbbbb | Nearest Tailwind neutral-400 |
  | P-33 | Canvas divider (minimap border, panel edges) | #e5e5e5 | #323232 | Tailwind neutral-200 / nearest neutral-800 |

- **States:** n/a (palette only).
- **Light/Dark:** both columns above.
- **Motion:** n/a.
- **AP target file(s):** `WEB/styles.css` (light and dark blocks, plus the React Flow override block that today sets the edge stroke and the selection rectangle to accent).
- **Notes:** Replace the existing React Flow overrides that point the edge stroke at gray-7 and the selection rectangle at the accent; the accent becomes orange and must not colour the selection rectangle.

### CAN-02 — Background dot grid

- **Values:** Dot pattern on P-01. Gap 16px in both directions (the same 16px grid steps snap to). Dot diameter 1px at 100% zoom (a single pixel at about 75% coverage); the gap and dot scale with zoom. Dot colour P-02.
- **States:** Normal; read-only (CAN-03).
- **Light/Dark:** P-01 / P-02 per mode.
- **Motion:** The pattern moves with pan and zoom (no parallax).
- **AP target file(s):** `BUILDER/flow-canvas/index.tsx` (the `Background` element: gap 10 → 16, keep the dots variant and size 1, colours to P-01/P-02; the canvas wrapper background to P-01).
- **Notes:** Verify by computed-style probe: canvas background rgb(245,245,245), grid gap 16px.

### CAN-03 — Read-only background (OPTIONAL)

- **Values:** When the canvas is read-only (viewing a run, an old version, or the flow is locked by another editor), the dots are replaced by diagonal stripes: a 20px repeating tile rotated 135°, each tile holding one 10px-wide stripe in P-03. The tile scales and moves with zoom and pan.
- **States:** Read-only only.
- **Light/Dark:** P-03 per mode.
- **Motion:** none.
- **AP target file(s):** `BUILDER/flow-canvas/index.tsx` (a custom pattern in place of the dot background when `readonly` is true).
- **Notes:** Optional polish; ship the dot grid first.

### CAN-04 — Viewport limits and zoom steps

- **Values:**

  | Property | Value |
  |---|---|
  | Minimum zoom | 0.05 (the reference allows 0; d3-zoom cannot, so AP uses 0.05) |
  | Maximum zoom | 4 |
  | Zoom-in / zoom-out step | multiply / divide by 1.2 (React Flow default) |
  | Snap grid for step positions | 16 × 16 |
  | Translate extent | none (remove the current extent; the user can pan anywhere) |

- **States:** n/a.
- **Light/Dark:** n/a.
- **Motion:** Zoom buttons and zoom keys apply instantly (no tween). Programmatic "focus a step" (jump to failed step, select from logs) pans with a 200ms linear tween.
- **AP target file(s):** `BUILDER/flow-canvas/index.tsx` (`minZoom`, `maxZoom`, remove `translateExtent`), `BUILDER/flow-canvas/canvas-controls/index.tsx`.
- **Notes:** Today AP clamps zoom to 0.5–1.5 and computes a translate extent from the graph bounds; both go.

### CAN-05 — Fit on load, first appearance, resize

- **Values:**
  - On first load of a flow (and when switching versions or opening a run), fit all steps and notes with padding 0.2 of the viewport and a maximum zoom of 1 (the view never zooms in past 100% to fit a small flow).
  - The `1` key and the controls' fit button run the same fit.
  - The `0` key sets zoom to exactly 1, keeping the viewport centre fixed.
  - When an empty flow is laid out by the auto-layout, the trigger's top-left lands at flow coordinates (176, 240) — both multiples of 16 — before the fit.
  - When the canvas container changes size (window resize, logs panel open/close, piece panel), the flow point at the centre of the viewport stays at the centre.
- **States:** Loading (canvas hidden) → ready (canvas shown).
- **Light/Dark:** n/a.
- **Motion:** The whole canvas fades from opacity 0 to 1 over 300ms (ease) once nodes are measured and the first fit has run, so the user never sees the pre-fit jump.
- **AP target file(s):** `BUILDER/flow-canvas/index.tsx`; replace `BUILDER/flow-canvas/canvas-controls/use-fit-to-view.ts` (its maths assume the vertical layout) with a plain fit call; `BUILDER/flow-canvas/hooks.tsx` (`useResizeCanvas`, `useFocusOnStep`).
- **Notes:** Step labels sit outside the 96px box, so the 0.2 padding is what keeps labels inside the viewport (design doc hard spot 10). The (176, 240) origin is a layout-engine constant suggestion; `design/graph-positions.md` does not fix an origin, so it is a free choice as long as it is snapped to 16.

### CAN-06 — Pan, zoom, select, cursors

- **Values:**

  | Input | Result |
  |---|---|
  | Mouse wheel / two-finger trackpad scroll | Pans in both axes |
  | Ctrl/⌘ + wheel, or trackpad pinch | Zooms around the pointer |
  | Hold Space or hold Ctrl/⌘ | Enters pan mode: left-drag pans, wheel zooms; releasing the key returns to select mode |
  | Middle-button drag | Always pans |
  | Left-drag on empty canvas (select mode) | Draws a selection rectangle (CAN-07) |
  | Left-drag on a step | Moves the step (`06-graph.md`, design doc §5) |
  | Click on empty canvas | Clears the selection and closes the piece panel |
  | Double-click on empty canvas | Nothing (zoom on double-click is off) |
  | Touch devices | One-finger drag pans; Shift + drag selects |

  | Situation | Cursor |
  |---|---|
  | Over empty canvas, select mode | Default arrow |
  | Space or Ctrl/⌘ held (pan mode) | Grab |
  | While panning | Grabbing |
  | Over a step | Pointer |
  | While dragging a step | Grabbing |
  | Over an output handle | Crosshair |

- **States:** Select mode (default), pan mode (key held). Losing window focus returns to select mode.
- **Light/Dark:** n/a.
- **Motion:** none.
- **AP target file(s):** `BUILDER/flow-canvas/index.tsx` (`panOnScroll` stays on; `panOnDrag` becomes the middle button only, or left + middle while a pan key is held; `selectionOnDrag` on in select mode; zoom-activation keys Space and Ctrl/Meta), `BUILDER/state/canvas-state.ts` (remove the persisted grab/select `panningMode`), `WEB/styles.css` (cursor overrides).
- **Notes:** The grab-mode and select-mode toggle buttons are removed from the controls (CAN-09). AP's current rule "Shift switches modes" is replaced by the Space / Ctrl rule above; Shift + click still adds to the selection.

### CAN-07 — Selection rectangle and multi-selection box

- **Values:** The live selection rectangle uses P-30. A step is selected when the rectangle touches it (partial mode, as today). After the drag ends, the selected steps get their selection halo (`06-graph.md` NOD-06) and, if more than one element is selected, a bounding box drawn 8px outside the selected elements in P-30. A box around a single element is not drawn.
- **States:** Dragging; settled multi-selection.
- **Light/Dark:** P-30 in both modes.
- **Motion:** none.
- **AP target file(s):** `BUILDER/flow-canvas/index.tsx`, `BUILDER/flow-canvas/widgets/selection-chevron-button.tsx` (keep AP's chevron next to the selection box; restyle it as a 28px ghost button on P-19 with the P-20 shadow), `WEB/styles.css`.
- **Notes:** AP's rule that selecting a loop, router or continue-on-failure step also selects its children stays.

### CAN-08 — Minimap

- **Values:** 200 × 120px, docked bottom-left: 16px from the canvas left edge, its bottom edge 72px above the canvas bottom edge (it sits directly above the controls group). Background P-23, 1px border P-33, radius 4, contents clipped. Each step is drawn as a block in P-24 with 16px corner radius (in minimap units); notes are drawn in P-24 at 20% opacity. The viewport mask uses React Flow's default mask. The minimap is pannable and zoomable.
- **States:**

  | State | Rule |
  |---|---|
  | Hidden (default) | Not shown when the canvas is idle |
  | Shown | Appears as soon as the user pans (pan-mode drag, middle drag, or wheel/trackpad scroll) |
  | Hiding | 1000ms after the last pan movement it hides, unless the pointer is over the minimap |
  | Hovered | Stays visible while hovered; leaving starts the 1000ms timer again |
  | Programmatic moves | Fit, zoom buttons and "focus step" do not show it |
  | Small screens | Never shown below 768px viewport width |

- **Light/Dark:** P-23 / P-24 / P-33 per mode.
- **Motion:** Fade in and out over 300ms (ease).
- **AP target file(s):** `BUILDER/flow-canvas/widgets/minimap.tsx`, `BUILDER/state/canvas-state.ts` (drop the `showMinimap` toggle state), `BUILDER/shortcuts.ts` (drop Ctrl/⌘+M).
- **Notes:** AP currently colours each block with the average colour of the piece logo and toggles the minimap from a button and Ctrl/⌘+M. Both go: blocks are flat P-24 and visibility follows panning only.

### CAN-09 — Bottom-left controls group

- **Values:**

  | Property | Value |
  |---|---|
  | Position | 16px from the canvas left edge and 16px from the canvas bottom edge |
  | Group | Horizontal row, no gaps between buttons, 2px inner padding, radius 6, P-19 surface, P-20 shadow, no border |
  | Buttons | Ghost, 36 × 36px, 16px Lucide icons in gray-12; hover background black 5% (dark: white 10%); pressed black 10% (dark: white 15%); focus ring per tokens |
  | Overall size | 148 × 40px with four buttons; 112 × 40px when tidy-up is hidden |

  | Order | Action | Lucide icon | Tooltip label | Shortcut chip |
  |---|---|---|---|---|
  | 1 | Fit view | Maximize | "Fit to view" (existing key) | 1 |
  | 2 | Zoom in | ZoomIn | "Zoom in" (existing key) | + |
  | 3 | Zoom out | ZoomOut | "Zoom out" (existing key) | − |
  | 4 | Tidy-up (re-run auto-layout, design doc §3 `tidyUp`) | WandSparkles | "Arrange steps" (new key) | ⇧ Alt T (⌥ on macOS) |

- **States:** Tidy-up is hidden when the canvas is read-only. Buttons have no "active" state.
- **Light/Dark:** P-19, P-20 per mode.
- **Motion:** Tooltips per CAN-10.
- **AP target file(s):** `BUILDER/flow-canvas/canvas-controls/index.tsx`, `BUILDER/flow-canvas/canvas-controls/canvas-control-button.tsx`.
- **Notes:** Removed from AP's current bar: the minimap toggle (separate box), download as image, vertical/horizontal layout toggle, grab mode, select mode, add note (moves to CAN-11). "Download as image" moves into the canvas right-click menu (`BUILDER/flow-canvas/context-menu/canvas-context-menu-content.tsx`, existing key "Download as image") so the feature is kept. The bar is no longer centred; it is anchored bottom-left.

### CAN-10 — Canvas tooltips with shortcut chip

- **Values:** Tooltip per the primitives spec (black bubble, 13px/500 text, 8px radius, no arrow). For canvas chrome the bubble holds the label, an 8px gap, then one chip per key: each chip 18px tall, minimum 18px wide, 4px horizontal padding, radius 2, white at 30% background, no border, 10px text in neutral-200 #e5e5e5, chips 4px apart. Modifier glyphs: Ctrl or ⌘ (by platform), ⇧ for Shift, Alt or ⌥ (by platform). Letter keys are shown upper-case.
- **States:** Shows 500ms after hover starts; hidden while the button is being pressed or dragged.
- **Light/Dark:** Same bubble in both modes.
- **Motion:** Per primitives tooltip.
- **AP target file(s):** `BUILDER/flow-canvas/canvas-controls/canvas-control-button.tsx`; reuse `WEB/components/custom/shortcut.tsx` for the key text, restyled as chips inside the tooltip.
- **Notes:** Placement: above for the bottom controls and the test bar; to the left for the top-right toolbar.

### CAN-11 — Top-right vertical toolbar

- **Values:** Same group styling as CAN-09 but vertical: 2px padding, 36 × 36px ghost buttons stacked with no gaps, P-19 surface, P-20 shadow, radius 6. Position: 16px from the canvas top edge and 16px from the canvas right edge. Size 40 × 112px.

  | Order | Action | Lucide icon | Tooltip label | Chip |
  |---|---|---|---|---|
  | 1 | Add step: opens the piece panel to add a step after the selected step, or after the last step of the main chain when nothing is selected | Plus | "Add step" (new key) | N |
  | 2 | Search: opens AP's global search | Search | "Search" (existing key) | Ctrl/⌘ K |
  | 3 | Add note: starts AP's note-placement overlay (the note follows the pointer until a click drops it) | StickyNote | "Add note" (existing key) | ⇧ S |

- **States:** Hidden while the piece panel is open. Hidden entirely in read-only mode. "Add note" shows the pressed background while note placement is active.
- **Light/Dark:** P-19, P-20.
- **Motion:** Tooltips open to the left (CAN-10).
- **AP target file(s):** new `BUILDER/flow-canvas/widgets/canvas-toolbar.tsx`; `BUILDER/flow-canvas/canvas-controls/index.tsx` (add-note handler moves here); `WEB/app/components/global-search/global-search-context.tsx` (open the existing search).
- **Notes:** If the global search provider is not mounted under the builder route, mount it or drop button 2. There is no fourth button (the reference has a side-panel toggle and an AI button; both are out of scope).

### CAN-12 — Bottom-centre test bar

- **Values:**

  | Property | Value |
  |---|---|
  | Position | Horizontally centred in the canvas, 16px above the canvas bottom edge (the canvas bottom is the top of the logs panel when it is open). Below a 768px canvas width it moves to the bottom-right corner, 16px from the right and bottom edges |
  | Layout | A row of buttons with 12px gaps |
  | Main button | Solid accent (accent-9 fill, white text), 36px tall, radius 6, 14px/500 label, 12px horizontal padding, 16px leading icon, P-20 shadow |
  | Leading icon | Lucide Play, filled, white |
  | Label | AP wording, existing keys: "Test Flow"; "Run Flow" for a manual trigger; "Open Chat" for a chat trigger |
  | Tooltip | Label plus shortcut chips Ctrl/⌘ D (CAN-10, above) |
  | Stop button | Subtle style (P-19 fill, 1px border black 10%, P-20 shadow), 36 × 36px, Lucide Square 16px, tooltip "Stop" (existing key) |

- **States:**

  | State | Look |
  |---|---|
  | Ready | Main button as above |
  | Disabled (trigger has no sample data) | Main button at 50% opacity, not-allowed cursor, tooltip "Please test the trigger first" (existing key) |
  | Running (test in progress) | Main button becomes icon-only, 36 × 36px, showing a spinner (one turn per 400ms) in place of the icon |
  | Running and cancellable (run status QUEUED or PAUSED) | Icon-only main button plus the stop button to its right; clicking stop cancels the run through AP's existing run-cancel request |
  | Running, not cancellable (status RUNNING) | Icon-only spinner button, no stop button (AP's server cannot cancel a RUNNING run) |
  | Flow has incomplete steps | The main button is replaced by AP's warning button with the existing plural key `incompleteSteps` ("Complete 1 step" / "Complete # steps"), 36px tall, warning-3 fill, warning-7 border, warning-11 text; clicking selects and focuses the first incomplete step (today's behaviour) |
  | Read-only | The slot shows AP's existing "edit flow / view draft" button instead |
  | Manual trigger, flow not published | Hidden (today's rule) |

- **Light/Dark:** Accent is the same in both modes; subtle button uses P-19.
- **Motion:** Spinner per primitives; the button-to-icon swap fades over 200ms.
- **AP target file(s):** `BUILDER/flow-canvas/widgets/test-flow-widget.tsx`, `BUILDER/flow-canvas/widgets/above-trigger-button.tsx` (becomes the test-bar button), `BUILDER/flow-canvas/widgets/incomplete-settings-widget.tsx`, `BUILDER/flow-canvas/widgets/index.tsx` (stops rendering widgets above the trigger in flow coordinates; the bar is a fixed overlay in screen coordinates), `WEB/features/flow-runs/api/flow-runs-api.ts` (cancel).
- **Notes:** e2e: the accessible name stays "Test Flow" (the shortcut chip moves from inside the button into the tooltip; Playwright's name match is a case-insensitive substring, so `getByRole('button', { name: 'Test Flow' })` still matches). The Ctrl/⌘+D shortcut is kept; Ctrl/⌘+Enter is added as an alias (CAN-16). The trigger's own hover button (`06-graph.md` NOD-02) runs the same action.

### CAN-13 — Banners on the canvas

- **Values:** AP's remaining canvas banners — flow locked by another editor, viewing an old version, approval pending — render as one single-line callout centred horizontally at the top of the canvas, its top edge 40px below the canvas top edge (this clears the header's segmented tabs, which overlap the canvas by 16px). Callout styling per the primitives spec (12px text, 12px padding, 1px border, radius 4, icon left).
- **States:** At most one banner at a time, in AP's current priority order (lock first).
- **Light/Dark:** Primitives callout colours.
- **Motion:** Fade in 200ms.
- **AP target file(s):** `BUILDER/flow-canvas/widgets/builder-banner.tsx`, `viewing-old-version-widget.tsx`, `flow-approval-banner.tsx`, `WEB/components/custom/resource-lock-widget.tsx`, `large-widget-wrapper.tsx`.
- **Notes:** The publish reminder moves into the header's Publish button (plan Phase 10). The run-info banner moves into the logs panel (`09-logs.md` LOG-05), which keeps the "Run Succeeded" text e2e waits for.

### CAN-14 — Empty-trigger placeholder

- **Values:**
  - Shown when the flow's trigger is the empty trigger. It **is** the trigger's canvas node (React Flow node id `trigger`), drawn as a placeholder instead of a step box.
  - Box: 100 × 100px, centred on the trigger's 96 × 96 layout box (2px overhang on each side, so layout maths and handle positions are unchanged). Radius 8, 2px dashed border in P-22, fill P-21.
  - Icon: Lucide Plus, 40px, stroke P-22, centred.
  - Label: 8px below the box, centred, one line, no width cap, 16px/500, line-height 24px, gray-12. The text is the trigger's display name, which is "Select Trigger" for a new flow (stored data, not an i18n key).
  - No hover toolbar, no selection halo, not draggable. If steps already follow the empty trigger (possible from templates or AI), it keeps a normal output handle on its right edge so the chain stays connected; otherwise it has no handles and no "+" stub.
- **States:** Idle; hovered (icon stroke turns accent-9, pointer cursor); piece panel open for it (icon stays accent-9).
- **Light/Dark:** P-21, P-22.
- **Motion:** Icon colour change 200ms.
- **AP target file(s):** `BUILDER/flow-canvas/nodes/step-node/index.tsx` (placeholder render branch for the empty trigger), `BUILDER/flow-canvas/nodes/step-node/trigger-widget.tsx` (removed for this state).
- **Notes:** Click opens the piece panel in trigger mode (`08-piece-panel.md` PCK-12). e2e impact: `getByTestId('rf__node-trigger').filter({ hasText: 'Select Trigger' })` keeps working because the label is rendered inside the node element and the node id is still `trigger`. Do not change the stored display name or the node id. AP keeps its "Select Trigger" semantics: no other placeholder wording is introduced.

### CAN-15 — Sticky notes

- **Values:**

  | AP `NoteColorVariant` | Light fill | Light border | Dark fill | Dark border |
  |---|---|---|---|---|
  | YELLOW | yellow-100 #fef9c2 | yellow-200 #fff085 | yellow-900 #733e0a | yellow-800 #894b00 |
  | ORANGE | orange-100 #ffedd4 | orange-300 #ffb86a | orange-900 #7e2a0c | orange-800 #9f2d00 |
  | RED | red-100 #ffe2e2 | red-300 #ffa2a2 | red-950 #460809 | red-900 #82181a |
  | GREEN | green-100 #dcfce7 | green-300 #7bf1a8 | green-950 #032e15 | green-900 #0d542b |
  | BLUE | blue-100 #dbeafe | blue-200 #bedbff | blue-900 #1c398e | blue-800 #193cb8 |
  | PURPLE | violet-200 #ddd6ff | violet-300 #c4b4ff | violet-950 #2f0d68 | violet-800 #5d0ec0 |

  (All Tailwind v4.)

  - Shape: radius 4, 1px solid border in the variant's border colour, no shadow.
  - Padding 8px top and bottom, 12px left and right.
  - Text: #2b2b2b (light; nearest Tailwind neutral-800 #262626) / Tailwind neutral-100 #f5f5f5 (dark).
  - Markdown sizes: body 14px, line-height 1.5; H1 24px/600; H2 20px/600; H3 16px/600.
  - Notes are drawn below steps and edges.
  - Default size for a new note 240 × 160px; minimum 150 × 80px; AP's 600 × 600 maximum stays. Resize handles are invisible 16px-wide strips on all four edges and 16px corner squares; the cursor shows the resize direction.
- **States:**

  | State | Look |
  |---|---|
  | Idle | As above |
  | Hovered | A small floating toolbar appears above the note's top-right (same strip styling as the step hover toolbar, `06-graph.md` NOD-05): colour picker, delete, more |
  | Selected | 4px outer ring in #f0f0f0 (light; nearest Tailwind neutral-100) / white at 40% (dark); no layout shift |
  | Editing | Double-click enters markdown editing (unchanged); Escape leaves it |

- **Light/Dark:** Table above.
- **Motion:** Toolbar fades in over 100ms.
- **AP target file(s):** `BUILDER/flow-canvas/nodes/note-node/index.tsx` (`NoteColorVariantClassName`, `FocusedBorderClassName` maps and the resize control), `note-tools.tsx`, `note-footer.tsx`, `BUILDER/flow-canvas/utils/consts.ts` (`NOTE_CREATION_OVERLAY_WIDTH/HEIGHT`, `DEFAULT_NOTE_COLOR`), `WEB/components/custom/markdown-input`.
- **Notes:** Notes keep dnd-kit dragging (design doc §5). Existing note coordinates were placed for the vertical canvas; the sample flow in `handler-flow-builder.ts` needs new coordinates (plan Phase 6). AP's note footer (author avatar) may stay, sized 12px, at the bottom-left inside the padding. The default colour for new notes changes from BLUE to YELLOW.

### CAN-16 — Keyboard map

- **Values:** Shortcuts fire only when focus is on the canvas, the page body or a step (never inside an input, the step modal, or the piece panel). Single-letter keys ignore the event when Ctrl, ⌘ or Alt is held, unless listed with that modifier.

  | Key | Action | Today in AP | Notes |
  |---|---|---|---|
  | 1 | Fit view (CAN-05) | — | New |
  | 0 | Zoom to 100% | — | New |
  | + or = | Zoom in | — | New |
  | − | Zoom out | — | New |
  | Space or Ctrl/⌘ (held) | Pan mode (CAN-06) | Space held = grab | Changed |
  | N | Open the piece panel to add a step (as CAN-11 button 1) | — | New |
  | Shift + S | Add note | — | New |
  | D | Skip / unskip the selected steps (not the trigger) | Ctrl/⌘ + E | Changed; keep Ctrl/⌘ + E as an alias |
  | Delete or Backspace | Delete the selected steps | Shift + Delete | Changed; keep Shift + Delete as an alias |
  | Enter | Open the step modal for the selected step | — | New (`07-step-modal.md` NDV-01) |
  | F2 | Open the step modal with the step name in edit mode | — | New (optional) |
  | R | Replace the selected step (piece panel in replace mode) | context menu only | New |
  | Ctrl/⌘ + C / Ctrl/⌘ + V | Copy / paste steps | same | Unchanged |
  | Ctrl/⌘ + A | Select all steps | — | New |
  | Ctrl/⌘ + D, Ctrl/⌘ + Enter | Test Flow | Ctrl/⌘ + D | Enter alias added |
  | Shift + Alt + T | Tidy-up | — | New. Match on the physical key code for T, because macOS Option + T produces "†" |
  | Arrow Left / Right | Select the previous / next step along the chain | — | New (optional) |
  | Arrow Up / Down | Select the sibling step in the branch above / below | — | New (optional) |
  | L | Open / close the logs panel | — | New (`09-logs.md`) |
  | I / O | Show / hide the logs input / output pane | — | New |
  | Ctrl/⌘ + K | Global search | same (app-wide) | Unchanged |
  | Escape | Cancel note placement or drag; close the piece panel; close the step modal | Exit drag | Extended |
  | Ctrl/⌘ + M | — | Minimap toggle | Removed (CAN-08) |

- **States:** Read-only canvas: only 1, 0, +, −, pan keys, Enter, arrows, L / I / O and Ctrl/⌘ + C work.
- **Light/Dark:** n/a.
- **Motion:** n/a.
- **AP target file(s):** `BUILDER/shortcuts.ts` (`CanvasShortcuts`, `shortcutHandler` — add Alt support and key-code matching), `BUILDER/flow-canvas/context-menu/canvas-context-menu.tsx` (the `CanvasShortcutsProps` type), `canvas-context-menu-content.tsx` (shortcut chips shown in the menu must match the new keys).
- **Notes:** Pinning has no AP equivalent; there is no P key. Cut has no AP equivalent and is not mapped. Duplicate keeps no shortcut, because Ctrl/⌘ + D stays bound to Test Flow.

## Conflicts with design doc

None for this file. Two notes for the orchestrator:

- `design/graph-positions.md` does not fix the auto-layout origin; CAN-05 suggests (176, 240).
- Plan Phase 6 lists the controls as "fit, zoom in, zoom out, tidy-up"; CAN-09 keeps that and also re-homes AP's "Download as image" into the canvas context menu, so no AP feature is lost.
