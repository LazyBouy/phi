# 07 — Three-pane step modal (NDV)

Builder-facing spec for the step editor that replaces AP's right-hand step-settings sidebar: a modal with three columns — INPUT (data from earlier steps), the step's parameters and settings, and OUTPUT (the step's test or run result). Colours use AP token steps and the canvas palette `P-NN` from `05-canvas.md` CAN-01; conventions are at the top of `05-canvas.md`.

Plan phase: 8. New code lives in a new folder `BUILDER/step-modal/`.

Two surface colours are used throughout:

| Surface | Light | Dark | Source |
|---|---|---|---|
| Centre column (parameters) and header | #ffffff | #2b2b2b | White / nearest Tailwind neutral-800 #262626 (same as P-06) |
| Data panes (INPUT, OUTPUT) | #f5f5f5 | #262626 | Tailwind neutral-100 / neutral-800 |
| Dividers between columns and under headers | #e5e5e5 | #404040 | Tailwind neutral-200 / neutral-700 (AP role gray-6) |

## Requirements

### NDV-01 — Open and close rules

- **Values:**

  | Action | Result |
  |---|---|
  | Single click on a step | Selects it only (halo, `06-graph.md` NOD-06); the modal does not open |
  | Double-click on a step | Opens the modal for that step |
  | Enter with exactly one step selected | Opens the modal for it |
  | F2 with one step selected | Opens the modal with the step name already in edit mode (optional) |
  | A step is added from the piece panel | The new step is selected and its modal opens (AP's current "select step after adding" behaviour) |
  | Double-click on a router output label | Opens the router's modal with that branch selected |
  | Escape | Closes the modal, unless an inner popover, dropdown or editor is open (that one closes first) |
  | Click on the overlay outside the frame | Closes the modal |
  | Header close button | Closes the modal |

- **States:** Closed; open (editable); open (read-only run view, NDV-18). Only one modal exists; switching to another step (header arrows, neighbour chips) swaps the content in place.
- **Light/Dark:** n/a.
- **Motion:** No open or close animation (appears and disappears instantly).
- **AP target file(s):** new `BUILDER/step-modal/index.tsx`; `BUILDER/builder-hooks.ts` and `BUILDER/state/*` (separate "selected" from "modal open"; today selecting a step opens the sidebar); `BUILDER/flow-canvas/nodes/step-node/index.tsx` (double-click); `BUILDER/shortcuts.ts` (Enter, F2).
- **Notes:** Closing keeps the step selected. Canvas shortcuts are disabled while the modal is open. e2e impact: today the settings sidebar does not cover the canvas or the header. With the modal open, the canvas "+" stubs and the header's Publish button are under the overlay, so `BuilderPage.addAction` and `publishFlow` must press Escape first (page-object change).

### NDV-02 — Frame and overlay

- **Values:**

  | Part | Value |
  |---|---|
  | Overlay | Black at 60% over the whole builder (header, canvas, side panel), both modes |
  | Frame | 24px inset from every window edge (width = window − 48px, height = window − 48px), radius 8, 1px border in the divider colour, contents clipped to the radius |
  | Layer | The step-modal layer from `01-tokens.md` z-index scale: above canvas chrome and the piece panel, below dialogs, popovers opened from inside the modal, and toasts |
  | Focus | Focus is trapped in the frame; on open, focus goes to the frame itself (not to an input), so Ctrl/⌘ + G works at once |

- **States:** n/a.
- **Light/Dark:** Overlay identical in both modes; frame border uses the divider colour per mode.
- **Motion:** none.
- **AP target file(s):** `BUILDER/step-modal/index.tsx` (Radix dialog primitive is fine; override its default size, padding and animation).
- **Notes:** Popovers, selects and the mention function search opened inside the modal must render inside the modal's stacking context.

### NDV-03 — Modal header

- **Values:**

  | Part | Value |
  |---|---|
  | Bar | 40px tall, centre-column surface, 1px bottom divider, 4px padding |
  | Left | 8px left margin; the step's piece logo at 20 × 20px (LogoPlate, no border, no tint); 8px gap; the step name, inline-editable, 14px/400, gray-12, at most 500px wide |
  | Right | AP's previous-step and next-step buttons (ghost 32 × 32px, Lucide ChevronLeft / ChevronRight 16px, existing tooltips); then a 1px vertical divider with 8px padding on its left; then the close button (ghost 32 × 32px, Lucide X 16px, tooltip "Close", existing key) |
  | Button hover | gray-3 background |

- **States:** Name idle; name editing (click on the name: it becomes an input with the same size; Enter or blur saves through AP's rename; Escape cancels); read-only (name not editable).
- **Light/Dark:** Surfaces per the table above.
- **Motion:** none.
- **AP target file(s):** new `BUILDER/step-modal/step-modal-header.tsx`; reuse `BUILDER/step-settings/editable-step-name.tsx` and `BUILDER/step-settings/step-navigation-buttons.tsx`.
- **Notes:** The reference header has a documentation link; AP piece metadata has no documentation URL, so it is not mapped. The step number is not shown in the header.

### NDV-04 — Columns: default and minimum widths

- **Values:**

  | Layout class | Used for | Centre width (default) | INPUT / OUTPUT |
  |---|---|---|---|
  | Regular | Most piece actions | 420px | Split the remaining width equally |
  | Wide | Code step, router, AI router, agent piece | 640px | Split the remaining width equally |
  | Inputless | Every trigger | 480px | No INPUT column; OUTPUT takes the rest |

  | Limit | Value |
  |---|---|
  | Centre column minimum | 368px |
  | INPUT / OUTPUT column minimum | 120px |
  | INPUT / OUTPUT content minimum | 280px; a narrower column scrolls its content horizontally |
  | Total | The three columns always fill the frame exactly |

  Columns are separated by 1px dividers. The centre column uses the centre surface; INPUT and OUTPUT use the data-pane surface.
- **States:** As the table; the class is chosen from the step type.
- **Light/Dark:** Surfaces per the table at the top.
- **Motion:** none.
- **AP target file(s):** `BUILDER/step-modal/index.tsx` using `WEB/components/ui/resizable-panel.tsx` (react-resizable-panels, already in AP).
- **Notes:** —

### NDV-05 — Resizing, the drag grip, reset and saved layout

- **Values:**
  - Both edges of the centre column are resize handles: an invisible 8px-wide strip centred on each divider, with the east-west resize cursor. Dragging the left edge trades width between INPUT and the centre; dragging the right edge trades width between the centre and OUTPUT. Widths change in 8px steps and stop at the minimums.
  - Drag grip: a small tab centred horizontally on the centre column, standing on the header's bottom divider (it rises into the header band). 18px tall; centre-column surface; 1px border on the top, left and right (none at the bottom, so it merges with the column); top corners radius 4; 4px top padding and 6px side padding. It holds a 12px Lucide GripVertical in P-22. On hover and while dragging, a 10px Lucide ArrowLeft and ArrowRight appear on either side of it, 6px apart.
  - Dragging the grip moves the centre column sideways at a constant width (INPUT and OUTPUT trade width), east-west resize cursor.
  - Double-click on either resize edge or on the grip resets the columns to the default for the layout class and forgets the saved layout.
  - Saved layout: when a resize or grip drag ends, save the three widths as percentages in localStorage, keyed per piece (suggested key `ap.stepModal.layout.<pieceName>`; for code, loop and router steps use the step type). On open, restore the saved widths clamped to the minimums at the current window size, otherwise use the defaults. Every localStorage read and write is wrapped in try/catch; failure means "use defaults".
- **States:** Idle; hovering a handle; dragging.
- **Light/Dark:** Grip uses the centre surface and divider colour per mode.
- **Motion:** Grip arrows fade in over 100ms.
- **AP target file(s):** `BUILDER/step-modal/index.tsx`, new `BUILDER/step-modal/column-grip.tsx`.
- **Notes:** —

### NDV-06 — Centre header: tabs and the test button

- **Values:**

  | Part | Value |
  |---|---|
  | Bar | 42px tall including a 1px bottom divider; centre surface; 8px right padding |
  | Tabs | Bottom-aligned at the left: "Parameters" and "Settings" (existing keys). 12px/600; 16px horizontal padding; 14px bottom padding; inactive gray-11; hover accent-9; active accent-9 with a 2px accent-9 underline that sits on the bar's bottom divider; keyboard focus shows a 1px inset violet outline |
  | Test button | Right side, vertically centred, 8px from the column's right edge. Solid accent (accent-9 fill, white text), 28px tall, radius 4, 13px/500 label, 12px horizontal padding, leading Lucide Play 12px (filled). After the label, inside the button, AP's shortcut chip "Ctrl + G" (⌘ + G on macOS): 18px tall, 4px horizontal padding, radius 2, white at 20% background, 10px white text |

  | Step | Label (existing keys) | Test id |
  |---|---|---|
  | Action, no sample data | "Test Step" | `test-step-button` |
  | Action with sample data | "Retest Step" | `test-step-button` |
  | Piece trigger, no sample data | "Test Trigger" | `test-trigger-button` |
  | Piece trigger with sample data | "Retest Trigger" | `test-trigger-button` |
  | Manual trigger, empty trigger | No button | — |

- **States:** Ready; testing (spinner replaces the icon, label "Testing..." for actions or "Testing Trigger" for triggers, both existing keys; clicking does nothing); disabled (50% opacity, tooltip with AP's existing reason: "Fill in the required fields first", "Please wait until all inputs are loaded" or "Saving..."); read-only run view (no button). Pressing Ctrl/⌘ + G on an invalid step shows AP's existing "Configure step first" toast.
- **Light/Dark:** Accent in both modes; tab colours per tokens.
- **Motion:** Tab colour 200ms; button loading swap 200ms.
- **AP target file(s):** new `BUILDER/step-modal/step-modal-center-header.tsx`; `BUILDER/test-step/test-step-cta-button.tsx` (logic reused; the soft-accent styling and the "Show Data" buttons go), `BUILDER/test-step/test-step-tooltip.tsx`, `WEB/components/ui/tabs.tsx` (underline variant from the primitives spec).
- **Notes:** e2e: `getByRole('button', { name: 'Test Step Ctrl + G' })` only matches if the "Ctrl + G" chip text is inside the button element, as AP's Button `keyboardShortcut` prop renders it today; keep that. `test-trigger-button` must exist exactly once in the DOM (do not repeat it in the OUTPUT empty state).

### NDV-07 — Parameters tab

- **Values:**
  - Hosts AP's existing settings form for the step type, unchanged in function: piece settings (including the connection select), code settings, loop settings, router settings (branches list and conditions), AI router settings, agent settings.
  - Layout: 16px padding on all sides of the scroll area; 16px between fields; each field is a label row, 4px gap, then the input.
  - Label: 13px/400, gray-12; AP's required marker stays and is coloured accent-9. Field descriptions below the input, 12px, gray-11.
  - Inputs, selects, switches, callouts: the primitives spec (`02-primitives.md`), using the compact 32px input size.
  - The tab content scrolls; the centre header stays fixed.
- **States:** Editable; read-only (AP's disabled forms).
- **Light/Dark:** Centre surface.
- **Motion:** none.
- **AP target file(s):** `BUILDER/step-settings/index.tsx` and its sub-folders (`piece-settings/`, `code-settings/`, `loops-settings.tsx`, `router-settings/`, `branch-settings/`, `ai-router-settings/`, `agent-settings/`), `BUILDER/piece-properties/generic-properties-form.tsx`, `auto-form-field-wrapper.tsx`.
- **Notes:** The current sidebar header (`BUILDER/sidebar-header.tsx`) is not used inside the modal; the modal header replaces it.

### NDV-08 — Field label row and the mention input

- **Values:**
  - The label row has a right-hand slot for field controls. The controls fade in when the field is hovered or focused and fade out when it is not.
  - Controls in that slot: AP's dynamic value toggle (switches a dropdown, checkbox or number field to a typed value that can hold references), as a 24 × 24px ghost icon button; AP's field info tooltip icon, 14px, gray-11.
  - There is no fixed/expression switch. In AP every input that accepts references is a mention input (the Tiptap editor in `text-input-with-mentions/`): references appear as AP's mention chips, typed text is literal, and AP's "/" function search stays. Nothing shows an expression prefix or an expression mode.
  - Mention input look: the primitives text input (32px minimum height, grows with content), focus ring per tokens.
- **States:** Field idle (controls hidden); hovered or focused (controls shown); droppable and drop-target (NDV-16).
- **Light/Dark:** Per primitives.
- **Motion:** Controls fade in over 100ms (ease-in) and out over 250ms with a slow start (cubic-bezier 0.98, −0.06, 0.49, −0.2).
- **AP target file(s):** `BUILDER/piece-properties/auto-form-field-wrapper.tsx`, `dynamic-value-toggle-button.tsx`, `text-input-with-mentions/index.tsx`, `text-input-with-mentions/tiptap-editor.tsx`, `mention-chips-input.tsx`.
- **Notes:** Clicking a value row in the INPUT pane while a mention input is focused inserts the reference, exactly as clicking in the data selector does today (`insertMention` registered by the focused editor).

### NDV-09 — Settings tab

- **Values:** Hosts the step options that are not parameters: AP's error-handling form ("Error handling" heading; "Add Error Handler" — continue on failure; "Retry on Failure" with "Retries up to 4 times before failing the step."; all existing keys) and the piece version update entry (AP's update-piece-version dialog trigger). Same padding and spacing as NDV-07; switches per primitives (on = green).
- **States:** The Settings tab is shown only for steps that have at least one of these options; otherwise only "Parameters" is shown.
- **Light/Dark:** Centre surface.
- **Motion:** none.
- **AP target file(s):** `BUILDER/piece-properties/action-error-handling.tsx`, `BUILDER/step-settings/update-piece-version-dialog/`, `BUILDER/step-settings/index.tsx`.
- **Notes:** Turning continue-on-failure on adds the Success / Failure outputs on the canvas (`06-graph.md` HDL-03).

### NDV-10 — INPUT pane

- **Values:**

  | Part | Value |
  |---|---|
  | Header | 42px including a 1px bottom divider; data-pane surface; 16px left padding, 4px right padding |
  | Title | "Input" (existing key), shown upper-case, 13px/600, letter-spacing 2px, gray-11 (reference #999999 light / #bbbbbb dark) |
  | Header right | Optional search (ghost 28 × 28px, Lucide Search 16px), then the view-mode control (NDV-12) |
  | Body | Scrolls; 8px side padding |
  | Step rows | One collapsible row per earlier step on the path to this step: the nearest earlier step first and expanded, the others collapsed, the trigger last. Row 32px tall: chevron (Lucide ChevronRight / ChevronDown 14px, gray-11), a 20 × 20px piece logo plate (radius 4, 1px divider border), 8px gap, "N. step name" (AP keeps the step number here) 13px/500 gray-12; trigger rows add a 12px accent-9 Lucide Zap after the name; right-aligned "N items" (EDG-06 key) 12px gray-11 when the step's sample output is an array |
  | Expanded row | The step's saved sample data (in a run: the run output) in the current view mode, indented 24px |
  | No sample data | The expanded row shows "No sample data yet — test this step first." (existing key), 12px gray-11 |
  | Variables row | Last row: "Variables" (existing key), collapsible, holding AP's project variables list |
  | Loop context | For a step inside a loop body, the loop's row exposes the current item and index fields as AP's data selector does today |

- **States:** Normal; searching (rows filter to matching keys and values); triggers have no INPUT pane.
- **Light/Dark:** Data-pane surface.
- **Motion:** Row expand / collapse has no animation.
- **AP target file(s):** new `BUILDER/step-modal/input-pane.tsx`; reuse the tree building in `BUILDER/data-selector/` (`utils.ts`, `utils-schema.ts`, `path-helpers.ts`, `data-selector-node.tsx`, `data-selector-node-content.tsx`, `variables-tab.tsx`).
- **Notes:** The floating data selector (`BUILDER/data-selector/index.tsx`) is no longer rendered; its tree logic lives on in this pane. The step-number prefix stays here because references in mention chips use it.

### NDV-11 — OUTPUT pane

- **Values:**

  | Part | Value |
  |---|---|
  | Header | As NDV-10, title "Output" (existing key) |
  | Status | After a test or in a run, after the title: a 16px Lucide CircleCheck in success-9 (tooltip "Tested Successfully", or "Success" in a run; existing keys) or Lucide CircleX in danger-9 (tooltip "Test Failed", or "Failed" in a run; existing keys); then a 16px Lucide Info in gray-11 whose tooltip shows the last test date, or the run duration |
  | Header right | Optional search; view-mode control (NDV-12); AP's "Copy to clipboard" and "Download JSON" (existing keys) as 28 × 28px ghost buttons with Lucide Copy and Download 16px |
  | Count line | Under the header when the output is an array: "N items" (EDG-06 key), 12px gray-11, 12px left padding, 8px vertical padding |
  | Body | The output in the current view mode; scrolls |

  Empty state (no sample data yet), centred in the pane, at most 280px wide: Lucide PackageOpen 24px gray-11; 16px gap; "No sample data yet" (existing key) 16px/600 gray-12; 8px gap; for actions "Run this step to capture sample data. You can then use the result in following steps." and for triggers "Test the trigger to capture sample data. You can then use the result in the following steps." (both existing keys) 13px gray-11; 16px gap; a subtle 32px button "Run a test" (new key) that starts the same test as the header button (no test id on it).

  For piece triggers without sample data, AP's trigger test sections (webhook instructions, first-time testing, simulation, "Load Sample Data") render in this pane in place of the generic empty state.
- **States:**

  | State | Look |
  |---|---|
  | Testing | AP's JSON skeleton and a subtle "Cancel Testing" button (existing key) |
  | Test failed | AP's friendly error view at the top in a danger callout, then the raw error in the current view; the note "Errors are not saved on refresh" (existing key) 12px gray-11 |
  | Run view, step did not run | "This step didn't run" (existing key) with its existing explanation, centred |

- **Light/Dark:** Data-pane surface.
- **Motion:** none.
- **AP target file(s):** new `BUILDER/step-modal/output-pane.tsx`; reuse `BUILDER/test-step/test-sample-data-viewer.tsx`, `BUILDER/test-step/json-tree-skeleton.tsx`, `BUILDER/test-step/test-trigger-section/*`, `BUILDER/data-display/data-display-tabs.tsx`, `BUILDER/data-display/friendly-error-view.tsx`; retire `BUILDER/step-data/step-data-panel-host.tsx`, `step-data-panel-header.tsx` and `step-data-panel-view-toggle.tsx` (the bottom-drawer / side-by-side data panel).
- **Notes:** The reference shows a banner when output is pinned. In AP every draft output shown here is saved sample data, so a banner would always show; it is not mapped. e2e: the "Load Sample Data" text must stay reachable (`BuilderPage.loadSampleData`).

### NDV-12 — View modes

- **Values:** The primitives segmented control (`02-primitives.md`, new `segmented-control.tsx`): 32px tall; track #e5e5e5 (dark #323232), 2px padding, radius 6; segments radius 4, 12px/500, 12px horizontal padding, 2px apart; selected segment white fill (dark #171717) with gray-12 text; others gray-11, hover #f0f0f0 (dark #2b2b2b) with gray-12 text.

  | Mode | Label | Compact icon (Lucide) |
  |---|---|---|
  | Schema | "Schema" (new key) | ListTree |
  | Table | "Table" (existing key) | Table2 |
  | JSON | "JSON" (existing key) | Braces |

  Defaults: INPUT starts in Schema, OUTPUT in Table. The last choice per pane is remembered in localStorage (try/catch).
- **States:** Compact: when the pane is narrower than 400px, the control switches to the small size (28px, 10px text) with square icon-only segments and tooltips.
- **Light/Dark:** As the values.
- **Motion:** Selected segment background 200ms.
- **AP target file(s):** `WEB/components/ui/segmented-control.tsx` (new, plan Phase 3), `BUILDER/step-modal/view-mode-control.tsx`.
- **Notes:** The 400px threshold is a proposal, not a measured value.

### NDV-13 — Schema view

- **Values:**
  - A tree of fields. Each field is a row: an optional 12px chevron (objects and arrays) to expand or collapse; a **pill** 24px tall, radius 4, 1px border #f0f0f0 (dark #404040), fill white (dark #2b2b2b), holding a 12px type icon in gray-11, a 1px vertical divider, then the key, 12px gray-12, 6px inner horizontal padding; then, 8px after the pill, the value preview, 12px gray-11, one line with an ellipsis.
  - Type icons (Lucide): Type for text, Hash for numbers, ToggleLeft for booleans, Braces for objects, Brackets for arrays, CircleSlash for null.
  - Each nesting level indents 24px. Rows are 4px apart.
  - When the piece defines an output schema (AP's curated output labels), the tree uses those labels and order, as AP's "Friendly View" does today.
- **States:** Pill hovered (grab cursor, border gray-8); pill being dragged (NDV-16); optional "already referenced" state when the field's path is used in this step's parameters: text accent-11, border accent-6, fill accent-2.
- **Light/Dark:** As the values.
- **Motion:** none.
- **AP target file(s):** new `BUILDER/step-modal/schema-view.tsx`; reuse `BUILDER/data-selector/utils-schema.ts`, `WEB/components/custom/smart-output-viewer/`.
- **Notes:** —

### NDV-14 — Table view

- **Values:**
  - An array of objects shows one row per item and one column per key (the union of keys across items, in first-seen order). A single object shows one row. An array of plain values shows a single column titled "Value" (new key if missing). Nested objects and arrays in a cell show as compact one-line JSON, truncated.
  - The table sits 12px inside the pane's left and right edges and spans the remaining width; columns share the width equally and the table scrolls horizontally when they do not fit.
  - Text 12px gray-12. Header row 32px, sticky, 12px/600, on the data-pane surface. Body rows 26px. Cell padding 4px top and bottom, 6px left and right. 1px borders on every cell side in black at 10% (dark: white at 10%).
  - Long tables are virtualised (AP already has a virtualized list).
- **States:** Header cell hovered (fill #e5e5e5, dark #323232; grab cursor); header cell being dragged (text accent-9).
- **Light/Dark:** As the values.
- **Motion:** none.
- **AP target file(s):** new `BUILDER/step-modal/table-view.tsx`; `WEB/components/ui/virtualized-list.tsx`.
- **Notes:** Header cells are drag sources (NDV-16); the dragged path is the column key under the item.

### NDV-15 — JSON view

- **Values:** AP's JSON viewer restyled: the mono font from `01-tokens.md`, 12px, line-height 1.5; collapsible objects and arrays; 1px indent guides in #e0e0e0 (dark #404040).

  | Token | Light | Dark |
  |---|---|---|
  | Keys | #444444 (nearest Tailwind neutral-700) | white |
  | Strings | violet-700 #7008e7 | violet-400 #a684ff |
  | Numbers, booleans | green-600 #00a63e | green-600 #00a63e |
  | null | red-600 #e7000b | red-400 #ff6467 |
  | Brackets, punctuation | gray-11 | gray-11 |

- **States:** Keys hovered (grab cursor); keys being dragged (NDV-16).
- **Light/Dark:** Table above.
- **Motion:** Expand / collapse instant.
- **AP target file(s):** `WEB/components/custom/json-viewer.tsx`.
- **Notes:** —

### NDV-16 — Drag to map

- **Values:**
  - **Sources:** in the INPUT pane, schema pills, table header cells and JSON keys. Each source knows the reference path the data selector would insert for that field (AP's property path, for example the path under `step_2`), built with the same helpers (`BUILDER/data-selector/path-helpers.ts`).
  - **Drag pill:** follows the pointer, centred horizontally above it (its bottom edge at the pointer). 24px tall, 6px horizontal padding, 1px border, radius 4, 12px text showing the field key. Default look: text accent-9, border accent-7 (orange-400 #ff8904), fill accent-3 (orange-100 #ffedd4), shadow 0 2px 6px in Tailwind stone-900 #1c1917 at 20%.
  - **Droppable fields:** while a drag is in progress, every mention input in the centre column shows a 1.5px dashed outline drawn just inside its border, in violet-600 #7f22fe (dark: accent-9), with a violet tint at 10% (dark: accent at 10%). Fields that cannot hold references (a dropdown, checkbox or number field whose dynamic value toggle is off) are not droppable.
  - **Hovered target:** the field's border turns solid success-9 and its fill green at 10%; the drag pill switches to success-9 text, green-300 #7bf1a8 border and a white fill.
  - **Drop:** inserts the reference token — the same mention node the data selector inserts, built from `{{` + path + `}}` — at the caret position nearest to the drop point (at the end if the field had no caret). The field keeps focus afterwards.
- **States:** Idle; dragging; over a droppable field; dropped; cancelled (Escape or release outside a field: nothing changes).
- **Light/Dark:** As the values.
- **Motion:** The outlines appear and disappear with the drag (no transition).
- **AP target file(s):** new `BUILDER/step-modal/drag-to-map.tsx` (or a small context); `BUILDER/piece-properties/text-input-with-mentions/tiptap-editor.tsx` (accept a drop: place the caret from the drop coordinates, then call the existing `insertMention`), `BUILDER/state/step-form-state.ts`.
- **Notes:** Use pointer events or the HTML drag-and-drop API; do not reuse the canvas's dnd-kit context, so a mapping drag never interacts with canvas notes.

### NDV-17 — Loop iterations in the data panes

- **Values:** When a run is loaded and the step is inside a loop body, the INPUT and OUTPUT headers show an iteration selector right after the title: a compact select, 28px tall, 12px text, reading "Iteration {index} of {total}" (new ICU key). Changing it sets AP's selected index for that loop (`loopsIndexes`), which also updates the canvas statuses and the logs panel.
- **States:** Shown only in runs and only for steps inside loops.
- **Light/Dark:** Primitives select.
- **Motion:** none.
- **AP target file(s):** `BUILDER/run-details/loop-iteration-input.tsx` (moved here from the step node), `BUILDER/state/run-state.ts`.
- **Notes:** —

### NDV-18 — Read-only run view

- **Values:** The same modal, used when a run is loaded (a finished test run or a run opened from the runs list): the centre column shows AP's disabled forms; the test button is hidden; the INPUT pane shows the step's resolved input for this run as one block (not the list of earlier steps); the OUTPUT pane shows the run output or error with its status icon and duration (NDV-11); loop steps get the iteration selector (NDV-17).
- **States:** Read-only.
- **Light/Dark:** As editable.
- **Motion:** none.
- **AP target file(s):** `BUILDER/run-details/flow-step-input-output.tsx` (data source), `BUILDER/run-details/ai-router-routes.tsx` (shown in the OUTPUT pane for AI routers), `WEB/app/routes/runs/id/index.tsx`.
- **Notes:** The right side panel keeps only the runs list and the version history (plan Phase 8).

### NDV-19 — Neighbour chips (OPTIONAL)

- **Values:** Small chips that let the user jump to adjacent steps without closing the modal. Previous steps sit on the frame's left edge, next steps on its right edge, each chip centred on the edge (half outside the frame), stacked vertically and centred, 16px apart. A chip is the step's 20px logo with 12px padding (44px square), radius 8, 1px divider border, P-06 fill. Hover shows the step name in a tooltip.
- **States:** At rest the chips are drawn at 80% scale; on hover 110%. Click switches the modal to that step.
- **Light/Dark:** P-06 and divider per mode.
- **Motion:** Scale changes over 200ms with a fast-out curve (cubic-bezier 0.19, 1, 0.22, 1).
- **AP target file(s):** new `BUILDER/step-modal/neighbour-chips.tsx`.
- **Notes:** "Previous" is the step before on the path; "next" is the next step, or the first step of each branch or of the loop body.

### NDV-20 — Keyboard inside the modal

- **Values:**

  | Key | Action |
  |---|---|
  | Escape | Close the innermost open popover; otherwise close the modal |
  | Ctrl/⌘ + G | Test the step (existing) |
  | Tab / Shift + Tab | Move through fields, staying inside the modal |
  | Arrow keys in the INPUT tree | Move between rows; Right expands, Left collapses (optional) |

- **States:** Canvas shortcuts (`05-canvas.md` CAN-16) are off while the modal is open.
- **Light/Dark:** n/a.
- **Motion:** n/a.
- **AP target file(s):** `BUILDER/step-modal/index.tsx`, `BUILDER/shortcuts.ts`.
- **Notes:** —

### NDV-21 — What leaves the old sidebar

- **Values:**

  | Today | After |
  |---|---|
  | Step settings in the right resizable sidebar (`StepSettingsContainer`) | Moves into the modal's centre column |
  | Floating data selector over the canvas | Not rendered; its tree powers the INPUT pane |
  | Step data drawer / side-by-side panel | Retired; its content is the OUTPUT pane |
  | "Show Data", "Bottom Panel" / "Side by Side" toggles | Removed |
  | Runs list and version history in the right sidebar | Stay in the right sidebar |

- **States:** n/a.
- **Light/Dark:** n/a.
- **Motion:** n/a.
- **AP target file(s):** `BUILDER/index.tsx` (the right panel renders only runs and versions), `BUILDER/types/index.ts` (`RightSideBarType.PIECE_SETTINGS` retired), `BUILDER/step-settings/index.tsx`, `BUILDER/data-selector/index.tsx`, `BUILDER/step-data/*`.
- **Notes:** —

## Conflicts with design doc

None. `design/graph-positions.md` does not cover the step modal.
