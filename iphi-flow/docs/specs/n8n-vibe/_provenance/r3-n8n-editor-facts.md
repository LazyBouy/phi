# r3 — n8n editor facts (provenance record)

Source tree: `iphi-flow/n8n/packages/frontend/editor-ui` (Vue 3), at n8n commit `55eb2ce442`.
Facts described in our own words. Colours: token families with ≈ hex (OKLCH → sRGB). Light theme unless noted.
EUI = `iphi-flow/n8n/packages/frontend/editor-ui/src`; DS = `iphi-flow/n8n/packages/frontend/@n8n/design-system/src`.

Effective radius values (legacy overrides win): base 4, lg 8, xl 12, sm 2, 2xs 6, 3xs 4, xs 8.
Spacing: 5xs 2, 4xs 4, 3xs 6, 2xs 8, xs 12, sm 16, md 20, lg 24, xl 32, 2xl 48, 3xl 64 px.
Font sizes: 3xs 10, 2xs 12, xs 13, sm 14, md 16, lg 18, xl 20 px. Font: Inter variable.
`node_modules` was absent, so canvas-library defaults (dot radius, selection rectangle colours, zoom step) are marked "library default".

## 0. Canvas-relevant colours

| Role | Light | Dark |
|---|---|---|
| Brand / primary | orange-500 #ff6900; hover #f54900 | same |
| Secondary (pinned, expression, focus) | purple-600 #7f22fe | — |
| Success | green-600 #00a63e | — |
| Danger | red-600 #e7000b | red-400 |
| Warning | gold-600 #b57617 | — |
| Canvas background | #f5f5f5 | #171717 |
| Grid dots | #999 | #444 |
| Canvas labels | #737373 on canvas colour at 85% alpha | — |
| Selection ring | hsla(220,47%,30%,0.1) | white 40% |
| Node fill | white | #262626 |
| Running border | primary | — |
| Pinned border | secondary | — |
| Foreground scale | neutral-200 / 250 / 500 / 150 | — |
| Text | neutral-900 / 700 / 500 | — |

Token sources: `DS/css/_primitives.scss`, `_tokens.scss`, `_tokens.legacy.scss`.

## 1. Canvas

Files: `EUI/features/workflows/canvas/components/Canvas.vue` (root), `WorkflowCanvas.vue` (background colour wrapper), `EUI/app/views/NodeView.vue` (page + overlay buttons), `EUI/app/css/plugins/_vueflow.scss` (library overrides), `.../canvas/components/elements/{nodes,edges,handles,buttons,background}/`.

- Library: Vue Flow core 1.48 + background, controls, minimap, node-resizer add-ons.
- Grid 16px; positions snap to 16×16. Background = library dot pattern, 16px gap, dot colour above; dot size library default.
- Read-only canvas: diagonal stripes, 20px tile rotated 135°, 10px stripes neutral-200 at 50%, follow pan/zoom.
- Zoom 0–4. On load fit view, padding 0.2, max zoom 1. Canvas fades 0→1 over 300ms ease when ready. First node starts at (176, 240). Container resize keeps the centre (`useViewportAutoAdjust.ts`).
- Wheel/trackpad pans. Space or Ctrl/Cmd: wheel zooms and left-drag pans. Middle-drag always pans. Left-drag on empty area always draws a selection rectangle. Mobile: drag pans, Shift+drag selects.
- Cursors: grab over pane, grabbing while dragging, default arrow while selecting.
- Connection drop snaps to a handle within 60px. Selection box padded 8px; single-element box selection hides the box. Selection rectangle colours = library default.
- Minimap: 200×120 bottom-left, 72px above the bottom edge; 1px border, radius 4, neutral-50 background; nodes drawn as foreground-shade-1 rects with 16px radius; stickies at 20%; appears only while panning/wheeling (300ms fade), hides 1000ms after movement stops, stays while hovered; pannable/zoomable; hidden at the smallest breakpoint.
- Bottom-left controls (`elements/buttons/CanvasControlButtons.vue`): horizontal toolbar group 16px from edges; group padding 2px, radius 6, white surface, small shadow (0 1px 3px −1px black 10%), no gaps; ghost buttons 36×36 with 16px icons, hover black 5%. Order: fit view (key 1), zoom in (+), zoom out (−), (experimental zoom-mode toggle), tidy up (Shift+Alt+T; hidden when read-only). Tooltips show label + shortcut chip.
- Top-right vertical toolbar (`EUI/features/shared/nodeCreator/views/NodeCreation.vue`): same style, vertical, 16px from top/right. Buttons: open nodes panel (N), command bar (⌘K), add sticky (Shift+S), toggle side/focus panel (Shift+F), AI assistant. Tooltips open left. Hidden while the node creator is open.
- Empty-canvas placeholder (`render-types/CanvasNodeAddNodes.vue`): 100×100 button, 2px dashed foreground-shade-2 border, radius 8, white fill, 40px plus icon (orange on hover); text 8px below, 16px/500/1.5, darkest text. Click opens the node creator in trigger mode. Hovering the run button shows a tooltip on it.
- Bottom-centre run bar (NodeView styles): centred, 16px from bottom, 12px gaps; moves bottom-right below the small breakpoint. Main button solid orange large (36px, radius 6, 14px/500, padding reduced to 12px), small shadow, white text; icon = current trigger's icon (20px, tinted) or a flask. Several triggers → split button with a 28px chevron segment listing triggers. While running → icon-only spinner + subtle stop button (square icon). Chat trigger → extra open/hide chat button (message-circle icon).
- Button component (`DS/components/N8nButton/Button.vue`) variants: solid orange; subtle white + 1px black-10% border + small shadow; ghost transparent. Sizes (h / radius / font): xsmall 24/4/12, small 28/4/13, medium 32/4/14, large 36/6/14, xlarge 40/8/16.
- Optional credentials-setup button at top-left, 16px from edges.

## 2. Node shapes and sizes

Files: `EUI/app/utils/nodeViewUtils.ts` (`calculateNodeSize`), `render-types/CanvasNodeDefault.vue`, `render-types/_canvasNodeStyles.scss`.

| Node kind | Size | Shape |
|---|---|---|
| Default action | 96×96; +32px height per main handle beyond 2 on a side | rounded square, radius 8 |
| Trigger | 96×96 | left corners radius 36, right corners 8 |
| Configuration sub-node (AI-type outputs only) | 80×80 | circle |
| Configurable (AI inputs) | height 96; width 80 + 48×(ports−1), min 4 slots → 224 | wide rounded rectangle, bottom handles |
| Configurable sub-node | width 80 + 16 + 48×(ports−1); height 80 | pill |
| Sticky note | default 240×160; min 150×80 | radius 4 |

- Border 1.5px solid black 10% (dark white 15–20%); opacity scales with zoom toward 70% at zoom 0.2 (gamma 2.2; `composables/useZoomAdjustedValues.ts`). Fill white (dark neutral-900).
- Icon centred: 48px (newer icon set), 40px (legacy); 36/30px in sub-nodes; configurable nodes put the icon left, centred 40px from the left edge (`EUI/app/utils/nodeIcon.ts`).
- Label (default, trigger, sub-node): outside, below, 8px gap; centred; text area ≥ 2× node width. Name 16px/500/1.25, max 2 lines. Subtitle 4px below, 13px/400, text-tint-1 grey, one line ellipsis. Pointer events off.
- Label (configurable): inside, right of the icon, left-aligned, 16px side margins.
- Hover toolbar (`nodes/CanvasNodeToolbar.vue`, positioned by `CanvasNode.vue`): centred above the node with 12px bottom padding; strip in canvas background colour, radius 4; ghost 28px grey buttons. Order: execute step (play), deactivate/activate (power), delete (trash), optional AI sparkles, more (ellipsis → context menu). Execute only on main-flow and AI-tool nodes. Fades in 100ms on hover/focus; stays while its menu is open or the pointer is over it. Stickies: colour picker, delete, more.
- Selected: 6px outer ring hsla(220,47%,30%,0.1), no layout shift; stickies 4px ring neutral-150.
- Disabled: border neutral-200; icon greyed; "(Deactivated)" under the name; power icon bottom-right; 2px foreground-shade-1 strike-through line through the vertical centre from 4px left of the node to 8px past its right edge — only when exactly one main input and one main output with ≤ 1 connection each; line green-300 with run data, gold-200 when dirty.
- Pinned data: 2px purple border; purple pin glyph bottom-right 6px inset. Setting badges top-right in 20px boxes as 12px grey icons (always output data, execute once, retry on fail, continue on error).
- Placeholder node: 2px dashed shade-2 border, plus icon orange on hover.
- Trigger extras (`render-types/parts/CanvasNodeTrigger.vue`): filled orange bolt outside the node on the left, vertically centred, 16px padding. Pointer zone 4× node width (starting 2 widths left) × 3× height: bolt slides 12px left + fades out; solid orange large "execute workflow" button (flask icon) slides in from −12px + fades in, 16px left of the node; 100ms ease-in. Chat trigger shows an open-chat button instead.
- Sticky notes (`render-types/CanvasNodeStickyNote.vue`, `DS/components/N8nSticky/Sticky.vue`): default yellow-100 #fef9c2 fill, yellow-200 border. Variants: yellow, gold (100/300), red (100/250), green (100/300), blue (100/200), purple (200/300), neutral (100/200); custom hex allowed. Markdown; double-click edits; padding 8 top/bottom, 12 left/right; invisible 16px resize edges; drawn below nodes and edges.
- Tidy-up (left-to-right graph layout): 128px between columns, 96px between rows. AI sub-node clusters 48px horizontal, 128px vertical. A node inserted after another lands 224px to the right, centre to centre.

## 3. Execution status visuals

Files: `CanvasNodeDefault.vue`, `_canvasNodeStyles.scss`, `render-types/parts/CanvasNodeStatusIcons.vue`, `CanvasNodeStatusMark.vue`.

| State | Border | Icon (bottom-right, 6px inset, 16px) | Notes |
|---|---|---|---|
| Success | 2px green-600 | green check | run count (14px bold) when run more than once |
| Error | 2px red-600 | red error mark | tooltip (500ms delay) lists issues grouped "x N" |
| Not configured / issues | unchanged | red issues icon | key icon in warning gold if only credentials missing |
| Dirty | 2px warning gold | gold dirty mark | tooltip explains |
| Pinned | 2px purple | purple pin | overrides success colouring |
| Running | border transparent | — | ring 3px outside the node: coral rgb(255,109,90) conic gradient, mostly solid with a faded arc at 20% alpha; 1.5s per turn, linear, infinite; follows node shape |
| Waiting | same ring | — | 4.5s per turn |
| Disabled | foreground grey | grey power icon | — |

- Precedence (later wins): selected < success < warning < error < pinned < disabled < running < waiting.
- Edge item counts: "N item(s)" (or "N items total" for AI connections over iterations); 13px canvas-label grey on 85% canvas-colour backdrop; at path midpoint lifted 12px (straight horizontal edges lifted a further label height); unconnected output with data shows the count above its plus-stub; pinned data counts. Source: `composables/useCanvasMapping.ts` (`getConnectionLabel`, `getConnectionStatus`).

## 4. Handles and ports

Files: `elements/handles/CanvasHandleRenderer.vue`, `render-types/*`, `parts/CanvasHandleDot.vue`, `CanvasHandleDiamond.vue`, `CanvasHandlePlus.vue`.

- Indicator 16×16, centred on the node edge (half outside).
- Main input (left): circle, white fill (dark neutral-850), 1px grey border (zoom-adjusted, ≈ #989898 at 100%). Optional label 12px left of the handle, 12px text, foreground shade-2, translucent backdrop; required inputs show a red "*".
- Main output (right): same circle; hover scale ×1.5, border 1.5px neutral-300, fill neutral-100 (200ms ease); crosshair cursor. Output labels 20px right, 12px canvas-label grey, translucent backdrop, max 96px when connected.
- Several handles on a side spaced at (i+1)/(n+1) of node height; node grows 32px per handle beyond 2.
- Plus-stub on unconnected outputs: horizontal 2px line from the handle ending in a 24px "plus" box (20×20 rect, radius 4, neutral-200 fill and border, dark-grey plus at 1.5px stroke). Line 46/66/80px depending on the longest output label (80 with run data). Edge grey; success-green when the output produced data. Box hover neutral-250 + darker glyph. Enter/leave: scale from 0 + fade, 200ms ease, from the handle. Hidden while dragging a connection from that handle. Click opens the node creator ("what next" mode).
- AI inputs (bottom of configurable nodes): diamond (16px square rotated 45°, scale 0.8; hover 1.2 + 1.5px border); x positions 40, 88, 136 … (48px steps); required first; spacer slots pad to 4; labels 24px below, centred, 12px grey; vertical plus-stub downward while more connections allowed.
- AI outputs (sub-nodes): one diamond top centre, label 24px above.
- Releasing a connection drag on empty canvas opens the node creator prefilled for that handle (not when clicking the plus box).

## 5. Edges

Files: `elements/edges/CanvasEdge.vue`, `utils/getEdgeRenderData.ts`, `CanvasEdgeToolbar.vue`, `CanvasArrowHeadMarker.vue`, `CanvasConnectionLine.vue`.

- Forward connections: smooth Bézier.
- Back-edges (target > 20px left of source, main only): two rounded step segments — drop to 130px below the source, run back, rise into the target; corner radius 16; 40px horizontal clearance from handles; label/toolbar anchor = bottom midpoint of the loop.
- Stroke 2px, square caps. Default neutral grey, zoom-dependent (≈ #cacaca at 100%, toward #808080 at 20%; dark #4d4d4d lighter). Hover: −0.3 lightness (light) / +0.2 (dark). Success → green-600; pinned → purple-600 (no hover change); running and error stay grey. Priority running > pinned > error > success.
- Arrowhead on main edges only: small closed triangle with rounded joins, 12.5 units relative to stroke, filled and stroked in the edge colour.
- AI connections: dashed (5 on, 6 off), no arrowhead.
- Hover: 40px-wide hit area; midpoint label replaced by two 28px subtle borderless icon buttons "+" (insert) and trash (delete); background neutral-200, hover neutral-250, gap 8, padding 8; tooltips above. "+" only on main edges and AI-tool → agent edges. Toolbar lingers 150ms after leave.
- No animated dashes.
- Live drag line: same routing, 2px foreground shade-2, round caps/joins, dashed for AI, same arrow; fades in only after 300ms (300ms transition).

## 6. Editor chrome

Main header (`EUI/app/components/MainHeader/MainHeader.vue`, `WorkflowDetails.vue`, `WorkflowHeaderDraftPublishActions.vue`, `TabBar.vue`, `ActionsDropdownMenu.vue`):
- 64px, white, 1px bottom border (foreground grey), padding 12px 20px.
- Left: breadcrumbs, "/" separator (20px, light grey), inline-editable name (14px, darkest text), ghost "…" button (32px) with share, version history, tags, import/export, duplicate, archive.
- Right: collaborator avatars; optional save button (only when autosave is off); publish split button (ghost, 1px border, radius 4; "Publish" or muted "Published"; 8px status dot: mint #009689 published, yellow-500 unpublished changes, red-600 issues, gold partial; chevron opens version menu).
- Tabs: segmented control (editor / executions / evaluations), centred, straddling the header's bottom border (shifted down half its height), floating above content. Segment track neutral-200, padding 2, radius 6, height 32, 12px/500; selected segment white with dark text; others subtle text, hover neutral-150 (`DS/components/N8nSegmentControl/`).

Left main sidebar (`EUI/app/components/MainSidebar.vue`, `MainSidebarHeader.vue`, `BottomMenu.vue`, `EUI/features/collaboration/projects/components/ProjectNavigation.vue`, `EUI/app/composables/useSidebarLayout.ts`):
- 42px collapsed; expanded drag-resizable 200–500px in 8px steps, default 200; width animates 200ms ease-out-cubic (0.215, 0.61, 0.355, 1).
- Neutral-50 background, 1px right border.
- Header row (8px/6px padding): logo top-left (20px tall, hidden collapsed); right-aligned ghost 28px icon buttons: create menu, search (⌘K), toggle sidebar ([). Collapsed: stacked vertically with a bottom border.
- Navigation: overview, personal, shared with you, optional chat, collapsible favourites and project lists.
- Items ≥ 32px, padding 4, radius 4, gap 4; active/hover neutral-100; long labels scroll on hover.
- Bottom block pinned, padding 6: templates, insights, help (popover right), settings (popover with sign-out last). No separate user card.

Node creator panel (`EUI/features/shared/nodeCreator/components/NodeCreator.vue`, `Panel/NodesListPanel.vue`, `Panel/SearchBar.vue`, `ItemTypes/*`, `DS/components/N8nNodeCreatorNode/NodeCreatorNode.vue`; data `views/viewsData.ts`):
- Fixed right, below the 65px header, full height, 385px wide; narrower windows (< 385 + 42) → full width minus 42px sidebar. White, 1px left border. Slides horizontally (transform from 100%) 200ms ease. Close "×" only at narrow widths. Sub-views slide in from the right over the old one (200ms ease); back reverses.
- Header (16px padding): 18px bold title (trigger mode / "what next" mode) + 14px subtitle. Sub-view headers add a 22px back arrow, neutral-125 background, bottom border.
- Search: 40px, 16px margin, 1px foreground border, radius 4, white; leading search icon (orange while there is input), trailing clear; focus border purple.
- List items: 12px vertical padding; 20–24px icon + 16px gap; title 14px/500; description 12px/400, 2px below, line-height 16px; trailing right-arrow for sub-views; trigger items get a tiny orange bolt; hover 2px grey left accent bar; keyboard-active orange bar.
- Category rows 14px bold, padding 8px 16px, bottom border, chevron right. Section labels 10px uppercase bold, 1px letter spacing. Separators 1px inset 16px. No dimming overlay.

Logs/chat panel (`EUI/features/execution/logs/components/LogsPanel.vue`, `LogsPanelHeader.vue`, `composables/useLogsPanelLayout.ts`):
- Docked under the canvas, 1px top border, neutral-50 background. Collapsed = 32px header bar; open default 30% of height; resizable from the top edge, 160px to 75%.
- Columns: chat (only with chat trigger; default min(800px, 30%), min 240), logs overview tree (default min(240px, 20%) when details shown; min 80), log details (input/output panes).
- Section headers 36px, white, 12px bold title, 8px h-padding; header click toggles. Pop-out window. Keys L / I / O.

## 7. Node Details View (NDV)

Files: `EUI/features/ndv/shared/views/NodeDetailsView.vue`, `panel/components/NDVHeader.vue`, `PanelDragButton.vue`, `NDVFloatingNodes.vue`, `InputPanel.vue`, `OutputPanel.vue`, `panel/composables/useNdvLayout.ts`, `settings/components/NodeSettingsHeader.vue`, `runData/components/*`.

- Opens on double-click or Enter. Modal over black 60% overlay, inset 24px each side. No open/close animation. Close: Escape, overlay click, header "×".
- Frame radius 8, 1px border. Header: 4px padding, white; left 24px icon + inline-editable name (14px dark); right docs link (12px bold) + vertical divider + ghost "×".
- Columns INPUT | parameters | OUTPUT. Centre default 420px (640 for wide node types); sides split the rest. No-input nodes: centre 480, output fills rest. Limits: centre ≥ 368; sides ≥ 120 (content ≥ 280). Layout saved per node-type class.
- Centre resizable from both edges (8px steps); double-click a resize edge or the grip resets. Drag-grip tab on top of the centre column, centred, 18px tall, small tab with 1px border and 4px top corners, grip icon, arrows on hover; dragging moves the centre column sideways (ew-resize). Columns separated by 1px borders, white.
- Floating neighbours: parents on the left border, children on the right, AI sub-nodes bottom, agent top; small chips at scale 0.8 → 1.1 on hover (200ms ease-out-expo); click switches node.
- Centre header 34px; tabs parameters | settings (+ docs/community); 12px bold; active orange + 2px underline; hover orange. Right: small solid orange "execute step" button (28px, flask/play icon); stop replaces it while running.
- Parameter rows: label above (14px dark); right-side hover/focus controls (100ms in / 250ms out): options "⋯", mini segmented fixed/expression switch (24px), optional side-panel button. Inputs small 28px, radius 4, white, 1px border, focus purple-600. Expression mode: grey "fx" prefix cell (22px) + expand corner button; resolved-value preview popover under the field.
- Drag-and-drop mapping: input-panel fields (table headers, schema pills, JSON keys) draggable; dragging pill 24px tall, 12px text, orange text and border on light orange, soft shadow; droppable fields show a 1.5px dashed purple outline; hovered target turns solid green border and the pill turns green on white; drop converts the field to an expression referencing the path.
- Input/output panes: header 34px; title 13px UPPERCASE, 2px letter spacing (output title bold grey); item count and run selector; right-aligned search, view-mode segmented control, edit (pencil), pin.
- View modes: schema | table | JSON (+ binary / HTML / rendered); narrow panes icon-only square segments.
- Table view: 12px; sticky header cells neutral-125 with 1px borders all sides; header cells draggable (grab; neutral-200 hover; orange while dragging); cell padding 4px 6px.
- Schema view: nested pills indented 24px per level; pill 24px tall, radius 4, light-grey border, type icon, key, divider, value preview; orange when mapped.
- JSON view: syntax colours strings purple-700, numbers/booleans green-600, null red-600, keys neutral-700.
- Pinned output: purple banner "data is pinned" + unpin, pin icon.

## 8. Workflows list / home

Files: `EUI/app/views/WorkflowsView.vue`, `EUI/app/components/layouts/{ResourcesListLayout,PageViewLayout,EmptyStateLayout,ResourcesListEmptyState}.vue`, `EUI/app/components/WorkflowCard.vue`, `EUI/features/collaboration/projects/components/{ProjectHeader,ProjectTabs}.vue`, `DS/components/N8nCard/Card.vue`.

- Content max 1280px; padding 24 top, 48 sides (16 on small screens).
- Header: large bold title + light grey subtitle; right primary solid orange medium create button with a dropdown for other resource types.
- Tabs below: workflows / credentials / executions / variables (+ settings for projects); underline style 14px, active orange + 2px underline.
- Filter row right-aligned: search 196px × 32px (icon, clearable), sort select, icon-only filter dropdown; 4px gaps; active filters → info line with reset link.
- List: full-width rows, paginated, pagination bottom-right. Row card radius 8, 1px border, white, whole card clickable, hover shadow 0 2px 8px warm brown 10% over 300ms. Left: name 14px bold, 16px padding; 12px grey meta line "updated <ago> | created <date>" + tag chips (3, then "+N"). Right (centred vertically, 16px right padding): ownership/project pill badge, publish status indicator, "⋯" menu. Archived: neutral-50 background, muted text.
- Empty state (new instance): large centred bold heading (fade, un-blur, lift); row of 192px-wide 4:3 action cards 24px apart (build, optional demo, optional agent); large outline icon over label; hover lifts 2px + 0 8px 25px shadow + icon orange; stagger 160ms + 80ms × index, 400ms ease-out each. Other resources: standard empty state (icon, heading, description, CTA). Loading: skeleton rows.

## 9. Motion

| Element | Duration | Easing / notes |
|---|---|---|
| Tokens | 200 / 400 / 1000 / 1500ms | ease-out (0.215, 0.61, 0.355, 1); ease-in-out (0.645, 0.045, 0.355, 1); spring (0.34, 1.56, 0.64, 1); ease-out-expo (0.19, 1, 0.22, 1) |
| Canvas first appearance | 300ms | opacity, ease |
| Minimap show/hide | 300ms fade | hides 1000ms after panning stops |
| Node hover toolbar | 100ms | opacity, ease-in |
| Trigger bolt → run button | 100ms | translate 12px + opacity, ease-in |
| Running / waiting ring | 1.5s / 4.5s per turn | linear, infinite |
| Handle hover | 200ms (border width 100ms) | ease; scale 1.5 dot / 1.2 diamond |
| Plus-stub appear/disappear | 200ms | scale from 0 + fade, ease |
| Edge hover → toolbar | immediate show, 150ms hide delay | — |
| Edge colour | 300ms | ease |
| Connection drag line | 300ms delay then 300ms fade | ease |
| Pan to selection | 200ms | linear viewport tween |
| Spotlight dimming | 500ms | edges 20%, other nodes 40% |
| Node creator slide | 200ms | ease; translateX from 100% |
| Node creator sub-view | 200ms | ease, horizontal slide |
| Sidebar collapse/expand | 200ms | ease-out-cubic, width |
| NDV open/close | none | instant |
| NDV neighbour hover | 200ms | ease-out-expo, scale 0.8 → 1.1 |
| Parameter label controls | 100ms in / 250ms out | opacity |
| Input border focus | 200ms | ease-in-out-cubic |
| Tooltip | — | black bubble, radius 8, 12–13px/500, max 180px; ~500ms show delay on canvas |
| Workflow card hover | 300ms | shadow, ease |
| Button loading | 200ms | ease-out; 4px rise + 2px blur |

## 10. Keyboard (canvas, `Canvas.vue`)
- 1 fit · 0 reset to 100% · +/− zoom · Space/Ctrl held = pan mode.
- Enter opens NDV · short Space or F2 renames.
- D deactivate · P pin · Delete/Backspace delete · ⌘C / ⌘X / ⌘D.
- N node creator · Shift+S sticky.
- ⌘↵ run workflow · Shift+Alt+T tidy up.
- Arrow keys move selection along connections/siblings · Shift+←/→ select all upstream/downstream.
- L / I / O toggle logs panel and its input/output panes.

## Caveats
- Dot radius, selection-rectangle fill/border and zoom step are library defaults (not readable without node_modules).
- Node groups and the agent card node are newer features (`elements/groups/CanvasNodeGroupTitleBar.vue`, `stores/canvasNodeGroups.constants.ts`, `render-types/CanvasNodeAgent.vue`; group header 96px, collapsed width 400, padding 56/40/88) — out of scope.
- Experimental flags (zoom mode, in-canvas parameter editor, right focus panel) left out.
