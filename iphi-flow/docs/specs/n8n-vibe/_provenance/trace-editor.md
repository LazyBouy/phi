# trace-editor — provenance for 05-canvas, 06-graph, 07-step-modal, 08-piece-panel, 09-logs

Reference lane and auditor only. Builders never read this file. It may name n8n paths.

- n8n tree: `iphi-flow/n8n` at commit `55eb2ce442` (CLI 2.43.0).
- `EUI` = `iphi-flow/n8n/packages/frontend/editor-ui/src`; `DS` = `iphi-flow/n8n/packages/frontend/@n8n/design-system/src`; `CANV` = `EUI/features/workflows/canvas/components`.
- Screenshots: `docs/specs/n8n-vibe/_ref/n8n/<name>.png` (1440×900, light and `-dark`). "Pixel-sampled" means colours and positions were read from the PNG with Pillow on 2026-10-09 (row/column colour runs).
- AP tree: `iphi-flow/activepieces` on `main` @ `518ae7091c`.
- How-verified codes: **SRC** = n8n source file read this session; **PIX** = pixel-sampled screenshot; **VIS** = screenshot viewed, not sampled; **R3** = taken from `r3-n8n-editor-facts.md` without re-reading the source; **AP** = derived from AP code read this session (no n8n input); **DEC** = AP-side design decision by this writer (no n8n counterpart); **LIB** = canvas-library default, not readable (no `node_modules`).

| ID | Source (n8n path and/or screenshot) | How verified |
|---|---|---|
| CAN-01 | `DS/css/_tokens.scss` (canvas, node, sticky, json blocks, light and dark), `DS/css/_tokens.legacy.scss` (foreground/text/background aliases), `DS/css/_primitives.scss` (neutral-150/250/850 values); all 10-*, 20-*, 21-*, 02-* screenshots | SRC + PIX (canvas #f5f5f5/#171717, dot #b0b0b0 and #393939 rendered, edge #cacaca/#4d4d4d, handle ≈#9e9e9e, node fill #fff/#2b2b2b, border #dcdcdc/#454545, halo #e0e3e7/#747474, plus box #e5e5e5, controls #fff/#262626). OKLCH lightness → sRGB converted by hand (L³ → sRGB gamma). Halo hue replaced by Tailwind slate-700 (rendered result within 2 levels of the reference); running-ring coral replaced by accent (never-use rule) |
| CAN-02 | `CANV/elements/background/CanvasBackground.vue` (gap = grid size); `EUI/app/utils/nodeViewUtils.ts` (GRID_SIZE 16); 02-canvas-empty(.dark) | SRC + PIX (dots every 16px, single pixel at ≈75% coverage → 1px diameter) |
| CAN-03 | `CANV/elements/background/CanvasBackgroundStripedPattern.vue` | SRC |
| CAN-04 | `CANV/Canvas.vue` (min-zoom 0, max-zoom 4, snap-grid) | SRC; zoom step 1.2 = LIB |
| CAN-05 | `CANV/Canvas.vue` (`onFitView`: padding 0.2, maxZoom default 1; `onResetZoom`; `.canvas` opacity 300ms); `EUI/app/composables/useViewportAutoAdjust.ts`; first-node (176, 240) | SRC (fit, fade, resize); origin = R3 |
| CAN-06 | `CANV/Canvas.vue` (panningKeyCode Space/Ctrl, panningMouseButton, selectionKeyCode, pan-on-scroll, zoom-activation); `EUI/app/css/plugins/_vueflow.scss` (pane / node cursors) | SRC |
| CAN-07 | `EUI/app/css/plugins/_vueflow.scss` (selection rect padding 8px) | SRC; rectangle colours = LIB (Vue Flow and React Flow share the same blue default) |
| CAN-08 | `CANV/Canvas.vue` (MiniMap 200×120, node-border-radius 16, visibility delay 1000, pane-move logic, 0.3s transition); `EUI/app/css/plugins/_vueflow.scss` (margin-bottom 48 + 2×12, border, radius, background light-2, sticky opacity 0.2, hidden xs) | SRC |
| CAN-09 | `CANV/elements/buttons/CanvasControlButtons.vue`; `DS/components/N8nButtonList/ButtonList.vue` (toolbar variant: padding 5xs, radius 2xs, surface, shadow xs); `EUI/app/css/plugins/_vueflow.scss` (controls margin sm); 10-linear-idle(.dark) | SRC + PIX (group 148×40 at 16px/16px; surface #fff/#262626) |
| CAN-10 | `EUI/app/components/KeyboardShortcutTooltip.vue` (show-after 500, kbd colours); `DS/components/N8nKeyboardShortcut/N8nKeyboardShortcut.vue` (18px keys, 4px padding, radius sm=2px, 3xs font) | SRC |
| CAN-11 | `EUI/features/shared/nodeCreator/views/NodeCreation.vue` (vertical toolbar, 16px from top/right, tooltips left, hidden while creator active) | SRC + PIX (40×148 at 16px/16px for four buttons) |
| CAN-12 | `EUI/app/views/NodeView.vue` (execution buttons: bottom sm, gap xs, centred, moves right below sm breakpoint); `CANV/elements/buttons/CanvasRunWorkflowButton.vue`; `CanvasStopCurrentExecutionButton.vue`; 10-*-idle | SRC + PIX (button 105×36, 16px above canvas bottom, centred). Cancellable statuses = AP (`flow-run-service.ts` CANCELLABLE_STATUSES) |
| CAN-13 | `EUI/app/views/NodeView.vue` (centre pill / read-only callout placement) | SRC (placement idea only); banner set and offset = DEC |
| CAN-14 | `CANV/elements/nodes/render-types/CanvasNodeAddNodes.vue`; 02-canvas-empty(.dark) | SRC + PIX (100×100, 2px dashed #999, white fill, label 8px below). AP label and e2e = AP |
| CAN-15 | `DS/css/_tokens.scss` sticky variants (light 90–109, dark 767–786); R3 §2 (padding, sizes, resize edges); 20-node-hover(.dark) | SRC + PIX (yellow fill #fef9c2 / border #fff085; dark #733e0a / #894b00; text #2b2b2b / #f5f5f5). Orange mapping = DEC (Tailwind orange in place of the custom gold ramp) |
| CAN-16 | `CANV/Canvas.vue` keyMap | SRC; AP columns = AP (`BUILDER/shortcuts.ts`) |
| NOD-01 | `CANV/elements/nodes/render-types/CanvasNodeDefault.vue`; `_canvasNodeStyles.scss` (border 1.5px); R3 §2 (`calculateNodeSize` +32/handle) | SRC + PIX (96px box) |
| NOD-02 | `CANV/elements/nodes/render-types/parts/CanvasNodeTrigger.vue`; `CANV/Canvas.vue` (hover rect x−2w, y−h, 4w×3h); 10-linear-idle | SRC + PIX (bolt ≈14px glyph, ≈18px gap) |
| NOD-03 | R3 §2 (icon 48/40px) | R3; LogoPlate approach = DEC + AP (`logo-plate.tsx`) |
| NOD-04 | `CanvasNodeDefault.vue` (.description, .label, .subtitle: 2xs margin, 4xs gap, md/500, line-clamp 2, xs subtitle, min-width 2× node) ; 25-logs-open | SRC + PIX (label text top 10px under box) |
| NOD-05 | `CANV/elements/nodes/CanvasNodeToolbar.vue`; `CANV/elements/nodes/CanvasNode.vue` (position, 0.1s fade); 20-node-hover | SRC + PIX (four 28px buttons, strip = canvas colour). Icons = DEC (Lucide) |
| NOD-06 | `_canvasNodeStyles.scss` (selected ring 6px); `DS/css/_tokens.scss` (selected-transparent); 21-node-selected(.dark) | SRC + PIX (6px ring) |
| NOD-07 | `CanvasNodeDefault.vue` (disabled border); `parts/CanvasNodeDisabledStrikeThrough.vue` (top h/2−1, left −4, width +12); R3 §2 (one-in/one-out rule) | SRC; one-in/one-out rule = R3 |
| NOD-08 | `_canvasNodeStyles.scss` (status mixins, ring inset −3px, radius 10px, conic stops, 1.5s / 4.5s); `parts/CanvasNodeStatusIcons.vue`; `parts/CanvasNodeStatusMark.vue` (count sm bold, gap 5xs); 11-*-after-run, 11-error-after-run | SRC + PIX (2px success / error borders). AP status mapping = AP (`flow-run-utils.ts`); precedence = R3 §3 adapted |
| NOD-09 | (no n8n counterpart for AP draft states; dirty = `CanvasNodeStatusIcons.vue` warning branch) | SRC (warning look) + DEC (mapping) + AP (`step-node-status-in-draft.tsx`) |
| NOD-10 | `CanvasNodeDefault.vue` (.pinned 2px secondary); `CanvasNodeStatusIcons.vue` (pin icon) | SRC; trigger/TESTING mapping = AP (`test-flow-widget.tsx`, `RunEnvironment`) + DEC |
| NOD-11 | `parts/CanvasNodeSettingsIcons.vue` (top-right, 20px boxes, gap 1px) | SRC; icons and texts = AP + DEC |
| NOD-12 | — | DEC (join dot has no n8n counterpart; styled as a stand-alone handle dot from `parts/CanvasHandleDot.vue`) |
| NOD-13 | `CANV/composables/useZoomAdjustedValues.ts` (base/max values, min zoom 0.2, gamma 2.2, hover ±) | SRC |
| NOD-14 | `EUI/app/css/plugins/_vueflow.scss` (dragging cursor) | SRC (cursor); drop-target visuals = DEC |
| HDL-01 | `parts/CanvasHandleDot.vue` (16px, white / neutral-850, 1px border lightness 0.68 / 0.5); `render-types/CanvasHandleMainInput.vue`; 10-linear-idle | SRC + PIX (16px circle, centred on edge) |
| HDL-02 | `parts/CanvasHandleDot.vue` (hover scale 1.5, border 1.5px neutral-300, fill neutral-100 / neutral-700, 0.2s / 0.1s, crosshair) | SRC |
| HDL-03 | R3 §4 ((i+1)/(n+1), +32px per handle) | R3; output table = design doc |
| HDL-04 | `render-types/CanvasHandleMainOutput.vue` (.outputLabel left md, 2xs font, canvas label colours, max 96px when connected); 10-branch-idle | SRC + PIX (label starts 12px past the box edge) |
| HDL-05 | `parts/CanvasHandlePlus.vue` (24px plus, 20px rect + 2px stroke, rx 4, neutral-200/850, hover 250/800, glyph 700/250 → 850/150, 1.5 stroke); `CanvasHandleMainOutput.vue` (line 46/66/80, run data 80, 0.2s scale transition); `EUI/features/workflows/canvas/canvas.utils.ts` (`getLabelSize` ≤2 / ≤6) | SRC + PIX (line 47px then 22px box) |
| HDL-06 | `CanvasHandleMainOutput.vue` (runDataLabel, success line); 25-logs-open | SRC + PIX (label bottom ≈6px above line) |
| HDL-07 | R3 §4 (connection released on empty canvas opens the creator) | R3; AP behaviour = plan (out-of-scope rule) |
| EDG-01 | `CANV/elements/edges/utils/getEdgeRenderData.ts` (bezier, 20px threshold) | SRC; curvature 0.25 = LIB |
| EDG-02 | `getEdgeRenderData.ts` (padding bottom 130, x 40, radius 16, two segments, label at first-segment end); `CANV/elements/edges/CanvasEdge.vue` (marker-end on every segment); 10-loop-idle-dark, 11-loop-after-run | SRC + PIX (drop 130 below source, 40px clearance, mid arrow visible) |
| EDG-03 | `CanvasEdge.vue` (status colours, no hover on coloured, 0.3s); `EUI/features/workflows/canvas/composables/useCanvasMapping.ts` (`getConnectionStatus`); 11-error-after-run (green edge into failed node) | SRC + PIX |
| EDG-04 | `CANV/elements/edges/CanvasArrowHeadMarker.vue` (12.5 strokeWidth units, closed rounded triangle, context-stroke) | SRC + PIX (≈8px arrow at handle edge). Geometry re-described, no marker data copied |
| EDG-05 | `CanvasEdge.vue` (interaction-width 40, delayed hover, toolbar replaces label); `CANV/elements/edges/CanvasEdgeToolbar.vue` (subtle small buttons, colours, gap/padding 2xs); `EUI/app/constants/durations.ts` (LEAVE 150) | SRC; trash button deliberately dropped (DEC, tree) |
| EDG-06 | `CanvasEdge.vue` (.edgeLabelWrapper −xs, .straight −100%, xs font, canvas label colours); `useCanvasMapping.ts` (`getConnectionLabel`); 25-logs-open, 11-loop-after-run | SRC + PIX. AP array / iteration rule = task mapping |
| EDG-07 | — | DEC |
| EDG-08 | R3 §5 (live line 300ms delay + 300ms fade, round caps) | R3 |
| EDG-09 | `EUI/app/css/plugins/_vueflow.scss` (bring-to-front z rules) | SRC |
| NDV-01 | R3 §7 (double-click / Enter, Escape, overlay, no animation) | R3; AP flow and e2e impact = AP (`tests-e2e/pages/builder.page.ts`, scenarios) |
| NDV-02 | `EUI/features/ndv/shared/views/NodeDetailsView.vue` (.dialog inset lg, 2xl size, backdrop overlay dark, radius lg); `DS/css/_tokens.scss` (overlay black-alpha-600); 24-step-modal-with-data(.dark) | SRC + PIX (frame 24..1415 × 24..875; overlay renders #626262 over #f5f5f5) |
| NDV-03 | `EUI/features/ndv/panel/components/NDVHeader.vue`; 24-step-modal-with-data | SRC + PIX (header 40px + 1px border). Docs link not mapped (AP has no URL) |
| NDV-04 | `EUI/features/ndv/panel/composables/useNdvLayout.ts` (368 / 120 / 480 / 640 / 420, safePanelWidth); `NodeDetailsView.vue` (.input/.output min-width 280) | SRC |
| NDV-05 | `useNdvLayout.ts` (onResize, onDrag, resetPanelSize, localStorage per pane type); `EUI/features/ndv/panel/components/PanelDragButton.vue`; `NodeDetailsView.vue` (.draggable 18px); 24-step-modal-with-data | SRC + PIX (grip at the header's bottom edge). 8px resize steps = R3. Per-piece key = plan |
| NDV-06 | `EUI/features/ndv/settings/components/NodeSettingsHeader.vue` (header height xl + 5xs); `NodeSettingsTabs.vue` (modern variant); `DS/components/N8nTabs/Tabs.vue` (modern: 2xs/bold, padding sm, underline 2px); 24-step-modal-with-data | SRC + PIX (42px bar, 2px #ff6900 underline, button 28px tall 8px from edge). Labels and test ids = AP |
| NDV-07 | 24-step-modal-with-data (16px column padding, 30px inputs, ≈68px row pitch) | PIX; forms = AP |
| NDV-08 | `DS/components/N8nInputLabel/*.vue` (options fade 100ms in / 250ms out with cubic-bezier); `EUI/features/ndv/parameters/components/ParameterInputFull.vue` (label props) | SRC; mention-input mapping = AP (`tiptap-editor.tsx` insertMention) |
| NDV-09 | — | AP + DEC |
| NDV-10 | `EUI/features/ndv/panel/components/OutputPanel.vue` (.title uppercase, 2px letter-spacing, bold, xs, text tint-1); `EUI/features/ndv/runData/components/RunData.vue` (.header height = ndv header, padding 4xs/sm; --ndv--spacing 2xs); 24-step-modal-with-data | SRC + PIX (pane #f5f5f5 / #262626, header 42px). Tree content = AP (`data-selector/`) |
| NDV-11 | `OutputPanel.vue`, `RunData.vue`; 22-step-modal, 24-step-modal-with-data | SRC + VIS (status check + info icons, count line). Texts = AP existing keys |
| NDV-12 | `EUI/features/ndv/runData/components/RunDataDisplayModeSelect.vue`; `DS/components/N8nSegmentControl/*.vue` (track foreground, padding 5xs, radius 2xs, items radius 3xs, 2xs/500) | SRC + PIX (32px control). Compact threshold 400px = DEC (not verified) |
| NDV-13 | R3 §7 (schema pills 24px, indent 24px); 24-step-modal-with-data | R3 + PIX (pill 24px tall, border #f0f0f0, white). Type icons = DEC (Lucide) |
| NDV-14 | 24-step-modal-with-data (header 32px, rows 26px + 1px border, borders #dcdcdc, 12px inset) | PIX; cell padding 4px/6px = R3 |
| NDV-15 | `DS/css/_tokens.scss` json tokens (light 220–229, dark 846–855) | SRC |
| NDV-16 | `EUI/features/ndv/runData/components/MappingPill.vue` (24px, 3xs padding, radius 4, primary / success variants, shadow); `EUI/features/ndv/parameters/components/ExpressionParameterInput.vue` (1.5px dashed outline, success active); `DS/css/_tokens.scss` (droppable colours light / dark) | SRC. Shadow colour replaced by Tailwind stone-900 (DEC); drop behaviour = AP (`insertMention`) |
| NDV-17 | — | AP (`loop-iteration-input.tsx`) + DEC (placement modelled on the run selector in `RunData.vue`) |
| NDV-18 | R3 §7 (read-only run view) | R3 + AP (`flow-step-input-output.tsx`) |
| NDV-19 | `EUI/features/ndv/panel/components/NDVFloatingNodes.vue` (edge-centred lists, gap sm, padding xs, radius lg, scale 0.8 → 1.1, 0.2s ease-out-expo curve); 22-step-modal | SRC + PIX (≈40px chip at the frame edge) |
| NDV-20 | R3 §7 | R3 + AP |
| NDV-21 | — | AP (`BUILDER/index.tsx`, `step-settings/`, `data-selector/`, `step-data/`) |
| PCK-01 | `EUI/features/shared/nodeCreator/components/NodeCreator.vue` (fixed, top header height, width 385, narrow rule, close button); `EUI/app/css/_variables.scss` (node-creator width 385); 23-piece-panel(.dark) | SRC + PIX (panel starts at x=1055 = 385px wide, below the 65px header) |
| PCK-02 | R3 §6 (transform from 100%, 200ms ease) | R3 |
| PCK-03 | `EUI/features/shared/nodeCreator/components/Panel/NodesListPanel.vue` (.header sm padding, lg bold title, sm subtitle, hasBg band + border); 23-piece-panel(.dark) | SRC + PIX (band 54px, #f5f5f5 / #444444, divider #e5e5e5 / #323232). Strings = DEC |
| PCK-04 | `EUI/features/shared/nodeCreator/components/Panel/SearchBar.vue` (40px, margin sm, radius 4, border, focus secondary, prefix active primary, drop-shadow); 23-piece-panel | SRC + PIX (box y 136–175, focus border #7f22fe). Test id = AP |
| PCK-05 | `EUI/features/shared/nodeCreator/views/viewsData.ts` (root categories concept); 23-piece-panel | VIS (structure only); rows, icons, titles = AP (`pieces-selector/index.tsx` `getTabsList`); descriptions = DEC |
| PCK-06 | `DS/components/N8nNodeCreatorNode/NodeCreatorNode.vue` (padding xs/2xs, name sm/500, description 2xs, line-heights, trailing arrow colours, trigger icon primary, disabled 0.45) | SRC + PIX (76px two-line row) |
| PCK-07 | `EUI/features/shared/nodeCreator/components/ItemTypes/CategoryItem.vue` (sm bold, padding 2xs sm, bottom border) | SRC |
| PCK-08 | `ItemTypes/LabelItem.vue` (10px bold uppercase, 1px spacing, margins); `Renderers/ItemsRenderer.vue` (separator inset sm, margin-top sm, padding-top xs) | SRC + PIX (separator x 1072–1423) |
| PCK-09 | `Renderers/ItemsRenderer.vue` (2px left border, hover text tint-1, active primary); `EUI/app/css/_variables.scss` | SRC + PIX (2px #ff6900 bar at x 1055–1056) |
| PCK-10 | `Panel/NodesListPanel.vue` (panel-slide-in / slide-out 200ms ease) | SRC |
| PCK-11 | — | AP (`pieces-card-list.tsx`, `piece-card-item.tsx`) + e2e page objects |
| PCK-12 | R3 §6 (openers) | R3 + AP (`piece-selector-state.ts`, design doc §4) |
| PCK-13 | — | AP (`handleAddingOrUpdatingStep`, `selectStepAfter`) + DEC |
| LOG-01 | `EUI/features/execution/logs/components/LogsPanel.vue` (.resizeWrapper border-top, background light-2); 25-logs-open(.dark) | SRC + PIX |
| LOG-02 | `LogsPanel.vue` (--logs-panel--header-height = height lg); `LogsPanelHeader.vue`; 02-canvas-empty, 10-linear-idle | SRC + PIX (collapsed bar y 864–899 = 36px). Plan value 32px differs (`useLogsPanelLayout.ts` COLLAPSED_PANEL_HEIGHT 32 is not the drawn height) |
| LOG-03 | `EUI/features/execution/logs/composables/useLogsPanelLayout.ts` (default 0.3, min 160, max 0.75, allowCollapse, localStorage) | SRC |
| LOG-04 | `useLogsPanelLayout.ts` (overview default min(240, 20%), min 80, max 500, allowFullSize); `LogsPanelHeader.vue` (2xs font, padding 2xs, border) | SRC |
| LOG-05 | 25-logs-open, 11-*-after-run (header "Logs" + clear button, summary line) | VIS + PIX; texts = AP (`run-info-widget.tsx`) |
| LOG-06 | `EUI/features/execution/logs/components/LogsOverviewRow.vue` (padding 2xs, radius, selected foreground, hover light-1, selected error callout bg, time column 20%); 25-logs-open(.dark) | SRC + PIX (selected row #e5e5e5 / #323232, 33px) |
| LOG-07 | `LogsOverviewRow.vue` (indent 32px per depth, connector 2px dot colour, curved radius lg) | SRC; iteration grouping = AP + DEC |
| LOG-08 | `EUI/features/execution/logs/components/LogDetailsPanel.vue` (xsmall subtle toggles, pressed state, 16px icon, input resizer); 25-logs-open(.dark) | SRC + PIX (Output pressed #e5e5e5 light; ≈#5c2f10 dark → "accent at 25%") |
| LOG-09 | `CANV/Canvas.vue` keyMap (l / i / o) | SRC |
| LOG-10 | — | AP (`run-state.ts` live follow) |
| LOG-11 | — | AP (`run-list/`, `routes/runs/id`) |
| LOG-12 | — | DEC (+ e2e constraint from `tests-e2e/pages/builder.page.ts`) |

## Values not verified

- Grid dot exact radius (library default; measured as a 1px dot at 100% zoom).
- Selection rectangle colours and the zoom step factor (library defaults, shared by Vue Flow and React Flow).
- Bézier curvature 0.25 (library default).
- Compact view-mode threshold (400px) in NDV-12 — writer's proposal.
- Parameter label size (13px) is from the screenshot; the size prop chain in source was not fully traced.
- Dark-mode colours for the minimap border, the step-modal schema pill border and the logs failed-row fill were not sampled (no dark screenshot shows them); values given are Tailwind choices.
- Live drag-line timing (EDG-08) and the 8px resize step (NDV-05) come from r3 and were not re-read.
