# 09 — Logs panel (LOG)

Builder-facing spec for the bottom panel that shows the current or last test run (and a run opened from the runs list): a list of the steps that ran, with status and duration, and the selected step's input and output. Colours use AP token steps and the canvas palette `P-NN` from `05-canvas.md` CAN-01; conventions are at the top of `05-canvas.md`.

Plan phase: 10. New code lives in a new folder `BUILDER/logs-panel/`.

| Surface | Light | Dark | Source |
|---|---|---|---|
| Header rows (collapsed bar, column headers) and the step list column | #ffffff | #171717 | White / Tailwind neutral-900 |
| Details body (behind the data panes) | #fafafa | #171717 | Tailwind neutral-50 / neutral-900 |
| Dividers | #e5e5e5 | #2e2e2e | Tailwind neutral-200 / nearest neutral-800 #262626 |
| Selected row | #e5e5e5 | #323232 | Tailwind neutral-200 / nearest neutral-800 |
| Hovered row | #f5f5f5 | #262626 | Tailwind neutral-100 / neutral-800 |
| Selected row of a failed step | red-50 #fef2f2 | red-950 #460809 at 50% | Tailwind |

## Requirements

### LOG-01 — Placement

- **Values:** Docked at the bottom of the canvas column: full width of the canvas area (from the left rail to the right side panel, or to the window edge when the side panel is closed), between the canvas and the window bottom. It takes height from the canvas (the canvas shrinks, it is not overlaid); the canvas keeps its centre point (`05-canvas.md` CAN-05) and the bottom-centre test bar and bottom-left controls move up with the canvas bottom edge. A 1px divider separates it from the canvas.
- **States:** Collapsed (LOG-02); open (LOG-03). The step modal and the piece panel cover it.
- **Light/Dark:** Surfaces table above.
- **Motion:** Height changes from the toggle animate over 200ms (ease-out); dragging the edge is live.
- **AP target file(s):** `BUILDER/index.tsx` (a vertical split inside the canvas panel: canvas above, logs panel below), new `BUILDER/logs-panel/index.tsx`, `WEB/components/ui/resizable-panel.tsx`.
- **Notes:** AP's chat drawer for chat triggers is unchanged and is not part of this panel.

### LOG-02 — Collapsed bar

- **Values:**

  | Part | Value |
  |---|---|
  | Height | 36px |
  | Fill | Header surface; 1px top divider |
  | Left | 8px padding; "Logs" (existing key), 12px/600, gray-12. When a run is loaded: 12px later, the run status — AP's run status icon (14px) and status text (12px, gray-11; for example "Run Succeeded") — then " · " and the run duration when the run has finished |
  | Right | A ghost 24 × 24px button with Lucide ChevronUp 16px (ChevronDown when open); tooltip "Logs" with shortcut chip L (`05-canvas.md` CAN-10) |
  | Click | Anywhere on the bar toggles the panel open |

- **States:** No run; run loaded (status shown).
- **Light/Dark:** Surfaces per mode.
- **Motion:** none.
- **AP target file(s):** new `BUILDER/logs-panel/logs-panel-bar.tsx`.
- **Notes:** The plan says 32px; the reference measures 36px (the bar shares the 36px header-row height of the open panel). This spec uses 36px.

### LOG-03 — Open height, resizing and opening rules

- **Values:**

  | Property | Value |
  |---|---|
  | Default open height | 30% of the canvas column's height |
  | Minimum | 160px |
  | Maximum | 75% of the canvas column's height |
  | Resize | Drag the panel's top edge (a 6px hit strip, north-south resize cursor); dropping it below the minimum collapses the panel |
  | Saved height | Stored in localStorage on resize end (suggested key `ap.builder.logsPanelHeight`), restored on the next open; reads and writes in try/catch |
  | Auto-open | Opens when "Test Flow" (or "Run Flow") starts, and when a run is opened in the builder from the runs list. It never closes on its own |

- **States:** Collapsed; open; resizing.
- **Light/Dark:** n/a.
- **Motion:** As LOG-01.
- **AP target file(s):** `BUILDER/logs-panel/index.tsx`, `BUILDER/flow-canvas/widgets/test-flow-widget.tsx` (open on start), `BUILDER/state/run-state.ts`.
- **Notes:** —

### LOG-04 — Open layout and header rows

- **Values:** Two columns side by side: the step list (LOG-05) on the left and the details (LOG-08) on the right, separated by a 1px divider. Each column starts with a 36px header row: header surface, 1px bottom divider, 8px horizontal padding, 12px text, titles 12px/600 gray-12. Clicking an empty part of the step-list header collapses the panel.

  | Column | Value |
  |---|---|
  | Step list default width | The smaller of 240px and 20% of the panel width |
  | Step list minimum / maximum | 80px / 500px |
  | Resize | Drag the divider (6px hit strip, east-west cursor). Dragging it to the right edge makes the step list fill the panel and hides the details |
  | Saved width | localStorage (suggested key `ap.builder.logsListWidth`), try/catch |

- **States:** Both columns; list only (details hidden).
- **Light/Dark:** Surfaces per mode.
- **Motion:** none.
- **AP target file(s):** `BUILDER/logs-panel/index.tsx`.
- **Notes:** —

### LOG-05 — Step list: header and run summary

- **Values:**
  - Header row: "Logs" (existing key) on the left; on the right a subtle 24px button with Lucide Trash2 12px and "Clear" (existing key) that unloads the test run (the canvas goes back to draft statuses).
  - Run summary line under the header: 8px vertical and 16px horizontal padding, 12px, gray-11. It shows AP's existing run status text — "Run Succeeded", "Run Failed", "Run Paused", "Running", "Queued", "Run Cancelled", and AP's longer texts for timeouts, memory, log-size and credit limits (all existing keys) — then " · " and the duration. Failure and limit statuses use danger-11.
  - After the text, when they apply: "See error" (existing key, danger-11 link button) selects the failed step; "Follow run updates" (existing key, link button) resumes following a running test; an info icon (Lucide Info 14px gray-11) opens AP's run timeline in a hover card.
- **States:** No run (LOG-12); running; finished.
- **Light/Dark:** Text tokens per mode.
- **Motion:** none.
- **AP target file(s):** new `BUILDER/logs-panel/logs-overview.tsx`; `BUILDER/flow-canvas/widgets/run-info-widget.tsx` (retired; `getStatusText`, `JumpToFailedStepButton` and `ResumeLiveFollowButton` move here), `WEB/features/flow-runs/components/timeline-bar.tsx`.
- **Notes:** e2e: `BuilderPage.testFlowAndWaitForSuccess` waits for `text=Run Succeeded`; this summary line (and the collapsed bar, LOG-02) keeps that text on screen. "Clear" is hidden when the run was opened from the runs list (there the existing "edit flow / view draft" button leaves the run).

### LOG-06 — Step rows

- **Values:**

  | Part | Value |
  |---|---|
  | Row | 32px tall, 8px left and right margins inside the column, 8px horizontal padding, radius 4 background |
  | Logo | The step's piece logo, 16 × 16px (LogoPlate, no border), 8px gap after it |
  | Name | The step display name, 12px/500, gray-12, one line with ellipsis |
  | Duration | Right-aligned, 12px, gray-11, AP's short duration format; shown only when the column is at least 200px wide |
  | Status icon | 14px at the right end: running → spinner in accent-9; failed → Lucide CircleX in danger-9 (and the name turns danger-11); paused → Lucide Pause in warning-9; succeeded → no icon |
  | Order | The order the steps ran in (depth-first through the flow tree); steps with no output in this run are not listed. Steps inside router or continue-on-failure branches are not nested |

- **States:** Idle; hovered (hovered-row fill); selected (selected-row fill); selected and failed (failed-row fill). Click selects the row, selects the step on the canvas and pans it into view if it is off-screen (200ms linear). Double-click opens the step modal in its run view (`07-step-modal.md` NDV-18).
- **Light/Dark:** Surfaces table above.
- **Motion:** Fill changes instant.
- **AP target file(s):** new `BUILDER/logs-panel/logs-step-row.tsx`; `WEB/features/flow-runs/utils/flow-run-utils.ts` (`extractStepOutput`, status helpers), `WEB/features/flow-runs/components/step-status-icon.tsx`.
- **Notes:** —

### LOG-07 — Loop iterations in the list

- **Values:** A loop step's row gets a 12px chevron before its logo. Expanded, it shows one row per iteration — "Iteration {index}" (new ICU key, the same text family as `07-step-modal.md` NDV-17), 12px gray-11, with its own chevron — and under each iteration the steps that ran in it. Each nesting level indents 32px. A 2px connector line in P-02 runs down the left side of nested rows and turns into the last child with an 8px corner radius.
- **States:** Loops start collapsed, except the loop that contains the failed step, which opens down to that step. Selecting a row inside an iteration sets AP's selected index for that loop (`loopsIndexes`), which also updates the canvas.
- **Light/Dark:** P-02 per mode.
- **Motion:** Chevron rotation 200ms; expand / collapse instant.
- **AP target file(s):** `BUILDER/logs-panel/logs-overview.tsx`, `BUILDER/run-details/loop-iteration-input.tsx` (its logic), `BUILDER/state/run-state.ts`.
- **Notes:** —

### LOG-08 — Details column

- **Values:**

  | Part | Value |
  |---|---|
  | Header row | Left: step logo 16px, 8px gap, step name 12px/600 gray-12, 8px gap, status text 12px gray-11 ("Succeeded", "Failed", "Running" or "Paused", existing keys) then " · " and the duration |
  | Header right | Two toggle buttons, "Input" and "Output" (existing keys): 24px tall, subtle style, 12px text, 8px apart. A pressed toggle (its pane is shown) has fill #e5e5e5 in light mode and accent at 25% in dark mode. Then a ghost 24px button (Lucide Ellipsis) with a menu item "Open step" (new key) that opens the step modal; then the collapse chevron (as LOG-02) |
  | Body | Details-body surface. The visible panes side by side — INPUT on the left, OUTPUT on the right — split 50/50 with a 1px divider that can be dragged |
  | Default | Only OUTPUT is shown |
  | Panes | The step modal's data panes (`07-step-modal.md` NDV-10 header styling, NDV-12 to NDV-15 views) with the run's data: INPUT = the step's resolved input in this run, OUTPUT = its output or error. The view-mode control uses the compact form when a pane is narrower than 400px |
  | No step selected | A centred hint "Select a step to see its data" (new key), 12px gray-11 |

- **States:** Output only; input only; both. At least one pane stays visible: switching off the last visible one is ignored.
- **Light/Dark:** Surfaces per mode.
- **Motion:** none.
- **AP target file(s):** new `BUILDER/logs-panel/logs-details.tsx`; `BUILDER/run-details/flow-step-input-output.tsx` (data source), `BUILDER/run-details/ai-router-routes.tsx`, `BUILDER/step-modal/input-pane.tsx` and `output-pane.tsx` (shared data panes).
- **Notes:** —

### LOG-09 — Keyboard

- **Values:**

  | Key | Action |
  |---|---|
  | L | Open / close the panel |
  | I | Show / hide the INPUT pane (panel open) |
  | O | Show / hide the OUTPUT pane (panel open) |
  | Arrow Up / Arrow Down (focus in the step list) | Move the selected row |
  | Enter (focus in the step list) | Open the step modal for the selected row |

- **States:** Off while typing in an input, while the step modal is open, or while the piece panel has focus.
- **Light/Dark:** n/a.
- **Motion:** n/a.
- **AP target file(s):** `BUILDER/shortcuts.ts`, `BUILDER/logs-panel/index.tsx`.
- **Notes:** —

### LOG-10 — Live updates during a test run

- **Values:** As the test runs, rows appear as steps start. The running step's row shows the spinner and is selected automatically, so its data shows in the details. If the user selects another row during the run, automatic following stops and "Follow run updates" appears in the summary (AP's current live-follow behaviour). When the run ends, the failed step is selected if the run failed; otherwise the last step that ran.
- **States:** Following; not following; finished.
- **Light/Dark:** n/a.
- **Motion:** New rows appear without animation.
- **AP target file(s):** `BUILDER/state/run-state.ts` (`userManuallySelectedStepDuringRun`, `resumeLiveFollow`, `selectFailedStep`), `BUILDER/logs-panel/logs-overview.tsx`.
- **Notes:** —

### LOG-11 — Run opened from the runs list

- **Values:** Opening a run in the builder loads it into the same panel, open by default, with the canvas read-only. "Clear" is hidden; leaving the run uses AP's existing "edit flow / view draft" button in the test-bar slot (`05-canvas.md` CAN-12).
- **States:** Read-only.
- **Light/Dark:** n/a.
- **Motion:** n/a.
- **AP target file(s):** `BUILDER/run-list/index.tsx`, `BUILDER/run-list/flow-run-card.tsx`, `WEB/app/routes/runs/id/index.tsx`.
- **Notes:** The runs list itself stays in the right side panel.

### LOG-12 — No run loaded

- **Values:** Collapsed bar as LOG-02 without a status. When opened with no run, the step-list header shows "Logs" and the body shows a centred hint "Test the flow to see each step's logs here" (new key), 12px gray-11. No button in the hint.
- **States:** Empty.
- **Light/Dark:** n/a.
- **Motion:** n/a.
- **AP target file(s):** `BUILDER/logs-panel/index.tsx`.
- **Notes:** Do not add a second button labelled "Test Flow" here: e2e uses `getByRole('button', { name: 'Test Flow' })`, which must match exactly one element.

## Conflicts with design doc

None. `design/graph-positions.md` does not cover the logs panel. Plan note: Phase 10 says "32px when collapsed"; LOG-02 uses the measured 36px.
