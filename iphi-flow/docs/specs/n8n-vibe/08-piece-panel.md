# 08 — Piece panel (PCK)

Builder-facing spec for the right slide-in panel that replaces AP's piece-selector popover. It lists AP's pieces, actions and triggers, grouped by task (PCK-14 to PCK-20, spec v1.3) in AP's own wording. Colours use AP token steps and the canvas palette `P-NN` from `05-canvas.md` CAN-01; conventions are at the top of `05-canvas.md`.

Plan phase: 9. PCK-14 to PCK-20: plan `piece-panel-categories-clean-room.md`. PCK-21 to PCK-24: plan `piece-catalogue-full-load.md`.

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

- **Values (revised in v1.3):** The root lists rows with an icon, a title, a one-line description and, for rows that open a list, a trailing arrow. In next-step and replace modes the rows are the six task categories of PCK-14; in trigger mode they are the trigger rows of PCK-17. After them come the platform's custom groups (after a separator, PCK-08), then the "Browse more pieces" row when available (PCK-21).

  | Row | Lucide icon (20px, gray-11) | Title | Description | Shown when |
  |---|---|---|---|---|
  | Task categories | PCK-14 | PCK-14 | PCK-14 | Next-step and replace modes |
  | Trigger rows | PCK-17 | PCK-17 | PCK-17 | Trigger mode |
  | Platform custom groups | LayoutGrid | The configured name | none | When the platform configures them; listed after a separator (PCK-08), in every mode |

- **States:** Next-step / replace mode; trigger mode.
- **Light/Dark:** Row styling PCK-06.
- **Motion:** none.
- **AP target file(s):** `WEB/features/pieces/components/piece-selector-tabs.tsx`, `BUILDER/pieces-selector/index.tsx` (`getTabsList`, `useRootTabs`), `WEB/features/pieces/utils/piece-selector-customization.tsx` (`buildResolvedTabs`).
- **Notes:** v1.3 replaces the earlier rows (Explore, AI & Agents, Apps, Utility, Approvals) with task categories. The earlier Apps description is retired because it echoed reference wording; every title and description in PCK-14 and PCK-17 is new Activepieces wording.

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

### PCK-14 — Task categories (next-step and replace modes)

- **Values:** Six category rows, in this order. Each opens a category sub-view (PCK-16). Titles and descriptions are new keys.

  | Order | Key | Lucide icon | Title | Description | Shown when |
  |---|---|---|---|---|---|
  | 1 | AI | Sparkles | "AI" | "Run agents, ask models and use AI services" | Always (contents per PCK-15) |
  | 2 | Apps | Puzzle | "Apps" | "Work with the apps and services you connect" | Always |
  | 3 | Transform data | Shuffle | "Transform data" | "Reshape text, dates, numbers and files" | Always |
  | 4 | Flow control | Split | "Flow control" | "Route, repeat, wait or call another flow" | Always |
  | 5 | Core tools | Wrench | "Core tools" | "HTTP, webhooks, code, storage and other building blocks" | Always |
  | 6 | Human in the loop | UserCheck | "Human in the loop" | "Wait for someone to approve or answer" | Always in these modes |

- **States:** All six rows show in next-step and replace modes, subject to the platform configuration (PCK-19).
- **Light/Dark:** As PCK-06.
- **Motion:** none.
- **AP target file(s):** `WEB/features/pieces/components/piece-selector-tabs.tsx` (`getTabDescription`), `WEB/features/pieces/stores/piece-selector-tabs-provider.tsx` (tab types), `BUILDER/pieces-selector/index.tsx`, `WEB/public/locales/en/translation.json`.
- **Notes:** Category rows never add a step themselves; they open a list.

### PCK-15 — Category membership

- **Values:** What each category lists, by section, in order. A section with nothing to show is hidden. A piece that is not downloaded is simply absent. Built-in steps are the Code, Loop on Items, Router and AI Router steps. A few items appear in two categories on purpose (marked "also in").

  | Category | Section (title, new key unless noted) | Contents |
  |---|---|---|
  | AI | "Popular" (existing key) | The AI piece's actions as item rows, with AP's current availability rule and connect-provider prompt; then the AI Router step when an AI router provider exists (also in Flow control) |
  | AI | "AI services" | Every piece whose categories include ARTIFICIAL_INTELLIGENCE or UNIVERSAL_AI, other than the AI piece, plus the pieces named in the AI name list (Azure OpenAI, Cohere); piece rows, alphabetical |
  | Apps | AP's current sections ("Highlights" for platform-pinned pieces, "Popular", then "Apps"; existing keys) | Every piece that is not a core piece and not in the AI category; messaging apps stay here even though their approval actions are also listed under Human in the loop |
  | Transform data | "Popular" | Code step (also in Core tools), Text Helper, Date Helper, Data Mapper |
  | Transform data | "Formats and files" | CSV, XML, Files Helper, PDF, Image Helper, QR Code, Crypto |
  | Transform data | "Others" (existing key) | Data Summarizer, Math Helper |
  | Flow control | "Popular" | Router step, Loop on Items step |
  | Flow control | "Others" (existing key) | AI Router step when available (also in AI), Delay, Sub Flows, Flow Helper |
  | Core tools | "Popular" | HTTP, Webhook, Code step (also in Transform data), Tables |
  | Core tools | "Others" (existing key) | Storage, GraphQL, SMTP, FTP/SFTP, Human Input (its "Respond on UI" action), Connections, Tags, Activepieces Platform |
  | Human in the loop | "Ask a person" | Item rows for the approval actions of Slack, Discord, Microsoft Teams, Microsoft Outlook, Gmail and Telegram (AP's current approvals list and picking rules), then the Approval piece's two actions |

  Every one of the 27 core pieces has exactly one home: actions in the table above; Manual Trigger and Schedule appear only in trigger mode (PCK-17). Within "Popular" sections the order is as listed; elsewhere alphabetical by display name.
- **States:** n/a.
- **Light/Dark:** n/a.
- **Motion:** n/a.
- **AP target file(s):** `WEB/features/pieces/utils/piece-search-utils.ts` (the classifiers become one category map), `WEB/features/pieces/hooks/pieces-hooks.ts` (`usePiecesSearch`), `BUILDER/pieces-selector/approvals-tab-content.tsx` and `ai-tab-content/` (reused as section sources).
- **Notes:** Keep the map in one place with a unit test that checks every core piece and every built-in step lands where this table says. When new list pieces are added later, they go in a "Work with lists" section placed second in Transform data.

### PCK-16 — Category sub-view

- **Values:** Header as the sub-view header of PCK-03 (back button, the category's Lucide icon, the title). Sections are group rows (PCK-07), all expanded when the view opens (this replaces "first group expanded" for category views). Inside a section: a built-in step or an action shows as an item row that adds the step directly; a piece with several actions shows as a piece row (with arrow) that pushes the piece sub-view (PCK-10), where its actions are listed.
- **States:** Loading (skeleton rows, as PCK-11); list.
- **Light/Dark:** As PCK-06 to PCK-08.
- **Motion:** PCK-10.
- **AP target file(s):** `BUILDER/pieces-selector/index.tsx` (`PiecePanelEntry`), `explore-tab-content.tsx` (its category list rendering is reused), `pieces-card-list.tsx`.
- **Notes:** —

### PCK-17 — Trigger-mode rows

- **Values:** In trigger mode the root lists these rows, in order. Titles and descriptions are new keys. A row whose piece is not downloaded is hidden.

  | Order | Lucide icon | Title | Description | Activating it |
  |---|---|---|---|---|
  | 1 | MousePointerClick | "Start manually" | "Run the flow yourself with a button" | Picks Manual Trigger's trigger directly |
  | 2 | Radio | "From an app" | "Start when something happens in an app you connect" | Pushes a list of app pieces that have triggers, with the Apps sections of PCK-15 |
  | 3 | Clock | "Scheduled" | "Every few minutes, hours or days, or a cron expression" | Pushes the Schedule piece's triggers |
  | 4 | Webhook | "When a webhook is called" | "Start when another system sends an HTTP request" | Picks Webhook's catch trigger directly |
  | 5 | ClipboardList | "When a form is submitted" | "Start when someone fills in a hosted form" | Picks Human Input's web form trigger directly |
  | 6 | MessageCircle | "When a chat message arrives" | "Start when someone writes in a hosted chat" | Picks Human Input's chat trigger directly |
  | 7 | Workflow | "When another flow calls it" | "Start when a Sub Flows step in another flow runs this one" | Picks Sub Flows' callable trigger directly |
  | 8 | Ellipsis | "Other triggers" | "Tables, file servers and other core triggers" | Pushes a list of the remaining core pieces with triggers (Tables, FTP/SFTP), alphabetical |

  Rows 1 and 4 to 7 add the trigger directly (no arrow); rows 2, 3 and 8 open a list. AI-category pieces with triggers appear under "From an app".
- **States:** n/a.
- **Light/Dark:** As PCK-06.
- **Motion:** none.
- **AP target file(s):** `BUILDER/pieces-selector/index.tsx` (`getTabsList`, the trigger branch), `WEB/features/pieces/hooks/pieces-hooks.ts`.
- **Notes:** There is no row for adding a second trigger: a flow has exactly one trigger.

### PCK-18 — Search inside a category

- **Values:** Root search is unchanged (PCK-11). Inside a category or a trigger-mode list, the view's own matching rows come first (filtered on the client, as today). Under them, a section label "Found in other groups" (new key) is followed by the root search results (PCK-11 rows) that are not already shown above. When neither part has a match, the no-results state of PCK-11 shows, with the catalogue hint of PCK-21 when available. Inside a piece sub-view, search filters only that piece's actions or triggers, as today.
- **States:** Category matches only; both parts; other categories only; nothing.
- **Light/Dark:** As PCK-08 and PCK-11.
- **Motion:** none.
- **AP target file(s):** `BUILDER/pieces-selector/pieces-card-list.tsx` (`usePieceSearchResultRows`), `explore-tab-content.tsx`, `piece-panel-utils.ts`.
- **Notes:** The root results keep their server order.

### PCK-19 — Platform configuration of the root

- **Values:** The platform's piece-selector configuration keeps working with the categories. Saved built-in keys map as follows: AI_AND_AGENTS → AI; APPS → Apps; UTILITY → Core tools; APPROVALS → Human in the loop; EXPLORE → no longer shown (saved entries are ignored). Two new built-in keys: DATA_TRANSFORMATION (Transform data) and FLOW_CONTROL (Flow control). Renaming, re-icon, ordering and hiding apply to the six categories in next-step and replace modes. Custom groups behave as today and also show in trigger mode. The admin dialog that edits this configuration lists the six categories under their new default names.
- **States:** n/a.
- **Light/Dark:** n/a.
- **Motion:** n/a.
- **AP target file(s):** `@activepieces/shared` `PIECE_SELECTOR_BUILTIN_TABS` and its schema (minor version bump), `WEB/features/pieces/utils/piece-selector-customization.tsx` (`BUILTIN_TAB_DISPLAY`, `buildResolvedTabs`), `WEB/app/routes/platform/setup/pieces/customize-selector-dialog.tsx`.
- **Notes:** Existing saved configurations must load without errors.

### PCK-20 — Retired parts

- **Values:** The Explore view (its popular and highlighted lists, and the built-in steps placed into it) is retired; its content now lives in the categories. The unmounted tab-provider context and the unreachable AI & Agents and Approvals branches of the search hook are removed. Openers and modes (PCK-12), keyboard (PCK-09), push and pop (PCK-10), root search (PCK-11) and the e2e test ids stay as they are.
- **States:** n/a.
- **Light/Dark:** n/a.
- **Motion:** n/a.
- **AP target file(s):** `BUILDER/pieces-selector/explore-tab-content.tsx`, `WEB/features/pieces/stores/piece-selector-tabs-provider.tsx`, `WEB/features/pieces/hooks/pieces-hooks.ts`.
- **Notes:** —

### PCK-21 — "Browse more pieces" row (Activepieces extension)

- **Values:** An Activepieces feature with no reference counterpart, styled with the panel's existing parts. It shows only when the instance downloads pieces selectively (the pieces-sync-mode flag is `OFFICIAL_SELECTED`).
  - At the end of the root list, after any custom groups and a separator (PCK-08), one row: Lucide PackagePlus icon, title "Browse more pieces" (new key), description "Download pieces from the catalog when you need them" (new key), trailing arrow (PCK-06). It appears in next-step, replace and trigger modes.
  - In root search with no results, under "No results" (PCK-11): a second line "Not here? Search the catalog" (new key), 14px gray-11, followed by a subtle 28px button "Search the catalog" (new key) that pushes the catalog view (PCK-22) with the current query carried over.
- **States:** Hidden unless the mode is selective.
- **Light/Dark:** As PCK-06 and PCK-11.
- **Motion:** none.
- **AP target file(s):** `BUILDER/pieces-selector/index.tsx`, `BUILDER/pieces-selector/piece-panel-utils.ts`, `BUILDER/pieces-selector/no-results-found.tsx`.
- **Notes:** The row is a group row (PCK-07 behaviour, opens a sub-view); Arrow Right and Enter push it like any group.

### PCK-22 — Catalog sub-view

- **Values:** Pushed like any sub-view (PCK-10).
  - Header: back button, title "More pieces" (new key), subtitle "Download a piece to use it in this flow" (new key) (PCK-03 styling).
  - Search box (PCK-04) filters the catalog on the client by piece name and description.
  - Rows are piece rows (PCK-06): logo on its plate, display name, one-line description, and on the right a "Download" label (new key) with Lucide Download 14px in gray-11, replacing the trailing arrow. Sorted by display name. Only pieces not yet downloaded appear; for trigger mode, only pieces that have triggers; for next-step and replace mode, only pieces that have actions.
  - Loading: three 48px skeleton rows (as PCK-11). Load failure: the shared in-place error state "Trouble loading {entity}" with a retry, entity = "the catalog" (new key). Empty: centred "Every piece is already downloaded" (new key), 14px gray-11.
- **States:** Loading; list; filtered; empty; failed.
- **Light/Dark:** As PCK-06.
- **Motion:** PCK-10.
- **AP target file(s):** new `BUILDER/pieces-selector/catalog-view.tsx`; `WEB/features/pieces/api/pieces-api.ts` (catalog list and download calls); `WEB/features/pieces/hooks/pieces-hooks.ts`.
- **Notes:** The list is virtualised like the other panel lists (the catalog has several hundred entries).

### PCK-23 — Downloading a piece

- **Values:**
  - Activating a catalog row (click or Enter) downloads that piece. While it downloads, the row's trailing label becomes a 14px spinner with "Downloading…" (new key); the row is marked busy; other rows stay usable, and a second activation of the same row does nothing.
  - On success, the instance's piece list refreshes and the piece's own sub-view (its actions, or its triggers in trigger mode) is pushed on top of the catalog view (PCK-10), so the user can pick at once. Going back from it returns to the catalog, where the piece no longer appears.
  - On failure, the row stays and shows "Couldn't download. Try again." (new key) in danger-11 under the description; activating the row again retries. No toast.
- **States:** Idle; downloading; failed; downloaded.
- **Light/Dark:** Error text danger-11 in both modes.
- **Motion:** spinner rotation; off under reduced motion (a static icon).
- **AP target file(s):** `BUILDER/pieces-selector/catalog-view.tsx`, `BUILDER/pieces-selector/piece-panel-utils.ts`.
- **Notes:** Downloading uses the instance's existing piece sync endpoint with a piece name; it fetches only that piece's latest compatible version.

### PCK-24 — Catalog keyboard and announcements

- **Values:** The catalog view uses the PCK-09 key map. Enter on a row downloads it. A polite live region announces "Downloaded {pieceName}" (new key) on success and "Couldn't download {pieceName}" (new key) on failure.
- **States:** n/a.
- **Light/Dark:** n/a.
- **Motion:** n/a.
- **AP target file(s):** `BUILDER/pieces-selector/catalog-view.tsx`, `BUILDER/pieces-selector/piece-panel-view.tsx`.
- **Notes:** —

## Conflicts with design doc

None. The insert locations used by the openers are exactly those in `design/graph-positions.md` §4.
