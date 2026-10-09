# Activepieces web UI map (builder-facing)

Map of where the Activepieces (AP) visual layer lives in the fork, as of `main` @ `518ae7091c` (2026-10-09).
AP is MIT outside `packages/ee/` and `packages/server/api/src/app/ee/`. This file holds no n8n material.

`WEB` = `iphi-flow/activepieces/packages/web`, `BUILDER` = `WEB/src/app/builder`.

Two AP docs are stale — trust the code:
- `packages/web/CLAUDE.md` says React 18; the app is on **React 19**.
- `.agents/skills/design/SKILL.md` says brand purple `#8142E3` and a `.dark` class; the real default is `#6e41e2` and dark mode uses `[data-theme='dark']`.

## 1. Stack
| Area | What |
|---|---|
| React | 19 (lock 19.2.5); React Router 6.11.2 |
| Build | Vite 6.4.3, `@vitejs/plugin-react`, `@tailwindcss/vite`; `WEB/vite.config.mts`; dev port 4200, `/api` → :3000 |
| Styling | Tailwind CSS v4.1.17, **no config file**: theme via `@theme` / `@theme inline` in `WEB/src/styles.css`; `tw-animate-css`, `class-variance-authority`, `clsx` + `tailwind-merge` (`cn()` in `WEB/src/lib/utils.ts`) |
| Components | shadcn/ui "new-york", via `radix-ui` 1.4.3 (`WEB/components.json`); cmdk, vaul, sonner, react-resizable-panels 4.7, react-day-picker, embla, recharts, input-otp |
| Icons | `lucide-react` 0.576.0 + animated wrappers in `WEB/src/components/icons/` |
| Fonts | self-hosted in `WEB/src/assets/fonts/`: Inter variable (sans), JetBrains Mono (mono), Sentient (serif); embedded mode can swap body font (`WEB/src/app/components/embedding-font-loader.tsx`) |
| Dark mode | `@custom-variant dark` on `[data-theme='dark']`; `WEB/src/components/providers/theme-provider.tsx` sets `data-theme` on `<html>`; subtree "islands" use `data-theme="light"|"dark"` |
| Other | `@xyflow/react` 12.3.5, `@dnd-kit`, `motion` 12, Tiptap 3, CodeMirror 6, shiki, react-data-grid |

## 2. Theming
- `WEB/src/styles.css` (≈1257 lines): `@theme inline` colour mapping, `@theme` (radius, fonts, shadows, animations), `:root, [data-theme='light']` and `[data-theme='dark']` blocks, React Flow overrides, Tiptap/auth-animation/shiki CSS.
- `WEB/src/styles/globals.css`: formula badges + CodeMirror reset. `WEB/src/app/routes/tables/id/react-data-grid.css`: tables grid.
- AP design-system docs: `iphi-flow/activepieces/brain/knowledge/design-system/colour.md`, `index.md`.

Colour architecture — five 12-step scales, utilities like `bg-gray-3`, `text-accent-11`, `border-danger-7`:

| Token | Light | Dark |
|---|---|---|
| `--gray-1..12` | `oklch(L 0 0)` with L = 99.3, 98.2, 97, 95.5, 93.8, 92.2, 88.5, 74, 63, 57, 52, 16 % | 11, 16.2, 19.5, 23.5, 27.5, 32, 39, 50, 60, 66, 84.8, 97 % |
| `--accent-1..12` | `var(--accent-light-N, <default>)`, default violet, step 9 `#6e41e2` | `var(--accent-dark-N, …)` |
| `--success-1..12` | step 9 `#00a63e` | same pattern |
| `--warning-1..12` | step 9 `#fe9a00` | same pattern |
| `--danger-1..12` | step 9 `#e7000b` | same pattern |
| Named | `--panel` (light white, dark `var(--gray-2)`), `--on-accent: #fff`, `--on-success/-warning/-danger`, `--scrim: oklch(0% 0 0 / 70%)` | |
| Categorical | `--swatch-1..12-{mark,surface,ink,line,on}`; `--chart-1..5` → swatches 1, 5, 9, 3, 7 | |

Step meaning (team rule): 1 app background · 2 sidebar and flow canvas · 3–5 component background / hover / pressed · 6 divider · 7 component border · 8 strong border and focus ring · 9 solid fill · 10 small marks · 11 quiet text · 12 main text. `body` = `bg-gray-1 text-gray-12`; base border `gray-6`.

Radius (`@theme`, `--radius: 0.5rem`): `--radius-lg: 0.75rem`, `--radius-md: calc(var(--radius) - 2px)`, `--radius-sm: calc(var(--radius) - 4px)`, `--radius-xs: calc(var(--radius) - 8px)`, `--radius-xss: calc(var(--radius) - 10px)` (negative).

Shadows: `--shadow-step-container`, `--shadow-add-button`, `--shadow-edge`, `--shadow-panel`, `--shadow-rest`, `--shadow-lift`, `--shadow-over`, `--shadow-glow-primary` — each points at a per-theme plain variable (`--rest`, `--lift`, …) built from `--cast-06/08/10/20`. The indirection is required: Tailwind copies `--shadow-*` literally, so a direct dark override would not apply.

Type: `--text-xss: 0.65rem`, `--text-3xl: 1.75rem`, `--text-4xl: 2rem`; body default `text-sm`.

White-label runtime:
- Server: `packages/server/api/src/app/ee/helper/appearance-helper.ts` (CE → `defaultTheme`; Cloud → platform branding; EE → if `platform.plan.customAppearanceEnabled`). `defaultTheme` / `generateTheme` in `packages/server/api/src/app/flags/theme.ts` (primary `#6e41e2`), served as flag `ApFlagId.THEME`.
- Client: `flagsHooks.useWebsiteBranding()` (`WEB/src/hooks/flags-hooks.ts`) → `ThemeProvider` sets title + favicon and calls `brandSeed.apply({ primaryColor, statusColors })`.
- **`WEB/src/lib/brand-seed.ts`** writes `--accent-light-N` / `--accent-dark-N` (+ status, `--on-accent`, `--on-*-seed`) inline on `<html>`.
- Ramp generator: `brandColors.ramp` in `packages/core/shared/src/lib/core/common/brand-colors.ts` (`DEFAULT_ACCENT_SOLID = '#6e41e2'`).
- Admin preview: `WEB/src/app/routes/platform/setup/general/appearance-section.tsx`, `color-preview.tsx`.
- Logos: `WEB/src/components/custom/full-logo.tsx`, `activepieces-wordmark.tsx`, `logo-plate.tsx` (tint via `WEB/src/lib/logo-tint.ts`).

Guardrails:
- `WEB/scripts/check-tailwind-classes.mjs` (in `npm run lint`) fails on classes Tailwind cannot generate and on `var(--x)` nothing defines.
- `WEB/test/styles/status-scales.test.ts` fails if CSS default ramps drift from the generator.
- No `dark:` colour utilities outside `styles.css` and `components/ui/`.

## 3. Primitives
`WEB/src/components/ui/` — 46 files: accordion, alert, avatar, badge, breadcrumb, button, calendar, card, carousel, chart, checkbox, collapsible, command, context-menu, dialog, drawer, dropdown-menu, empty, form, hover-card, input-otp, input, item, label, popover, progress, radio-group, resizable-panel, scroll-area, select, separator, sheet, sidebar-shadcn, skeleton, slider, sonner, sortable, switch, table, tabs, text-shimmer, textarea, toggle, tooltip, virtualized-list, virtualized-scroll-area.
- Button (cva): variants default (`bg-accent-9 text-on-accent`), basic, secondary, destructive, outline, accent, ghost, link, transparent; sizes default `h-9`, xs, sm, lg, xl, icon, icon-xs, icon-sm, icon-lg; base `rounded-md text-sm font-normal`.
- Card `rounded-lg border bg-gray-1`. Sidebar width `15rem`, icon width `3rem`, hover-expand mode.
- `WEB/src/components/custom/` (87 tsx): `data-table/`, `page-header.tsx`, `logo-plate.tsx`, `searchable-select.tsx`, `json-viewer.tsx`, `smart-output-viewer/`, `markdown-input/`, `clipboard/`, `ap-error-dialog/`, `spinner.tsx`, `status-icon-with-text.tsx`, `text-with-tooltip.tsx`, `user-avatar.tsx`, `dot.tsx`, `data-fetch-error-state.tsx`. Also `prompt-kit/` (11), `icons/` (38), `providers/`.

## 4. App shell
- Entry: `WEB/src/main.tsx` → `WEB/src/app/app.tsx` (QueryClient → Embedding → InitialDataGuard → Tooltip → ThemeProvider → router + bottom-right Toaster).
- Routes: `WEB/src/app/guards/index.tsx`, `WEB/src/app/routes/{project-routes,auth-routes,platform-routes,public-routes}.tsx`.
- Dashboard layout: `WEB/src/app/components/project-layout/` (`index.tsx` ProjectDashboardLayout, `project-dashboard-layout-header.tsx`, `project-dashboard-page-header.tsx`).
- Builder layout: `WEB/src/app/components/builder-layout/index.tsx` — rail + content card `rounded-xl shadow-panel border`, `p-1.5` inset on `bg-gray-2`.
- Left navigation: `WEB/src/app/components/primary-rail/index.tsx` (808 lines): `bg-gray-2`, `w-62` open / `w-14` collapsed; `RailHeader`, `RailNavButton`, `RailPinnedProjects` / `ProjectRow`, `RailPlatformAdminButton`, `RailAccountRow`. Related: `WEB/src/app/components/sidebar/`, `platform-layout.tsx`.
- Project/platform switching: `WEB/src/features/projects/components/{projects-selector,platform-switcher,ap-project-display}.tsx`, `WEB/src/app/components/project-avatar.tsx`.
- Page header `WEB/src/components/custom/page-header.tsx` (sticky, `bg-gray-1`); `WEB/src/app/components/dashboard-page-header.tsx`; global search `WEB/src/app/components/global-search/`; settings `WEB/src/app/components/settings-hub/`; theme toggle `WEB/src/app/components/account-settings/theme-toggle.tsx`.
- Flows list ("automations"): `WEB/src/app/routes/automations/index.tsx` + `WEB/src/features/automations/components/` (custom table, filters, pagination, selection bar, empty state, create menu). `/flows` and `/tables` redirect here.
- Runs: `WEB/src/app/routes/runs/index.tsx`, `WEB/src/features/flow-runs/components/runs-table/` (DataTable + `runs-status-chart.tsx`); run detail `WEB/src/app/routes/runs/id/index.tsx` reuses `BuilderPage` read-only.
- Connections: `WEB/src/app/routes/connections/index.tsx`, `WEB/src/app/connections/`, `WEB/src/features/connections/components/`.
- Tables: `WEB/src/app/routes/tables/id/`, `WEB/src/features/tables/components/`.
- Auth: `WEB/src/app/routes/{sign-in,sign-up}/index.tsx` (thin) → `WEB/src/features/authentication/components/auth-landing/` (`auth-landing.tsx`, animated `auth-backdrop.tsx`, `auth-drawer-body.tsx` 1143 lines, `turnstile-widget.tsx`), `sign-in-form.tsx`, `sign-up-form.tsx`, `third-party-logins.tsx`; `.auth-anim-*` CSS in `styles.css`.

## 5. Flow builder
- Route `WEB/src/app/routes/flows/id/index.tsx` → `ReactFlowProvider` → `BuilderStateProvider` → `BuilderPage` (`BUILDER/index.tsx`): `BuilderHeader`; horizontal `ResizablePanelGroup` with canvas panel (`FlowCanvas`, `BuilderBanner`, `CanvasControls`, `ShowPoweredBy`, `DataSelector`) and right panel (step settings, `RunsList` or `FlowVersionsList`, default 25%, min 400px); `ChatDrawer`.
- State (Zustand): `BUILDER/state/` (`builder-state-provider.tsx`, `canvas-state.ts` — orientation in localStorage `ap.builder.canvasOrientation`, `flow-state.ts`, `run-state.ts`, `piece-selector-state.ts`, `step-form-state.ts`, `notes-state.tsx`, `chat-state.ts`); hooks `BUILDER/builder-hooks.ts`; shortcuts `BUILDER/shortcuts.ts`.
- Canvas `BUILDER/flow-canvas/index.tsx`: imports `@xyflow/react/dist/style.css`; nodes not draggable/connectable; zoom 0.5–1.5; pan on scroll; `BackgroundVariant.Dots` gap 10 size 1, bg `var(--gray-2)`, dots `var(--gray-8)`; React Flow overrides in `styles.css` `@layer utilities` (edge stroke `--xy-edge-stroke: var(--gray-7)`, selection box, hidden attribution). dnd-kit step drag: `BUILDER/flow-canvas/flow-drag-layer.tsx`. Context menu `BUILDER/flow-canvas/context-menu/`.
- Nodes `BUILDER/flow-canvas/nodes/`: `step-node/index.tsx` (one `ApStepCanvasNode` for every step type) + `step-node-logo.tsx`, `step-node-display-name.tsx`, `step-node-chevron.tsx`, `trigger-widget.tsx`, `step-node-status-in-run.tsx`, `step-node-status-in-draft.tsx`, `step-node-skipped-status.tsx`, `step-node-badge-container.tsx`, `step-node-run-duration-and-piece-name.tsx`, `step-drag-overlay.tsx`; `big-add-button-node.tsx`; `loop-return-node.tsx`; `flow-end-widget-node.tsx`; `note-node/`. Registry `BUILDER/flow-canvas/utils/consts.ts`.
- Edges `BUILDER/flow-canvas/edges/`: `straight-line-edge.tsx`, `loop-start-edge.tsx`, `loop-return-edge.tsx`, `router-start-edge.tsx`, `router-end-edge.tsx` (hand-built SVG via `BaseEdge`, 15px arcs, hand-drawn arrowhead, stroke 1.5); `add-button.tsx` (20×20 `foreignObject`, `data-testid="add-action-button"`); `branch-label.tsx`; `use-edge-layout-space.ts`; `BUILDER/flow-canvas/utils/svg-path-utils.ts`.
- Layout: own fixed tree layout in `BUILDER/flow-canvas/utils/flow-canvas-utils.ts` (729 lines: `buildFlowGraph`, `buildLoopChildGraph`, `buildRouterChildGraph`, `buildContinueOnFailureBranchesGraph`, `calculateGraphBoundingBox`, `offsetRouterChildSteps`, `createFlowGraph`); always top-to-bottom, `transposeGraphPositions` mirrors for horizontal; spacing `BUILDER/flow-canvas/utils/layout-consts.ts` (`ORIENTATION_LAYOUT`); base sizes in `packages/core/execution/src/lib/flows/util/flow-canvas-util.ts` (also used server-side by `flowCanvasUtils.computeStepPositions` in `packages/server/api/src/app/mcp/tools/ap-flow-structure.ts`); PNG export `flow-screenshot-utils.ts`.
- Controls `BUILDER/flow-canvas/canvas-controls/` (`index.tsx`, `canvas-control-button.tsx`, `use-fit-to-view.ts`): bottom bar `bg-gray-1 border border-gray-6 rounded-lg`; minimap toggle, zoom in/out, fit, download image, vertical/horizontal toggle, grab mode, select mode, add note. Minimap `BUILDER/flow-canvas/widgets/minimap.tsx` (blocks filled with each logo's average colour).
- Widgets `BUILDER/flow-canvas/widgets/`: `test-flow-widget.tsx` + `above-trigger-button.tsx` (Test Flow / Run Flow / Open Chat above the trigger); `builder-banner.tsx` (one of `publish-flow-reminder-widget.tsx` — **the Publish button lives here** inside `large-widget-wrapper.tsx` — `flow-approval-banner.tsx`, `viewing-old-version-widget.tsx`, `run-info-widget.tsx`, resource lock); `incomplete-settings-widget.tsx`, `required-actions-dialog.tsx`, `selection-chevron-button.tsx`.
- Header `BUILDER/builder-header/builder-header.tsx`: breadcrumb (project / folder / editable name + `FlowActionMenu`); right: support, active users, "Runs" button, `BuilderFlowStatusSection` (`flow-status/index.tsx`), created-by badge; wraps `PageHeader`; `BUILDER_HEADER_HEIGHT: 60`; inline style `` height: `$${...}px` `` is an invalid value (bug).
- Step settings `BUILDER/step-settings/index.tsx` (487 lines) + `BUILDER/sidebar-header.tsx`, `editable-step-name.tsx`, `step-navigation-buttons.tsx`; subfolders `piece-settings/` (`connection-select.tsx`), `code-settings/`, `loops-settings.tsx`, `router-settings/`, `branch-settings/`, `ai-router-settings/`, `agent-settings/`, `update-piece-version-dialog/`.
- Inputs `BUILDER/piece-properties/` (~35 files: `generic-properties-form.tsx`, `auto-form-field-wrapper.tsx`, dynamic/array properties, `text-input-with-mentions/` Tiptap mapping input).
- Test step `BUILDER/test-step/` (`test-step-cta-button.tsx` `data-testid="test-trigger-button"`, `test-action-section.tsx`, `test-trigger-section/`, `test-sample-data-viewer.tsx`).
- Step data `BUILDER/step-data/` (`step-data-panel-host.tsx`, `step-data-panel-header.tsx`, view toggle) + `BUILDER/data-display/` (`data-display-tabs.tsx`, `friendly-error-view.tsx`).
- Data selector `BUILDER/data-selector/` (`index.tsx` 492 lines, `data-selector-node.tsx`, `data-selector-node-content.tsx`, size togglers, `variables-tab.tsx`), floating over the canvas.
- Piece selector `BUILDER/pieces-selector/` (`index.tsx` Radix Popover `w-[340px] md:w-[600px]`, `pieces-card-list.tsx`, `piece-card-item.tsx` `data-testid={displayName}`, `piece-actions-or-triggers-list.tsx`, `generic-piece-selector-item.tsx`, `explore-tab-content.tsx`, `ai-tab-content/`, `approvals-tab-content.tsx`, `no-results-found.tsx`) + `WEB/src/features/pieces/components/{piece-selector-tabs,piece-selector-search,piece-icon}.tsx` (`data-testid="pieces-search-input"`).
- Runs `BUILDER/run-list/` (`index.tsx`, `flow-run-card.tsx`); run details `BUILDER/run-details/` (`flow-step-input-output.tsx`, `loop-iteration-input.tsx`, `ai-router-routes.tsx`); versions `BUILDER/flow-versions/`.

## 6. Current node look
- Sizes: `FLOW_CANVAS_STEP_HEIGHT 60`, `FLOW_CANVAS_STEP_WIDTH 232`, `FLOW_CANVAS_VSPACE 60`, `FLOW_CANVAS_ARC 15`, `FLOW_CANVAS_HSPACE 80`; loop offset 120, router 150; horizontal mode 80×80 steps, 80px apart, 150px label below; add button 20×20; big add 50×50; edge line 1.5.
- Node card `rounded-md border border-solid border-gray-6 bg-gray-1`, hover `border-gray-8`, selected `border-accent-9`, skipped `bg-gray-4`; trigger `rounded-tl-none` with a "Trigger" tab above; no shadow; contents logo → "N. Display name" + piece name → chevron.
- Logo: `LogoPlate` `rounded-lg border-gray-6/50`, `size-9 p-2` vertical / `size-12 p-2.5` horizontal.
- Status pill above top-right (`absolute -top-[28px] right-[1px]`); classes `flowRunUtils.getStatusContainerClassName` (`WEB/src/features/flow-runs/utils/flow-run-utils.ts`); icons `StepStatusIcon` (`WEB/src/features/flow-runs/components/step-status-icon.tsx`); drafts show `InvalidStepIcon` / `TriangleAlert`.

## 7. Tests touching the UI
- No Storybook, no visual snapshot tests.
- Playwright `packages/tests-e2e/` (1.54.1, Checkly): page objects `pages/builder.page.ts`, `automations.page.ts`, `authentication.page.ts`; scenarios `scenarios/ce|ee/`. Depends on: `rf__node-trigger` with text "Select Trigger", `pieces-search-input`, `add-action-button`, `test-trigger-button`, piece display-name test ids, button names "Test Flow", "Test Step Ctrl + G", "Publish", "Dismiss", texts "Run Succeeded" / "Load Sample data", link "Automations", "Create New" → "New Flow", `button:has(svg.lucide-more-horizontal)`, `sign-in-*` / `sign-up-*` / `auth-*` ids.
- Vitest: 135 files in `WEB/test/` (30 under `WEB/test/app/builder/`). Layout-sensitive: `flow-canvas/utils/flow-canvas-utils.test.ts`, `layout-consts.test.ts`, `svg-path-utils.test.ts`, `nodes/step-node/step-drag-overlay.test.tsx`, `nodes/note-node/note-drag-overlay.test.tsx`. Also `WEB/test/styles/status-scales.test.ts`, `WEB/test/lib/brand-seed.test.ts`, `WEB/test/components/custom/logo-plate.test.tsx`, `WEB/test/app/routes/platform/setup/general/appearance-section.test.tsx`. Three tests live in `src/`: `BUILDER/data-display/explanation-prompt.test.ts`, `BUILDER/data-selector/path-helpers.test.ts`, `utils-schema.test.ts`.

## 8. Size
| Scope | .tsx | Other |
|---|---|---|
| BUILDER | 156 (~25.4k lines) | 39 .ts |
| WEB/src | 879 (~137.5k lines) | 331 .ts, 3 .css |
| routes / features / custom / app components / ui / prompt-kit | 267 / 191 / 87 / 55 / 46 / 11 | |
