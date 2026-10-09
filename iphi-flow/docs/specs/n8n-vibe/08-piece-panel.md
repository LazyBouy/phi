# 08 — Piece panel (PCK)

Builder-facing spec for the right slide-in panel that replaces AP's piece-selector popover. It lists AP's pieces, actions and triggers, in AP's own grouping and wording. Colours use AP token steps and the canvas palette `P-NN` from `05-canvas.md` CAN-01; conventions are at the top of `05-canvas.md`.

Plan phase: 9.

| Surface | Light | Dark | Source |
|---|---|---|---|
| Panel body | #ffffff | #262626 | White / Tailwind neutral-800 |
| Header band | #f5f5f5 | #444444 | Tailwind neutral-100 / nearest neutral-700 #404040 |
| Dividers (left edge, header bottom, search border, separators) | #e5e5e5 | #323232 | P-33 |

## Requirements

### PCK-01 — Panel container

- **Values:**

  | Property | Value |
  |---|---|
  | Anchor | Fixed to the right edge of the builder; top = the bottom edge of the builder header (64px, plan Phase 10; read AP's header-height constant rather than hard-coding it); bottom = window bottom |
  | Width | 385px |
  | Narrow windows | When the window is narrower than 427px (385 + 42), width = window width − 42px, and a close button (ghost 32 × 32px, Lucide X 16px, tooltip "Close", existing key) shows 12px from the panel's top and right edges |
  | Fill | Panel body surface |
  | Left edge | A 1px divider line |
  | Layer | Above the canvas, the canvas chrome and the logs panel (it runs to the window bottom over them); below the step modal and dialogs |
  | Canvas | Not dimmed, not resized, still interactive (a click on it closes the panel) |

- **States:** Closed (off-screen); open.
- **Light/Dark:** Surfaces table above.
- **Motion:** PCK-02.
- **AP target file(s):** `BUILDER/pieces-selector/index.tsx` (the Radix popover becomes a panel rendered once at builder level instead of once per anchor), `BUILDER/index.tsx`, `BUILDER/state/piece-selector-state.ts`.
- **Notes:** The popover's sizing logic (the 340 / 600px widths, the 300px list-height cap and the "adjust list height to available space" hook) becomes obsolete: the list fills the panel height. The top-right canvas toolbar hides while the panel is open (`05-canvas.md` CAN-11).

### PCK-02 — Slide motion

- **Values:** Opening slides the panel in from the right: horizontal offset from 100% of its width to 0. Closing reverses it.
- **States:** Opening; open; closing.
- **Light/Dark:** n/a.
- **Motion:** 200ms, ease, transform only. Off under reduced motion (appears and disappears instantly).
- **AP target file(s):** `BUILDER/pieces-selector/index.tsx`.
- **Notes:** Switching from one opener to another while open swaps the content without closing.

### PCK-03 — Header

- **Values:**

  Root header: 16px padding on all sides; header-band fill; 1px bottom divider; title 18px/600, line-height 22px, gray-12; optional subtitle 4px below it, 14px/400, line-height 19px, gray-11.

  | Mode | Title (new key) | Subtitle (new key) |
  |---|---|---|
  | Next step | "Add a step" | none |
  | Trigger (empty trigger, or replacing the trigger) | "Choose a trigger" | "Pick the event that starts this flow" |
  | Replace an action | "Replace step" | "Pick another piece for {stepName}" (ICU variable) |

  Sub-view header: same fill, padding and divider. Left: a back button (no background, Lucide ArrowLeft 20px, gray-11, hover gray-12) with 12px space after it; then a 20px icon (the piece logo for a piece view, the row icon for a group view) with 16px space after it; then the title (piece or group name), 18px/600; under the title, for a piece view, the piece description, 14px/400 gray-11, at most 2 lines.
- **States:** Root; sub-view.
- **Light/Dark:** Header band per mode.
- **Motion:** The header slides with its view (PCK-10).
- **AP target file(s):** new `BUILDER/pieces-selector/piece-panel-header.tsx`.
- **Notes:** Do not reuse the reference's header wording; the strings above are AP's.

### PCK-04 — Search box

- **Values:**

  | Part | Value |
  |---|---|
  | Box | 40px tall; 16px margin on all sides; 12px horizontal padding; 1px divider border; radius 4; panel-body fill; shadow 0 2px 5px, black at 4% |
  | Leading icon | Lucide Search 16px, gray-11, 12px space after it; accent-9 while the query is not empty |
  | Input | 14px, gray-12; placeholder "Search pieces" (existing key) in gray-11 |
  | Trailing | A clear button (Lucide CircleX 16px, gray-11, hover gray-12) while the query is not empty |
  | Focus | Border turns violet-600 #7f22fe (the tokens focus colour); no extra ring |
  | Test id | `data-testid="pieces-search-input"` on the input element |

- **States:** Empty; typing (results replace the list, PCK-11; AP's 300ms debounce stays); focused. The box is shown on every view; at the root it searches everything, in a sub-view it filters that view's list.
- **Light/Dark:** Surfaces per mode.
- **Motion:** Border colour 200ms.
- **AP target file(s):** `WEB/features/pieces/components/piece-selector-search.tsx`.
- **Notes:** The input is focused when the panel opens and after every push or pop.

### PCK-05 — Root view

- **Values:** The root lists AP's selector groups (today's tabs) as rows with an icon, a title, a one-line description and a trailing arrow. Order and visibility follow AP's current rules and the platform's piece-selector configuration.

  | Row | Lucide icon (20px, gray-11) | Title (existing key) | Description (new key) | Shown when |
  |---|---|---|---|---|
  | Explore | LayoutGrid | "Explore" | "Popular pieces to get started" | Always |
  | AI & Agents | Sparkles | "AI & Agents" | "Use AI models and agents in this flow" | Adding or replacing an action, and AI providers plus the AI piece are available |
  | Apps | Puzzle | "Apps" | "Do something in an app or service" | Always |
  | Utility | Wrench | "Utility" | "Code, loops, routers, HTTP and other core tools" | Always |
  | Approvals | CircleCheck | "Approvals" | "Pause the flow until someone responds" | Adding or replacing an action |
  | Platform custom groups | LayoutGrid | The configured name | none | When the platform configures them; listed after a separator (PCK-08) |

- **States:** Next-step / replace mode shows all eligible rows; trigger mode shows Explore, Apps and Utility.
- **Light/Dark:** Row styling PCK-06.
- **Motion:** none.
- **AP target file(s):** `WEB/features/pieces/components/piece-selector-tabs.tsx` (tabs become root rows), `BUILDER/pieces-selector/index.tsx` (`getTabsList`, `pieceSelectorCustomization.buildResolvedTabs`).
- **Notes:** Activating a row pushes that group's content as a sub-view: Explore → AP's explore categories; AI & Agents → AP's AI actions list; Apps and Utility → piece lists; Approvals → AP's approvals list.

### PCK-06 — List rows

- **Values:**

  | Part | Value |
  |---|---|
  | Row | 12px padding top and bottom, 8px right; the icon starts 16px from the panel's left edge; minimum height 48px |
  | Icon | 24px piece logo (AP's piece icon, no tooltip) for piece and action rows; 20px Lucide icon for group rows |
  | Gap | 16px between icon and text |
  | Title | 14px/500, line-height 18px, gray-12, one line with ellipsis |
  | Description | 2px below the title; 12px/400, line-height 16px, gray-11; up to 2 lines (AP drops a trailing full stop, as today) |
  | Trigger marker | Rows that represent a trigger show Lucide Zap 12px, filled, accent-9, 4px after the title |
  | Classification badge | AP's action classification badge stays after the title (primitives badge, accent variant) |
  | Trailing arrow | Rows that open a sub-view end with Lucide ArrowRight 16px, gray-11; gray-12 when the row is hovered |
  | Disabled row | Icon and text at 45% opacity, not-allowed cursor |

- **States:** Idle; hovered and keyboard-active (PCK-09); disabled.
- **Light/Dark:** gray steps per mode on the panel body surface.
- **Motion:** none.
- **AP target file(s):** `BUILDER/pieces-selector/piece-card-item.tsx`, `generic-piece-selector-item.tsx`, `piece-actions-or-triggers-list.tsx`, `WEB/components/custom/card-list`, `WEB/features/pieces/components/piece-icon.tsx`.
- **Notes:** Rows have no background change on hover; the accent bar (PCK-09) is the only hover cue.

### PCK-07 — Group (category) rows

- **Values:** Used inside sub-views that group pieces (for example AP's explore categories): 14px/600, line-height 1.25, gray-12; padding 8px 16px; 1px bottom divider; trailing Lucide ChevronRight 16px gray-11 that turns to ChevronDown when expanded. Activating it expands or collapses its items in place (the first group starts expanded).
- **States:** Collapsed; expanded; hovered; keyboard-active.
- **Light/Dark:** Divider per mode.
- **Motion:** Chevron rotation 200ms; expand / collapse instant.
- **AP target file(s):** `BUILDER/pieces-selector/explore-tab-content.tsx`.
- **Notes:** The explore view's two-column grid becomes this single-column list.

### PCK-08 — Section labels and separators

- **Values:**
  - Section label: 10px/600, upper-case, letter-spacing 1px, line-height 12px, gray-11; 16px top padding, 4px bottom margin, 16px left and right margins. Used to head groups inside a piece sub-view ("Triggers" and "Actions", existing or new keys) and the explore view's popular list.
  - Separator: a 1px divider line inset 16px from both panel edges, with 16px of space above it and 12px below it. Used between AP's built-in root rows and platform custom groups.
- **States:** n/a (not selectable).
- **Light/Dark:** Divider per mode.
- **Motion:** none.
- **AP target file(s):** `BUILDER/pieces-selector/*`.
- **Notes:** —

### PCK-09 — Hover and keyboard-active bars; keyboard navigation

- **Values:**
  - Every selectable row (item rows and group rows; not section labels) has a 2px bar on its left edge, flush with the panel's left divider: transparent at rest, gray-11 when hovered, accent-9 when keyboard-active.
  - Keyboard:

    | Key | Action |
    |---|---|
    | Arrow Down / Arrow Up | Move the keyboard-active row (scrolls it into view); the first row is active when a view opens |
    | Enter | Activate the active row (push its sub-view, or pick the item) |
    | Arrow Right | Push the active row's sub-view, if it has one |
    | Arrow Left, or Backspace with an empty search | Pop back to the previous view |
    | Escape | Clear the search if it is not empty; otherwise close the panel |

- **States:** Hovered and keyboard-active are independent; a row can show the gray bar (hover) while another shows the accent bar (keyboard).
- **Light/Dark:** gray-11 / accent-9 per mode.
- **Motion:** none.
- **AP target file(s):** `BUILDER/pieces-selector/*`, `WEB/components/custom/card-list`.
- **Notes:** AP's "ignore hover until the cursor moves" guard stays.

### PCK-10 — Sub-view push and pop

- **Values:** Activating a row with a sub-view pushes a new view that slides in from the right over the current one (offset 100% to 0); the current view stays still underneath. Going back slides the top view out to the right (0 to 100%), revealing the view below. The stack is root → group → piece (for example Apps → Gmail → Gmail's actions). The search query is cleared on every push and pop.

  A piece sub-view lists that piece's actions (next-step and replace modes) or triggers (trigger mode) as item rows: title = action or trigger display name, description = its description, icon = the piece logo.
- **States:** Pushing; popping; settled.
- **Light/Dark:** n/a.
- **Motion:** 200ms, ease, transform only; off under reduced motion.
- **AP target file(s):** `BUILDER/pieces-selector/index.tsx`, `explore-tab-content.tsx`, `ai-tab-content/`, `approvals-tab-content.tsx`, `piece-actions-or-triggers-list.tsx`.
- **Notes:** —

### PCK-11 — Search results

- **Values:** While the query is not empty, the list shows AP's search results: for each matching piece, a piece row followed directly by its matching actions or triggers as item rows (their text aligned with the piece title). Activating a piece row pushes that piece's sub-view; activating an item row picks it.

  No results: centred in the list area, Lucide SearchX 24px gray-11, then "No results" (existing key) 14px/600 gray-12. Loading: three 48px skeleton rows.
- **States:** Loading; results; no results.
- **Light/Dark:** As rows.
- **Motion:** none.
- **AP target file(s):** `BUILDER/pieces-selector/pieces-card-list.tsx`, `piece-card-item.tsx`, `no-results-found.tsx`.
- **Notes:** e2e: keep `data-testid={pieceDisplayName}` on the piece row in results (`BuilderPage.addAction` clicks `getByTestId(piece)`). `addAction` then clicks `getByText(action).nth(1)`, which relies on the action name being rendered twice; after this change, check how many matches exist (results list plus pushed sub-view) and update the page object (for example to `.last()`) if needed. `selectInitialTrigger` clicks `getByText(trigger)` after filling the search; the trigger must appear as an item row in the results.

### PCK-12 — Openers and modes

- **Values:**

  | Opener | Mode | Operation / insert location |
  |---|---|---|
  | An output "+" stub (`06-graph.md` HDL-05) | Next step | ADD_ACTION at that output's location (design doc §4) |
  | An edge "+" (`06-graph.md` EDG-05) | Next step | ADD_ACTION at the edge's location |
  | The canvas toolbar "+" and the N key (`05-canvas.md` CAN-11, CAN-16) | Next step | ADD_ACTION AFTER the selected step; with nothing selected, AFTER the last step of the main chain |
  | Releasing a drag from an output handle on empty canvas (`06-graph.md` HDL-07) | Next step | ADD_ACTION at that output; the new step goes to the release point |
  | The empty-trigger placeholder (`05-canvas.md` CAN-14) | Trigger | UPDATE_TRIGGER on the empty trigger |
  | "Replace" in the step menu, or the R key, on an action | Replace | UPDATE_ACTION on that step |
  | "Replace" on a piece trigger | Trigger | UPDATE_TRIGGER |

- **States:** While the panel is open, the opener that opened it ("+" box or placeholder) keeps its hover look.
- **Light/Dark:** n/a.
- **Motion:** n/a.
- **AP target file(s):** `BUILDER/state/piece-selector-state.ts` (keep `openedPieceSelectorStepNameOrAddButtonId` as the single record of which opener the panel serves), `BUILDER/flow-canvas/utils/flow-canvas-utils.ts` (`createAddOperationFromAddButtonData`).
- **Notes:** —

### PCK-13 — Closing, and the result of a pick

- **Values:**
  - The panel closes when: an item is picked; Escape is pressed with an empty search; the canvas or canvas chrome is clicked; the narrow-width close button is pressed; the step modal opens.
  - After a pick: the panel slides out; AP's existing add / update handler applies the operation (plus the position follow-up from design doc §2); the new or replaced step is selected; its step modal opens (`07-step-modal.md` NDV-01).
  - Closing the panel for the empty trigger without a pick deselects the trigger (today's behaviour).
- **States:** n/a.
- **Light/Dark:** n/a.
- **Motion:** PCK-02.
- **AP target file(s):** `BUILDER/pieces-selector/index.tsx`, `BUILDER/builder-hooks.ts` (`handleAddingOrUpdatingStep` with `selectStepAfter`).
- **Notes:** e2e: after `selectInitialTrigger`, the tests read `markdown-code-block` and click `test-trigger-button`; both are in the trigger's step modal, which opens after the pick, so they stay reachable.

## Conflicts with design doc

None. The insert locations used by the openers are exactly those in `design/graph-positions.md` §4.
