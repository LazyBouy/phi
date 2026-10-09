# n8n-vibe spec — index

## Purpose

This spec tells the build team how to make the Activepieces (AP) web app look and feel like the reference workflow product (n8n) without copying anything from it.

- It is written by the reference lane, which may look at the reference product.
- It holds only facts in our own words: sizes in px, colours as hex (taken from the Tailwind CSS v4 default palette, MIT, wherever Tailwind has the value), durations in ms, easing numbers, layout, states and behaviour.
- It is the only input the build lane needs besides the AP code. The build lane never opens the reference product.

## How to read it

| File | Prefix | Covers |
|---|---|---|
| `01-tokens.md` | TOK | Colour scales (grey, accent, success, warning, danger), named exceptions, focus ring, radius, shadows, fonts, type ramp, weights, spacing, control heights, borders, z-index layers, breakpoints, the hard-coded palette, the contrast ledger |
| `02-primitives.md` | PRM | Every shared primitive in `packages/web/src/components/ui/` plus the data table, with sizes, colours by AP step, every state, and the variant mapping |
| `03-shell.md` | SHL | Sidebar, the 64px header, page layout |
| `04-pages.md` | PAG | Automations list, runs, connections, tables, settings, empty states, auth |
| `05-canvas.md` | CAN | Canvas background, viewport, controls, minimap, toolbars, test bar, empty placeholder, keyboard |
| `06-graph.md` | NOD, HDL, EDG | Nodes, handles and plus-stubs, edges |
| `07-step-modal.md` | NDV | The three-pane step editor |
| `08-piece-panel.md` | PCK | The right slide-in piece selector |
| `09-logs.md` | LOG | The bottom run and logs panel |
| `10-motion.md` | MOT | Shared durations and easings, and the motion of every primitive |

Reading order for a builder:

1. TOK first. Every other file names colours by AP step (for example `accent-9`, `gray-6`) and sizes by AP utility (for example `h-8`, `rounded-lg`). TOK says what value each of those has after the change.
2. Then the file for the phase being built.
3. MOT for anything that moves.

Every requirement is a block:

- A heading `### <ID> — <title>`.
- Then a short table or bullets with: Values · States · Light/Dark · AP target (file path under `iphi-flow/activepieces`) · Notes.

Words used throughout:

- **Target** means the look being reproduced.
- **Step** means a position 1–12 on one of AP's five colour scales, exactly as in AP's `brain/knowledge/design-system/colour.md`.
- **Light island / dark island** means AP's existing mechanism: an element that carries AP's theme attribute so that the steps inside it resolve to one theme whatever the page theme is (as `LogoPlate` does today).
- **Panel** means AP's `--panel` exception: the raised surface (cards, menus, dialogs).
- **Subtle text** means the ink `text-gray-12/87` defined in TOK-03.

## ID scheme

- An ID is a prefix, a hyphen and a two-digit number: `TOK-07`, `PRM-12`, `MOT-05`.
- Numbers are never reused. A requirement that is dropped keeps its number with the word "Withdrawn".
- A cross-reference names the ID, for example "see TOK-11 (focus recipe B)". When the referenced block lives in a file written by another writer and its number is not fixed yet, the reference names the prefix and the subject, for example "CAN (minimap)".
- Build commits cite the IDs they implement, for example `SPEC TOK-02, TOK-04`.

| Prefix | File | Subject |
|---|---|---|
| TOK | 01-tokens.md | Design tokens |
| PRM | 02-primitives.md | Shared primitives |
| MOT | 10-motion.md | Motion |
| SHL | 03-shell.md | App shell |
| PAG | 04-pages.md | Dashboard pages and auth |
| CAN | 05-canvas.md | Canvas chrome |
| NOD | 06-graph.md | Nodes |
| HDL | 06-graph.md | Handles and plus-stubs |
| EDG | 06-graph.md | Edges |
| NDV | 07-step-modal.md | Step modal |
| PCK | 08-piece-panel.md | Piece panel |
| LOG | 09-logs.md | Logs panel |

## Clean-room rules for builders

- Work only from this spec and the AP code. Never open, search or fetch the reference product's code, assets or site.
- Write every value yourself from the numbers in this spec. Do not paste CSS, SVG or text from anywhere outside AP.
- Keep AP's token names, variant names and size names. Change values, not names. New names are added only where this spec says so.
- Colours come from AP steps and the named exceptions in TOK-08. Raw colour is allowed only where AP's colour rules already allow it (shadows, the cases listed in `colour.md`) or where this spec states it.
- Icons come from `lucide-react`. Any glyph that Lucide does not have is drawn from scratch.
- Fonts come from their upstream releases: Inter (already in AP) and Commit Mono (TOK-14).
- All user-facing text stays AP's own words through i18n keys.
- Cite the spec IDs in every build commit.

## NEVER USE

- The n8n name or logo, anywhere in code, assets, copy, comments, test ids or file names.
- The reference product's node icons, its custom icon artwork and its integration icons.
- The reference product's illustrations and image assets.
- The coral `#ff6d5a` (the reference logo colour). The brand orange is Tailwind orange-500 `#ff6900`.
- The reference product's AI-assistant gradient (a three-stop blue-violet-to-pink gradient) or any look-alike of it.
- The reference product's UI copy. AP keeps its own wording, for example "Test flow".

## Spec ID → AP file map

Generated by `iphi-flow/tools/spec-index.mjs` from the requirement blocks (214 requirements in 10 files). Re-run it after any spec edit. Paths are relative to the AP fork; `WEB` = `packages/web`, `BUILDER` = `WEB/src/app/builder`.

| ID | Requirement | Spec file | AP target |
|---|---|---|---|
| TOK-01 | What changes, and where | `01-tokens.md` | `packages/web/src/styles.css`, `packages/core/shared/src/lib/core/common/brand-colors.ts`, `packages/web/src/lib/brand-seed.ts`, `packages/server/api/src/app/flags/theme.ts`, `packages/web/src/app/routes/platform/setup/general/appearance-section.tsx`, `color-preview.tsx` |
| TOK-02 | Grey scale | `01-tokens.md` | `packages/web/src/styles.css` |
| TOK-03 | Text tiers | `01-tokens.md` | `02-primitives.md` |
| TOK-04 | Accent scale (brand orange) | `01-tokens.md` | `styles.css` |
| TOK-05 | Success scale (green) | `01-tokens.md` | `styles.css` |
| TOK-06 | Warning scale (yellow, standing in for the target's gold) | `01-tokens.md` | `styles.css`, `brand-colors.ts` |
| TOK-07 | Danger scale (red) | `01-tokens.md` | `styles.css` |
| TOK-08 | Named exceptions | `01-tokens.md` | `styles.css` |
| TOK-09 | Hard-coded palette and the ramp generator | `01-tokens.md` | `packages/core/shared/src/lib/core/common/brand-colors.ts`, `packages/server/api/src/app/flags/theme.ts`, `packages/web/src/lib/brand-seed.ts`, `packages/web/src/app/routes/platform/setup/general/appearance-section.tsx`, `packages/web/src/app/routes/platform/setup/general/color-preview.tsx`, `packages/web/src/styles.css`, `packages/web/test/styles/status-scales.test.ts`, `packages/web/test/lib/brand-seed.test.ts`, `packages/core/shared/package.json` |
| TOK-10 | Swatches and charts | `01-tokens.md` | `styles.css` |
| TOK-11 | Focus ring | `01-tokens.md` | `packages/web/src/components/ui/` |
| TOK-12 | Radius | `01-tokens.md` | `styles.css` |
| TOK-13 | Shadows | `01-tokens.md` | `styles.css`, `--cast-06/08/10/20` |
| TOK-14 | Font families | `01-tokens.md` | `styles.css` |
| TOK-15 | Type ramp | `01-tokens.md` | `styles.css` |
| TOK-16 | Font weights | `01-tokens.md` | `styles.css` |
| TOK-17 | Spacing | `01-tokens.md` | No token change |
| TOK-18 | Control heights and icon sizes | `01-tokens.md` | — |
| TOK-19 | Borders and disabled opacity | `01-tokens.md` | — |
| TOK-20 | Z-index layers | `01-tokens.md` | `z-*` utilities in the primitives; Tailwind v4 accepts any integer, so no theme key is needed |
| TOK-21 | Breakpoints | `01-tokens.md` | No change |
| TOK-22 | Contrast ledger | `01-tokens.md` | — |
| TOK-23 | AP colour documentation | `01-tokens.md` | `brain/knowledge/design-system/colour.md`, `index.md` |
| PRM-01 | Button | `02-primitives.md` | `components/ui/button.tsx` |
| PRM-02 | Icon button | `02-primitives.md` | `components/ui/button.tsx` |
| PRM-03 | Input | `02-primitives.md` | `components/ui/input.tsx` |
| PRM-04 | Textarea | `02-primitives.md` | `components/ui/textarea.tsx` |
| PRM-05 | Select (trigger, panel, option) | `02-primitives.md` | `components/ui/select.tsx`, `components/custom/searchable-select.tsx`, `components/ui/command.tsx` |
| PRM-06 | Tabs (underline) | `02-primitives.md` | `components/ui/tabs.tsx` |
| PRM-07 | Segmented control (new) | `02-primitives.md` | `components/ui/segmented-control.tsx`, `components/ui/tabs.tsx` |
| PRM-08 | Tooltip | `02-primitives.md` | `components/ui/tooltip.tsx` |
| PRM-09 | Dropdown menu and context menu | `02-primitives.md` | `components/ui/dropdown-menu.tsx`, `components/ui/context-menu.tsx`, `components/ui/command.tsx` |
| PRM-10 | Popover (and hover card) | `02-primitives.md` | `components/ui/popover.tsx`, `components/ui/hover-card.tsx` |
| PRM-11 | Dialog | `02-primitives.md` | `components/ui/dialog.tsx` |
| PRM-12 | Sheet and drawer | `02-primitives.md` | `components/ui/sheet.tsx`, `components/ui/drawer.tsx` |
| PRM-13 | Badge | `02-primitives.md` | `components/ui/badge.tsx` |
| PRM-14 | Tag / chip | `02-primitives.md` | `components/ui/badge.tsx`, `features/automations/components/` |
| PRM-15 | Card | `02-primitives.md` | `components/ui/card.tsx` |
| PRM-16 | Table and data table | `02-primitives.md` | `components/ui/table.tsx`, `components/custom/data-table/index.tsx`, `data-table-column-header.tsx`, `data-table-skeleton.tsx`, `data-table-toolbar.tsx` |
| PRM-17 | Switch | `02-primitives.md` | `components/ui/switch.tsx` |
| PRM-18 | Checkbox | `02-primitives.md` | `components/ui/checkbox.tsx` |
| PRM-19 | Radio | `02-primitives.md` | `components/ui/radio-group.tsx` |
| PRM-20 | Callout (AP alert) | `02-primitives.md` | `components/ui/alert.tsx` |
| PRM-21 | Notice banner | `02-primitives.md` | `components/ui/alert.tsx` |
| PRM-22 | Toast (sonner) | `02-primitives.md` | `components/ui/sonner.tsx` |
| PRM-23 | Scrollbar | `02-primitives.md` | `styles.css`, `components/ui/scroll-area.tsx` |
| PRM-24 | Skeleton | `02-primitives.md` | `components/ui/skeleton.tsx`, `components/custom/data-table/data-table-skeleton.tsx` |
| PRM-25 | Empty state | `02-primitives.md` | `components/ui/empty.tsx` |
| PRM-26 | Toggle | `02-primitives.md` | `components/ui/toggle.tsx` |
| PRM-27 | Field label and form messages | `02-primitives.md` | `components/ui/label.tsx`, `components/ui/form.tsx` |
| SHL-01 | Shell frame | `03-shell.md` | `WEB/src/app/components/project-layout/index.tsx`, `WEB/src/app/components/platform-layout.tsx`, `WEB/src/app/components/builder-layout/index.tsx`, `WEB/src/components/custom/route-loading-bar.tsx` |
| SHL-02 | Sidebar container | `03-shell.md` | `WEB/src/app/components/primary-rail/index.tsx`, `WEB/src/features/workspace/lib/rail-collapsed.ts` |
| SHL-03 | Sidebar resize handle | `03-shell.md` | `WEB/src/app/components/primary-rail/index.tsx` |
| SHL-04 | Sidebar header row (expanded) | `03-shell.md` | `WEB/src/app/components/primary-rail/index.tsx`, `WEB/src/features/projects` |
| SHL-05 | Sidebar header (collapsed) | `03-shell.md` | `WEB/src/app/components/primary-rail/index.tsx` |
| SHL-06 | Sidebar create menu | `03-shell.md` | `WEB/src/app/components/primary-rail/index.tsx`, `WEB/src/features/automations/components/create-new-menu.tsx`, `WEB/src/features/automations/hooks/use-automations-mutations.ts`, `WEB/src/features/projects` |
| SHL-07 | Navigation item (base look) | `03-shell.md` | `WEB/src/app/components/primary-rail/index.tsx` |
| SHL-08 | Primary navigation group | `03-shell.md` | `WEB/src/app/components/primary-rail/index.tsx` |
| SHL-09 | Section group: Projects | `03-shell.md` | `WEB/src/app/components/primary-rail/index.tsx` |
| SHL-10 | Usage limits card | `03-shell.md` | `WEB/src/features/billing`, `WEB/src/app/components/primary-rail/index.tsx` |
| SHL-11 | Sidebar bottom block | `03-shell.md` | `WEB/src/app/components/primary-rail/index.tsx` |
| SHL-12 | Bottom-block popovers | `03-shell.md` | `WEB/src/app/components/primary-rail/index.tsx`, `WEB/src/app/components/help-and-feedback.tsx` |
| SHL-13 | Collapsed sidebar behaviour | `03-shell.md` | `WEB/src/app/components/primary-rail/index.tsx` |
| SHL-14 | Sidebar keyboard | `03-shell.md` | `WEB/src/app/components/primary-rail/index.tsx`, `WEB/src/app/components/global-search/global-search-context.tsx` |
| SHL-15 | Platform admin sidebar | `03-shell.md` | `WEB/src/app/components/sidebar/platform/index.tsx`, `WEB/src/app/components/sidebar/ap-sidebar-item.tsx`, `WEB/src/app/components/sidebar/sidebar-user.tsx`, `WEB/src/app/components/platform-layout.tsx` |
| SHL-16 | Dashboard page header | `03-shell.md` | `WEB/src/components/custom/page-header.tsx`, `WEB/src/app/components/dashboard-page-header.tsx`, `WEB/src/app/components/project-layout/project-dashboard-page-header.tsx`, `WEB/src/app/components/project-layout/project-dashboard-layout-header.tsx` |
| SHL-17 | Primary create split button | `03-shell.md` | `WEB/src/app/components/project-layout/project-dashboard-page-header.tsx`, `WEB/src/features/automations/components/create-new-menu.tsx`, `WEB/src/features/automations/components/automations-filters.tsx` |
| SHL-18 | Project tabs row | `03-shell.md` | `WEB/src/app/components/project-layout/project-dashboard-layout-header.tsx`, `WEB/src/components/ui/tabs.tsx` |
| SHL-19 | Builder header frame | `03-shell.md` | `WEB/src/app/builder/builder-header/builder-header.tsx`, `WEB/src/app/builder/flow-canvas/utils/consts.ts`, `WEB/src/app/builder/index.tsx` |
| SHL-20 | Builder header, left: breadcrumb, name and menu | `03-shell.md` | `WEB/src/app/builder/builder-header/builder-header.tsx`, `WEB/src/components/custom/editable-text.tsx`, `WEB/src/app/components/flow-actions-menu.tsx`, `WEB/src/components/ui/breadcrumb.tsx`, `WEB/src/features/flows/components/flow-created-by-badge.tsx` |
| SHL-21 | Builder header, centre: Editor / Runs segmented control | `03-shell.md` | `WEB/src/app/builder/builder-header/builder-header.tsx`, `WEB/src/components/ui/segmented-control.tsx`, `WEB/src/app/builder/builder-header/flow-status/view-draft-or-edit-flow-button.tsx` |
| SHL-22 | Builder header, right: support and collaborators | `03-shell.md` | `WEB/src/app/builder/builder-header/builder-header.tsx`, `WEB/src/components/custom/active-users-widget.tsx` |
| SHL-23 | Publish split button with status dot | `03-shell.md` | `WEB/src/app/builder/builder-header/`, `flow-status/`, `WEB/src/app/builder/flow-canvas/widgets/publish-flow-reminder-widget.tsx`, `WEB/src/app/builder/flow-canvas/widgets/builder-banner.tsx`, `WEB/src/features/flows/components/flow-version-state-dot.tsx` |
| SHL-24 | Flow on/off toggle in the header | `03-shell.md` | `WEB/src/app/builder/builder-header/flow-status/index.tsx`, `WEB/src/features/flows/components/flow-status-toggle.tsx` |
| SHL-25 | Builder layout: full-bleed canvas | `03-shell.md` | `WEB/src/app/components/builder-layout/index.tsx`, `WEB/src/app/builder/index.tsx`, `WEB/src/app/builder/flow-canvas/widgets/builder-banner.tsx` |
| SHL-26 | White-label and embedding invariants | `03-shell.md` | All files listed in this document. |
| PAG-01 | Page container and vertical rhythm | `04-pages.md` | `WEB/src/app/components/project-layout/index.tsx`, `WEB/src/lib/utils.ts`, `WEB/src/components/custom/data-table/data-table-toolbar.tsx` |
| PAG-02 | Automations list: structure | `04-pages.md` | `WEB/src/app/routes/automations/index.tsx`, `WEB/src/features/automations/components/automations-table.tsx`, `WEB/src/features/automations/components/automations-table-row.tsx` |
| PAG-03 | Automations filter row | `04-pages.md` | `WEB/src/features/automations/components/automations-filters.tsx`, `WEB/src/features/automations/components/multi-select-filter.tsx`, `WEB/src/app/routes/automations/index.tsx` |
| PAG-04 | Automations row card: body | `04-pages.md` | `WEB/src/features/automations/components/automations-table-row.tsx`, `WEB/src/features/automations/components/automations-table.tsx` |
| PAG-05 | Automations row card: trailing zone | `04-pages.md` | `WEB/src/features/automations/components/automations-table-row.tsx`, `WEB/src/features/flows/components/flow-status-toggle.tsx`, `WEB/src/components/custom/ap-avatar.tsx` |
| PAG-06 | Automations row card: states | `04-pages.md` | `WEB/src/features/automations/components/automations-table.tsx`, `WEB/src/features/automations/components/automations-table-row.tsx` |
| PAG-07 | Folders in the automations list | `04-pages.md` | `WEB/src/features/automations/components/automations-table.tsx`, `WEB/src/features/automations/components/automations-table-row.tsx` |
| PAG-08 | Bulk selection | `04-pages.md` | `WEB/src/features/automations/components/automations-selection-bar.tsx`, `WEB/src/features/automations/components/automations-table.tsx`, `WEB/src/features/automations/components/automations-filters.tsx`, `WEB/src/components/custom/data-table/data-table-bulk-actions.tsx` |
| PAG-09 | Automations loading, no results, error | `04-pages.md` | `WEB/src/features/automations/components/automations-table.tsx`, `WEB/src/features/automations/components/automations-no-results-state.tsx`, `WEB/src/app/routes/automations/index.tsx` |
| PAG-10 | Pagination row (automations and data tables) | `04-pages.md` | `WEB/src/features/automations/components/automations-pagination.tsx`, `WEB/src/components/custom/data-table/index.tsx` |
| PAG-11 | Create menu content (header split button) | `04-pages.md` | `WEB/src/features/automations/components/create-new-menu.tsx`, `WEB/src/features/automations/components/automations-filters.tsx`, `WEB/src/app/routes/automations/index.tsx` |
| PAG-12 | Data table: container and header | `04-pages.md` | `WEB/src/components/custom/data-table/index.tsx`, `WEB/src/components/ui/table.tsx`, `WEB/src/components/custom/data-table/data-table-column-header.tsx` |
| PAG-13 | Data table: rows and cells | `04-pages.md` | `WEB/src/components/ui/table.tsx`, `WEB/src/components/custom/data-table/index.tsx`, `WEB/src/components/custom/status-icon-with-text.tsx`, `WEB/src/components/custom/data-table/truncated-column-text-value.tsx` |
| PAG-14 | Data table toolbar | `04-pages.md` | `WEB/src/components/custom/data-table/data-table-toolbar.tsx`, `WEB/src/components/custom/data-table/data-table-filter.tsx`, `WEB/src/components/custom/data-table/data-table-select-popover.tsx`, `WEB/src/components/custom/data-table/data-table-input-popover.tsx`, `WEB/src/components/custom/data-table/data-table-checkbox-filter.tsx` |
| PAG-15 | Data table loading | `04-pages.md` | `WEB/src/components/custom/data-table/index.tsx`, `WEB/src/components/custom/data-table/data-table-skeleton.tsx` |
| PAG-16 | Data table empty and error states | `04-pages.md` | `WEB/src/components/custom/data-table/index.tsx`, `WEB/src/components/custom/data-fetch-error-state.tsx` |
| PAG-17 | Runs page | `04-pages.md` | `WEB/src/app/routes/runs/index.tsx`, `WEB/src/features/flow-runs/components/runs-table/index.tsx`, `WEB/src/features/flow-runs/components/runs-table/runs-status-chart.tsx` |
| PAG-18 | Connections page | `04-pages.md` | `WEB/src/app/routes/connections/index.tsx`, `WEB/src/app/connections/`, `WEB/src/features/connections/components/` |
| PAG-19 | Tables: list and editor grid | `04-pages.md` | `WEB/src/app/routes/tables/id/index.tsx`, `WEB/src/app/routes/tables/id/react-data-grid.css`, `WEB/src/features/tables/components/` |
| PAG-20 | Settings and platform admin surfaces | `04-pages.md` | `WEB/src/app/components/project-settings/`, `WEB/src/app/components/account-settings/`, `WEB/src/app/components/settings-hub/`, `WEB/src/app/routes/platform/` |
| PAG-21 | New-project empty state (action cards) | `04-pages.md` | `WEB/src/features/automations/components/automations-empty-state.tsx` |
| PAG-22 | Generic empty state | `04-pages.md` | `WEB/src/components/ui/empty.tsx`, `WEB/src/features/automations/components/automations-no-results-state.tsx`, `WEB/src/app/components/no-projects-state.tsx` |
| PAG-23 | Auth page shell | `04-pages.md` | `WEB/src/features/authentication/components/auth-landing/auth-landing.tsx`, `WEB/src/features/authentication/components/auth-landing/auth-backdrop.tsx`, `WEB/src/styles.css`, `WEB/src/app/routes/forget-password/index.tsx`, `WEB/src/app/routes/change-password/index.tsx`, `WEB/src/features/authentication/components/verify-email.tsx` |
| PAG-24 | Auth card | `04-pages.md` | `WEB/src/features/authentication/components/auth-landing/auth-landing.tsx`, `WEB/src/features/authentication/components/auth-landing/auth-drawer-body.tsx` |
| PAG-25 | Auth form content | `04-pages.md` | `WEB/src/features/authentication/components/sign-in-form.tsx`, `WEB/src/features/authentication/components/sign-up-form.tsx`, `WEB/src/features/authentication/components/third-party-logins.tsx`, `WEB/src/features/authentication/components/auth-landing/auth-drawer-body.tsx`, `WEB/src/features/authentication/components/auth-landing/turnstile-widget.tsx` |
| PAG-26 | Auth steps without a reference counterpart | `04-pages.md` | `WEB/src/features/authentication/components/auth-landing/auth-drawer-body.tsx`, `WEB/src/features/authentication/components/saml-login-form.tsx`, `WEB/src/components/ui/input-otp.tsx` |
| PAG-27 | Forgot password, reset password and verify email pages | `04-pages.md` | `WEB/src/app/routes/forget-password/index.tsx`, `WEB/src/features/authentication/components/reset-password-form.tsx`, `WEB/src/features/authentication/components/change-password.tsx`, `WEB/src/features/authentication/components/verify-email.tsx` |
| CAN-01 | Canvas palette | `05-canvas.md` | `WEB/styles.css` |
| CAN-02 | Background dot grid | `05-canvas.md` | `BUILDER/flow-canvas/index.tsx` |
| CAN-03 | Read-only background (OPTIONAL) | `05-canvas.md` | `BUILDER/flow-canvas/index.tsx` |
| CAN-04 | Viewport limits and zoom steps | `05-canvas.md` | `BUILDER/flow-canvas/index.tsx`, `BUILDER/flow-canvas/canvas-controls/index.tsx` |
| CAN-05 | Fit on load, first appearance, resize | `05-canvas.md` | `BUILDER/flow-canvas/index.tsx`, `BUILDER/flow-canvas/canvas-controls/use-fit-to-view.ts`, `BUILDER/flow-canvas/hooks.tsx` |
| CAN-06 | Pan, zoom, select, cursors | `05-canvas.md` | `BUILDER/flow-canvas/index.tsx`, `BUILDER/state/canvas-state.ts`, `WEB/styles.css` |
| CAN-07 | Selection rectangle and multi-selection box | `05-canvas.md` | `BUILDER/flow-canvas/index.tsx`, `BUILDER/flow-canvas/widgets/selection-chevron-button.tsx`, `WEB/styles.css` |
| CAN-08 | Minimap | `05-canvas.md` | `BUILDER/flow-canvas/widgets/minimap.tsx`, `BUILDER/state/canvas-state.ts`, `BUILDER/shortcuts.ts` |
| CAN-09 | Bottom-left controls group | `05-canvas.md` | `BUILDER/flow-canvas/canvas-controls/index.tsx`, `BUILDER/flow-canvas/canvas-controls/canvas-control-button.tsx` |
| CAN-10 | Canvas tooltips with shortcut chip | `05-canvas.md` | `BUILDER/flow-canvas/canvas-controls/canvas-control-button.tsx`, `WEB/components/custom/shortcut.tsx` |
| CAN-11 | Top-right vertical toolbar | `05-canvas.md` | `BUILDER/flow-canvas/widgets/canvas-toolbar.tsx`, `BUILDER/flow-canvas/canvas-controls/index.tsx`, `WEB/app/components/global-search/global-search-context.tsx` |
| CAN-12 | Bottom-centre test bar | `05-canvas.md` | `BUILDER/flow-canvas/widgets/test-flow-widget.tsx`, `BUILDER/flow-canvas/widgets/above-trigger-button.tsx`, `BUILDER/flow-canvas/widgets/incomplete-settings-widget.tsx`, `BUILDER/flow-canvas/widgets/index.tsx`, `WEB/features/flow-runs/api/flow-runs-api.ts` |
| CAN-13 | Banners on the canvas | `05-canvas.md` | `BUILDER/flow-canvas/widgets/builder-banner.tsx`, `viewing-old-version-widget.tsx`, `flow-approval-banner.tsx`, `WEB/components/custom/resource-lock-widget.tsx`, `large-widget-wrapper.tsx` |
| CAN-14 | Empty-trigger placeholder | `05-canvas.md` | `BUILDER/flow-canvas/nodes/step-node/index.tsx`, `BUILDER/flow-canvas/nodes/step-node/trigger-widget.tsx` |
| CAN-15 | Sticky notes | `05-canvas.md` | `BUILDER/flow-canvas/nodes/note-node/index.tsx`, `note-tools.tsx`, `note-footer.tsx`, `BUILDER/flow-canvas/utils/consts.ts`, `NOTE_CREATION_OVERLAY_WIDTH/HEIGHT`, `WEB/components/custom/markdown-input` |
| CAN-16 | Keyboard map | `05-canvas.md` | `BUILDER/shortcuts.ts`, `BUILDER/flow-canvas/context-menu/canvas-context-menu.tsx`, `canvas-context-menu-content.tsx` |
| NOD-01 | Action step box | `06-graph.md` | `BUILDER/flow-canvas/nodes/step-node/index.tsx`, `BUILDER/flow-canvas/utils/consts.ts`, `packages/core/execution/src/lib/flows/util/flow-layout-util.ts` |
| NOD-02 | Trigger step shape, bolt and hover test button | `06-graph.md` | `BUILDER/flow-canvas/nodes/step-node/index.tsx`, `BUILDER/flow-canvas/nodes/step-node/trigger-widget.tsx`, `BUILDER/flow-canvas/widgets/above-trigger-button.tsx` |
| NOD-03 | Piece logo inside the box | `06-graph.md` | `BUILDER/flow-canvas/nodes/step-node/step-node-logo.tsx`, `WEB/components/custom/logo-plate.tsx` |
| NOD-04 | Label below the box | `06-graph.md` | `BUILDER/flow-canvas/nodes/step-node/step-node-display-name.tsx`, `step-node-run-duration-and-piece-name.tsx` |
| NOD-05 | Step hover toolbar | `06-graph.md` | `BUILDER/flow-canvas/nodes/step-node/step-node-toolbar.tsx`, `BUILDER/flow-canvas/utils/bulk-actions.ts`, `BUILDER/flow-canvas/context-menu/canvas-context-menu-content.tsx`, `BUILDER/test-step/test-runner-context.tsx` |
| NOD-06 | Selected halo | `06-graph.md` | `BUILDER/flow-canvas/nodes/step-node/index.tsx` |
| NOD-07 | Skipped step | `06-graph.md` | `BUILDER/flow-canvas/nodes/step-node/step-node-skipped-status.tsx`, `BUILDER/flow-canvas/nodes/step-node/index.tsx` |
| NOD-08 | Run status visuals | `06-graph.md` | `BUILDER/flow-canvas/nodes/step-node/step-node-status-in-run.tsx`, `step-node-badge-container.tsx`, `BUILDER/flow-canvas/utils/flow-canvas-utils.ts`, `WEB/features/flow-runs/utils/flow-run-utils.ts` |
| NOD-09 | Draft status visuals | `06-graph.md` | `BUILDER/flow-canvas/nodes/step-node/step-node-status-in-draft.tsx` |
| NOD-10 | Sample-data ("pinned") visual | `06-graph.md` | `BUILDER/flow-canvas/nodes/step-node/step-node-status-in-run.tsx`, `BUILDER/state/run-state.ts` |
| NOD-11 | Settings badges | `06-graph.md` | `BUILDER/flow-canvas/nodes/step-node/index.tsx` |
| NOD-12 | Join dot | `06-graph.md` | `BUILDER/flow-canvas/nodes/join-node.tsx`, `BUILDER/flow-canvas/utils/types.ts`, `consts.ts` |
| NOD-13 | Zoom-dependent contrast (OPTIONAL) | `06-graph.md` | `BUILDER/flow-canvas/` |
| NOD-14 | Drag and re-parent visuals | `06-graph.md` | `BUILDER/flow-canvas/index.tsx`, `BUILDER/state/layout-state.ts`, `BUILDER/flow-canvas/edges/flow-edge.tsx`, `BUILDER/flow-canvas/nodes/step-node/output-stub.tsx`, `step-drag-overlay.tsx`, `edges/add-button.tsx`, `flow-drag-layer.tsx` |
| HDL-01 | Input handle | `06-graph.md` | `BUILDER/flow-canvas/nodes/step-node/index.tsx`, `BUILDER/flow-canvas/utils/consts.ts` |
| HDL-02 | Output handle | `06-graph.md` | `BUILDER/flow-canvas/nodes/step-node/index.tsx` |
| HDL-03 | Several outputs on one step | `06-graph.md` | `BUILDER/flow-canvas/nodes/step-node/index.tsx` |
| HDL-04 | Output labels | `06-graph.md` | `BUILDER/flow-canvas/edges/branch-label.tsx` |
| HDL-05 | "+" stub on an unconnected output | `06-graph.md` | `BUILDER/flow-canvas/nodes/step-node/output-stub.tsx`, `nodes/big-add-button-node.tsx`, `nodes/flow-end-widget-node.tsx` |
| HDL-06 | Stub with run data | `06-graph.md` | `BUILDER/flow-canvas/nodes/step-node/output-stub.tsx` |
| HDL-07 | Dragging out of an output handle | `06-graph.md` | `BUILDER/flow-canvas/index.tsx`, `BUILDER/state/layout-state.ts` |
| EDG-01 | Forward edge | `06-graph.md` | `BUILDER/flow-canvas/edges/flow-edge.tsx`, `straight-line-edge.tsx`, `loop-start-edge.tsx`, `loop-return-edge.tsx`, `router-start-edge.tsx`, `router-end-edge.tsx`, `use-edge-layout-space.ts`, `BUILDER/flow-canvas/utils/svg-path-utils.ts` |
| EDG-02 | Back-edge | `06-graph.md` | `BUILDER/flow-canvas/utils/edge-path-utils.ts`, `BUILDER/flow-canvas/edges/flow-edge.tsx` |
| EDG-03 | Edge colours by state | `06-graph.md` | `BUILDER/flow-canvas/edges/flow-edge.tsx`, `BUILDER/flow-canvas/utils/flow-canvas-utils.ts`, `WEB/styles.css` |
| EDG-04 | Arrowheads | `06-graph.md` | `BUILDER/flow-canvas/edges/flow-edge.tsx` |
| EDG-05 | Edge hover and the "+" toolbar | `06-graph.md` | `BUILDER/flow-canvas/edges/flow-edge.tsx`, `BUILDER/flow-canvas/utils/flow-canvas-utils.ts`, `WEB/styles.css`, `BUILDER/flow-canvas/edges/add-button.tsx` |
| EDG-06 | Item-count labels | `06-graph.md` | `BUILDER/flow-canvas/edges/flow-edge.tsx`, `BUILDER/flow-canvas/utils/flow-canvas-utils.ts`, `WEB/features/flow-runs/utils/flow-run-utils.ts` |
| EDG-07 | Edges at the join dot | `06-graph.md` | `BUILDER/flow-canvas/edges/flow-edge.tsx`, `BUILDER/flow-canvas/nodes/join-node.tsx` |
| EDG-08 | Live drag line | `06-graph.md` | `BUILDER/flow-canvas/index.tsx` |
| EDG-09 | Layering | `06-graph.md` | `BUILDER/flow-canvas/index.tsx` |
| NDV-01 | Open and close rules | `07-step-modal.md` | `BUILDER/step-modal/index.tsx`, `BUILDER/builder-hooks.ts`, `BUILDER/state/*`, `BUILDER/flow-canvas/nodes/step-node/index.tsx`, `BUILDER/shortcuts.ts` |
| NDV-02 | Frame and overlay | `07-step-modal.md` | `BUILDER/step-modal/index.tsx` |
| NDV-03 | Modal header | `07-step-modal.md` | `BUILDER/step-modal/step-modal-header.tsx`, `BUILDER/step-settings/editable-step-name.tsx`, `BUILDER/step-settings/step-navigation-buttons.tsx` |
| NDV-04 | Columns: default and minimum widths | `07-step-modal.md` | `BUILDER/step-modal/index.tsx`, `WEB/components/ui/resizable-panel.tsx` |
| NDV-05 | Resizing, the drag grip, reset and saved layout | `07-step-modal.md` | `BUILDER/step-modal/index.tsx`, `BUILDER/step-modal/column-grip.tsx` |
| NDV-06 | Centre header: tabs and the test button | `07-step-modal.md` | `BUILDER/step-modal/step-modal-center-header.tsx`, `BUILDER/test-step/test-step-cta-button.tsx`, `BUILDER/test-step/test-step-tooltip.tsx`, `WEB/components/ui/tabs.tsx` |
| NDV-07 | Parameters tab | `07-step-modal.md` | `BUILDER/step-settings/index.tsx`, `piece-settings/`, `code-settings/`, `loops-settings.tsx`, `router-settings/`, `branch-settings/`, `ai-router-settings/`, `agent-settings/`, `BUILDER/piece-properties/generic-properties-form.tsx`, `auto-form-field-wrapper.tsx` |
| NDV-08 | Field label row and the mention input | `07-step-modal.md` | `BUILDER/piece-properties/auto-form-field-wrapper.tsx`, `dynamic-value-toggle-button.tsx`, `text-input-with-mentions/index.tsx`, `text-input-with-mentions/tiptap-editor.tsx`, `mention-chips-input.tsx` |
| NDV-09 | Settings tab | `07-step-modal.md` | `BUILDER/piece-properties/action-error-handling.tsx`, `BUILDER/step-settings/update-piece-version-dialog/`, `BUILDER/step-settings/index.tsx` |
| NDV-10 | INPUT pane | `07-step-modal.md` | `BUILDER/step-modal/input-pane.tsx`, `BUILDER/data-selector/`, `utils.ts`, `utils-schema.ts`, `path-helpers.ts`, `data-selector-node.tsx`, `data-selector-node-content.tsx`, `variables-tab.tsx` |
| NDV-11 | OUTPUT pane | `07-step-modal.md` | `BUILDER/step-modal/output-pane.tsx`, `BUILDER/test-step/test-sample-data-viewer.tsx`, `BUILDER/test-step/json-tree-skeleton.tsx`, `BUILDER/test-step/test-trigger-section/*`, `BUILDER/data-display/data-display-tabs.tsx`, `BUILDER/data-display/friendly-error-view.tsx`, `BUILDER/step-data/step-data-panel-host.tsx`, `step-data-panel-header.tsx`, `step-data-panel-view-toggle.tsx` |
| NDV-12 | View modes | `07-step-modal.md` | `WEB/components/ui/segmented-control.tsx`, `BUILDER/step-modal/view-mode-control.tsx` |
| NDV-13 | Schema view | `07-step-modal.md` | `BUILDER/step-modal/schema-view.tsx`, `BUILDER/data-selector/utils-schema.ts`, `WEB/components/custom/smart-output-viewer/` |
| NDV-14 | Table view | `07-step-modal.md` | `BUILDER/step-modal/table-view.tsx`, `WEB/components/ui/virtualized-list.tsx` |
| NDV-15 | JSON view | `07-step-modal.md` | `WEB/components/custom/json-viewer.tsx` |
| NDV-16 | Drag to map | `07-step-modal.md` | `BUILDER/step-modal/drag-to-map.tsx`, `BUILDER/piece-properties/text-input-with-mentions/tiptap-editor.tsx`, `BUILDER/state/step-form-state.ts` |
| NDV-17 | Loop iterations in the data panes | `07-step-modal.md` | `BUILDER/run-details/loop-iteration-input.tsx`, `BUILDER/state/run-state.ts` |
| NDV-18 | Read-only run view | `07-step-modal.md` | `BUILDER/run-details/flow-step-input-output.tsx`, `BUILDER/run-details/ai-router-routes.tsx`, `WEB/app/routes/runs/id/index.tsx` |
| NDV-19 | Neighbour chips (OPTIONAL) | `07-step-modal.md` | `BUILDER/step-modal/neighbour-chips.tsx` |
| NDV-20 | Keyboard inside the modal | `07-step-modal.md` | `BUILDER/step-modal/index.tsx`, `BUILDER/shortcuts.ts` |
| NDV-21 | What leaves the old sidebar | `07-step-modal.md` | `BUILDER/index.tsx`, `BUILDER/types/index.ts`, `RightSideBarType.PIECE_SETTINGS`, `BUILDER/step-settings/index.tsx`, `BUILDER/data-selector/index.tsx`, `BUILDER/step-data/*` |
| PCK-01 | Panel container | `08-piece-panel.md` | `BUILDER/pieces-selector/index.tsx`, `BUILDER/index.tsx`, `BUILDER/state/piece-selector-state.ts` |
| PCK-02 | Slide motion | `08-piece-panel.md` | `BUILDER/pieces-selector/index.tsx` |
| PCK-03 | Header | `08-piece-panel.md` | `BUILDER/pieces-selector/piece-panel-header.tsx` |
| PCK-04 | Search box | `08-piece-panel.md` | `WEB/features/pieces/components/piece-selector-search.tsx` |
| PCK-05 | Root view | `08-piece-panel.md` | `WEB/features/pieces/components/piece-selector-tabs.tsx`, `BUILDER/pieces-selector/index.tsx`, `pieceSelectorCustomization.buildResolvedTabs` |
| PCK-06 | List rows | `08-piece-panel.md` | `BUILDER/pieces-selector/piece-card-item.tsx`, `generic-piece-selector-item.tsx`, `piece-actions-or-triggers-list.tsx`, `WEB/components/custom/card-list`, `WEB/features/pieces/components/piece-icon.tsx` |
| PCK-07 | Group (category) rows | `08-piece-panel.md` | `BUILDER/pieces-selector/explore-tab-content.tsx` |
| PCK-08 | Section labels and separators | `08-piece-panel.md` | `BUILDER/pieces-selector/*` |
| PCK-09 | Hover and keyboard-active bars; keyboard navigation | `08-piece-panel.md` | `BUILDER/pieces-selector/*`, `WEB/components/custom/card-list` |
| PCK-10 | Sub-view push and pop | `08-piece-panel.md` | `BUILDER/pieces-selector/index.tsx`, `explore-tab-content.tsx`, `ai-tab-content/`, `approvals-tab-content.tsx`, `piece-actions-or-triggers-list.tsx` |
| PCK-11 | Search results | `08-piece-panel.md` | `BUILDER/pieces-selector/pieces-card-list.tsx`, `piece-card-item.tsx`, `no-results-found.tsx` |
| PCK-12 | Openers and modes | `08-piece-panel.md` | `BUILDER/state/piece-selector-state.ts`, `BUILDER/flow-canvas/utils/flow-canvas-utils.ts` |
| PCK-13 | Closing, and the result of a pick | `08-piece-panel.md` | `BUILDER/pieces-selector/index.tsx`, `BUILDER/builder-hooks.ts` |
| LOG-01 | Placement | `09-logs.md` | `BUILDER/index.tsx`, `BUILDER/logs-panel/index.tsx`, `WEB/components/ui/resizable-panel.tsx` |
| LOG-02 | Collapsed bar | `09-logs.md` | `BUILDER/logs-panel/logs-panel-bar.tsx` |
| LOG-03 | Open height, resizing and opening rules | `09-logs.md` | `BUILDER/logs-panel/index.tsx`, `BUILDER/flow-canvas/widgets/test-flow-widget.tsx`, `BUILDER/state/run-state.ts` |
| LOG-04 | Open layout and header rows | `09-logs.md` | `BUILDER/logs-panel/index.tsx` |
| LOG-05 | Step list: header and run summary | `09-logs.md` | `BUILDER/logs-panel/logs-overview.tsx`, `BUILDER/flow-canvas/widgets/run-info-widget.tsx`, `WEB/features/flow-runs/components/timeline-bar.tsx` |
| LOG-06 | Step rows | `09-logs.md` | `BUILDER/logs-panel/logs-step-row.tsx`, `WEB/features/flow-runs/utils/flow-run-utils.ts`, `WEB/features/flow-runs/components/step-status-icon.tsx` |
| LOG-07 | Loop iterations in the list | `09-logs.md` | `BUILDER/logs-panel/logs-overview.tsx`, `BUILDER/run-details/loop-iteration-input.tsx`, `BUILDER/state/run-state.ts` |
| LOG-08 | Details column | `09-logs.md` | `BUILDER/logs-panel/logs-details.tsx`, `BUILDER/run-details/flow-step-input-output.tsx`, `BUILDER/run-details/ai-router-routes.tsx`, `BUILDER/step-modal/input-pane.tsx`, `output-pane.tsx` |
| LOG-09 | Keyboard | `09-logs.md` | `BUILDER/shortcuts.ts`, `BUILDER/logs-panel/index.tsx` |
| LOG-10 | Live updates during a test run | `09-logs.md` | `BUILDER/state/run-state.ts`, `BUILDER/logs-panel/logs-overview.tsx` |
| LOG-11 | Run opened from the runs list | `09-logs.md` | `BUILDER/run-list/index.tsx`, `BUILDER/run-list/flow-run-card.tsx`, `WEB/app/routes/runs/id/index.tsx` |
| LOG-12 | No run loaded | `09-logs.md` | `BUILDER/logs-panel/index.tsx` |
| MOT-01 | Durations | `10-motion.md` | Tailwind's numeric `duration-*` utilities accept any integer, so no theme key is needed; AP's existing `--transition-duration-1500` stays |
| MOT-02 | Easing curves | `10-motion.md` | `packages/web/src/styles.css` |
| MOT-03 | Default transition | `10-motion.md` | `styles.css` |
| MOT-04 | Hover, press and colour feedback | `10-motion.md` | `packages/web/src/components/ui/` |
| MOT-05 | Floating surfaces: popover, dropdown and context menu, select panel, hover card, command panel | `10-motion.md` | `components/ui/popover.tsx`, `dropdown-menu.tsx`, `context-menu.tsx`, `select.tsx`, `hover-card.tsx`, `command.tsx` |
| MOT-06 | Tooltip | `10-motion.md` | `components/ui/tooltip.tsx` |
| MOT-07 | Dialog | `10-motion.md` | `components/ui/dialog.tsx` |
| MOT-08 | Sheet and drawer | `10-motion.md` | `components/ui/sheet.tsx`, `components/ui/drawer.tsx` |
| MOT-09 | Button loading | `10-motion.md` | `components/ui/button.tsx`, `components/custom/spinner.tsx` |
| MOT-10 | Switch | `10-motion.md` | `components/ui/switch.tsx` |
| MOT-11 | Instant state switches | `10-motion.md` | `tabs.tsx`, `segmented-control.tsx`, `checkbox.tsx`, `radio-group.tsx` |
| MOT-12 | Field focus | `10-motion.md` | `components/ui/input.tsx`, `textarea.tsx`, `select.tsx` |
| MOT-13 | Toasts | `10-motion.md` | `components/ui/sonner.tsx`, `styles.css` |
| MOT-14 | Loading indicators | `10-motion.md` | `components/ui/skeleton.tsx`, `components/custom/data-table/` |
| MOT-15 | Collapsible and accordion | `10-motion.md` | `styles.css` |
| MOT-16 | Shared entrance recipes | `10-motion.md` | `styles.css` |
| MOT-17 | Scroll-area bar | `10-motion.md` | `components/ui/scroll-area.tsx` |
| MOT-18 | Motion owned by other files | `10-motion.md` | — |
| MOT-19 | Reduced motion | `10-motion.md` | `styles.css`, `packages/web/src/app/app.tsx` |

Cross-cutting requirements with no AP target of their own (they constrain the targets of other IDs): TOK-18 (01-tokens.md), TOK-19 (01-tokens.md), TOK-22 (01-tokens.md), MOT-18 (10-motion.md).
