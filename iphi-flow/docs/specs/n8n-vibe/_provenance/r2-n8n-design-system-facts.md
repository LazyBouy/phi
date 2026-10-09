# r2 — n8n design-system facts (provenance record)

Source tree: `iphi-flow/n8n/packages/frontend/@n8n/design-system` and `editor-ui`, at n8n commit `55eb2ce442`.
Facts described in our own words. "≈" = converted from OKLCH source to the nearest sRGB hex.
DS = `iphi-flow/n8n/packages/frontend/@n8n/design-system/src`.

## 1. Where the tokens live

| Concern | File | Notes |
|---|---|---|
| Primitives: colour ramps, spacing, font family/size/weight, line height, letter spacing, radius, heights, durations, easings, shadows | `DS/css/_primitives.scss` | Newest layer; OKLCH ramps; small dark block changes only shadow colours |
| Semantic tokens, light + dark | `DS/css/_tokens.scss` | Backgrounds, borders, text, icons, status, focus, canvas, node, button, table, callout, dialog, switch |
| Legacy aliases | `DS/css/_tokens.legacy.scss` | Older primary/secondary/success/warning/danger/text/foreground/background ramps, legacy shadows and radius; pulled into the semantic file |
| Element Plus–era variables | `DS/css/common/var.scss` | z-index, transitions, component sizes, breakpoints |
| Motion | `DS/css/mixins/motion.scss` | Keyframes, durations, reduced-motion |
| Focus ring | `DS/css/mixins/_focus.scss` | |
| Input sizes and theme | `DS/css/mixins/_input.scss` | |
| Popover surface, menu item | `DS/css/mixins/_popover.scss`, `_floating-item.scss` | |
| Fonts | `DS/css/fonts.scss`, `DS/css/fonts/inter.scss` | |
| Entry point | `DS/css/index.scss` | primitives → tokens → reset → base → fonts → components |

Other places:
- App-wide z-index scale: `iphi-flow/n8n/packages/frontend/@n8n/frontend-constants/src/z-indexes.ts` (written to the root element as custom properties at startup).
- Storybook token docs: `DS/styleguide/` (`css-tokens.mdx`, `type.mdx`, `spacing-size.mdx`, `shadow.mdx`, `motion.mdx`, `colour.mdx`).

Naming:
- Old single-dash names (e.g. primary colour, dark text, base border radius) and new double-dash names coexist.
- New legacy aliases check the old name first, then fall back to a primitive.
- New code uses primitives plus "semantic v2" names (background / text colour / border colour / icon colour families).

Radius cascade: the semantic file loads after primitives and its legacy block overrides three radius names.

| Radius name | Primitive value | Value that applies |
|---|---|---|
| sm | 12px | **2px** |
| lg | 20px | **8px** |
| xl | 24px | **12px** |

The legacy block also adds a base radius of **4px**. Dialogs, cards and canvas nodes therefore render at 8px.

## 2. Colour palette

### 2a. Primitive ramps (≈)

Orange, green, purple, mint, red, blue, yellow and pink render to the same hex as Tailwind v4's default orange, green, violet, teal, red, blue, yellow and pink.

| Ramp | 50 | 100 | 200 | 300 | 400 | 500 | 600 | 700 | 800 | 900 | 950 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| neutral | #fafafa | #f5f5f5 | #e5e5e5 | #d9d9d9 | #bbbbbb | #999999 | #737373 | #444444 | #323232 | #262626 | #171717 |
| orange | #fff7ed | #ffedd4 | #ffd6a7 | #ffb86a | #ff8904 | **#ff6900** | #f54900 | #ca3500 | #9f2d00 | #7e2a0c | #441306 |
| purple (= TW violet) | #f5f3ff | #ede9fe | #ddd6ff | #c4b4ff | #a684ff | #8e51ff | **#7f22fe** | #7008e7 | #5d0ec0 | #4d179a | #2f0d68 |
| green | #f0fdf4 | #dcfce7 | #b9f8cf | #7bf1a8 | #05df72 | #00c950 | **#00a63e** | #008236 | #016630 | #0d542b | #032e15 |
| red | #fef2f2 | #ffe2e2 | #ffc9c9 | #ffa2a2 | #ff6467 | #fb2c36 | **#e7000b** | #c10007 | #9f0712 | #82181a | #460809 |
| blue | #eff6ff | #dbeafe | #bedbff | #8ec5ff | #51a2ff | #2b7fff | #155dfc | #1447e6 | #193cb8 | #1c398e | #162456 |
| yellow | #fefce8 | #fef9c2 | #fff085 | #ffdf20 | #fdc700 | #f0b100 | #d08700 | #a65f00 | #894b00 | #733e0a | #432004 |
| gold (custom) | #fdf9f1 | #f7e3c4 | #f4d8ae | #efc381 | #e6a23d | #d48a1c | **#b57617** | #905e13 | #63410d | #2d1d06 | — |
| mint (= TW teal) | #f0fdfa | #cbfbf1 | #96f7e4 | #46ecd5 | #00d5be | #00bba7 | #009689 | #00786f | #005f5a | #0b4f4a | #022f2e |
| slate (custom violet-grey) | — | #e4e3e8 | #c8c7d1 | #adabba | #928fa3 | #76738c | #5f5c70 | #474554 | #2f2e38 | #18171c | — |

- Most ramps also have 150 and 250 steps (orange and purple repeat 100/200).
- Deprecated greys: neutral-125 #f5f5f5, neutral-750 #424242, neutral-850 #2b2b2b.
- Alpha ramps: black and white at 5–95%, plus orange alpha steps.
- Purple focus alpha base ≈ #5a4cc2 at 10/25/40/60/80%.

### 2b. Light theme roles

| Role | Value |
|---|---|
| Primary / brand | orange-500 **#ff6900** |
| Primary hover / active / focus | #f54900 / #ca3500 / #ff8904 |
| Primary tints 1 / 2 / 3 | #ff8904 / #ffd6a7 / #ffedd4 |
| Secondary | purple-600 **#7f22fe** (shade #7008e7; tints #c4b4ff, #ddd6ff) |
| Success | green-600 **#00a63e** (shade #008236; tints #7bf1a8, #b9f8cf, #dcfce7, #f0fdf4) |
| Warning | gold-600 **#b57617** (shade gold-500 #d48a1c; tints #f4d8ae, #fdf9f1) |
| Danger | red-600 **#e7000b** (shade #c10007; tints #ff6467, #ffa2a2, #ffe2e2, #fef2f2) |
| Text dark / base / light / lighter / xlight | #262626 / #444444 / #999999 / #e5e5e5 / #ffffff |
| Foreground (lines) xdark / dark / base / light / xlight | #999 / #e0e0e0 / #e5e5e5 / #f0f0f0 / #fff |
| Background dark / medium / base / light-base / light / xlight | #171717 / #e5e5e5 / #f5f5f5 / #f5f5f5 / #fafafa / #ffffff |
| Page body | background **#fafafa**, text #262626 |
| Canvas | **#f5f5f5**, dots #999999 on a **16px** grid |
| v2 surface / subtle | #ffffff / #fafafa |
| v2 hover / active / disabled backgrounds | black 5% / black 10% / #e5e5e5 |
| v2 border default / subtle / strong / stronger | black 10% / 5% / 20% / 30% (legacy border 1px solid black 10%) |
| v2 text default / subtle / subtler / disabled | #262626 / #444 / #999 / #bbb |
| v2 icon default / subtle / strong | #999 / #e5e5e5 / #323232 |
| Status success bg / border / text | #f0fdf4 / #b9f8cf / #016630 |
| Status warning bg / border / text | #fef9c2 / #fff085 / #894b00 |
| Status danger bg / border / text | #fef2f2 / #ffc9c9 / #9f0712 |
| Status info bg / border / text | #eff6ff / #bedbff / #193cb8 |
| Inverse bg / border / text | #262626 / #444 / #f5f5f5 |
| Canvas node | background #ffffff; running fill #ffedd4; pinned border purple; running border orange |

### 2c. Dark theme

| Role | Value |
|---|---|
| Brand | Same orange ramp; disabled brand background #323232 |
| Danger | red-400 #ff6467 |
| Text dark / base / light / lighter / xlight | #ffffff / #e5e5e5 / #bbbbbb / #737373 / #323232 |
| Foreground xdark / dark / base / light / xlight | #bbb / #444 / #323232 / #2b2b2b / #171717 |
| Background dark / medium / base / light-base / light / xlight | #f0f0f0 / #737373 / #444 / #2b2b2b / #171717 / #262626 |
| v2 surface / subtle | #262626 / #323232 |
| v2 hover / active | white 10% / white 15% |
| v2 border default / subtle / strong / stronger | white 15% / 10% / 20% / 40% |
| v2 text default / subtle / subtler / disabled | #fff / #e5e5e5 / #bbb / #737373 |
| Status success / warning / danger / info | green-950/800/50; yellow-900/800/100; red-950/800/50; blue-900/800/50 (bg/border/text) |
| Inverse | white background, #323232 text |
| Canvas | background #171717, dots #444, node background #2b2b2b |
| Shadow colour | black 25%; outline ring white 10% |

Dark mode switching:
- `data-theme="light"|"dark"` attribute on the body; "system" removes it and a `prefers-color-scheme: dark` media query applies dark tokens.
- Stored in localStorage; can be forced with a `?theme=` query parameter.
- `color-scheme` is set to match so `light-dark()` resolves.
- Logic: `iphi-flow/n8n/packages/frontend/editor-ui/src/app/stores/ui.utils.ts`.

Brand nuance: legacy HSL variables still describe the classic coral hsl(7,100%,68%) ≈ #ff6d5a, used only in the pulse-glow animation, link-active/slider-hover calculations and the rotating gradient on running canvas nodes (rgb 255,109,90). The live primary is orange-500 #ff6900.

## 3. Typography

- UI font **Inter** variable ("InterVariable", sans-serif fallback); bundled woff2 files (`DS/../assets/fonts/InterVariable.woff2`, italic); 100–900 range; `font-display: swap`. Licence: SIL OFL 1.1 (Rasmus Andersson).
- Mono font **Commit Mono** variable (`CommitMonoVariable.woff2`); fallback ui-monospace, Menlo, Consolas, DejaVu Sans Mono, monospace; its only `@font-face` is marked italic style. Licence: SIL OFL 1.1 (Eigil Nikolajsen). No OFL text shipped in the n8n repo → take both fonts from upstream.
- `element-icons.ttf/.woff` = Element Plus icon font (MIT), legacy.
- Body: 16px, line-height 1, weight 400, antialiased. Plain buttons default to 600; the design-system button uses 500.

| Name | 4xs | 3xs | 2xs | xs | sm | md | lg | xl | 2xl |
|---|---|---|---|---|---|---|---|---|---|
| px | 8 | 10 | 12 | **13** | **14** (workhorse) | 16 | 18 | 20 | 28 |

- Weights: 400, 500, 600 ("bold"); no 700.
- Line heights: xs 1.0, sm 1.25, md 1.3, lg 1.35, xl 1.5.
- Letter spacing: −0.05em, −0.025em, −0.01em, 0, 0.025em, 0.05em, 0.1em.

Text component ramp:

| Step | Size | Line height | Letter spacing |
|---|---|---|---|
| 4xs | 8px | 1.0 | wider |
| 3xs | 10px | 1.25 | wider |
| 2xs | 12px | 1.3 | normal |
| xs | 13px | 1.3 | normal |
| sm | 14px | 1.35 | normal |
| md | 16px | 1.35 | normal |
| lg | 18px | 1.5 | tight |
| xl | 20px | 1.5 | tight |
| 2xl | 28px | 1.5 | tighter |

Text "bold" = 500; Heading "bold" = 600; Heading 2xl/xl line-height 1.25.

## 4. Spacing, sizes, radius, borders, shadows, focus, motion, z-index

Spacing: 5xs 2, 4xs 4, 3xs 6, 2xs 8, xs 12, sm 16, md 20, lg 24, xl 32, 2xl 48, 3xl 64, 4xl 128, 5xl 256 px.

Control heights: 5xs 8, 4xs 12, 3xs 16, 2xs 20, xs 24, sm 28, md 32, lg 36, xl 40, 2xl 48, 3xl 56, 4xl 64, 5xl 96 px.

Radius (effective): 4xs 2, 3xs 4, 2xs 6, xs 8, sm 2, base 4, md 16, lg 8, xl 12, 2xl 32, full = pill.

Borders: default 1px solid; canvas nodes 1.5px (2px in success/error/warning); focus rings 2px; notice banner left accent 7px.

Shadows (colour black 10% light / 25% dark):

| Name | Shape |
|---|---|
| outline | 1px spread ring, no blur |
| 2xs | 1px down, no blur |
| xs | 1px down, 3px blur, −1px spread |
| sm | 4/6/−1 + 2/4/−2 |
| md | 10/15/−3 + 4/6/−4 |
| xl | 20/25/−5 + 8/10/−6 |

These match Tailwind shadow / shadow-md / shadow-lg / shadow-xl. Floating surfaces use md + outline ring.
Legacy: base 2px/4px at 20% + 6px glow at 10%; light 2px/12px at 10% (toasts, legacy dropdowns); card hover 2px/8px warm brown at 10%.

Focus ring:
- Standard: 2px outline purple at 25% (≈ #5a4cc2 base), no offset.
- Inputs: ring + 1px border/inset ring purple-500 #8e51ff.
- Offset variant: 2px solid purple-500 with 2px offset.
- Switch/checkbox: 2px ring secondary purple #7f22fe.
- Tabs and sidebar items: 1px inset purple outline.
- Older inputs: border turns secondary purple on focus.

Motion:
- Durations: snappy 200ms, base 400ms, slow 1000ms, slowest 1500ms; "blur reveal" 350ms.
- Easings: ease-out (0.215, 0.61, 0.355, 1), ease-in, ease-in-out, ~10% overshoot spring, out-quart, out-quint, out-expo.
- Popover/dropdown open 200ms: opacity 0→1, scale 0.96→1, 2px slide from anchor side.
- Fade-ins: 8px or 4px rise + 2px blur.
- All animation off under reduced motion.

Breakpoints: xs < 768, sm ≥ 768, md ≥ 992, lg ≥ 1200, xl ≥ 1920; dialogs fix widths from 640px.

Z-index: context menu 10; app header 99; select 100; sidebar/banners 999; node creator 1700; assistant chat 1750; node details 1800; dialog overlay/dialog 1949/1950; modals 2000; toasts 2100; floating UI 3000; drag layers 9,999,999. Element Plus layer: normal 1, top 1000, popper 2000, tooltip 2001.

App chrome: top nav 64px; content container 1280px; banner 48px; main sidebar 42px collapsed, 200–500px expanded (resizable).

## 5. Component look and feel

### Buttons
| Size | Height | H-padding | Radius | Font | Icon |
|---|---|---|---|---|---|
| xsmall | 24 | 8 | 4 | 12 | 10 |
| small | 28 | 12 | 4 | 13 | 12 |
| medium (default) | 32 | 12 | 4 | 14 | 14 |
| large | 36 | 16 | 6 | 14 | 16 |
| xlarge | 40 | 16 | 8 | 16 | 20 |

- Weight 500, line-height 1, icon–label gap 6px; icon-only = square; borders drawn as 1px inset ring.
- Solid: #ff6900 bg, white text; hover #f54900; pressed #ca3500; xs shadow.
- Subtle: surface bg + 1px border-colour ring + xs shadow; hover mixes 5% black (10% pressed; white in dark); ring 20% / 30%.
- Outline: transparent + ring; hover bg black 5%, pressed 10%.
- Ghost: transparent, no ring; hover 5%, pressed 10%.
- Destructive: light red-500 #fb2c36 → red-600 hover; dark red-600 → red-500 hover → red-400 pressed; white text; small soft shadow.
- Success: light green-600 → green-700; dark green-700 → green-600 → green-500.
- Disabled 50% opacity, not-allowed cursor. Loading: spinner replaces label (400ms/turn), swap fades with 4px rise + 2px blur over 200ms. Open menu trigger shows pressed colour. Focus: 2px purple ring.

### Inputs and v2 select trigger
| Size | Height | Radius | Font | H-padding |
|---|---|---|---|---|
| xlarge | 40 | 6 | 16 | 12 |
| large (default) | 36 | 6 | 14 | 12 |
| medium | 32 | 4 | 14 | 12 |
| small | 28 | 4 | 13 | 8 |
| mini | 24 | 4 | 12 | 8 |

- White bg (dark #171717); inset 1px ring black 10% → 20% hover; focus-within purple-500 ring + 2px purple 25% outline.
- Placeholder #999; disabled 60%; prefix/suffix icons 16px at 70%; add-on segments #f0f0f0 (dark #323232) with 1px divider; textarea line-height 1.3.
- Select panel: surface, md shadow + outline ring, input radius; min width max(trigger, 128px); max height ≈ 288px; inner padding 4px. Trigger variants ghost (hover black 5%) and flush.
- Legacy Element select/input: heights 40/36/30/26, radius 4, focus border secondary purple; options 34px tall, 0 20px padding, 14px, hover #f5f5f5, selected orange text 600; panel radius 4, 1px border, light shadow, max 274px; multi-select chips pills 20px radius on #e5e5e5.

### Tabs
- Default: row 24px; labels 14px/500 #444; 16px h-padding, ~10px bottom padding; hover orange; active orange + 2px orange underline.
- Modern: row 26px, 12px/600, 12px bottom padding. Small: 12px labels. Danger red; disabled #999; unread dot orange ~0.3em; hidden-scrollbar overflow with 10px arrow buttons.

### Tooltips
- v2: #000 bg, #f5f5f5 text, 13px/500, line-height 1.3; padding 4px 6px; min height 28px; max width 180px; radius 8px; sm shadow; no arrow; above, 8px offset; no show delay; hoverable; optional actions 16px below with 8px gap.
- Legacy: #171717, 12px, 10px padding, 4px radius, max 200px, 6px arrow.

### Dropdown menus
- Panel: white, radius 8, md shadow + 1px outline ring; min width 128; max height min(available, 75vh); padding 4; bottom fade.
- Items: row, gap 8, 14px, line-height 1.25, min height 32, padding 8, radius 6; highlight black 5%; disabled #bbb; destructive dark red on hover.
- Separators 1px border colour, 2px vertical margins, −4px horizontal bleed. Section headers padding 8 top/sides, 6 bottom. Submenus max ~24rem.
- Legacy: panel padding 10, radius 4, rows 36 with 16 h-padding.

### Dialogs
- Centred, fixed; padding 24; radius 8; white (dark #323232).
- Shadow stack: 0.5px ring; 8/8 at 10%; 32/32 at 10%; 64/64 at 6%; dark adds 1.5px top inner highlight.
- Widths from 640px viewport: small 360, medium 480 (default), large 564, xlarge 640, 2xlarge 780, fit, full, cover; below 640: viewport − 24px.
- Overlay black 30% (dark 60%) + 8px backdrop blur.
- Animation 200ms ease-out: fade, 8px rise, scale 0.98→1.
- Header column gap 8; title 18px/500/1.35 #262626 (dark #f5f5f5); description 14px #323232 (dark #e5e5e5); footer right-aligned, gap 8, 20px above.
- Close button 24×24, 16px from top-right, radius 4, hover #f5f5f5.
- Legacy modal: min 420, max 80%, padding 24, title 20px/400, overlay slate-violet ~75%.

### Badges
- Pill, 1px border, weight 500.
- Sizes: xxsmall 20/12px; xsmall 24/12px (default); small 28/13px; medium 32/13px (12px padding); large 36/14px (16px padding); xlarge 40/14px. Up to small: 8px h-padding. Icons 14px (20px large).
- Variants: filled #e5e5e5 (dark #444) / #444 text; primary orange/white; secondary purple-200/purple-900; subtle surface + border + xs shadow; outline (default) transparent + border; ghost; warning yellow-200/yellow-900; danger red-200/red-900; success green-200/green-900; info blue-200/blue-900.
- Clickable: −5% hover, −10% pressed; disabled 60%.

### Tags
- 1px border, radius 4, weight 400. sm (default) 20px / 0 4px / 12px; md 24px / 4px 8px / 13px; lg 28px / 4px 8px / 13px.
- Light: #f5f5f5 bg, #f0f0f0 border; hover #f0f0f0/#e5e5e5; active #e5e5e5/#e0e0e0. Dark: #444 bg, #323232 border. 300ms background transition.

### Cards
- Radius 8, 1px border, white, padding 16; row layout; optional icon column 24px wide + 16px gap; hoverable cards turn border and text orange over 300ms.

### Tables
- Container radius 8, 1px #e5e5e5 border, clips content; body 14px.
- Header sticky, 36px, #f5f5f5, 12px/600 title case, #444.
- Rows 48px, white; hover #fafafa; 1px #e5e5e5 separators.
- Cell padding 8px horizontal, 16px at first/last column.
- Loading: 2px orange indeterminate bar; rows dim to 38%.
- Older tokens: even rows #fafafa; hover light orange #ffedd4.

### Switch, toggle, checkbox
- Switch small (default) track 32×16, knob 12×12 (radius 6); large 40×20, knob 16×16 (radius 8); pill track with 1px border.
- Off #bbb (dark #171717 track, #444 border); on green-500 #00c950; knob white (dark #f5f5f5) with 1px/2px shadow at 20%; 2px inset; slides 200ms ease-out; stretches 2px on hover/press; focus 2px purple ring; label 14px (12px small), line-height 1.25, 8px gap; disabled 60%.
- Toggle button shares button sizes; pressed uses active background.
- Checkbox 16×16, radius 4, 1px border; checked orange with white tick; disabled checked #e5e5e5; focus 2px purple ring.

### Callouts
- 12px, line-height 1.5, padding 12 (slim 6px 8px), 1px border, radius 4; icon left with 12px gap (info / circled check / warning triangle), 14px icons.

| Theme | Border | Background | Text |
|---|---|---|---|
| info | #e5e5e5 | white | #444 (icon #999) |
| success | #b9f8cf | #f0fdf4 | #00a63e |
| warning | #f4d8ae | #fdf9f1 | #b57617 |
| danger | #ffe2e2 | #fef2f2 | #e7000b |
| secondary | #c4b4ff | #ddd6ff | #7f22fe, 600 |

Dark: background is a deep shade (green-900, gold-800, red-950, purple 25%), text white. Links inside: secondary purple, 500, underlined.

### Notice banners
- 12px, line-height 1.25, padding 8, vertical margin 16; border 1px top/right/bottom + **7px left**; radius 2.
- warning (default) #f4d8ae / #fdf9f1; danger #ffe2e2 / #fef2f2; success #b9f8cf / #f0fdf4; info #e5e5e5 / #f5f5f5. Dark warning: gold-200 border on gold 20%. Links 600.

### Toasts
- 330px wide; padding 14 26 14 13; radius 8; 1px #f0f0f0 border; white (dark #2b2b2b); light shadow; title 16px/600 capitalised; body 14px/1.5; status icon 24px; 16px from right; slides in from right.

### Sidebar menu items
- Min height 32, padding 4, gap 4, radius 4, text #444; hover/active #f5f5f5 bg, text #262626.

### Scrollbars
- 6px wide, thumb radius 5, thumb #e5e5e5 → #999 hover; menus use a hover-only variant.

### Canvas (reference)
- Grid 16px; default nodes 96×96 radius 8; trigger left radius 36px; selected node 6px translucent navy halo; running node rotating orange-coral conic gradient border (1.5s/turn); canvas library Vue Flow (MIT).

## 6. Icons
- Main set **Lucide** (ISC), via Iconify JSON + unplugin-icons; curated ≈247 names; runtime fallback renders any Lucide name at stroke 1.5. Allowed-name list: `DS/components/N8nIcon/icons.ts`.
- No Font Awesome dependency remains.
- Sizes: default 1em; xsmall 10, small 12, medium 14, large 16, xlarge 20, xxlarge 40; current text colour; per-icon stroke width.
- Custom SVGs: 52 in `DS/components/N8nIcon/custom/` (status/node-state glyphs, third-party brand marks); 80 core-node icons in `DS/components/N8nIcon/nodes/`.

## 7. Proprietary and trademark assets — never reuse
- n8n logo and marks: `DS/components/N8nLogo/` (logo-icon.svg, logo-text.svg, Logo.vue); `editor-ui/public/favicon.ico`; `editor-ui/public/static/n8n-logo.png`, `og_image.png`; `iphi-flow/n8n/assets/n8n-logo.png` and screenshots; `packages/cli/src/user-management/email/templates/n8n-logo.png`; storybook logos; `@n8n/chat/public/favicon.ico`.
- Custom icon artwork: `N8nIcon/custom/`, `N8nIcon/nodes/`; inline SVG in `AskAssistantIcon/AssistantIcon.vue`, `N8nCircleLoader`, `N8nSpinner`.
- Illustrations: `editor-ui/public/static/` (openChat.png, community_package_tooltip_img.png, data-mapping-gif.gif, webhook-icon.svg, form-grey.svg, open-ai.svg); `@n8n/chat/resources/images/`; ≈29 editor-ui components with inline SVG art (EntityNotFound.vue, EntityUnAuthorised.vue, OAuthConsentView.vue, AiStarsIcon.vue, TidyUpIcon.vue, canvas run button, plus-handle, experiment graphics).
- Third-party trademarks: `editor-ui/src/features/ai/gateway/assets/service-icons/`; `editor-ui/src/features/integrations/externalSecrets.ee/assets/images/` (also enterprise-licensed); `editor-ui/src/features/ai/instanceAi/assets/os-icons/`.
- Integration node icons: `packages/nodes-base/nodes/` (≈357 SVG, 68 PNG); `packages/@n8n/nodes-langchain/` (≈101 SVG).
- Signature treatments: AI-assistant gradient #5b60e8 → #aa7bec → #ec7b8e at 105°; legacy coral #ff6d5a (logo colour).
- Component docs link to n8n's private Figma file.

## 8. Licensing
- Repo root `LICENSE.md`: Sustainable Use License 1.0 (internal business, non-commercial or personal use; redistribution only free of charge for non-commercial purposes).
- `.ee.` files and `.ee` directories: `LICENSE_EE.md`, paid enterprise licence.
- Design-system package: no separate LICENSE; package.json declares `LicenseRef-n8n-sustainable-use`; no `.ee` files. Its CSS, SVG and component code are under the Sustainable Use License.
- Element Plus–derived parts of `DS/css/` (`common/var.scss`, BEM mixins, per-component Element styles) originate from MIT "theme-chalk".
- ≈40+ `.ee` files/folders in editor-ui and `@n8n/rest-api-client`.
- Underlying libraries: Inter (OFL 1.1), Commit Mono (OFL 1.1), Lucide (ISC), Iconify packaging (MIT; each set its own licence), Element Plus (MIT), Reka UI (MIT), Vue Flow (MIT).
- Clean-room takeaway: measurements and colour values are facts; the ramps are effectively Tailwind v4 defaults; fonts and icons are available upstream under permissive licences; never copy n8n SCSS, Vue code, SVG, PNG or bundled font files.
