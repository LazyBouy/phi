# Trace — tokens, primitives, motion (TOK, PRM, MOT)

Reference-lane record for `01-tokens.md`, `02-primitives.md`, `10-motion.md`. Builders never read this file.

Abbreviations:

- `DS` = `iphi-flow/n8n/packages/frontend/@n8n/design-system/src` (n8n commit `55eb2ce442`).
- `EUI` = `iphi-flow/n8n/packages/frontend/editor-ui/src`.
- `REF/` = `iphi-flow/docs/specs/n8n-vibe/_ref/n8n/` (screenshots of n8n 2.43.0, 1440×900).
- `TW` = Tailwind CSS 4.1.17 `theme.css`, read from the local bun cache (`/root/.bun/install/cache/tailwindcss@4.1.17@@@1/theme.css`), the same version AP pins. Hex values were converted from TW oklch with AP's own `oklchToHex` (sRGB clamp).
- `GEN` = AP's ramp generator (`activepieces/packages/core/shared/src/lib/core/common/brand-colors.ts`) run in place (type-stripped in Node, parameters replaced in memory; no file written) with the TOK-09 parameter set.
- `px-sample` = pixel colours read from the screenshot with Pillow (mode of a region, or the darkest/lightest pixel for text ink).
- r2 / r3 = `_provenance/r2-n8n-design-system-facts.md` / `r3-n8n-editor-facts.md`.

## Tokens

| ID | Source | How verified |
|---|---|---|
| TOK-01 | Plan Phase 2; AP `packages/web/src/styles.css`, `packages/web/test/styles/status-scales.test.ts` | Read AP code; the test compares every coloured step and swatch role with the generator output |
| TOK-02 | `DS/css/_primitives.scss` (neutral ramp incl. 125/150/250), `DS/css/_tokens.scss` (surface, subtle, hover, active, border default/subtle/strong/stronger, text tiers, light and dark blocks), `DS/css/_tokens.legacy.scss` (background light-1/2/3, foreground, text tints, light and dark); REF/`01-home-workflows.png` + `-dark` (page `#fafafa`/`#171717`, card `#fff`/`#262626`, card border `#e5e5e5`/`#474747`, sidebar `#fff`/`#262626`, pager active `#e0e0e0`/`#3a3a3a`), REF/`10-linear-idle.png` + `-dark` (canvas `#f5f5f5`/`#171717`, header border `#e5e5e5`/`#323232`, segmented track `#e5e5e5`/`#323232`, node fill `#fff`/`#2b2b2b`, edge `#cacaca`/`#4d4d4d`), REF/`22-step-modal.png` + `-dark` (side panes `#f5f5f5`/`#262626`, centre `#fff`/`#2b2b2b`, input border `#e5e5e5`/`#3a3a3a`, dark input bg `#171717`), REF/`31-home-executions.png` + `-dark` (table header `#f5f5f5`/`#2b2b2b`, separators `#e5e5e5`/`#323232`); TW neutral | Read source; px-sample; TW values computed; contrast ratios computed with AP's `contrastRatio` |
| TOK-03 | `DS/css/_tokens.scss` text colour / subtle / subtler / disabled (light and dark); REF/`01-home-workflows.png` + `-dark` (title `#262626`/`#fff`, subtitle and meta `#999`/`#bbb`, tab inactive `#444`/`#e5e5e5`, badge text `#444`/`#e5e5e5`), REF/`30-home-credentials.png` + `-dark` (empty description `#444`/`#e5e5e5`, glyph `#999`/`#bbb`) | px-sample (darkest / lightest ink pixel); `text-gray-12/87` composites computed (≈ `#424242` on white, ≈ `#e3e3e3` on `#262626`) |
| TOK-04 | `DS/css/_tokens.scss` (brand bg, hover orange-600, active orange-700, focus orange-400), `DS/css/_primitives.scss` (orange ramp, = TW orange); r2 §2b tints; TW orange; GEN | GEN output with accent anchor orange-500 + exact anchor; compared each step with TW orange hex |
| TOK-05 | `DS/css/_tokens.legacy.scss` success roles; `DS/css/_tokens.scss` status success; r2 §2b; TW green; GEN | GEN output (success anchor unchanged; steps 10–11 shift only from the new grounds) |
| TOK-06 | `DS/css/_primitives.scss` gold ramp (gold-600 oklch 61.78% 0.1267 70.31 = `#b57617`) and yellow ramp; `DS/css/_tokens.scss` status warning (yellow-100/200/800); r2 §5 callouts; r3 §0 warning; EUI header publish dot (yellow-500, r3 §6); TW amber/yellow; GEN | OKLab distance from the gold to every amber/yellow/orange 500–800 shade computed (yellow-700 0.0653, yellow-600 0.0674, amber-600 0.0777, amber-700 0.0918); GEN shows the family is picked by hue (yellow-700 alone would fall into amber), so the anchor is yellow-500 |
| TOK-07 | `DS/css/_tokens.legacy.scss` danger; `DS/css/_tokens.scss` dark danger red-400; TW red; GEN | GEN output |
| TOK-08 | `DS/components/N8nDialog/DialogOverlay.vue` (overlay black 30% light / 60% dark, 8px blur); r3 §7 + REF/`22-step-modal.png` (step-modal overlay 60%: page `#fafafa` → `#666666`); `DS/css/_tokens.scss` focus (border purple-500, outline purple-alpha-200); `DS/css/_primitives.scss` purple-alpha base (oklch 49.83% 0.1772 283.27 ≈ `#5a4cc2`); `DS/css/_tokens.scss` canvas dot (neutral-500) + r2 §2c dark dot `#444`; `DS/css/_tokens.scss` surface (white / neutral-900 `#262626`); GEN `onPrimaryFor('#ff6900')` = black | Read source; nearest TW to the halo base computed (indigo-700 0.0785, indigo-600 0.089, violet-800 0.092, violet-600 0.119); composites on white computed |
| TOK-09 | AP `brand-colors.ts`, `packages/web/src/lib/brand-seed.ts`, `packages/server/api/src/app/flags/theme.ts` (`defaultTheme` primary `#6e41e2`), `theme-provider.tsx` and `appearance-section.tsx` call sites of `brandSeed`; plan Phase 2 | Read AP code; GEN run with the stated parameters produced the TOK-04…07 tables |
| TOK-10 | AP `brand-colors.ts` `swatches()` | Read code: swatch ink uses the text grounds, surface/line use the dark ladder |
| TOK-11 | `DS/css/mixins/_focus.scss` (ring, ring-with-border, offset); `DS/components/N8nInput/Input.vue` (focus-within ring + 1px focus border); `DS/components/N8nButton/Button.vue` (focus-visible ring, border to focus colour); `DS/components/N8nSegmentControl/SegmentControlItem.vue` (offset ring); `DS/components/N8nRadioGroup/RadioGroupItem.vue` (offset ring); `DS/components/N8nTabs/Tabs.vue` (1px inset outline); `DS/components/N8nSwitch/Switch.vue` (2px ring, secondary purple) | Read source |
| TOK-12 | `DS/css/_primitives.scss` radius; `DS/css/_tokens.legacy.scss` radius overrides (base 4, lg 8, xl 12, sm 2); r2 §1 radius table; AP `@theme` radius keys; TW deprecated `--radius: 0.25rem` | Read source; AP radius usage counted with grep (rounded-lg 150, rounded-md 242, rounded-xs 7, rounded-xss 0) |
| TOK-13 | `DS/css/_primitives.scss` shadows (outline, 2xs, xs, sm, md, xl; light and dark colours); `DS/components/N8nDialog/DialogContent.vue` (dialog stack, light-dark); `DS/css/_tokens.legacy.scss` (light 0 2 12, card hover 0 2 8 rgba(68,28,23,.1)); `DS/css/drawer.scss` (0 6 16 rgb(68 28 23 / 6%)); `DS/css/mixins/_popover.scss` (md + outline); `DS/components/N8nTooltip/Tooltip.vue` (sm); EUI `app/components/WorkflowCard.vue` (card hover); TW shadow keys | Read source; mapped to TW geometry; warm brown matched to TW orange-950 `#441306` |
| TOK-14 | `DS/css/fonts.scss`, `DS/css/fonts/inter.scss`; r2 §3 (Inter, Commit Mono, OFL, fallbacks); AP `styles.css` font faces | Read source and AP code |
| TOK-15 | `DS/css/_primitives.scss` font sizes, line heights, letter spacing; r2 §3 text ramp; REF/`01-home-workflows.png` (page title cap height 15px ⇒ 20px; tab and card-title cap height 11px ⇒ 14px; meta 12px; badge 12px); AP `@theme` text keys; TW text keys | Read source; measured glyph rows in screenshots; AP usage counted (text-sm 749, text-xs 441) |
| TOK-16 | `DS/css/_primitives.scss` weights (400/500/600) | Read source; AP usage counted (font-bold 38, font-extrabold 2) |
| TOK-17 | `DS/css/_primitives.scss` spacing | Read source |
| TOK-18 | `DS/css/_primitives.scss` heights; r2 §6 icon sizes | Read source |
| TOK-19 | r2 §4 borders; `DS/components/N8nButton/Button.vue` (disabled 0.5), `DS/components/N8nInput/Input.vue` (0.6), `DS/components/N8nBadge/Badge.vue` (0.6), r2 switch (60%) | Read source |
| TOK-20 | `iphi-flow/n8n/packages/frontend/@n8n/frontend-constants/src/z-indexes.ts`; `DS/css/common/var.scss` popper indices | Read source; translated to AP-sized integers keeping the order |
| TOK-21 | `DS/css/common/var.scss` breakpoints (768/992/1200/1920); `DialogContent.vue` widths from 640 | Read source |
| TOK-22 | Computed | AP `contrastRatio` on every listed pair |
| TOK-23 | AP `brain/knowledge/design-system/colour.md`, `index.md` | Read AP docs |

## Primitives

| ID | Source | How verified |
|---|---|---|
| PRM-01 | `DS/components/N8nButton/Button.vue` (sizes, solid/subtle/outline/ghost/destructive/success, inset border shadow, xs shadow, disabled, iconOnly, loading container, focus); REF/`01-home-workflows.png` (create button 32px tall, `#ff6900`), REF/`22-step-modal.png` (subtle button white with `#e5e5e5` ring; dark `#262626` with `#474747`) | Read source; px-sample and measured heights |
| PRM-02 | `Button.vue` iconOnly; r3 §1 canvas controls | Read source |
| PRM-03 | `DS/css/mixins/_input.scss` (sizes, theme variables), `DS/components/N8nInput/Input.vue` (inset ring, hover strong, focus-within, disabled 0.6, prefix/suffix 70%, prepend/append colours); REF/`01-home-workflows.png` (search 32×196, `#e5e5e5`), REF/`22-step-modal.png` + `-dark` | Read source; px-sample |
| PRM-04 | `Input.vue` textarea rules | Read source |
| PRM-05 | r2 §5 v2 select trigger and panel; `DS/css/mixins/_popover.scss`, `_floating-item.scss`; REF/`01-home-workflows.png` (sort select with a single down chevron) | Read source; screenshot |
| PRM-06 | `DS/components/N8nTabs/Tabs.vue`; REF/`01-home-workflows.png` (2px `#ff6900` underline at y 124–125, 16px side padding, no row border, inactive `#444`), REF/`22-step-modal.png` (compact tabs) | Read source; px-sample |
| PRM-07 | `DS/components/N8nSegmentControl/SegmentControl.vue`, `SegmentControlItem.vue`; REF/`10-linear-idle.png` + `-dark`, REF/`22-step-modal.png` + `-dark` (track and selected colours) | Read source; px-sample |
| PRM-08 | `DS/components/N8nTooltip/Tooltip.vue` (black, neutral-100 text, 13px/500, 4/6 padding, min 28, max 180, radius 8, sm shadow, top, offset 8, delay 0, no arrow, closed no animation) | Read source |
| PRM-09 | `DS/css/mixins/_popover.scss`, `_floating-item.scss`; r2 §5 dropdown menus | Read source |
| PRM-10 | `DS/components/N8nPopover/Popover.vue` | Read source |
| PRM-11 | `DS/components/N8nDialog/DialogContent.vue` (radius, padding, bg light/dark, shadow stack, widths, animation), `DialogOverlay.vue`; r2 §5 dialog header/footer/close | Read source |
| PRM-12 | `DS/css/drawer.scss` | Read source |
| PRM-13 | `DS/components/N8nBadge/Badge.vue` (pill, border = fill, variants, clickable mix 5/10%, disabled 0.6); REF/`01-home-workflows.png` (badge 24px tall, 12px text), REF/`31-home-executions.png` + `-dark` (violet badge stays `#ddd6ff`/`#4d179a` in dark) | Read source; px-sample |
| PRM-14 | `DS/components/N8nTag/Tag.vue` (sizes, 300ms background transition); r2 §5 tag colours | Read source |
| PRM-15 | r2 §5 cards (`DS/components/N8nCard/Card.vue`); EUI `app/components/WorkflowCard.vue` (hover shadow 0.3s); REF/`01-home-workflows.png` | Read source; px-sample |
| PRM-16 | `DS/components/TableBase/TableBase.vue`; r2 §5 tables (loading bar, 38%); REF/`31-home-executions.png` + `-dark` | Read source; px-sample |
| PRM-17 | `DS/components/N8nSwitch/Switch.vue` (focus); r2 §5 switch | Read source |
| PRM-18 | `DS/css/checkbox.scss`; r2 §5 checkbox; REF/`31-home-executions.png` (checked `#ff6900`, unchecked border `#e5e5e5`; dark `#3c3c3c`) | Read source; px-sample |
| PRM-19 | `DS/components/N8nRadioGroup/RadioGroupItem.vue` | Read source |
| PRM-20 | r2 §5 callouts (`DS/components/N8nCallout`) | r2 |
| PRM-21 | r2 §5 notice banners (`DS/components/N8nNotice`); REF/`22-step-modal.png` (fill `#fdf9f1`, border and left bar `#f4d8ae`, orange 600 link) | r2; px-sample |
| PRM-22 | `DS/css/notification.scss`, `DS/css/common/var.scss` (notification width/padding/radius/icon/title/content), `iphi-flow/n8n/packages/frontend/@n8n/composables/src/useToast.ts` (bottom-right) | Read source |
| PRM-23 | `DS/css/mixins/mixins.scss` (scrollbar mixin: 6px, radius 5, thumb colours), `DS/css/scrollbar.scss` (bar inset 2px, radius 4, fades), `DS/css/common/var.scss` (thumb tint-2 / hover tint-1) | Read source |
| PRM-24 | `DS/css/skeleton.scss` (gradient 25/37/63, 400%, 1.4s), `DS/components/N8nLoading/Loading.vue` (61% / 40% widths) | Read source |
| PRM-25 | `DS/components/N8nEmptyState/EmptyState.vue` (2px dashed, radius lg, padding 3xl/xl, gap md, 40px icon stroke 1.5, heading xlarge, description text-base); REF/`30-home-credentials.png` + `-dark` (frame `#e5e5e5`/`#323232`, glyph `#999`/`#bbb`, button 36px) | Read source; px-sample |
| PRM-26 | r2 §5 ("toggle button shares button sizes; pressed uses active background") | r2 |
| PRM-27 | r3 §7 (parameter labels 14px dark); `RadioGroupItem.vue` label sizes | r3; read source |

## Motion

| ID | Source | How verified |
|---|---|---|
| MOT-01 | `DS/css/_primitives.scss` durations; `DS/css/mixins/motion.scss`; r3 §9 | Read source |
| MOT-02 | `DS/css/_primitives.scss` easings; `motion.scss` blur curve (0.32, 0.72, 0, 1); CSS keyword curves | Read source; AP `@theme` read (`--ease-*` cleared, `--ease-expand-out` kept) |
| MOT-03 | AP / TW default transition keys (150ms, 0.4 0 0.2 1) vs the target's 200ms standard | Read TW theme.css and AP `styles.css` |
| MOT-04 | EUI `WorkflowCard.vue` (box-shadow 0.3s ease); `Tag.vue` (0.3s ease) | Read source |
| MOT-05 | `motion.scss` popover-in (opacity, scale 0.96, translate); `Popover.vue` placement offsets (±2px, origins); `_popover.scss` (closed = hidden) | Read source |
| MOT-06 | `Tooltip.vue` (no open animation, closed animation none) | Read source |
| MOT-07 | `DialogContent.vue` keyframes (200ms ease-out, +8px, scale 0.98, both ways); `DialogOverlay.vue` (200ms ease) | Read source |
| MOT-08 | `DS/css/drawer.scss` (0.3s, translate 100%, opacity) | Read source |
| MOT-09 | `Button.vue` fade transition (0.2s cubic-out, 4px, blur 2px; reduced-motion 0.1s opacity); `motion.scss` spin default (400ms) | Read source |
| MOT-10 | r2 §5 switch (200ms ease-out, 2px stretch) | r2 |
| MOT-11 | `Tabs.vue`, `SegmentControlItem.vue` (no transitions on the indicator) | Read source |
| MOT-12 | r3 §9 (input border focus 200ms ease-in-out-cubic) | r3 |
| MOT-13 | `DS/css/notification.scss` (0.3s transitions, top 0.4s, enter translateX(100%), leave opacity 0) | Read source |
| MOT-14 | `DS/css/skeleton.scss`; r2 §5 tables loading | Read source |
| MOT-15 | `motion.scss` collapsible slide (200ms, ease-out-cubic) | Read source |
| MOT-16 | `motion.scss` fadeIn (8px, blur 2px), fadeInUp (4px, blur 2px), blurred collapsible (350ms, blur 4px); r3 §8 empty-state stagger (160 + 80 × index, 400ms) | Read source; r3 |
| MOT-17 | `DS/css/scrollbar.scss` (340ms in, 120ms out, ease-out) | Read source |
| MOT-18 | r3 §9 | r3 |
| MOT-19 | `motion.scss` reduced-motion mixin (animation and transition none); `Button.vue` reduced-motion swap (0.1s opacity); spin mixin stops | Read source |

## Values that could not be verified

| Item | Why |
|---|---|
| Commit Mono weight range and file name | Not available offline; the builder takes them from the upstream release |
| Dark hover of tags and dark disabled-checkbox look | Not set in the sources read; filled with the nearest step |
| Toast dark border | Taken from the legacy light-border token's dark value (neutral-850); not visible in any screenshot |
| Callout, notice, card-hover-border and switch details | Taken from r2 (gathered from source by the research agent), not re-read here |
