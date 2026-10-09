# 04 — Dashboard pages and auth (PAG)

Scope: the page container, the automations list, the shared data table (runs, connections, variables, releases, platform admin lists), the tables editor grid, empty states, and the auth screens. The shell (sidebar, page header, tabs, builder header) is in `03-shell.md` (SHL). Primitive look comes from `02-primitives.md` (PRM); colour, type, shadow and motion values come from `01-tokens.md` (TOK).

Facts only. AP keeps all of its data, actions, conditions and wording; only the visual treatment and the placement of some controls change. Wherever a new i18n key is needed, it is marked "new key".

Path prefix: `WEB` = `iphi-flow/activepieces/packages/web`.

Colour roles are the ones in the table at the top of `03-shell.md`: page background `gray-1`, surface `panel`, hover `gray-3`, track `gray-4`, hairline `gray-6`, control border `gray-7`, strong border `gray-8`, tertiary text `gray-10`, secondary text `gray-11`, primary text `gray-12`, accent `accent-9` / `accent-10` / `accent-11`. TOK is authoritative for the step each role uses.

---

### PAG-01 — Page container and vertical rhythm

- **Values:**
  - The container is centred in the content column. Maximum width 1280 px, including its side padding.
  - Padding: 24 px top, 48 px left and right, 0 bottom. Below a 768 px viewport width: 16 px top and sides.
  - Children stack in this order: page header (SHL-16), tabs (SHL-18), page body.
  - Full-width variant (for the tables editor, PAG-19): no maximum width, 20 px side padding.
  - Reference ruler at 1440 × 900 with the sidebar collapsed:

  | Element | Top (px) | Bottom (px) |
  |---|---|---|
  | Page header block | 24 | 88 |
  | Tab label line | 96 | 120 |
  | Active tab indicator | 124 | 126 |
  | Filter row | 132 | 164 |
  | First row card | 176 | 245 (69 px including borders) |
  | Next card | 8 px gap | — |
  | Pagination row | about 28 px below the last card | 32 px tall |
  | Bottom margin | 24 px below pagination | — |

- **States:** Embedded: the same container. AP's page-header and side-navigation flags may hide the first two children.
- **Light/Dark:** Page background `gray-1` (#fafafa / #171717).
- **Motion:** None. The content column scrolls; the header (SHL-16) stays sticky.
- **AP target file(s):** `WEB/src/app/components/project-layout/index.tsx` (wrap children in the container), `WEB/src/lib/utils.ts` (`DASHBOARD_CONTENT_PADDING_X`), `WEB/src/components/custom/data-table/data-table-toolbar.tsx`.
- **Notes:** AP pages add their own 16 px side padding through a shared constant. Inside the new container that padding must be 0, so page content lines up with the header and the tabs.

### PAG-02 — Automations list: structure

- **Values:** Inside the page body, in order:
  1. The filter row (PAG-03).
  2. The optional active-filters line (PAG-03).
  3. The list of row cards (PAG-04 to PAG-07): a vertical stack of full-width cards, 8 px apart. There is no table header row and there are no column titles; the 1000 px minimum-width grid goes.
  4. The pagination row (PAG-10).
  5. The floating selection bar (PAG-08), when items are selected.
- **States:** Loading, no results and error: PAG-09. Empty project: PAG-21.
- **Light/Dark:** Per the cards.
- **Motion:** Per the parts.
- **AP target file(s):** `WEB/src/app/routes/automations/index.tsx`, `WEB/src/features/automations/components/automations-table.tsx`, `WEB/src/features/automations/components/automations-table-row.tsx`.
- **Notes:** Filtering, sorting, paging, pins, folders, selection and every row action keep their current logic. `/tables` and `/flows` still redirect here, so this list is also the tables list.

### PAG-03 — Automations filter row

- **Values:**
  - One row of 32 px controls, centred vertically, 12 px gap below it.
  - Left end: the select-all control (PAG-08).
  - Right end, end-aligned, 4 px apart, in this order:
    1. Search.
       - 32 px tall, 240 px wide, PRM input at medium size (radius 4).
       - Leading search icon, 16 px, `gray-10`, 12 px from the left edge. Placeholder 14 px, `gray-10`; AP's placeholders are unchanged and truncate with an ellipsis.
       - When there is text, AP's clear button shows at the right: a 20 px circle with a 12 px x icon.
    2. Sort.
       - PRM select, 32 px tall, 196 px wide.
       - Options and their AP sort values: "Last modified" (existing key) → default, which is most recently updated first; "Sort by name A to Z" (existing key) → name ascending; "Sort by name Z to A" (existing key) → name descending.
       - The trigger shows the chosen option.
    3. Filter.
       - PRM subtle icon button, 32 × 32 px, with a 16 px funnel icon. Tooltip "Filters" (new key).
       - When at least one filter is active, a 16 px pill (solid `accent-9`, white 10 px / 600 count) sits on its top-right corner, offset 4 px outward.
       - It opens a PRM popover aligned to its end: 320 px wide, padding 12 px. The popover holds AP's existing filters, stacked 12 px apart: Type, Status, Connections, Owner (hidden when embedded), Folder (only when folders exist). Each filter is a 12 px / 500 `gray-11` label above a full-width 32 px trigger that opens AP's existing multi-select list.
       - The popover footer has "Clear all" (existing key) as an `accent-9` text button, shown when a filter is active.
  - Active-filters line: shown when any filter or the search is active. A 20 px line, 8 px below the filter row and right-aligned, with 12 px `gray-10` text "{count, plural, =1 {1 filter active} other {# filters active}}" (new key), a middle dot, and "Clear all" (existing key) as a 12 px / 500 `accent-9` link.
- **States:** PRM control states. Changing a filter, the search or the sort keeps today's side effects: selection cleared, pagination reset.
- **Light/Dark:** PRM inputs and buttons.
- **Motion:** PRM popover.
- **AP target file(s):** `WEB/src/features/automations/components/automations-filters.tsx`, `WEB/src/features/automations/components/multi-select-filter.tsx`, `WEB/src/app/routes/automations/index.tsx`.
- **Notes:**
  - The Create New button moves to the page header (SHL-17). The Import dropdown's two items move into that button's menu (PAG-11).
  - The reference search box is 196 px; this spec widens it to 240 px because AP's placeholders are longer.

### PAG-04 — Automations row card: body

- **Values:**
  - Card: full content width, radius 8, 1 px `gray-6` border, surface background. The whole card is clickable (pointer cursor), except its interactive children.
  - Height: about 69 px with a single-line meta row.
  - Three zones in one row: leading (selection and pin), content (name and meta) and trailing (PAG-05).
  - Leading zone:
    - 16 px left padding.
    - Selection checkbox: PRM checkbox, 16 × 16 px, always visible.
    - 12 px gap.
    - Pin star: 16 px. Outline `gray-10` star while the card is hovered or holds focus. A pinned item shows AP's filled yellow star at all times.
    - 8 px gap.
    - The star's space is reserved even when hidden, so nothing shifts. Only top-level items (depth 0) get a star (AP rule).
  - Content zone (takes the remaining width):
    - Top line, 16 px from the card's top edge: the type icon (16 px, AP's existing colours: flow in the accent, table and agent in their swatch colours, folder filled `gray-10`), an 8 px gap, then the name (14 px / 500, `gray-12`, ellipsis with tooltip). The created-by "AI" badge (PRM outline badge, 20 px) follows the name 6 px after it.
    - Meta line, directly under the name: 12 px / 400, `gray-10`. Parts are 8 px apart, with a "|" divider in the same colour between them. The meta row is at least 32 px tall, including 16 px of bottom padding.

  | Item type | Meta parts, in order |
  |---|---|
  | Flow | "Updated {time}" (new key; relative time) · "Created {date}" (new key; AP short date) · AP piece icon list (up to 3 icons, 16 px, 4 px apart, then a "+N" chip) |
  | Table | "Updated {time}" · "Created {date}" |
  | Agent | "Updated {time}" · "Created {date}" · AP agent tool stack at 16 px |
  | Folder | "{n} files" using AP's existing file / files wording |

  The data comes from each item's `updated` and `created` fields, formatted with AP's existing date helpers.
- **States:** PAG-06.
- **Light/Dark:** Card #ffffff / #262626. Border `gray-6`. Name #262626 / #ffffff. Meta #999999 / #bbbbbb.
- **Motion:** PAG-06.
- **AP target file(s):** `WEB/src/features/automations/components/automations-table-row.tsx` (`RowItemIcon`, `RowItemDetails`, `RowItemOwner`), `WEB/src/features/automations/components/automations-table.tsx`.
- **Notes:** The Details, Last modified, Owner and Status columns disappear as columns. Their content moves into the meta line and the trailing zone.

### PAG-05 — Automations row card: trailing zone

- **Values:** Centred vertically, 16 px right padding, 8 px between items, in this order:
  1. Owner pill (flows and agents that have an owner; hidden when embedded):
     - 24 px tall pill, 1 px `gray-6` border, surface fill, padding 0 8 px 0 4 px.
     - AP's avatar (16 px round), a 6 px gap, then the owner's name (12 px / 500, `gray-11`, ellipsis, maximum 160 px).
     - Items without an owner show nothing, instead of today's "-".
  2. Status:
     - Flow: AP's flow status toggle (PRM small switch) with its trigger icon, behaving exactly as today.
     - Agent: a status pill, 24 px tall, 1 px `gray-6` border, transparent fill, padding 0 8 px. It holds an 8 px dot (`success-9` for "Live", `gray-8` for "Draft"), a 6 px gap and the label, 12 px / 500 `gray-11` (existing keys "Live" and "Draft").
     - Tables and folders: nothing.
  3. Folder create: folders only. A ghost 28 × 28 px button with a 16 px plus icon in `gray-11`. It opens AP's create-in-folder menu.
  4. More:
     - A ghost 28 × 28 px button with a 16 px horizontal-ellipsis icon in `gray-11`.
     - Use the same lucide "more horizontal" icon component AP uses today; the e2e cleanup finds row menus by that icon.
     - It opens AP's existing row menu with the same items and conditions: Copy URL, Rename, Duplicate, Move To, Export, Share, and Delete in danger text.
- **States:**
  - Folder create: visible while the card is hovered or holds focus, and while its menu is open; hidden (but still in the DOM) otherwise.
  - More: always visible; shows the pressed fill while its menu is open.
  - Clicks inside the trailing zone never open the item.
- **Light/Dark:** Per the role table.
- **Motion:** The folder create button fades in and out over 150 ms.
- **AP target file(s):** `WEB/src/features/automations/components/automations-table-row.tsx`, `WEB/src/features/flows/components/flow-status-toggle.tsx`, `WEB/src/components/custom/ap-avatar.tsx`.
- **Notes:** —

### PAG-06 — Automations row card: states

- **Values and states:**
  - Rest: `gray-6` border, no shadow.
  - Hover: shadow 0 2 px 8 px in a warm dark brown (rgb 68 28 23) at 10% opacity. In dark mode, use black at 25%. The pin star and the folder create button appear.
  - Selected (checkbox on): fill `gray-3`, border `gray-7`.
  - Focus-visible: the card is focusable. Enter opens it the same way a click does. PRM focus ring outside the 8 px radius.
  - Pinned: filled star visible.
  - Ctrl-click or ⌘-click opens the item in a new tab (unchanged).
  - Click: flow → builder; table → table editor; agent → agent page; folder → expand or collapse (all unchanged).
- **Light/Dark:** Selected fill #f5f5f5 / #2b2b2b.
- **Motion:** The shadow transitions over 300 ms, ease. No transition under reduced motion.
- **AP target file(s):** `WEB/src/features/automations/components/automations-table.tsx` (row wrapper), `WEB/src/features/automations/components/automations-table-row.tsx`.
- **Notes:** AP rows are not keyboard-focusable today; this adds focus and Enter.

### PAG-07 — Folders in the automations list

- **Values:**
  - A folder is a row card (PAG-04) with a disclosure chevron (16 px, `gray-10`) in the leading zone, just before the folder icon. The chevron points right when the folder is closed and down when it is open.
  - Folder icon: 16 px, filled `gray-10`. Meta: "{n} files". Trailing: folder create and More (PAG-05).
  - Clicking anywhere on the folder card expands or collapses it (unchanged).
  - Expanded folder:
    - Its children render directly below the folder card as a nested stack: 8 px gap below the folder card, 8 px between children.
    - Each child card is indented 24 px from the content's left edge.
    - A 1 px `gray-6` vertical guide line runs 12 px from the content's left edge, from below the folder card to the middle of the last child.
    - Child cards have no star (depth 1) but do have a checkbox.
  - "Load {count} more items..." (existing key): a 32 px ghost text button in the indented column, 8 px below the last child. 14 px / 500 `accent-9` with a 16 px arrow-down icon; hover underline.
- **States:** Expanded and collapsed. Collapsing a folder clears the selection (unchanged).
- **Light/Dark:** Per the role table.
- **Motion:** The chevron turns over 150 ms. Children expand and collapse with AP's existing accordion height animation. Both are off under reduced motion.
- **AP target file(s):** `WEB/src/features/automations/components/automations-table.tsx` (accordion), `WEB/src/features/automations/components/automations-table-row.tsx`.
- **Notes:** The reference opens folders as separate pages. AP keeps in-place expansion, drawn as indented cards.

### PAG-08 — Bulk selection

- **Values:**
  - Select all: at the left end of the filter row. A PRM checkbox (16 px) followed, 8 px later, by the label "Select all" (existing key), 14 px `gray-11`. It is checked when every selectable item is selected. It shows the indeterminate mark when some, but not all, are selected.
  - It must be the first checkbox on the page in document order. An e2e scenario selects everything by clicking the first checkbox.
  - Card checkboxes: PAG-04. Checked means an `accent-9` fill with a white tick (PRM checkbox).
  - Floating selection bar (AP's):
    - Fixed at the bottom centre, 24 px above the viewport bottom.
    - Surface per the PRM popover: radius 8, medium shadow plus a 1 px outline ring. Padding 8 px; items 12 px apart.
    - Items:
      - "Move to": hidden when folders are hidden.
      - "Export": hidden when import and export are hidden; shows a spinner and "Exporting" while busy.
      - "Delete": danger text, trash icon, opens the existing confirmation.
      - A 1 px × 24 px `gray-6` divider.
      - "{count} selected" (existing key): 14 px `gray-10`.
      - A close button: ghost icon button, 28 px, x icon.
    - Action buttons are PRM ghost medium (32 px) with 16 px leading icons.
- **States:** Disabled actions per AP's existing rules: nothing movable or exportable selected, or an action in progress.
- **Light/Dark:** PRM popover surface.
- **Motion:** The bar enters from 80 px below while fading in, as a spring (damping 25, stiffness 300), and exits the same way. Under reduced motion it only fades.
- **AP target file(s):** `WEB/src/features/automations/components/automations-selection-bar.tsx`, `WEB/src/features/automations/components/automations-table.tsx` (select-all leaves the old header row), `WEB/src/features/automations/components/automations-filters.tsx` (select-all lands here), `WEB/src/components/custom/data-table/data-table-bulk-actions.tsx` (same bar look).
- **Notes:** The same e2e scenario then clicks the bar's trash-icon button and confirms "Delete". Keep the trash icon and the "Delete" label.

### PAG-09 — Automations loading, no results, error

- **Values:**
  - First load: 10 skeleton cards, shown only if loading lasts more than 300 ms.
    - Each is the same size and frame as a real card (69 px, radius 8, 1 px `gray-6` border, surface).
    - Each holds two bars, radius 4, filled `gray-3`: a name bar 160 × 14 px, 16 px from the top-left, and a meta bar 240 × 10 px, 8 px below it.
  - Refetch while cards are shown: the cards stay. The route loading bar (2 px `accent-9`, indeterminate, along the top of the content column) shows progress.
  - No results (a filter or the search is active, and nothing matches): the generic empty state (PAG-22) in place of the list, with:
    - AP's no-results icon.
    - Heading "No results found" (existing key).
    - AP's existing description.
    - A PRM subtle "Clear filters" button (existing key).
  - Error: AP's data-fetch error state in place of the list, with 64 px vertical padding. Its content and behaviour are unchanged (see PAG-16).
- **States:** —
- **Light/Dark:** Per the role table.
- **Motion:** The skeleton bars use PRM skeleton pulsing; none under reduced motion.
- **AP target file(s):** `WEB/src/features/automations/components/automations-table.tsx` (skeleton), `WEB/src/features/automations/components/automations-no-results-state.tsx`, `WEB/src/app/routes/automations/index.tsx`.
- **Notes:** —

### PAG-10 — Pagination row (automations and data tables)

- **Values:**
  - Right-aligned, below the list or table: about 28 px below an automations list, 16 px below a table container. 24 px bottom margin. Controls are 32 px tall and 8 px apart.
  - Order:
    1. AP's optional "Showing the first {count}" note (automations only): 12 px `gray-10`.
    2. "Rows per page" (existing key): 14 px `gray-10`.
    3. Page-size select: PRM select, 32 px tall, 72 px wide. AP's options are unchanged: 10, 20, 50 for automations; 10, 30, 50 for data tables.
    4. Previous: an icon-only PRM ghost button, 32 × 32 px, chevron-left 16 px, accessible name and tooltip "Previous" (existing key).
    5. Next: the same with chevron-right, "Next" (existing key).
- **States:** Previous and Next are disabled per AP's existing rules: 50% opacity, not-allowed cursor.
- **Light/Dark:** PRM controls.
- **Motion:** None.
- **AP target file(s):** `WEB/src/features/automations/components/automations-pagination.tsx`, `WEB/src/components/custom/data-table/index.tsx` (pagination block).
- **Notes:** Data tables page with cursors, so there are no page numbers and no totals. The reference shows a total and page numbers; AP has no data for either.

### PAG-11 — Create menu content (header split button)

- **Values:** The chevron segment of SHL-17 opens a PRM dropdown, minimum width 200 px, below the button and aligned to its end, 4 px away. Items have 16 px leading icons and use AP's existing wording and icons. Items show according to AP's existing permissions and embed flags; items the user cannot use are disabled, with AP's "permission needed" tooltip, as today.
  - On the Automations tab, in order:
    1. New Flow (workflow icon). While pending: a spinner and "Creating...".
    2. Start from Template (sparkles). Embedded: opens AP's templates dialog; otherwise goes to `/templates`.
    3. New Table (table icon). Hidden when tables are hidden.
    4. New Agent (bot icon). Only when agents are visible.
    5. New Folder (folder-plus icon). Hidden when folders are hidden.
    6. A separator.
    7. Import Flow (upload icon). Hidden when import and export are hidden.
    8. Import Table (upload icon). Hidden when tables or import are hidden.
  - On the other project tabs: items 1 to 4 only.
- **States:** PRM dropdown item states.
- **Light/Dark:** PRM dropdown.
- **Motion:** PRM dropdown.
- **AP target file(s):** `WEB/src/features/automations/components/create-new-menu.tsx`, `WEB/src/features/automations/components/automations-filters.tsx` (the Import dropdown is removed here), `WEB/src/app/routes/automations/index.tsx` (dialogs stay on the page).
- **Notes:** Keep "New Flow" as a menu item even though the main segment also creates a flow. The e2e flow opens the menu by the button named "Create New" and clicks the "New Flow" item.

### PAG-12 — Data table: container and header

- **Values:**
  - Container: full width of the page container, 12 px below the toolbar. Radius 8, 1 px `gray-6` border, surface background. It clips its content. Every dashboard data table uses this bordered form.
  - Header row:
    - 36 px tall, fill `gray-3`, 1 px `gray-6` bottom border.
    - Text 12 px / 600, `gray-11`, in AP's existing column titles (title case), vertically centred.
    - Header icons, where AP shows them: 14 px `gray-10`, 6 px before the title.
    - Sortable headers show a 14 px `gray-10` sort arrow; on hover the title turns `gray-12`.
  - When rows are virtualized, the header is sticky and keeps its fill and bottom border.
- **States:** —
- **Light/Dark:** Header fill #f5f5f5 / #2b2b2b. Title #444444 / #e5e5e5. Border `gray-6`.
- **Motion:** None.
- **AP target file(s):** `WEB/src/components/custom/data-table/index.tsx` (always bordered; the sticky-header styling), `WEB/src/components/ui/table.tsx` (header and header cell), `WEB/src/components/custom/data-table/data-table-column-header.tsx`.
- **Notes:** The table header loses its top border; the container frames it.

### PAG-13 — Data table: rows and cells

- **Values:**
  - Rows:
    - Minimum height 48 px, surface background, 1 px `gray-6` divider between rows (none after the last).
    - Text 14 px / 400 `gray-12`. Empty values ("-") in `gray-10`.
  - Cells:
    - 8 px horizontal padding, 16 px on the first and last columns (replacing today's 32 px). Content centred vertically, about 8 px vertical padding.
    - Checkbox column: 16 px left padding, a 16 px checkbox, 40 px wide in total.
  - Actions column: right-aligned. AP's existing action controls are PRM ghost icon buttons, 28 × 28 px, with 16 px `gray-11` icons.
  - Status cells (AP's status icon with text):
    - A 16 px icon tinted by status: success `success-9` (filled check-circle), failure `danger-9`, warning or paused `warning-9`, queued and other neutral states `gray-10`, running `accent-9` (spinner).
    - Then an 8 px gap and the label, 14 px `gray-12`.
  - Long values are truncated with AP's `TextWithTooltip`.
- **States:**
  - Hover (clickable rows only): fill `gray-1`.
  - Selected: fill `gray-3`.
  - Non-clickable rows: no hover fill, default cursor.
- **Light/Dark:** Row #ffffff / #262626. Hover #fafafa / #171717. Dividers #e5e5e5 / #323232.
- **Motion:** None.
- **AP target file(s):** `WEB/src/components/ui/table.tsx` (row and cell), `WEB/src/components/custom/data-table/index.tsx`, `WEB/src/components/custom/status-icon-with-text.tsx`, `WEB/src/components/custom/data-table/truncated-column-text-value.tsx`.
- **Notes:** —

### PAG-14 — Data table toolbar

- **Values:**
  - A row above the container: AP's filters on the left, AP's toolbar buttons on the right. Controls are 32 px tall and 8 px apart. No side padding, so the toolbar lines up with the page container. 12 px gap below.
  - Filter triggers (AP's data-table filters): PRM subtle buttons, 32 px tall, radius 4, with a 16 px leading icon in `gray-11` and a 14 px / 500 label.
    - With values chosen, the label is followed by a 20 px PRM tag showing the value or count, and the trigger border becomes `gray-8`.
  - Toolbar buttons keep their wording and actions (New Connection, New variable, Create Release, Replace, and others): PRM subtle medium buttons (32 px) with 16 px leading icons.
  - The runs status chart stays a toolbar item.
- **States:** PRM states.
- **Light/Dark:** PRM.
- **Motion:** PRM popovers for filter inputs and selects.
- **AP target file(s):** `WEB/src/components/custom/data-table/data-table-toolbar.tsx`, `WEB/src/components/custom/data-table/data-table-filter.tsx`, `WEB/src/components/custom/data-table/data-table-select-popover.tsx`, `WEB/src/components/custom/data-table/data-table-input-popover.tsx`, `WEB/src/components/custom/data-table/data-table-checkbox-filter.tsx`.
- **Notes:** The page's single orange button is the header create button (SHL-17). Toolbar create buttons are subtle, so a page never shows two solid orange buttons.

### PAG-15 — Data table loading

- **Values:**
  - First load (no rows yet): skeleton rows inside the container, as many as the page size (up to 10).
    - Each is 48 px tall with `gray-6` dividers.
    - Each holds one bar, 16 px tall, radius 4, filled `gray-3`, inset by the cell padding.
  - Reload while rows are shown (page change, filter change, retry):
    - A 2 px `accent-9` indeterminate bar runs along the top edge of the body, just under the header. Reuse AP's existing indeterminate progress animation.
    - The current rows dim to 38% opacity until the new data arrives.
- **States:** —
- **Light/Dark:** Bar `accent-9`; skeleton `gray-3`.
- **Motion:** The indeterminate bar loops; the dimming fades over 150 ms. Under reduced motion the bar is static at full width and there is no fade.
- **AP target file(s):** `WEB/src/components/custom/data-table/index.tsx`, `WEB/src/components/custom/data-table/data-table-skeleton.tsx`.
- **Notes:** Today AP swaps rows for skeletons whenever loading. Dimming needs to know that earlier data exists (for example from the query's fetching flag). If that is not available for a table, keep the skeleton.

### PAG-16 — Data table empty and error states

- **Values:**
  - Empty: inside the container, a centred block, minimum height 320 px. It has the content of the generic empty state (PAG-22) without its dashed frame:
    - AP's empty-state icon at 40 px, stroke 1.5, `gray-10`.
    - 8 px gap, then AP's title, 16 px / 500 `gray-12`.
    - 8 px gap, then AP's description, 14 px `gray-11`, maximum 512 px wide.
    - 20 px gap, then AP's empty-state action as a PRM button.
  - Error: AP's data-fetch error state, in the same place and minimum height. Its content, structure and calm tone are unchanged: the warning-tinted 40 px icon tile, the title, the reassurance line, and the "Try again" button as a PRM subtle small button. It only takes on the new token values; it never gets a destructive red treatment.
- **States:** —
- **Light/Dark:** Per the role table; the warning tile per TOK's warning ramp.
- **Motion:** None.
- **AP target file(s):** `WEB/src/components/custom/data-table/index.tsx`, `WEB/src/components/custom/data-fetch-error-state.tsx`.
- **Notes:** AP rule: a primary-data fetch failure is shown in place, never as a toast. This is unchanged.

### PAG-17 — Runs page

- **Values:** Page header and tabs (SHL-16 to SHL-18), then AP's runs table using PAG-12 to PAG-16. Filters, the status chart and columns are unchanged. Status cells follow PAG-13. Times and durations are 14 px `gray-12`. Clicking a row opens the run (unchanged). Bulk actions use the PAG-08 bar.
- **States:** Per the table.
- **Light/Dark:** Per the table. Chart colours come from the success and danger ramps.
- **Motion:** None.
- **AP target file(s):** `WEB/src/app/routes/runs/index.tsx`, `WEB/src/features/flow-runs/components/runs-table/index.tsx`, `WEB/src/features/flow-runs/components/runs-table/runs-status-chart.tsx`.
- **Notes:** —

### PAG-18 — Connections page

- **Values:** AP's connections table using PAG-12 to PAG-16.
  - Piece cell: AP's logo plate (20 px, radius 4), 8 px gap, piece name.
  - Status: PAG-13.
  - Global or scope markers: PRM badges.
  - Toolbar: "New Connection" as a PRM subtle button with a plus icon, and "Replace" (PAG-14).
  - Row actions: PRM ghost icon buttons.
- **States:** Per the table.
- **Light/Dark:** Per the table.
- **Motion:** None.
- **AP target file(s):** `WEB/src/app/routes/connections/index.tsx`, `WEB/src/app/connections/`, `WEB/src/features/connections/components/`.
- **Notes:** —

### PAG-19 — Tables: list and editor grid

- **Values:**
  - List: tables are listed in the automations list (PAG-02 to PAG-09), filtered by type.
  - Editor page: uses the full-width container variant (PAG-01). The grid takes the data-table look:
    - Header row 36 px, fill `gray-3`, 12 px / 600 `gray-11`.
    - Cells 14 px `gray-12` on the surface colour.
    - 1 px `gray-6` grid lines.
    - Row hover fill `gray-1`.
    - The selected cell gets a 2 px inset outline in the focus colour.
    - AP's warning-tinted highlight keeps the TOK warning step 3.
- **States:** Editing cells per PRM input (small).
- **Light/Dark:** Per the role table.
- **Motion:** None.
- **AP target file(s):** `WEB/src/app/routes/tables/id/index.tsx`, `WEB/src/app/routes/tables/id/react-data-grid.css`, `WEB/src/features/tables/components/`.
- **Notes:** The reference's own data-table editor was not captured. The grid values here carry over from the list table (PAG-12 and PAG-13) and are not verified against it.

### PAG-20 — Settings and platform admin surfaces

- **Values:**
  - Platform admin pages: the platform sidebar (SHL-15), the page container (PAG-01) and the generic header (SHL-16). Content uses the primitives:
    - Lists: PAG-12 to PAG-16.
    - Forms: PRM Input, Select, Textarea, Switch, Checkbox, Radio group.
    - Panels: PRM Card.
    - Banners: PRM Callout and Notice.
  - Dialog-based settings (project settings with its General, Members, Alerts, Pieces and Environment tabs; account settings, including the theme and language toggles; the settings hub; invite, rename, move-to, create-folder and delete confirmations):
    - PRM Dialog widths and surface.
    - Tabs inside dialogs: PRM Tabs (underline).
    - Any vertical navigation inside a dialog: the SHL-07 item look.
  - Cross-references in `02-primitives.md`: Button, Input, Select, Textarea, Switch, Checkbox, Tabs, Segmented control, Tooltip, Dropdown, Popover, Dialog, Badge, Tag, Card, Table, Callout, Notice, Toast, Scrollbar.
- **States:** Per PRM.
- **Light/Dark:** Per PRM.
- **Motion:** Per PRM.
- **AP target file(s):** `WEB/src/app/components/project-settings/`, `WEB/src/app/components/account-settings/`, `WEB/src/app/components/settings-hub/`, `WEB/src/app/routes/platform/`.
- **Notes:** No page-specific values beyond the container and header. Resolve each primitive to its PRM ID in `02-primitives.md`.

### PAG-21 — New-project empty state (action cards)

- **Values:**
  - Shown when the automations list has no items and no filters are active (AP's empty-state condition). The filter row and pagination are not shown.
  - Layout: a centred column in the page container. It is vertically centred in the remaining height when it fits; otherwise it starts 48 px below the tabs.
  - Heading: AP's "Get started with {brandName}" (existing key). 20 px / 600, `gray-12`, centred, 16 px above the card row.
  - Card row: centred, wrapping, 24 px gap (20 px below a 768 px viewport width). AP's cards: "Build a Flow", "Create a Table" (unless tables are hidden), "Build an Agent" (when agents are visible).
  - Card frame: 240 px wide, radius 8, 1 px `gray-6` border, surface background. Padding 16 px for the top section; the option rows run to the card edges.
  - Card top section:
    - A 48 px outline icon (stroke 1.5, `gray-10`), centred: workflow, table and bot for the three cards.
    - 12 px gap, then the title, 14 px / 500 `gray-12`, centred.
    - 4 px gap, then the description, 12 px `gray-10`, centred.
    - 12 px gap.
  - Option rows: AP's existing buttons with their existing labels ("Start from scratch", "Import", "Use Templates"), each:
    - 36 px tall, padding 0 16 px, with 1 px `gray-6` hairlines above.
    - A 16 px `gray-11` icon, 8 px gap, the label (14 px / 500 `gray-12`), and a trailing 16 px chevron-right in `gray-10`.
  - "Templates For You" section, 48 px below the cards and left-aligned:
    - Header: "Templates For You" in 14 px / 500 `gray-11` with AP's sparkles icon. "All templates" link on the right: 14 px `gray-10`, `gray-12` on hover.
    - Grid: 3 columns, 16 px gap. Template cards are PRM cards (radius 8, 1 px `gray-6`, surface, padding 16) with the PAG-06 hover shadow.
- **States:**
  - Card hover: the card rises 2 px, gets a 0 8 px 25 px shadow in black at 10%, and its icon turns `accent-9`.
  - Option row hover: fill `gray-3`.
  - Disabled option rows: 50% opacity.
- **Light/Dark:** Per the role table. Dark card shadow: black at 25%.
- **Motion:**
  - Heading: over 400 ms, ease-out. It fades in from 0, un-blurs from 3 px, and moves 24 px upward: it starts 12 px below its layout position and ends 12 px above it.
  - Cards: each fades in from 0 and rises 8 px into place over 400 ms, ease-out. Delays are 160 ms, 240 ms and 320 ms (160 ms plus 80 ms per card index).
  - The icon colour changes over 300 ms. The hover lift and shadow transition over 200 ms.
  - Under reduced motion: no entrance animation and no lift.
- **AP target file(s):** `WEB/src/features/automations/components/automations-empty-state.tsx`.
- **Notes:**
  - The e2e flow waits for the heading text (brand name "Activepieces" in Community Edition) and clicks the first "Start from scratch". Keep both.
  - This screen centres its heading and cards, unlike AP's left-aligned F-pattern guideline. The reference layout centres here.

### PAG-22 — Generic empty state

- **Values:**
  - Frame: 2 px dashed `gray-6` border, radius 8, no fill (the page background shows), padding 64 px top and bottom and 32 px at the sides. Centred column, 20 px gap between its parts.
  - Icon: 40 px outline, stroke 1.5, `gray-10`.
  - Text block (maximum 512 px wide, 8 px gap): heading 20 px / 400 `gray-12`, centred; description 14 px / 400 `gray-11`, centred.
  - Call to action: PRM primary, large (36 px), using AP's action and label. Secondary actions are PRM subtle.
  - Optional PRM callout below, full width.
  - Use for empty or no-results surfaces that are not inside a table container: automations no results (PAG-09), the no-projects state, and standalone empty lists. Inside a table, use PAG-16.
- **States:** Disabled call to action: PRM disabled, with AP's tooltip.
- **Light/Dark:** Border `gray-6`; text per the role table.
- **Motion:** None.
- **AP target file(s):** `WEB/src/components/ui/empty.tsx`, `WEB/src/features/automations/components/automations-no-results-state.tsx`, `WEB/src/app/components/no-projects-state.tsx`.
- **Notes:** —

### PAG-23 — Auth page shell

- **Values:**
  - Applies to: sign-in (sign-up redirects to it), forgot password, reset password and verify email.
  - Page background `gray-1`.
  - Remove the animated app backdrop, the blurred dimming layer above it, the "nudge" that bounces the panel when the backdrop is clicked, and the zoom-in entrance.
  - Layout: a column centred horizontally and aligned to the top.
    - 36 px top padding.
    - The platform's full logo (AP's full-logo component, white-label), 40 px tall, centred.
    - 30 px gap, then the card (PAG-24).
    - 32 px bottom padding.
    - The page scrolls when it is taller than the viewport.
  - Below a 400 px viewport width: 16 px side padding, and the card width becomes the viewport width minus 32 px.
- **States:** A signed-in user is redirected (unchanged).
- **Light/Dark:** #fafafa / #171717.
- **Motion:** None for the page.
- **AP target file(s):** `WEB/src/features/authentication/components/auth-landing/auth-landing.tsx`, `WEB/src/features/authentication/components/auth-landing/auth-backdrop.tsx` (no longer used; delete it and the auth-animation styles in `WEB/src/styles.css` once unused), `WEB/src/app/routes/forget-password/index.tsx`, `WEB/src/app/routes/change-password/index.tsx`, `WEB/src/features/authentication/components/verify-email.tsx`.
- **Notes:** In the reference measurement the logo spans y = 36–76 and the card's top edge is at y = 106.

### PAG-24 — Auth card

- **Values:**
  - 352 px wide, padding 24 px, surface background, 1 px `gray-6` border, radius 8.
  - Shadow: 0 4 px 16 px in a cool violet (rgb 99 77 255) at 6% opacity in light mode; none in dark mode.
  - Height follows the content. The logo is no longer inside the card (it moves above it, PAG-23).
  - The card stays a labelled region (keep AP's accessible label). It is no longer a dialog, since there is no overlay.
- **States:** AP's steps (method, code, verified, name, password, reset, SSO) render inside the same card.
- **Light/Dark:** Surface #ffffff / #262626; border `gray-6`.
- **Motion:** Kept from AP: the card animates its height between steps (240 ms, curve (0.16, 1, 0.3, 1)), and the steps cross-fade (140 ms, ease-out). Neither runs under reduced motion.
- **AP target file(s):** `WEB/src/features/authentication/components/auth-landing/auth-landing.tsx` (panel), `WEB/src/features/authentication/components/auth-landing/auth-drawer-body.tsx` (`DrawerShell`, `AutoHeight`).
- **Notes:** The current panel is 400 px wide with 32 px side padding and 16 px corner radius; all three change.

### PAG-25 — Auth form content

- **Values:**
  - Heading: 20 px / 400, line height 1.5, `gray-12`, centred. Wording is unchanged ("Welcome back", "Create your account", "Sign in with password", "Welcome", "Reset your password", "Enter your code", "What should we call you?", and the method-step tagline). 32 px below the heading to the first content.
    - With a subtitle: the subtitle is 14 px / 400 `gray-11`, centred, 6 px under the heading; then 32 px to the content.
  - Fields:
    - Label: 14 px / 500 `gray-12`.
    - 4 px gap, then a PRM input at default size (36 px), full width.
    - 16 px between fields.
    - Field messages: 12 px in the danger text step, 4 px under the input.
    - The password field keeps AP's show/hide eye button: ghost, 28 px, inside the right edge.
  - "Forgot your password?" (existing key): stays at the right end of the password label row. 12 px / 500 `accent-9`; hover `accent-10` with underline.
  - Primary submit ("Sign in", "Sign up", "Continue", "Send reset link"): PRM primary, large (36 px), centred, sized to its label (minimum 96 px). 32 px above it, measured from the last field; 16 px below it.
  - AP's email field with the inline arrow button (method step): one PRM input, 36 px tall, with a 16 px mail icon 12 px from the left. The arrow button sits inside its right edge, 4 px from the top, right and bottom: a 28 px solid primary icon button.
  - Third-party buttons (Google, SAML and others; wording unchanged): PRM subtle, 36 px, full width, radius 6, 14 px / 500, with an 18 px provider logo 8 px before the label. 12 px between them.
  - "or" separator: 12 px `gray-10`, centred, with 1 px `gray-6` lines on both sides and 16 px above and below.
  - Secondary links ("Use password", "Use SSO"): 12 px `gray-10`, `gray-12` on hover, centred, 20 px above, with a `gray-8` dot between them.
  - Mode switch line ("Don't have an account?" / "Already have an account?"): 14 px `gray-11`, centred, 24 px above. The action ("Sign up" / "Sign in") is 14 px / 500 `accent-9`; hover `accent-10` with underline.
  - Work-email hint and the email error strip (AP): keep their structure. Text is 12 px; tints come from the accent and danger ramps.
  - Legal note: 12 px `gray-10`, centred, line height 1.5. 24 px top margin, with a 1 px `gray-6` hairline above it and 16 px padding between the hairline and the text. Its links are underlined `gray-11`, `gray-12` on hover.
  - Turnstile: below the step content, centred, 16 px above it. The widget follows the app theme as today.
  - Test ids stay on the same elements:
    - Sign-in: `sign-in-email`, `sign-in-password`, `sign-in-button`.
    - Sign-up: `sign-up-first-name`, `sign-up-last-name`, `sign-up-email`, `sign-up-password`, `sign-up-button`.
    - Auth flow: `auth-use-password`, `auth-switch-mode`, `auth-email`, `auth-continue`, `auth-full-name`, `auth-name-continue`, `auth-code`.
- **States:** PRM input, button and link states. Loading buttons per PRM.
- **Light/Dark:** Per the role table; inputs per PRM (dark input fill #171717).
- **Motion:** PRM.
- **AP target file(s):** `WEB/src/features/authentication/components/sign-in-form.tsx`, `WEB/src/features/authentication/components/sign-up-form.tsx`, `WEB/src/features/authentication/components/third-party-logins.tsx`, `WEB/src/features/authentication/components/auth-landing/auth-drawer-body.tsx` (`Heading`, `ModeSwitch`, `LegalNote`, `EmailStep`, `NameStep`, `ResetStep`, `BackLink`), `WEB/src/features/authentication/components/auth-landing/turnstile-widget.tsx`.
- **Notes:** The reference centres a label-sized primary button; this spec follows it. Third-party buttons stay full width because they form a stack of choices.

### PAG-26 — Auth steps without a reference counterpart

- **Values:** These AP steps have no reference counterpart. They take the PAG-25 typography and spacing inside the PAG-24 card:
  - Email-code step: AP's one-time-code slots become PRM input-styled slots: 36 px tall, 40 px wide, radius 6, 8 px apart, 16 px / 500 digits. The resend line is 12 px `gray-10`, `gray-12` on hover; the countdown text is unchanged.
  - Verified flash: AP's 64 px round tile and check icon stay. The tile uses `accent-3` and the icon `accent-11`, so both are now orange.
  - Name step: a single field and a "Continue" primary (PAG-25).
  - SSO step and the back link: the back link is 12 px `gray-10` with a 14 px arrow, centred, 16 px above the heading.
- **States:** Per AP.
- **Light/Dark:** Per the role table.
- **Motion:** AP's step cross-fade (PAG-24).
- **AP target file(s):** `WEB/src/features/authentication/components/auth-landing/auth-drawer-body.tsx` (`CodeStep`, `VerifiedFlash`, `NameStep`, `BackLink`), `WEB/src/features/authentication/components/saml-login-form.tsx`, `WEB/src/components/ui/input-otp.tsx`.
- **Notes:** —

### PAG-27 — Forgot password, reset password and verify email pages

- **Values:** Same shell and card as PAG-23 and PAG-24.
  - Forgot password:
    - AP's reset form, restyled to the PAG-24 card.
    - Heading "Reset Password" or "Check Your Inbox" (existing keys) per PAG-25.
    - The email field.
    - The "Send Password Reset Link" primary, centred.
    - "Back to sign in" (existing key), 14 px `accent-9`, centred, 16 px below the button.
  - Reset password: the same card with AP's change-password fields.
  - Verify email: the same card with AP's 48 px status icon, 14 px text and the 24 px spinner.
- **States:** Per AP (sent, verifying, failed).
- **Light/Dark:** Per the role table.
- **Motion:** None.
- **AP target file(s):** `WEB/src/app/routes/forget-password/index.tsx`, `WEB/src/features/authentication/components/reset-password-form.tsx`, `WEB/src/features/authentication/components/change-password.tsx`, `WEB/src/features/authentication/components/verify-email.tsx`.
- **Notes:** These pages use a heavy drop-shadow card with a small radius today; both change to PAG-24.
