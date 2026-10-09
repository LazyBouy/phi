# 03 — App shell (SHL)

Scope: the left sidebar, the dashboard page header and tabs, the builder header, and the frame that holds them. Page bodies are in `04-pages.md` (PAG). Primitive look (buttons, inputs, menus, tooltips, switches, badges) comes from `02-primitives.md` (PRM); colour, type, shadow and motion values come from `01-tokens.md` (TOK).

Facts only. Every value below is a measurement or a behaviour; nothing here is to be copied from anywhere. AP keeps its own navigation items, its own wording (existing i18n keys) and its white-label logos and product name.

Path prefix: `WEB` = `iphi-flow/activepieces/packages/web`.

## Colour roles used in this file

TOK is authoritative. Each requirement names a role and an indicative AP token. If TOK assigns a different step to a role, use TOK's step for that role and keep the role.

| Role | Indicative AP token | Light | Dark |
|---|---|---|---|
| Page background | `gray-1` | #fafafa | #171717 |
| Surface (sidebar, headers, cards, menus) | `panel` | #ffffff | #262626 |
| Canvas | `gray-2` | #f5f5f5 | #171717 |
| Hover fill, active nav item, table header | `gray-3` | #f5f5f5 | #2b2b2b |
| Track fill, pressed fill | `gray-4` | #e5e5e5 | #323232 |
| Hairline border and divider (black 10% / white 15% equivalent) | `gray-6` | #e5e5e5 | about #3a3a3a on page, #474747 on surface |
| Control border, resize indicator | `gray-7` | about #e0e0e0 | #444444 |
| Strong border | `gray-8` | #bbbbbb | #737373 |
| Tertiary text, idle icons | `gray-10` | #999999 | #bbbbbb |
| Secondary text, default icons | `gray-11` | #444444 | #e5e5e5 |
| Primary text | `gray-12` | #262626 | #ffffff |
| Accent solid; accent text (active tab, links) | `accent-9` | #ff6900 | #ff6900 |
| Accent hover | `accent-10` | #f54900 | #f54900 |
| Accent pressed | `accent-11` | #ca3500 | #ca3500 |
| Status dots | `success-9`, `warning-9`, `danger-9` | per TOK | per TOK |
| Focus ring | TOK focus (violet) | per TOK | per TOK |

Type: Inter; sizes in px; weights 400 / 500 / 600 only.

---

### SHL-01 — Shell frame

- **Values:** Two columns. The sidebar (SHL-02) is on the left, full viewport height. The content column fills the rest of the width and holds the page (or the builder). The content column has no gutter and no inset card: remove the 6 px (builder) and 8–12 px (dashboard, platform admin) gutters, the 12 px-radius content card, its border and its panel shadow. The page background shows directly behind dashboard content. The content element keeps the id `dashboard-content-container` and stays position-relative, because the route loading bar is portalled into it.
- **States:** Embedded (rail hidden by AP's embed flags): the content column takes the full width and has no left border. Platform admin: the platform sidebar (SHL-15) takes the sidebar's place.
- **Light/Dark:** Page background `gray-1`.
- **Motion:** None of its own. The sidebar width animation (SHL-02) reflows the content column.
- **AP target file(s):** `WEB/src/app/components/project-layout/index.tsx`, `WEB/src/app/components/platform-layout.tsx`, `WEB/src/app/components/builder-layout/index.tsx`, `WEB/src/components/custom/route-loading-bar.tsx` (consumer of the id; no change).
- **Notes:** Keep the global-search provider, the sidebar provider, the credits-usage alert and the manage-plan dialog where they are. Only the frame styling goes.

### SHL-02 — Sidebar container

- **Values:**
  - Collapsed width 42 px (41 px of content plus a 1 px right border).
  - Expanded width defaults to 200 px. The user can resize it from 200 to 500 px; the width snaps to multiples of 8 px while dragging (SHL-03).
  - The expanded width is remembered per browser in a new localStorage key (for example `primary-rail-width`). Read and write it inside try/catch; clamp on read to 200–500; fall back to 200. The collapsed flag keeps the existing key `primary-rail-collapsed`.
  - Background is the surface colour. Right edge: 1 px `gray-6` border. No vertical padding on the container (AP's current 12 px top and bottom padding goes).
  - Vertical stack: header (SHL-04 / SHL-05), a scrollable middle (SHL-08, SHL-09), the usage card (SHL-10, expanded only), the bottom block (SHL-11) pinned to the bottom.
  - The middle scrolls on its own. In the expanded state, when its content overflows, a 1 px `gray-6` line appears along its bottom edge; once it is scrolled away from the top, a 1 px `gray-6` line also appears along its top edge.
- **States:** Expanded; collapsed (SHL-13); resizing (width animation off); held collapsed by route (AP's existing agent-route rule, unchanged); hidden when embedded (unchanged).
- **Light/Dark:** Surface #ffffff / #262626. Border `gray-6`.
- **Motion:** Width animates over 200 ms with the ease-out curve (0.215, 0.61, 0.355, 1). No animation while the user drags the edge. No animation under reduced motion.
- **AP target file(s):** `WEB/src/app/components/primary-rail/index.tsx` (`PrimaryRail`), `WEB/src/features/workspace/lib/rail-collapsed.ts`.
- **Notes:**
  - Today a click anywhere on the collapsed rail opens it, with an east-west resize cursor and a hover title. Remove that. The rail now expands through the toggle button (SHL-05), the keyboard (SHL-14) or an edge drag (SHL-03).
  - The approved plan says the sidebar background is the lightest grey. The reference renders it white (verified in the running reference and its source). Use the surface colour.
  - Current AP widths are 248 px open and 56 px closed; both change.

### SHL-03 — Sidebar resize handle

- **Values:**
  - A 4 px-wide invisible hit strip, full height, centred on the sidebar's right border. Cursor: column resize. At the minimum width the cursor becomes east-resize; at the maximum it becomes west-resize.
  - On hover and during a drag, a 6 px-wide `gray-7` bar shows centred on the border, full height.
  - Dragging sets the width, snapped to 8 px steps and clamped to 200–500 px. The width is saved when the drag ends.
  - Collapse by drag: while dragging an expanded sidebar, if the pointer goes left of x = 100 px (viewport), the sidebar collapses. Expand by drag: while dragging the collapsed sidebar's edge, if the pointer goes right of x = 100 px, the sidebar expands and the drag continues as a resize.
  - During a drag, embedded iframes ignore the pointer and text selection is suppressed, so the drag is not lost.
- **States:** Idle (invisible), hover (bar visible), dragging (bar visible, width animation off).
- **Light/Dark:** Bar `gray-7` (about #e0e0e0 / #444444).
- **Motion:** The bar appears and disappears instantly.
- **AP target file(s):** `WEB/src/app/components/primary-rail/index.tsx`.
- **Notes:** None of AP's existing components provide this; build it inside the rail.

### SHL-04 — Sidebar header row (expanded)

- **Values:**
  - One row, padding 8 px top and bottom and 6 px left and right, items centred vertically, gap 4 px. Row height 44 px.
  - Left block (takes the remaining width, may shrink):
    - The platform icon logo from branding (`logoIconUrl`), 20 × 20 px, linking to `/`, with the website name as its tooltip.
    - 6 px gap, then the website name from branding, 14 px / 500, `gray-12`, single line with ellipsis (tooltip when truncated).
    - On Cloud, when not embedded, AP's platform switcher replaces the name: a 28 px-tall ghost trigger, radius 4, platform name 14 px / 500, then a 12 px up-down chevron icon in `gray-10`; hover fill `gray-3`.
  - Right block (no shrink): three ghost icon buttons, each 28 × 28 px, radius 4, with 16 px icons in `gray-11`, in this order:
    1. Create (plus icon), see SHL-06.
    2. Search (magnifier icon), opens AP's global search (same action as today).
    3. Collapse (panel-left icon), collapses the sidebar.
  - Tooltips appear below the buttons after about 500 ms, with the label and a shortcut chip (PRM tooltip): "Search" with the Ctrl K / ⌘ K chip; "Close sidebar" with the [ chip. Labels use AP's existing keys.
- **States:** Button hover: fill `gray-3`, icon `gray-12`. Pressed: fill `gray-4`. Focus-visible: PRM focus ring. Create is hidden when SHL-06 has no item to offer.
- **Light/Dark:** Surface background; text and icons per the role table.
- **Motion:** None.
- **AP target file(s):** `WEB/src/app/components/primary-rail/index.tsx` (`RailHeader`), `WEB/src/features/projects` (`PlatformSwitcher`).
- **Notes:** The logo and name are always the platform's white-label branding. Never use the reference product's mark, name or logo colour.

### SHL-05 — Sidebar header (collapsed)

- **Values:** The logo and name are hidden. The three buttons from SHL-04 stack vertically and are centred: create, search, expand. Padding 8 px top and bottom, 6 px left and right; 4 px gap between the buttons. The block is 108 px tall and ends with a 1 px `gray-6` bottom border across the full sidebar width. The third button uses the same panel-left icon with the label "Open sidebar".
- **States:** As SHL-04. Tooltips open to the right.
- **Light/Dark:** As SHL-04.
- **Motion:** None.
- **AP target file(s):** `WEB/src/app/components/primary-rail/index.tsx` (`RailHeader`, collapsed branch).
- **Notes:** In the collapsed state AP currently shows the logo as the open button; that logo button goes.

### SHL-06 — Sidebar create menu

- **Values:**
  - The create button opens a PRM dropdown. It sits below the button, aligned to its start, when the sidebar is expanded, and to the right of the button when collapsed. Minimum width 200 px.
  - Items, in this order. Each one shows only when a current project exists and the user passes the permission check AP already applies to that action:
    1. New Flow
    2. New Table (hidden when embedding hides tables)
    3. New Agent (only when agents are visible)
    4. A separator, then New Project (only when AP's existing create-project condition holds: the team-project limit is not 0 and the user is a platform admin)
  - Each item runs AP's existing action:
    - New Flow behaves as Create New → New Flow on the automations page: it creates the flow in the current project root and opens the builder with the name in edit mode.
    - New Table and New Agent behave as their Create New counterparts.
    - New Project opens AP's existing create-project dialog.
  - Items have 16 px leading icons. The icons and wording are the ones AP's create menu already uses.
- **States:** A pending action shows a spinner and AP's "Creating..." text in place of the item's icon and label. Items without permission are not shown. When no item is available, or the app is embedded, the create button is hidden.
- **Light/Dark:** PRM dropdown.
- **Motion:** PRM dropdown open/close.
- **AP target file(s):** `WEB/src/app/components/primary-rail/index.tsx`, `WEB/src/features/automations/components/create-new-menu.tsx` (reuse its items), `WEB/src/features/automations/hooks/use-automations-mutations.ts` (flow/table/agent creation), `WEB/src/features/projects` (`CreateProjectButton`).
- **Notes:** AP has no sidebar create button today. This adds a new entry point to existing actions only. The menu adds no new actions and no new copy.

### SHL-07 — Navigation item (base look)

- **Values:**
  - Row: minimum height 32 px, padding 4 px, gap 4 px between the icon box and the label, radius 4 px. The item spans the list width; lists have 6 px side padding, so items are the sidebar width minus 12 px. Consecutive items are 2 px apart.
  - Icon box: 24 × 24 px with the icon centred, 16 px, `gray-11`.
  - Label: 14 px / 400, line height 18 px, `gray-12`, single line with ellipsis. Wrap it in AP's `TextWithTooltip` so truncated labels show a tooltip.
  - Optional trailing chevron-right (16 px, `gray-10`) on items that open a popover.
  - Optional count badge: PRM badge, 20 px pill.
  - Optional notification dot: 4 px circle in `danger-9` at the icon box's top-right corner.
- **States:**
  - Rest: transparent.
  - Hover: fill `gray-3`; label and icon `gray-12`.
  - Active (current route): fill `gray-3`, icon `gray-12`. The label weight stays 400; the active icon is no longer tinted with the accent.
  - Focus-visible: 1 px inset outline in the focus colour, no offset.
  - Disabled: label `gray-10`, not-allowed cursor.
  - Collapsed: label and trailing parts hidden, icon box centred, tooltip to the right (SHL-13).
- **Light/Dark:** Hover and active fill #f5f5f5 / #2b2b2b. Label #262626 / #ffffff. Icon #444444 / #e5e5e5.
- **Motion:** None; fills change instantly.
- **AP target file(s):** `WEB/src/app/components/primary-rail/index.tsx` (`RailNavButton`, `ProjectRow`).
- **Notes:** This replaces AP's fully rounded pills (40 px nav rows, 36 px project rows) and the accent-tinted active icon.

### SHL-08 — Primary navigation group

- **Values:** It sits directly below the header. List padding is 8 px top, 6 px sides, 8 px bottom. It holds AP's own items in AP's order and under AP's conditions, each rendered as SHL-07:

| # | Label (AP key) | Icon (lucide, unchanged) | Shown when (unchanged) | Active when (unchanged) |
|---|---|---|---|---|
| 1 | Chat | square-pen | the platform plan has chat enabled | path starts with `/chat` |
| 2 | MCP | unplug | MCP is reachable for the user | path starts with `/mcp-server` |
| 3 | Agents | bot | the agents nav is visible | path starts with `/agents` |
| 4 | Explore | compass | always | path starts with `/templates` |
| 5 | Impact | chart-line | always | path starts with `/impact` |

- **States:** Per SHL-07. Click side effects are unchanged: Chat fires the new-chat event; Explore sends the explore telemetry event.
- **Light/Dark:** Per SHL-07.
- **Motion:** None.
- **AP target file(s):** `WEB/src/app/components/primary-rail/index.tsx` (`PrimaryRail`).
- **Notes:** Collapsed, the group ends with a 1 px `gray-6` bottom border across the full sidebar width (SHL-13). Expanded, there is no separator; the Projects section header follows 4 px below.

### SHL-09 — Section group: Projects

- **Values:**
  - Section header (expanded only):
    - A full-width button, inset 6 px from both sides, 4 px top margin, padding 4 px 6 px, radius 4 px, gap 4 px.
    - Label "Projects" (existing key), 12 px / 500, `gray-10`, in sentence case. This replaces the 11 px uppercase, letter-spaced label.
    - A chevron-down icon (14 px, `gray-10`) right after the label. Clicking the header collapses or expands the project list; when collapsed, the chevron turns −90°.
  - Header actions, pushed to the right end of the header:
    - Create project (plus), only when AP allows it today.
    - Sort (sliders icon).
    - Both are 20 × 20 px ghost icon buttons with 14 px `gray-10` icons. They show while the header is hovered or holds focus, and while their menu is open; otherwise they are hidden but stay in the DOM for keyboard users.
  - Rows: list padding 8 px top and bottom, 6 px sides. Each project is an SHL-07 item:
    - The icon box holds AP's project badge, 18 × 18 px, radius 4. A team project shows a colour tile with its initial (10 px / 600, palette colours unchanged). A personal project shows a 12 px lock icon in `gray-10`.
    - The label is the project name. A row is active when the path includes the project id.
    - Order is unchanged: personal first, then team projects, using the chosen sort (Recently added / Recently used / Alphabetical).
  - Sort menu: a PRM dropdown on the right side, 192 px wide. The chosen option has a trailing check in `accent-9`.
- **States:**
  - Header hover: fill `gray-3`; label and chevron `gray-12`. Header focus-visible: 1 px inset focus outline.
  - The section's collapsed or expanded state is stored in a new localStorage key (try/catch).
  - Collapsed sidebar: the header is hidden and rows are icon-only with right tooltips; the list still scrolls.
- **Light/Dark:** Per the role table. The project palette colours are unchanged.
- **Motion:** The chevron rotates over 150 ms, ease. Row reorder keeps AP's layout animation (400 ms, curve (0.16, 1, 0.3, 1)). Both are off under reduced motion.
- **AP target file(s):** `WEB/src/app/components/primary-rail/index.tsx` (`RailPinnedProjects`, `ProjectRow`, `PinnedSortMenu`).
- **Notes:** The thin divider line above the projects list goes.

### SHL-10 — Usage limits card

- **Values:** Expanded only. It sits between the scrolling middle and the bottom block, with 6 px side margins and 6 px below. It is restyled as a compact PRM card: radius 8, 1 px `gray-6` border, surface background, padding 12 px, 12 px text. Its content is unchanged.
- **States:** Hidden when the sidebar is collapsed, and whenever AP hides it today.
- **Light/Dark:** PRM card.
- **Motion:** None.
- **AP target file(s):** `WEB/src/features/billing` (`SidebarUsageLimits`), `WEB/src/app/components/primary-rail/index.tsx`.
- **Notes:** —

### SHL-11 — Sidebar bottom block

- **Values:** Pinned to the bottom, padding 6 px. Items are SHL-07 rows, 2 px apart, in this order:

| # | Item | Icon | Shown when | Action |
|---|---|---|---|---|
| 1 | Platform Admin | shield | the user is a platform admin and the app is not embedded (unchanged) | goes to `/platform/projects`; active when the path starts with `/platform` |
| 2 | Help & Feedback | circle-help | not embedded | opens the help popover (SHL-12); trailing chevron-right |
| 3 | Settings | settings (gear) | always | opens AP's Account Settings dialog (same action as today's gear button) |
| 4 | Account | the user's avatar, 20 px round, as the icon | a user is signed in | opens the account popover (SHL-12); label is the user's full name; trailing chevron-right |

- **States:** Per SHL-07. Collapsed, the block gets a 1 px `gray-6` top border across the full width; items are icon-only with right tooltips ("Account" for the avatar).
- **Light/Dark:** Per SHL-07.
- **Motion:** None.
- **AP target file(s):** `WEB/src/app/components/primary-rail/index.tsx` (`RailPlatformAdminButton`, `RailAccountRow`).
- **Notes:**
  - The divider line above Platform Admin goes, and so does the standalone gear icon button; its action becomes the Settings row.
  - Help & Feedback moves out of the account menu into its own row. Its entries are unchanged.
  - The reference has no account row; AP keeps one because it has no other place for the user menu.

### SHL-12 — Bottom-block popovers

- **Values:**
  - Popovers open to the right of the sidebar, aligned with the bottom edge of their trigger, 12 px from the sidebar edge.
  - Surface per the PRM popover: radius 8, medium shadow plus a 1 px outline ring, padding 4 px. Minimum width 260 px.
  - Rows are PRM dropdown items: 32 px, 14 px text, 16 px leading icon in `gray-11`.
  - Help popover: Documentation, Changelog, and Community Support (only when the community flag is on). Entries and links are unchanged.
  - Account popover, in this order:
    1. A header: 32 px avatar, then the name (14 px / 500, `gray-12`) above the email (12 px, `gray-10`).
    2. A separator.
    3. Account Settings.
    4. A separator.
    5. Log out, last.
- **States:** PRM item states. The trigger row shows the active fill while its popover is open.
- **Light/Dark:** PRM popover.
- **Motion:** PRM popover open and close (200 ms).
- **AP target file(s):** `WEB/src/app/components/primary-rail/index.tsx`, `WEB/src/app/components/help-and-feedback.tsx` (render as popover content instead of a submenu).
- **Notes:** The account popover no longer contains the Help & Feedback submenu.

### SHL-13 — Collapsed sidebar behaviour

- **Values:**
  - Width 42 px. The header is stacked (SHL-05).
  - Fixed 1 px `gray-6` separators: under the header block, under the primary navigation group, and above the bottom block.
  - Every item is icon-only: 32 px tall and the full inner width (sidebar width minus 6 px on each side), with the icon box centred.
  - Hidden while collapsed: section headers, the usage card, labels, trailing chevrons and badges. A count badge collapses into the 4 px notification dot.
  - Account shows only the avatar.
  - Tooltips open to the right after about 500 ms and show the item label (PRM tooltip).
  - Popovers and menus still open to the right.
- **States:** Hover, active and focus as SHL-07. There is no hover-to-expand overlay.
- **Light/Dark:** Per SHL-07.
- **Motion:** Width per SHL-02. Labels are not cross-faded; they are clipped by the width change.
- **AP target file(s):** `WEB/src/app/components/primary-rail/index.tsx`.
- **Notes:** Routes that hold the rail closed (agent pages) are unchanged.

### SHL-14 — Sidebar keyboard

- **Values:**
  - The [ key toggles collapse and expand. It works only when focus is not in an editable element (input, textarea, content-editable, code editor) and no dialog is open.
  - Ctrl+K / ⌘+K opens global search (existing behaviour).
  - Tooltips show both shortcuts as key chips (PRM tooltip).
- **States:** —
- **Light/Dark:** —
- **Motion:** Toggling uses the SHL-02 width animation.
- **AP target file(s):** `WEB/src/app/components/primary-rail/index.tsx`, `WEB/src/app/components/global-search/global-search-context.tsx` (unchanged).
- **Notes:** [ is not used by the planned canvas shortcuts (1, 0, +, −, N, D, Shift+S, Shift+Alt+T, Enter).

### SHL-15 — Platform admin sidebar

- **Values:**
  - Fixed width 256 px (AP's current width; not resizable). Surface background, 1 px `gray-6` right border, full height, scrolls on overflow.
  - Top row "Back to app" (existing key): padding 12 px, gap 6 px, a 16 px chevron-left icon, label 14 px / 500 `gray-12`.
  - Groups (Platform, Catalogue, Security, Developers, Operations, Account; unchanged content and conditions):
    - Group label row: 12 px / 500 `gray-10`, padding 4 px 6 px, 12 px top margin (4 px for the first group). Group labels do not collapse.
    - Items: SHL-07 rows inside 6 px side padding. Items with sub-items show a trailing chevron (right when closed, down when open).
    - Sub-items: 32 px rows without icons, indented 28 px so their labels line up with the parent label.
    - Plan-locked items keep AP's trailing 14 px crown icon in `gray-10`.
  - Bottom: the user row (avatar and name, opening AP's user menu) styled as the SHL-11 Account row.
- **States:**
  - "Back to app" hover: label and icon `accent-9`.
  - Items and sub-items per SHL-07; the active sub-item has the `gray-3` fill.
- **Light/Dark:** Per the role table.
- **Motion:** Sub-item lists open and close instantly.
- **AP target file(s):** `WEB/src/app/components/sidebar/platform/index.tsx`, `WEB/src/app/components/sidebar/ap-sidebar-item.tsx`, `WEB/src/app/components/sidebar/sidebar-user.tsx`, `WEB/src/app/components/platform-layout.tsx`.
- **Notes:** The content frame follows SHL-01 (no inset card).

### SHL-16 — Dashboard page header

- **Values:**
  - The header lives inside the page container (PAG-01) and starts at its 24 px top padding. Minimum height 64 px. Two columns, both top-aligned: a title block on the left and actions on the right, at least 16 px apart.
  - Title: 20 px / 600, line height 1.25, `gray-12`, ellipsis with tooltip.
    - On project pages the title is AP's project display: a 20 px project avatar or icon, an 8 px gap, then the name.
    - A personal project adds AP's 16 px lock icon in `gray-10` (with its existing tooltip), 4 px after the name.
  - Subtitle: shown only when the page passes a description (AP's existing prop). 14 px / 400, line height 1.35, `gray-10`, directly under the title.
  - Right actions: a row with 8 px gaps. AP's existing items in their existing order and conditions, restyled as PRM ghost medium buttons (32 px):
    1. Members count: users icon 16 px plus the count, 14 px / 500.
    2. "Add Members": icon plus label.
    3. Project settings: icon-only, 32 × 32 px.
    - Then a 12 px gap and the primary create split button (SHL-17, project pages only).
  - Background is the page background (no fill of its own, no bottom border). The header stays sticky at the top of the scroll area so content passes under it.
  - Pages that use the generic header (Explore, Impact, platform admin pages and others) follow the same title, subtitle and right-slot rules. Their string titles change from 16 px / 600 to 20 px / 600.
- **States:** Hidden where AP hides it today (no project, the routes in AP's no-header list, platform pages for the project header, the embed flag that hides page headers).
- **Light/Dark:** Title #262626 / #ffffff; subtitle #999999 / #bbbbbb.
- **Motion:** None.
- **AP target file(s):** `WEB/src/components/custom/page-header.tsx`, `WEB/src/app/components/dashboard-page-header.tsx`, `WEB/src/app/components/project-layout/project-dashboard-page-header.tsx`, `WEB/src/app/components/project-layout/project-dashboard-layout-header.tsx`.
- **Notes:**
  - Reference measurement at 1440 × 900 with the sidebar collapsed: the header block starts at y = 24 and the create button spans y = 24–56.
  - The builder header no longer follows this requirement; see SHL-19.

### SHL-17 — Primary create split button

- **Values:**
  - Two joined segments, both PRM solid primary, medium size: 32 px tall, solid `accent-9`, white text and icon, extra-small shadow. Outer corners radius 4; inner corners square.
  - Main segment: label "New Flow" (existing key), 14 px / 500, 12 px horizontal padding. It runs the same action as Create New → New Flow.
  - Chevron segment:
    - 32 × 32 px with a 16 px white chevron-down. A 1 px divider in black at 10% opacity runs along its left edge.
    - Its accessible name is "Create New" (existing key), given as visually hidden text inside the button, not only as an attribute.
    - It opens a PRM dropdown below the button, aligned to its end, 4 px away. The items are listed in PAG-11.
  - The control appears on every project tab (Automations, Runs, Connections, Variables, Releases, Pending approvals).
- **States:**
  - Hover, per segment independently: `accent-10`. Pressed: `accent-11`. While its menu is open, the chevron segment shows the pressed colour.
  - Focus-visible: PRM focus ring.
  - Disabled: 50% opacity, not-allowed cursor.
  - Loading (flow being created): a spinner replaces the main label; the segment keeps its width.
  - Permissions: without permission to write flows, the main segment is hidden and the chevron menu shows only the permitted items. With no permitted item, the whole control is hidden.
- **Light/Dark:** Same orange in both themes.
- **Motion:** PRM button: the loading swap fades over 200 ms with a 4 px rise.
- **AP target file(s):** `WEB/src/app/components/project-layout/project-dashboard-page-header.tsx` (right slot), `WEB/src/features/automations/components/create-new-menu.tsx` (menu content), `WEB/src/features/automations/components/automations-filters.tsx` (its Create New and Import buttons are removed, PAG-03).
- **Notes:**
  - The visually hidden "Create New" text keeps the existing e2e lookups working: they find a button whose text is "Create New", then a menu item "New Flow". Verify both in the e2e run.
  - Page-specific create buttons (New Connection, New variable, Create Release) stay in their page toolbars (PAG-14).

### SHL-18 — Project tabs row

- **Values:**
  - The row sits directly below the page header, 8 px down. Reference positions: tab labels occupy y = 96–120, the active indicator y = 124–126, and the next row (filters) starts at y = 132, so 6 px below the indicator.
  - Tabs are navigation links (anchor semantics). They are AP's tabs in AP's order, under AP's conditions: Automations, Runs, Connections, Variables, Releases (conditional), Pending approvals (conditional).
  - Tabs have no icons, and there is no vertical separator between Automations and the others.
  - Tab: label 14 px / 500, line height 20 px, `gray-11`; horizontal padding 16 px, so the first label is indented 16 px from the content edge. Below the label: 8 px, then a 2 px indicator.
  - Active tab: label `accent-9` and a 2 px `accent-9` indicator across the tab's full padded width.
  - There is no baseline rule under the whole row (AP's bottom border goes).
  - Pending approvals count: PRM badge, 20 px pill, solid `accent-9`, white 12 px / 500 text, 4 px after the label. A "Beta" tag, where present, is a PRM badge in the secondary (violet tint) variant, 20 px tall.
  - Overflow: the row scrolls horizontally with a hidden scrollbar. When it overflows, 10 px-wide arrow buttons appear at the ends.
- **States:**
  - Inactive hover: label `accent-9`.
  - Focus-visible: 1 px inset outline in the focus colour, radius 4.
  - Disabled: label `gray-10`, not-allowed cursor.
  - The row is hidden when the embed flag that hides side navigation is set (unchanged).
- **Light/Dark:** Labels #444444 / #e5e5e5; the active orange is the same in both themes.
- **Motion:** None.
- **AP target file(s):** `WEB/src/app/components/project-layout/project-dashboard-layout-header.tsx` (`AnimatedTab`, the tabs row), `WEB/src/components/ui/tabs.tsx` (PRM tabs, underline style).
- **Notes:**
  - AP's animated tab icons are dropped.
  - The e2e page object has a helper that looks for a link named "Automations". Link semantics satisfy it.

### SHL-19 — Builder header frame

- **Values:**
  - Height 64 px plus a 1 px `gray-6` bottom border (65 px in total). Surface background. Padding 12 px top and bottom, 20 px left and right.
  - Three zones:
    - Left: flexible, minimum width 0, see SHL-20.
    - Centre: the segmented control, positioned independently of the side zones, see SHL-21.
    - Right: actions, no shrink, see SHL-22 to SHL-24.
    - Keep at least 20 px between the left and right zones.
  - The header stacks above the canvas and the right panel, and below dialogs, menus and toasts.
  - Set the builder header height constant from 60 to 64.
  - Fix the existing bug: the wrapper's height is built from a template string with a stray dollar sign. It produces the value "$60px", which browsers reject, so the header height has been driven by its content. Give the wrapper a real 64 px height.
- **States:** Embedded: AP's embed flags decide which parts render (SHL-20, SHL-22).
- **Light/Dark:** Surface #ffffff / #262626; border #e5e5e5 / #323232.
- **Motion:** None.
- **AP target file(s):** `WEB/src/app/builder/builder-header/builder-header.tsx`, `WEB/src/app/builder/flow-canvas/utils/consts.ts`, `WEB/src/app/builder/index.tsx` (the header wrapper).
- **Notes:** The header no longer needs the generic page header's 16 px padding and sticky behaviour.

### SHL-20 — Builder header, left: breadcrumb, name and menu

- **Values:** One row, items centred vertically, 14 px text, in this order:
  1. When embedded, AP's home button first (unchanged).
  2. Project crumb (hidden when the embed flag disables builder navigation): the project name, 14 px / 400, `gray-11`. Clicking it goes back to the automations list, keeping the flow's folder (AP's existing behaviour).
  3. Separator: a "/" glyph, 20 px / 400, `gray-7`, padding 6 px 4 px 4 px.
  4. Flow name (hidden when the embed flag hides it):
     - Inline-editable, 14 px / 400, `gray-12`, padding 6 px 4 px 4 px, maximum width 500 px, ellipsis.
     - It is read-only when the open version is not the latest (AP rule).
     - New flows open with the name in edit mode (AP's query-parameter behaviour). Enter commits; Escape cancels.
  5. AI badge: AP's created-by badge, shown only when the flow was created over MCP. A PRM outline badge, 20 px tall, 8 px after the name.
  6. More button: a ghost 32 × 32 px icon button with a 16 px horizontal ellipsis icon in `gray-11`, 4 px after the name or badge. It opens AP's existing flow actions menu (same items), below and aligned to the button's start. It replaces the 24 px chevron-down button.
- **States:**
  - Project crumb hover: `gray-12` and a pointer cursor.
  - Editable name hover: a text cursor and a 1 px `gray-6` inset outline, radius 4.
  - Editing: the name becomes a PRM small input (28 px) with the focus ring.
  - More button: PRM ghost states; it shows the pressed fill while its menu is open.
- **Light/Dark:** Per the role table.
- **Motion:** None.
- **AP target file(s):** `WEB/src/app/builder/builder-header/builder-header.tsx` (`titleContent`), `WEB/src/components/custom/editable-text.tsx`, `WEB/src/app/components/flow-actions-menu.tsx`, `WEB/src/components/ui/breadcrumb.tsx`, `WEB/src/features/flows/components/flow-created-by-badge.tsx`.
- **Notes:** The created-by badge moves from the right group to sit beside the name.

### SHL-21 — Builder header, centre: Editor | Runs segmented control

- **Values:**
  - Two segments labelled "Editor" and "Runs" (existing keys). This is the PRM segmented control at medium size.
  - Track: 32 px tall, 2 px padding, radius 6 px, fill `gray-4`, 2 px gap between segments.
  - Segment: 28 px tall, horizontal padding 12 px, radius 4 px, 12 px / 500, line height 1. Segments size to their labels.
  - Position: centred horizontally on the header. Vertically, the track is centred on the header's bottom border line, so its lower half (16 px) overlaps the top of the canvas. It stays centred whatever the side zones contain, and stacks above canvas content and canvas overlays.
- **States:**
  - Selected segment: surface fill, `gray-12` text. Unselected: transparent, `gray-11` text.
  - Unselected hover: fill `gray-3`, text `gray-12`.
  - Keyboard: radio-group semantics; arrow keys move the selection. Focus-visible: PRM focus ring with a 2 px offset.
  - Selection mapping (AP):
    - "Runs" is selected when the right sidebar shows the runs list, or a run is open (the run-detail route, or a run in builder state).
    - "Editor" is selected otherwise.
  - Actions:
    - Choosing Runs opens AP's runs list panel; this is the same action as today's "Runs" header button.
    - Choosing Editor closes the runs list. If a run is open, it leaves the run the same way AP's "Edit flow" control does: on the run route it goes to the flow; otherwise it switches to the draft.
  - The control renders only when the user has the permission AP checks for the Runs button today.
- **Light/Dark:** Track #e5e5e5 / #323232. Selected segment #ffffff / #171717. Text per the role table.
- **Motion:** None; the selection changes instantly.
- **AP target file(s):** `WEB/src/app/builder/builder-header/builder-header.tsx`; new primitive `WEB/src/components/ui/segmented-control.tsx` (PRM); builder state (right-sidebar setter and `RightSideBarType`); `WEB/src/app/builder/builder-header/flow-status/view-draft-or-edit-flow-button.tsx` (reuse its exit-run logic).
- **Notes:** The ghost "Runs" button in the right group is removed. Canvas overlays at the top centre must start at least 24 px below the header border (SHL-25).

### SHL-22 — Builder header, right: support and collaborators

- **Values:** A row, items centred, gap 8 px, ending at the 20 px right padding. Order:
  1. Support: only when the community flag is on, unchanged. A PRM ghost medium button (32 px): circle-help icon 16 px, then "Support" 14 px / 500 `gray-11`. Same action.
  2. Collaborators: AP's active-users widget, hidden by its embed flag as today.
     - Avatars 24 px, overlapping by 6 px, each with a 2 px ring in the surface colour.
     - Overflow: a "+N" circle, 24 px, surface fill, 1 px `gray-6` border, 10 px / 600 `gray-11`, with AP's existing list on hover. The maximum number of visible avatars is unchanged.
  3. The publish split button (SHL-23).
  4. The on/off toggle (SHL-24).
- **States:** PRM ghost states.
- **Light/Dark:** Per the role table.
- **Motion:** None.
- **AP target file(s):** `WEB/src/app/builder/builder-header/builder-header.tsx` (`rightContent`), `WEB/src/components/custom/active-users-widget.tsx`.
- **Notes:** —

### SHL-23 — Publish split button with status dot

- **Values:**
  - Container: 1 px `gray-6` border, radius 4, no fill. Inner height 32 px (34 px with the border).
  - Main segment:
    - PRM ghost, 32 px tall, horizontal padding 12 px, 14 px / 500, `gray-12`.
    - Content, in order: an optional 8 px status dot followed by an 8 px gap; an optional 12 px spinner followed by an 8 px gap; the label.
    - The dot and spinner are hidden from assistive technology. When the label is "Publish", the button's accessible name must be exactly "Publish". Keep the name attribute AP sets for tests.
  - Chevron segment:
    - PRM ghost, 32 × 32 px, 16 px chevron-down in `gray-11`, with a 1 px `gray-6` divider along its left edge. The divider hides while the main segment is hovered.
    - Its accessible name is "More" (existing key). It must not contain the word "Publish".
    - It opens a PRM dropdown aligned to its end with:
      - "Discard changes": only when the open version is a draft and the flow has a published version; same action as today.
      - "Version History": opens AP's versions panel.
  - Main-segment tooltip: shows after about 300 ms, 15 px from the button, with the reason text from the table below.

  | AP state | Dot | Label | Main segment | Tooltip |
  |---|---|---|---|---|
  | Draft, never published, all steps valid | none | Publish, or Request approval when AP requires approval | enabled | — |
  | Draft, never published, incomplete steps | none | Publish | disabled | You have incomplete steps |
  | Draft, a published version exists, all steps valid | `warning-9` (unpublished changes) | Publish, or Request approval | enabled | You have unpublished changes |
  | Draft, a published version exists, incomplete steps | `danger-9` (issues) | Publish | disabled | You have incomplete steps |
  | Locked, and it is the published version | `success-9` (published) | Published, in `gray-10` | disabled | — |
  | Locked, not the published version (old version open) | — | control hidden | — | AP's viewing-old-version notice stays on the canvas |
  | Saving | none, spinner | Saving... | disabled | Saving... |
  | Publishing | none, spinner | Publishing... | disabled | — |
  | Discarding changes | none, spinner | Discarding changes... | disabled | — |
  | No permission to write the flow | dot as above | label as above | disabled | Permission Needed |
  | A run is open, or another editor holds the lock | — | control hidden | — | — |

  The AP inputs are: the version state (draft or locked), whether the flow has a published version and whether the open version is it, the version's validity, the saving, publishing and discarding flags, the approval requirement, the open run, the resource lock and the write permission.
- **States:**
  - Main segment: hover fill `gray-3`; pressed `gray-4`. Disabled: label `gray-10`, not-allowed cursor; the dot keeps its colour.
  - Chevron segment: PRM ghost states.
  - Focus: PRM focus ring.
- **Light/Dark:** Border #e5e5e5 / white 15%. Dot colours per TOK.
- **Motion:** PRM spinner. No transition on the dot.
- **AP target file(s):**
  - New header control in `WEB/src/app/builder/builder-header/` (inside `flow-status/` or beside it).
  - Logic moved from `WEB/src/app/builder/flow-canvas/widgets/publish-flow-reminder-widget.tsx`: publish, discard, the required-actions check and dialog, and the approval wording.
  - `WEB/src/app/builder/flow-canvas/widgets/builder-banner.tsx`: stop rendering the reminder.
  - `WEB/src/features/flows/components/flow-version-state-dot.tsx`: its role passes to the dot inside the button.
- **Notes:**
  - The reference uses a teal for "published" and a bright yellow for "unpublished changes". This spec maps them onto AP's success and warning ramps. If TOK defines a teal role, use it for the published dot.
  - The publish reminder banner on the canvas no longer exists, so there is exactly one "Publish" button on the page.
  - The flow approval banner stays on the canvas.

### SHL-24 — Flow on/off toggle in the header

- **Values:** It sits right of the publish control, 8 px away. It is AP's flow status toggle, restyled to the PRM small switch (track 32 × 16 px; on = green per PRM). When the flow is on, AP's trigger-type icon (bolt or timer, 16 px, `gray-11`) follows in a 24 px box. When loading, a 16 px spinner replaces the icon.
- **States:** Shown under AP's existing condition: the published version is open, or a draft of a published flow is open. Disabled states and tooltips are unchanged ("Flow is on", "Flow is off", "Please publish flow first", "Permission Needed"); tooltips open below.
- **Light/Dark:** PRM switch.
- **Motion:** PRM switch (knob slides over 200 ms).
- **AP target file(s):** `WEB/src/app/builder/builder-header/flow-status/index.tsx`, `WEB/src/features/flows/components/flow-status-toggle.tsx`.
- **Notes:** The separate draft/published dot that sat beside the toggle is removed; SHL-23 carries that information.

### SHL-25 — Builder layout: full-bleed canvas

- **Values:**
  - Under the header, the work area runs edge to edge: the canvas spans from the sidebar's right border to the window's right edge, or to the right panel. No gutter, no rounded card, no shadow.
  - The right panel (step settings, runs list, versions) is docked to the right, full height under the header. Surface background, 1 px `gray-6` left border, no radius. It keeps AP's resizable-panel behaviour, with a PRM resize handle.
  - Canvas overlays at the top centre (viewing-old-version notice, approval banner, run info, resource lock) start at least 24 px below the header border, so they clear the lower half of the segmented control. Their exact placement belongs to the canvas spec (CAN).
- **States:** Embedded: the same, without the sidebar. Read-only (run view, lock): the same frame.
- **Light/Dark:** Canvas `gray-2` (#f5f5f5 / #171717, per CAN); right panel uses the surface colour.
- **Motion:** None.
- **AP target file(s):** `WEB/src/app/components/builder-layout/index.tsx`, `WEB/src/app/builder/index.tsx`, `WEB/src/app/builder/flow-canvas/widgets/builder-banner.tsx`.
- **Notes:** The publish reminder no longer renders on the canvas (SHL-23).

### SHL-26 — White-label and embedding invariants

- **Values:**
  - Logos, the product name, the favicon and the page title always come from branding: the icon logo, the full logo and the website name.
  - Never show the reference product's name, mark or logo colour.
  - AP's embed flags keep their current effect on every shell part: rail hidden, page header hidden, side navigation hidden, builder navigation disabled, flow name hidden, active users hidden, folders hidden, tables hidden, import and export hidden, duplicate hidden.
  - All shell copy uses AP's existing i18n keys. The shell needs no new keys.
- **States:** —
- **Light/Dark:** —
- **Motion:** —
- **AP target file(s):** All files listed in this document.
- **Notes:** Platform colour overrides no longer apply to the UI (plan decision). Logos and names remain white-label.
