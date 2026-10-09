# 01 — Tokens (TOK)

The target theme expressed in AP's own token architecture. AP keeps its five 12-step scales (`gray`, `accent`, `success`, `warning`, `danger`), its step jobs, its named exceptions and its `@theme` keys. Only values change, plus the few additions this file names.

Conventions in this file:

- "TW" means the Tailwind CSS v4.1.17 default palette (MIT), the exact version AP ships. Hex values for TW colours are the sRGB conversions of TW's oklch values. TW v4 values differ from v3 in places; for example TW v4 neutral-400 is `#a1a1a1`, not v3's `#a3a3a3`.
- "Non-TW" marks a value the target needs that Tailwind does not have. The value to use is given.
- oklch values are written as lightness, chroma, hue. AP writes greys as literal oklch with zero chroma.
- Contrast figures are WCAG 2 ratios.

---

### TOK-01 — What changes, and where

| Item | Detail |
|---|---|
| Values | Every grey step (TOK-02), the accent ramp (TOK-04), the warning ramp (TOK-06), the dark steps 1–8 of success and danger and the light steps 10–11 of success (TOK-05, TOK-07), `--panel` dark, `--scrim`, four new exceptions (TOK-08), radius (TOK-12), shadows (TOK-13), mono font (TOK-14), type ramp (TOK-15), weights (TOK-16), z-index layers (TOK-20) |
| AP target | `packages/web/src/styles.css`: the `@theme inline` colour mapping (add the new exceptions), the `@theme` block (radius, shadows, text sizes, weights, easings, default transition), both theme blocks (light and dark). `packages/core/shared/src/lib/core/common/brand-colors.ts` (TOK-09). `packages/web/src/lib/brand-seed.ts`, `packages/server/api/src/app/flags/theme.ts`, `packages/web/src/app/routes/platform/setup/general/appearance-section.tsx` and `color-preview.tsx` (TOK-09) |
| Unchanged | The step jobs (1 app background … 12 main text), the swatch families, the chart mapping, the light/dark switching mechanism, the shadow indirection rule |
| Notes | The coloured ramps in CSS must stay exactly the generator's output; `packages/web/test/styles/status-scales.test.ts` enforces this. So the coloured values in TOK-04 to TOK-07 are produced by changing the generator's parameters (TOK-09) and regenerating, not by typing hex into CSS |

---

### TOK-02 — Grey scale

The grey scale stays pure neutral (zero chroma) in both themes. Steps 2 and 3 are equal in light, and steps 1 and 2 are equal in dark, because the target puts the canvas on the page tone in dark mode and puts chips and table headers on the canvas tone in light mode. Steps 5 and 6 are equal in both themes because the target's pressed tone and its hairline are the same grey.

**Light**

| Step | AP job | Target role it serves | Value | Source | oklch |
|---|---|---|---|---|---|
| 1 | App background | Page background | `#fafafa` | TW neutral-50 | 98.5% 0 0 |
| 2 | Sidebar + flow canvas | Canvas background (verification probe: rgb 245,245,245) | `#f5f5f5` | TW neutral-100 | 97% 0 0 |
| 3 | Component background | Table header, tag fill, step-modal side panes, tinted rows | `#f5f5f5` | TW neutral-100 | 97% 0 0 |
| 4 | Component hover | Hover fill of ghost buttons, menu rows, tags; input add-on segment | `#f0f0f0` | Non-TW (the target's hover grey; ≈ black 5% over white) | 95.51% 0 0 |
| 5 | Component pressed | Pressed fill, filled badge, segmented-control track, selected pager button | `#e5e5e5` | TW neutral-200 | 92.2% 0 0 |
| 6 | Divider | Every default hairline: card, table, input, sidebar and header borders, separators | `#e5e5e5` | TW neutral-200 | 92.2% 0 0 |
| 7 | Component border | Hovered control border (≈ black 20% over white), canvas edge stroke (EDG) | `#d4d4d4` | TW neutral-300 | 87% 0 0 |
| 8 | Strong border | Stronger border (≈ black 30%), switch-off track, disabled ink | `#bbbbbb` | Non-TW (TW neutral-300 `#d4d4d4` is too light, neutral-400 `#a1a1a1` too dark) | 79.21% 0 0 |
| 9 | Solid / quiet decoration ink | Canvas dots, empty-state glyph, scrollbar thumb on hover | `#999999` | Non-TW (TW neutral-400 `#a1a1a1` is the nearest; the target is slightly darker) | 68.3% 0 0 |
| 10 | Small mark | Neutral status dot, small marks that must read 3:1 on the page | `#8a8a8a` | Non-TW (chosen so a mark reads 3.3:1 on the page) | 63.34% 0 0 |
| 11 | Quiet text | Secondary text: subtitles, meta lines, descriptions, placeholders, helper text | `#737373` | TW neutral-500 | 55.6% 0 0 |
| 12 | Main text | Titles, body, cell text; inverse ground | `#262626` | TW neutral-800 | 26.9% 0 0 |

**Dark**

| Step | AP job | Target role it serves | Value | Source | oklch |
|---|---|---|---|---|---|
| 1 | App background | Page background | `#171717` | TW neutral-900 | 20.5% 0 0 |
| 2 | Sidebar + flow canvas | Canvas background (probe: rgb 23,23,23) | `#171717` | TW neutral-900 | 20.5% 0 0 |
| 3 | Component background | Table header, tag-ish chips, step-modal centre pane, node fill (NOD) | `#2b2b2b` | Non-TW | 28.91% 0 0 |
| 4 | Component hover | Hover fill; segmented-control track; dark dialog surface (PRM-11) | `#323232` | Non-TW | 31.71% 0 0 |
| 5 | Component pressed | Pressed fill, selected pager button | `#3a3a3a` | Non-TW (≈ white 15% over the page) | 34.85% 0 0 |
| 6 | Divider | Every default hairline, input border | `#3a3a3a` | Non-TW | 34.85% 0 0 |
| 7 | Component border | Hovered control border (≈ white 20% over the page), canvas dots (TOK-08), canvas edge stroke (EDG) | `#444444` | Non-TW (TW neutral-700 is `#404040`) | 38.67% 0 0 |
| 8 | Strong border | Stronger border (≈ white 40% over the panel), disabled ink | `#737373` | TW neutral-500 | 55.6% 0 0 |
| 9 | Solid / quiet decoration ink | Decorative glyphs | `#8a8a8a` | Non-TW | 63.34% 0 0 |
| 10 | Small mark | Neutral marks | `#a1a1a1` | TW neutral-400 | 70.8% 0 0 |
| 11 | Quiet text | Secondary text, placeholders, empty-state glyph | `#bbbbbb` | Non-TW (the target's dark secondary text) | 79.21% 0 0 |
| 12 | Main text | Titles and body; inverse ground | `#ffffff` | TW white | 100% 0 0 |

| Item | Detail |
|---|---|
| States | Hover rule: a component hovers one step up (3 → 4), presses to 5. A row on the page or on a panel hovers to `gray-1` in tables (PRM-16) and to `gray-4` in menus (PRM-09) |
| Light/Dark | Authored independently, as AP requires. The target's translucent overlays (black 5% / 10%, white 10% / 15%) are replaced by these solid steps |
| AP target | `packages/web/src/styles.css`, both theme blocks, `--gray-1` … `--gray-12` |
| Notes | The target sidebar is the raised surface (white in light, `#262626` in dark), not step 2: see SHL. Anything that used `gray-2` to separate itself from the page in dark mode must move to `--panel`. `body` stays `bg-gray-1 text-gray-12`. The global default border colour stays `gray-6`. The light quiet-text value is darker than the target's `#999` on purpose (TOK-22) |

---

### TOK-03 — Text tiers

The target has four text tiers and one decoration ink. AP has two text steps, so the third tier is an opacity on the main ink, which AP's colour rules allow ("an opacity on an ink is a prominence no step provides").

| Tier | Use | Light | Dark | AP utility |
|---|---|---|---|---|
| Main | Titles, body, table cells, input text | `#262626` | `#ffffff` | `text-gray-12` |
| Subtle | Tab labels at rest, table header labels, badge and tag text, dialog descriptions, empty-state descriptions | ≈ `#424242` (target `#444444`) | ≈ `#e3e3e3` (target `#e5e5e5`) | `text-gray-12/87` |
| Quiet | Subtitles, meta lines, placeholders, helper text, timestamps | `#737373` (target `#999999`, see TOK-22) | `#bbbbbb` | `text-gray-11` |
| Disabled | Disabled labels and items | `#bbbbbb` | `#737373` | `text-gray-8` |
| Decoration | Empty-state glyph (light), canvas dots, idle decorative icons | `#999999` | `#8a8a8a` | `text-gray-9` |

| Item | Detail |
|---|---|
| States | Hovered tab and link labels switch to brand orange (`text-accent-9`), see PRM-06 |
| AP target | Used by the primitives in `02-primitives.md`; no new token |
| Notes | Do not put `text-gray-11` on `gray-3`, `gray-4` or `gray-5` grounds in primitives; use subtle text there (TOK-22) |

---

### TOK-04 — Accent scale (brand orange)

Accent becomes the Tailwind orange family with step 9 = TW orange-500 `#ff6900`. The values below are the generator's output after the TOK-09 changes; they are exact TW orange shades except where marked "interpolated" (the generator's in-between shades 25, 150 and 250) or "contrast-adjusted" (the generator lowers step 11 until it reads 4.5:1 on every chip ground).

| Step | AP job | Target role | Light value (oklch) | Light source | Dark value (oklch) | Dark derivation |
|---|---|---|---|---|---|---|
| 1 | App background tint | Faintest brand wash | `#fffbf6` (99% 0.008 73.68) | Orange "25", interpolated | `#251510` (21.5% 0.0277 36.26) | Orange-950 hue, dark surface ladder |
| 2 | Subtle tint | Hover wash on brand items | `#fff7ed` (98% 0.016 73.68) | TW orange-50 | `#311913` (24.5% 0.0395 36.26) | Orange-950 hue |
| 3 | Component bg | Brand tint 3: running-step fill (NOD), drag pill fill (NDV), inverted badge | `#ffedd4` (95.4% 0.038 75.16) | TW orange-100 | `#3e2119` (28.5% 0.0474 36.26) | Orange-950 hue |
| 4 | Hover | Hover of brand tints | `#ffe1be` (92.75% 0.057 70.7) | Orange "150", interpolated | `#522010` (31.5% 0.08 38.17) | Orange-900 hue |
| 5 | Pressed | Brand tint 2 | `#ffd6a7` (90.1% 0.076 70.7) | TW orange-200 | `#5d2614` (34.5% 0.0861 38.17) | Orange-900 hue |
| 6 | Divider | Hairline on brand tints | `#ffc78b` (86.9% 0.102 66.29) | Orange "250", interpolated | `#6f2309` (37% 0.113 37.3) | Orange-800 hue |
| 7 | Component border | Border of brand-tinted chips; selected outline | `#ffb86a` (83.7% 0.128 66.29) | TW orange-300 | `#7d2d13` (41% 0.1178 37.3) | Orange-800 hue |
| 8 | Strong border | Brand tint 1 (the target's brand focus tone) | `#ff8904` (75% 0.183 55.93) | TW orange-400 | `#9f2e00` (47% 0.156 38.4) | Orange-700 hue |
| 9 | Solid fill | Primary brand: solid button, checked checkbox, tab underline, active tab label, links, loading bar | `#ff6900` | TW orange-500 | `#ff6900` | TW orange-500 |
| 10 | Small mark | Solid hover (light), brand marks | `#f54900` (64.6% 0.222 41.12) | TW orange-600 | `#ff8904` (75% 0.183 55.93) | TW orange-400 |
| 11 | Quiet text | Solid pressed (light), brand text on tints | `#c32d00` (53.3% 0.195 38.4) | TW orange-700 `#ca3500`, contrast-adjusted | `#ffb86a` (83.7% 0.128 66.29) | TW orange-300 |
| 12 | Main text | Deep brand text on tints | `#7e2a0c` (40.8% 0.123 38.17) | TW orange-900 | `#ffedd4` (95.4% 0.038 75.16) | TW orange-100 |

| Item | Detail |
|---|---|
| States | Solid hover = `accent-10`, pressed = `accent-11`, in light. In dark AP's steps 10–11 are light tints, so the solid button is a light island (PRM-01) and shows the same three oranges in both themes, as the target does |
| Light/Dark | Step 9 is the same hex in both themes |
| AP target | `styles.css` theme blocks, `--accent-1` … `--accent-12`, each keeping AP's override-with-fallback form (`--accent-light-N` / `--accent-dark-N` override, generated value as fallback) |
| Notes | The label on `accent-9` is white (`--on-accent`, TOK-08). The generator would pick black for `#ff6900`; that is why `--on-accent` stays a fixed exception and brand-seed must not write it (TOK-09). See the never-use list in `00-index.md` |

---

### TOK-05 — Success scale (green)

AP's success already matches the target: step 9 = TW green-600 `#00a63e`. Only light steps 10–11 move slightly (new chip grounds) and the dark surfaces 1–8 lift (new dark ladder).

| Step | Target role | Light (oklch) | Light source | Dark (oklch) | Dark source |
|---|---|---|---|---|---|
| 1 | — | `#f8fefa` (99.1% 0.009 155.83) | Green "25" | `#111d14` (21.5% 0.0228 152.93) | Green-950 hue |
| 2 | Success callout / notice background | `#f0fdf4` (98.2% 0.018 155.83) | TW green-50 | `#142519` (24.5% 0.0325 152.93) | Green-950 hue |
| 3 | Success tint | `#dcfce7` (96.2% 0.044 156.74) | TW green-100 | `#1a3021` (28.5% 0.039 152.93) | Green-950 hue |
| 4 | — | `#cbfadb` (94.35% 0.064 156) | Green "150" | `#153a22` (31.5% 0.0618 152.53) | Green-900 hue |
| 5 | Success badge fill, callout / notice border | `#b9f8cf` (92.5% 0.084 156) | TW green-200 | `#1a4328` (34.5% 0.0665 152.53) | Green-900 hue |
| 6 | — | `#9df5bb` (89.8% 0.117 154.45) | Green "250" | `#134c27` (37% 0.0857 151.33) | Green-800 hue |
| 7 | Success border | `#7bf1a8` (87.1% 0.15 154.45) | TW green-300 | `#1d5830` (41% 0.0893 151.33) | Green-800 hue |
| 8 | — | `#05df72` (79.2% 0.209 151.71) | TW green-400 | `#0e6d33` (47% 0.1232 150.07) | Green-700 hue |
| 9 | Success solid: switch on, success marks, success edge after a run (EDG), success node border (NOD) | `#00a63e` | TW green-600 | `#00a63e` | TW green-600 |
| 10 | Success small mark | `#00a43c` (62.2% 0.194 149.21) | TW green-600, contrast-adjusted | `#05df72` (79.2% 0.209 151.71) | TW green-400 |
| 11 | Success text | `#00772b` (49.2% 0.154 150.07) | TW green-700 `#008236`, contrast-adjusted | `#7bf1a8` (87.1% 0.15 154.45) | TW green-300 |
| 12 | Success badge text | `#0d542b` (39.3% 0.095 152.53) | TW green-900 | `#dcfce7` (96.2% 0.044 156.74) | TW green-100 |

| Item | Detail |
|---|---|
| Light/Dark | `--on-success` stays black (`#000000`), the generator's measured label for `#00a63e` |
| AP target | `styles.css`, `--success-1` … `--success-12` |
| Notes | The target's switch-on green is TW green-500 `#00c950`, which is not a step; the switch uses `success-9` (PRM-17) |

---

### TOK-06 — Warning scale (yellow, standing in for the target's gold)

The target's warning colour is a custom gold `#b57617` (oklch 61.78% 0.1267 70.31) that Tailwind does not have.

- **Nearest Tailwind value: yellow-700 `#a65f00`.** It has the smallest OKLab distance to the gold (0.065; next are yellow-600 `#d08700` at 0.067 and amber-600 `#e17100` at 0.078). Unlike yellow-600 (2.9:1) it reads 4.9:1 on white, so it can carry warning text, which is how the target uses the gold.
- The warning scale is therefore the **Tailwind yellow family**. The gold role (warning text, warning icons, the "dirty" mark) lands on steps 11 and 10, which the generator derives from yellow-700 and yellow-600.
- Step 9 (the bright solid) is TW yellow-500 `#f0b100`, which is also the target's "unpublished changes" status dot. This keeps AP's rule that `warning-9` is a bright solid with a dark label.
- The amber family is rejected: its 600/700 shades are orange-brown and sit too close to the new brand orange.

| Step | Target role | Light (oklch) | Light source | Dark (oklch) | Dark source |
|---|---|---|---|---|---|
| 1 | — | `#fefdf4` (99.35% 0.013 102.21) | Yellow "25" | `#22170f` (21.5% 0.0231 53.81) | Yellow-950 hue |
| 2 | Warning callout / notice background | `#fefce8` (98.7% 0.026 102.21) | TW yellow-50 | `#2d1c11` (24.5% 0.033 53.81) | Yellow-950 hue |
| 3 | Warning tint (the target's status-warning fill) | `#fef9c2` (97.3% 0.071 103.19) | TW yellow-100 | `#3a2517` (28.5% 0.0396 53.81) | Yellow-950 hue |
| 4 | — | `#fff4a5` (95.9% 0.1 101.54) | Yellow "150" | `#49290e` (31.5% 0.0618 57.71) | Yellow-900 hue |
| 5 | Warning badge fill, callout / notice border | `#fff085` (94.5% 0.129 101.54) | TW yellow-200 | `#532f12` (34.5% 0.0665 57.71) | Yellow-900 hue |
| 6 | — | `#ffe75e` (92.5% 0.1555 98.11) | Yellow "250" | `#5e3404` (37% 0.0821 61.91) | Yellow-800 hue |
| 7 | Warning border | `#ffdf20` (90.5% 0.182 98.11) | TW yellow-300 | `#6b3e0f` (41% 0.0855 61.91) | Yellow-800 hue |
| 8 | — | `#fdc700` (85.2% 0.199 91.94) | TW yellow-400 | `#824c00` (47% 0.108 66.44) | Yellow-700 hue |
| 9 | Bright warning solid, "unpublished changes" dot | `#f0b100` | TW yellow-500 | `#f0b100` | TW yellow-500 |
| 10 | Gold mark: "dirty" step border (NOD), warning dots | `#c77e00` (65.1% 0.162 75.83) | TW yellow-600 `#d08700`, contrast-adjusted to 3:1 | `#fdc700` (85.2% 0.199 91.94) | TW yellow-400 |
| 11 | Gold text: warning callout text, warning icons, missing-connection key icon | `#9b5500` (51.9% 0.135 66.44) | TW yellow-700 `#a65f00`, contrast-adjusted to 4.5:1 | `#ffdf20` (90.5% 0.182 98.11) | TW yellow-300 |
| 12 | Warning badge text | `#733e0a` (42.1% 0.095 57.71) | TW yellow-900 | `#fef9c2` (97.3% 0.071 103.19) | TW yellow-100 |

| Item | Detail |
|---|---|
| Light/Dark | `--on-warning` stays black (`#000000`); the generator measures black for `#f0b100` |
| AP target | `styles.css`, `--warning-1` … `--warning-12`; generator anchor in `brand-colors.ts` (TOK-09) |
| Notes | The target's callout tints are a desaturated gold (background `#fdf9f1`, border `#f4d8ae`) that no Tailwind family matches; callouts use the yellow steps 2 and 5 instead (PRM-20, PRM-21). AP's previous warning-9 was amber-500 `#fe9a00`; every `bg-warning-9` call site becomes yellow |

---

### TOK-07 — Danger scale (red)

AP's danger already matches the target: step 9 = TW red-600 `#e7000b`.

| Step | Target role | Light (oklch) | Light source | Dark (oklch) | Dark source |
|---|---|---|---|---|---|
| 1 | — | `#fff9f9` (98.55% 0.0065 17.38) | Red "25" | `#271312` (21.5% 0.0322 26.04) | Red-950 hue |
| 2 | Danger callout / notice background | `#fef2f2` (97.1% 0.013 17.38) | TW red-50 | `#331715` (24.5% 0.046 26.04) | Red-950 hue |
| 3 | Danger callout / notice border, destructive menu-row highlight | `#ffe2e2` (93.6% 0.032 17.72) | TW red-100 | `#411e1b` (28.5% 0.0552 26.04) | Red-950 hue |
| 4 | — | `#ffd6d5` (91.05% 0.047 18.33) | Red "150" | `#571917` (31.5% 0.0917 25.72) | Red-900 hue |
| 5 | Danger badge fill | `#ffc9c9` (88.5% 0.062 18.33) | TW red-200 | `#631f1d` (34.5% 0.0987 25.72) | Red-900 hue |
| 6 | — | `#ffb6b5` (84.65% 0.088 19.57) | Red "250" | `#751816` (37% 0.1274 26.9) | Red-800 hue |
| 7 | Danger border | `#ffa2a2` (80.8% 0.114 19.57) | TW red-300 | `#83221f` (41% 0.1327 26.9) | Red-800 hue |
| 8 | — | `#ff6467` (70.4% 0.191 22.22) | TW red-400 | `#a51f1c` (47% 0.1704 27.52) | Red-700 hue |
| 9 | Danger solid: destructive button, error node border (NOD), invalid field border | `#e7000b` | TW red-600 | `#e7000b` | TW red-600 |
| 10 | Danger mark | `#e7000b` (57.7% 0.245 27.32) | TW red-600 | `#ff6467` (70.4% 0.191 22.22) | TW red-400 (the target's dark-mode danger) |
| 11 | Danger text; destructive hover | `#c10007` (50.5% 0.213 27.52) | TW red-700 | `#ffa2a2` (80.8% 0.114 19.57) | TW red-300 |
| 12 | Danger badge text | `#82181a` (39.6% 0.141 25.72) | TW red-900 | `#ffe2e2` (93.6% 0.032 17.72) | TW red-100 |

| Item | Detail |
|---|---|
| Light/Dark | `--on-danger` stays white (`#ffffff`) |
| AP target | `styles.css`, `--danger-1` … `--danger-12` |
| Notes | The target's destructive button rests on TW red-500 `#fb2c36`, which is not a step; it uses `danger-9` (PRM-01) |

---

### TOK-08 — Named exceptions

| Token | Light | Dark | Why it is an exception |
|---|---|---|---|
| `--panel` | `#ffffff` (TW white) | `#262626` (TW neutral-800); was `gray-2` | Raised surface: cards, menus, popovers, inputs' ground, header, sidebar. Lighter than the page in both themes |
| `--on-accent` | `#ffffff` | `#ffffff` | White label on the orange solid, fixed (the generator would measure black) |
| `--on-success` | `#000000` | `#000000` | Unchanged |
| `--on-warning` | `#000000` | `#000000` | Unchanged; generator's label for `#f0b100` |
| `--on-danger` | `#ffffff` | `#ffffff` | Unchanged |
| `--scrim` | black 30% | black 60% | Dialog and sheet overlay (target). Was black 70% in both |
| `--scrim-strong` (new) | black 60% | black 60% | Step-modal overlay (NDV). No step or the plain scrim can be 60% in light |
| `--focus` (new) | `#8e51ff` (TW violet-500) | `#8e51ff` | Focus border and solid focus rings. A fixed violet in both themes; no scale holds violet |
| `--focus-halo` (new) | TW indigo-700 `#432dd7` at 25% alpha (oklch 45.7% 0.24 277.02, alpha 25%) | same | The soft 2px focus outline. The target's halo base is a violet-indigo `#5a4cc2` at 25% that Tailwind lacks; indigo-700 is the nearest TW value (OKLab distance 0.079; violet-600 is 0.12). On white it composites to ≈ `#d0cbf5`, target ≈ `#d6d2f0` |
| `--canvas-dot` (new) | `gray-9` (`#999999`) | `gray-7` (`#444444`) | Canvas grid dots. The target's dot sits at different steps in the two themes, so no single step can do it (consumed by CAN) |

| Item | Detail |
|---|---|
| States | — |
| AP target | `styles.css`: define each in both theme blocks (`--on-accent` stays in the `:root` block); map the new ones in `@theme inline` as `--color-scrim-strong`, `--color-focus`, `--color-focus-halo`, `--color-canvas-dot` so utilities such as `bg-scrim-strong`, `border-focus`, `ring-focus`, `outline-focus-halo` exist |
| Notes | Two plain per-theme variables for scrollbars are defined in the theme blocks as references to steps (not new colours): thumb at rest = light `gray-6`, dark `gray-8`; thumb on hover = light `gray-9`, dark `gray-11` (PRM-23). The exceptions list in `colour.md` grows from six to ten (TOK-23) |

---

### TOK-09 — Hard-coded palette and the ramp generator

Platform brand colours stop overriding the UI. Logos, favicon and product name stay white-label.

| Item | Detail |
|---|---|
| Values — generator (`packages/core/shared/src/lib/core/common/brand-colors.ts`) | `DEFAULT_ACCENT_SOLID` → `#ff6900`. Scale anchors: accent → orange family, shade 500; warning → yellow family, shade 500; danger (red 600) and success (green 600) unchanged. The exact-anchor check also applies to the accent scale (drop its accent exclusion), so the stock accent ramp is the pure orange family with no hue shift or chroma scaling. Text grounds for light (panel + grey 1–5) → 100, 98.5, 97, 95.5, 92.2. Mark grounds for light → 100, 98.5, 97. Text grounds for dark (grey 1–5 + panel) → 20.5, 26.9, 28.9, 31.7, 34.9. Mark grounds for dark → 20.5, 26.9. Dark surface ladder lightness for steps 1–8 → 21.5, 24.5, 28.5, 31.5, 34.5, 37, 41, 47 (chroma shares unchanged) |
| Values — CSS | Every coloured fallback in both theme blocks, every swatch role (`--swatch-N-mark/surface/ink/line/on`) and the three `--on-*-seed` fallbacks are regenerated from the changed generator. The expected results for the four ramps are the tables in TOK-04 to TOK-07 |
| Values — server | `defaultTheme` in `packages/server/api/src/app/flags/theme.ts`: primary `#6e41e2` → `#ff6900` |
| Brand seed | `packages/web/src/lib/brand-seed.ts` stops writing the accent and status variables (and `--on-accent`). The theme provider keeps setting title, favicon and logos. The CSS fallbacks are then the only colours |
| Admin UI | `routes/platform/setup/general/appearance-section.tsx` and `color-preview.tsx`: remove the primary and status colour pickers and their live preview; keep the logo and favicon fields |
| Tests | `packages/web/test/styles/status-scales.test.ts` passes unchanged once the CSS equals the regenerated output. `packages/web/test/lib/brand-seed.test.ts` asserts that no colour variable is written. `appearance-section.test.tsx` drops the colour-picker cases |
| Version | Bump `@activepieces/shared` (behaviour change of the default ramps). AP's rule asks for a minor bump for behaviour changes; check whether the branch has already bumped it |
| Light/Dark | Both theme blocks |
| AP target | `packages/core/shared/src/lib/core/common/brand-colors.ts`, `packages/server/api/src/app/flags/theme.ts`, `packages/web/src/lib/brand-seed.ts`, `packages/web/src/app/routes/platform/setup/general/appearance-section.tsx`, `packages/web/src/app/routes/platform/setup/general/color-preview.tsx`, `packages/web/src/styles.css`, `packages/web/test/styles/status-scales.test.ts`, `packages/web/test/lib/brand-seed.test.ts`, `packages/core/shared/package.json` |
| Notes | Out of scope: email templates keep `{{primaryColor}}`. The guard `scripts/check-tailwind-classes.mjs` must pass with the new `@theme` keys. Grey values are not produced by the generator; type them as in TOK-02 |

---

### TOK-10 — Swatches and charts

| Item | Detail |
|---|---|
| Values | Same twelve families and the same chart sampling (swatches 1, 5, 9, 3, 7). Their surface, line and ink values shift because the generator's grounds and dark ladder change (TOK-09); regenerate them |
| AP target | `styles.css`, `--swatch-*` in both theme blocks |
| Notes | Swatch 11 (blue) is used for the info badge (PRM-13), since AP has no blue scale |

---

### TOK-11 — Focus ring

The focus ring becomes violet. It replaces AP's neutral `gray-8` ring everywhere in the primitives. `gray-8` stays the strong-border step.

| Recipe | Look | Used by |
|---|---|---|
| A — halo | 2px outline in `--focus-halo`, no offset, following the element's radius | Buttons, icon buttons, links, clickable cards and badges, toggles |
| B — field | Recipe A plus the element's 1px border (or inset ring) turning `--focus` | Inputs, textarea, select trigger, combobox, the subtle and outline buttons |
| C — offset | 2px solid `--focus` outline with a 2px offset | Segmented-control items, radio controls |
| D — inset | 1px solid `--focus` outline drawn 1px inside the element (no layout shift) | Underline tabs, sidebar rows (SHL) |
| (none) | No ring; keyboard focus shows as the row's highlight fill | Menu, select and command rows (PRM-05, PRM-09) |
| E — solid ring | 2px solid `--focus` ring, no offset | Switch, checkbox |

| Item | Detail |
|---|---|
| States | Shown on keyboard focus (focus-visible) only; fields show B while focused by any means (focus-within) |
| Light/Dark | Same in both themes |
| AP target | All primitives in `packages/web/src/components/ui/` that today use `ring-gray-8` or `border-gray-8` for focus |
| Notes | Invalid fields keep AP's rule: border `danger-9` (and a `danger-9` halo at 20% while invalid) |

---

### TOK-12 — Radius

Target: base 4px; controls 4–6px; cards, dialogs, popovers, tooltips, toasts and nodes 8px; large 12px; notice banners 2px.

| AP utility | Today | Target | Change | Typical users |
|---|---|---|---|---|
| `rounded-xss` | negative (renders 0) | — | Remove the token (no call sites) | — |
| `rounded-xs` | 0px | 2px | `--radius-xs` → 0.125rem | Notice banner |
| `rounded-sm` | 4px | 4px | none (write 0.25rem literally instead of the calc) | Small and medium buttons, checkbox, tags, callouts, segmented items |
| `rounded` | 4px | 4px | none (Tailwind default) | — |
| `rounded-md` | 6px | 6px | none (write 0.375rem literally) | Large buttons, inputs, select, menu rows, segmented track |
| `rounded-lg` | 12px | 8px | `--radius-lg` → 0.5rem | Cards, dialogs, popovers, menus, tooltips, tables, skeleton, empty state, xl button |
| `rounded-xl` | 12px | 12px | none | Large surfaces |
| `rounded-2xl`, `3xl`, `full` | 16, 24, pill | same | none | Badges and switch use `rounded-full` |
| `--radius` (runtime var) | 8px | 8px | none | Toasts read it (PRM-22) |

| Item | Detail |
|---|---|
| AP target | `styles.css` `@theme` radius keys and the `--radius` value in the light block |
| Notes | 150 call sites use `rounded-lg`; all move from 12 to 8px, which is the intended look. Canvas node radius is set by NOD |

---

### TOK-13 — Shadows

Shadow colour: black 10% in light, black 25% in dark ("cast"). Outline ring: black 10% in light, white 10% in dark ("ring"). Raw colour is allowed in shadows by AP's rules.

| Name (AP `@theme` key) | Geometry (x y blur spread) | Light | Dark | Used by |
|---|---|---|---|---|
| `--shadow-2xs` | 0 1 0 0 | cast | cast | Hairline lift |
| `--shadow-xs` | 0 1 3 −1 | cast | cast | Solid, subtle and secondary buttons; subtle badge; canvas control groups (CAN) |
| `--shadow-sm` | 0 1 3 0 + 0 1 2 −1 | cast | cast | Destructive button |
| `--shadow-md` | 0 4 6 −1 + 0 2 4 −2 | cast | cast | Tooltip |
| `--shadow-lg` | 0 10 15 −3 + 0 4 6 −4 | cast | cast | — |
| `--shadow-xl` | 0 20 25 −5 + 0 8 10 −6 | cast | cast | Large overlays |
| `--shadow-ring` (new) | 0 0 0 1 | ring | ring | Outline-only surfaces |
| `--shadow-float` (new) | `--shadow-lg` geometry + the 1px ring | cast + ring | cast + ring | Popover, dropdown, context menu, select panel, hover card, command panel |
| `--shadow-dialog` (new) | 0 0 0 0.5 (black 10%); 0 8 8 0 (black 10%); 0 32 32 0 (black 10%); 0 64 64 0 (black 6%) | as listed | inset 0 1.5 0 0 (white 15%, top highlight); 0 0 0 0.5 (black 30%); 0 8 8 0 (black 30%); 0 32 32 0 (black 20%); 0 64 64 0 (black 10%) | Dialog |
| `--shadow-toast` (new) | 0 2 12 0 | cast | cast | Toast |
| `--shadow-drawer` (new) | 0 6 16 0, TW orange-950 `#441306` at 6% | as listed | black 25% | Sheet / drawer |
| `--shadow-rest` → plain var `--rest` | the 1px ring + `--shadow-xs` geometry | | | Resting raised surfaces |
| `--shadow-lift` → `--lift` | 0 2 8 0, TW orange-950 `#441306` at 10% (the target's warm card-hover shadow) | as listed | same | Card hover (PRM-15, PAG) |
| `--shadow-over` → `--over` | same as `--shadow-float` | | | Floating surfaces (legacy name) |
| `--shadow-edge` → `--edge` | 0 0 0 1, `gray-6` | | | Hairline ring |
| `--shadow-panel` → `--panel-shadow` | none | | | Target panels are flat; separation comes from 1px borders |
| `--shadow-add-button`, `--shadow-step-container`, `--shadow-glow-primary` | unchanged here | | | Owned by NOD / EDG / CAN, which may redefine them |

| Item | Detail |
|---|---|
| States | Hover and pressed do not change shadows except card hover (`--lift`) |
| Light/Dark | Every key whose value differs per theme must point at a plain per-theme variable defined in both theme blocks (AP's indirection rule: Tailwind copies `--shadow-*` values literally, so a direct dark override never lands). This now includes the Tailwind default names `--shadow-2xs` … `--shadow-xl`, which become theme-aware |
| AP target | `styles.css` `@theme` shadow keys and both theme blocks. The old casts `--cast-06/08/10/20` may be removed once nothing reads them |
| Notes | Geometry for `--shadow-sm` … `--shadow-xl` is Tailwind's; only `--shadow-xs` changes geometry (Tailwind's is 0 1 2 0 at 5%) |

---

### TOK-14 — Font families

| Item | Detail |
|---|---|
| Values | Sans: Inter variable, weights 100–900, already self-hosted in AP (`packages/web/src/assets/fonts/InterVariable.woff2` and the italic). Mono: **Commit Mono**, the variable woff2 from its upstream release (SIL OFL 1.1, by Eigil Nikolajsen), placed in `packages/web/src/assets/fonts/` with its OFL licence text. Mono fallbacks after Commit Mono: ui-monospace, Menlo, Consolas, DejaVu Sans Mono, monospace |
| States | `font-display: swap` like the existing faces |
| AP target | `styles.css`: add the Commit Mono face (normal style, the weight range the upstream file declares); `--font-mono` → Commit Mono first; keep `--font-mono--font-feature-settings` (`calt` off). `--font-sans` unchanged. JetBrains Mono's face can be removed if nothing else names it |
| Notes | Never take a font file from the reference product. Sentient (serif) stays as is |

---

### TOK-15 — Type ramp

Target sizes 10 / 12 / 13 / 14 / 16 / 18 / 20 / 28 px; 14px is the workhorse (body). AP's body default `text-sm` is already 14px. The target needs a 13px step AP does not have.

| Target px | Target line height | AP token | AP today | Change |
|---|---|---|---|---|
| 10 | 1.25 | `text-xss` | 0.65rem (10.4px), Tailwind-default line height | → 0.625rem, line height 1.25 |
| 12 | 1.3 | `text-xs` | 12px / 1.333 | line height → 1.3 |
| 13 | 1.3 | `text-xsm` (new) | — | Add 0.8125rem, line height 1.3 |
| 14 | 1.35 | `text-sm` | 14px / 1.4286 | line height → 1.35 |
| 16 | 1.35 | `text-base` | 16px / 1.5 | line height → 1.35 |
| 18 | 1.5 | `text-lg` | 18px / 1.556 | line height → 1.5 |
| 20 | 1.5 | `text-xl` | 20px / 1.4 | line height → 1.5 |
| 24 | — | `text-2xl` | 24px | none (no target step; keep for existing use) |
| 28 | 1.25 | `text-3xl` | 28px (AP override) / 1.2 | line height → 1.25 |
| 32 | — | `text-4xl` | 32px | none |

| Item | Detail |
|---|---|
| Values | Letter spacing uses Tailwind's keys: headings `tracking-tight` (−0.025em; the target uses −0.01em at 18–20px and −0.025em at 28px), uppercase eyebrows `tracking-wider` (0.05em) or `tracking-widest` (0.1em) |
| States | — |
| AP target | `styles.css` `@theme`: `--text-xss`, `--text-xsm` (new, with its line-height key), and the `--text-*--line-height` keys above |
| Notes | Headings at 18 and 20px use `leading-tight` (1.25) where they stand alone (dialog titles use 1.35, PRM-11). Page title = 20px / 600 (SHL/PAG). Controls with a fixed height set `leading-none`. Changing the default line heights makes every text block a little denser; that is the target look. Update the type-scale guidance in `packages/web/CLAUDE.md` (13px → `text-xsm`) |

---

### TOK-16 — Font weights

| Item | Detail |
|---|---|
| Values | 400 regular (`font-normal`), 500 medium (`font-medium`), 600 semibold (`font-semibold`). The target never renders 700 |
| AP target | `styles.css` `@theme`: `--font-weight-bold` → 600 and `--font-weight-extrabold` → 600, so the 40 existing `font-bold` / `font-extrabold` call sites render at 600 without edits |
| Notes | Buttons, tabs, badges, menu labels use 500; headings and table header labels use 600; body uses 400 |

---

### TOK-17 — Spacing

The target's spacing steps are all on Tailwind's 4px-based scale, so AP's spacing utilities need no change.

| Target px | 2 | 4 | 6 | 8 | 12 | 16 | 20 | 24 | 32 | 48 | 64 | 128 | 256 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| AP number (`p-`, `gap-`, `m-`, `size-` …) | 0.5 | 1 | 1.5 | 2 | 3 | 4 | 5 | 6 | 8 | 12 | 16 | 32 | 64 |

| Item | Detail |
|---|---|
| AP target | No token change |
| Notes | AP's no-negative-margin rule still holds outside `components/ui/` |

---

### TOK-18 — Control heights and icon sizes

| Target px | 8 | 12 | 16 | 20 | 24 | 28 | 32 | 36 | 40 | 48 | 56 | 64 | 96 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| AP height utility | `h-2` | `h-3` | `h-4` | `h-5` | `h-6` | `h-7` | `h-8` | `h-9` | `h-10` | `h-12` | `h-14` | `h-16` | `h-24` |

| Use | Height |
|---|---|
| Buttons | 24 / 28 / 32 (default) / 36 / 40 (PRM-01) |
| Inputs, select | 24 / 28 / 32 / 36 (default) / 40 (PRM-03) |
| Segmented control | 32 default (PRM-07) |
| Menu row | 32 minimum |
| Badge | 24 default |
| Table header / row | 36 / 48 |
| App header | 64 (SHL) |

| Icon size (px) | 10 | 12 | 14 | 16 | 20 | 40 |
|---|---|---|---|---|---|---|
| AP utility | `size-2.5` | `size-3` | `size-3.5` | `size-4` | `size-5` | `size-10` |

| Item | Detail |
|---|---|
| Notes | Icons are `lucide-react` at Lucide's default stroke (2); the empty-state glyph uses stroke 1.5 (PRM-25). Icons take the current text colour |

---

### TOK-19 — Borders and disabled opacity

| Item | Value |
|---|---|
| Default border | 1px solid `gray-6` |
| Focus border / ring | 2px (TOK-11) |
| Canvas node border | Set by NOD |
| Notice banner left edge | 7px (PRM-21) |
| Empty-state frame | 2px dashed (PRM-25) |
| Disabled opacity | Buttons 50%; inputs, badges, switch, segmented items 60% |
| Disabled cursor | not-allowed |

---

### TOK-20 — Z-index layers

AP today puts every Radix overlay at `z-50` and relies on portal order. The new surfaces need an explicit order.

| Layer | z | Members |
|---|---|---|
| Canvas chrome | 10 | Canvas controls, vertical toolbar, test bar, minimap, logs panel (CAN, LOG) |
| App header | 20 | Builder header and its straddling segmented control (SHL) |
| App sidebar and top banners | 30 | SHL |
| Piece panel | 40 | PCK |
| Step modal (overlay and frame) | 45 | NDV |
| Dialogs and sheets (overlay and content) | 50 | PRM-11, PRM-12 (AP's current value) |
| Toasts | 60 | PRM-22 |
| Floating UI | 70 | Popover, dropdown and context menu, select panel, hover card, tooltip, command panel |
| Drag layer | 80 | Dragged steps and notes (NOD, CAN) |

| Item | Detail |
|---|---|
| AP target | `z-*` utilities in the primitives; Tailwind v4 accepts any integer, so no theme key is needed |
| Notes | Floating UI above dialogs keeps selects and menus usable inside dialogs and the step modal. Sonner's own very high default must be lowered to the toast layer |

---

### TOK-21 — Breakpoints

| Item | Detail |
|---|---|
| Values | AP keeps Tailwind's breakpoints: `sm` 640, `md` 768, `lg` 1024, `xl` 1280, `2xl` 1536 px |
| Target thresholds | Dialog fixed widths start at 640 → `sm:`. The "small screen" switch at 768 (page side padding 48 → 16, minimap hidden, test bar moves) → `md:`. The target's 992, 1200 and 1920 thresholds are not used by any in-scope requirement |
| AP target | No change |

---

### TOK-22 — Contrast ledger

Rule used: exact target colour where the element is a short label or a brand mark; an AA-keeping value where the colour carries running text.

| Pair | Ratio | Decision |
|---|---|---|
| White label on `accent-9` `#ff6900` (solid button, primary badge) | 2.9:1 | Kept: the target's look. Below AA for 14px text |
| `accent-9` ink on white / page (active tab label, links) | 2.9 / 2.8:1 | Kept: short labels, target look |
| Quiet text `gray-11` `#737373` on panel / page | 4.7 / 4.5:1 | AA. The target's `#999999` (2.9:1) is not used for text |
| `gray-11` on `gray-3` / `gray-4` / `gray-5` | 4.35 / 4.2 / 3.8:1 | Below AP's own "4.5 on every chip ground" rule; primitives put subtle text (TOK-03) on those grounds instead |
| Decoration `gray-9` `#999999` on white | 2.9:1 | Decoration only (dots, glyphs), never text |
| Disabled `gray-8` `#bbbbbb` on white | 1.9:1 | Disabled content is exempt |
| Dark quiet text `#bbbbbb` on `#262626` | 7.9:1 | AA |

| Item | Detail |
|---|---|
| Notes | If the reviewers want the target's lighter quiet text, set light `gray-11` to `#999999`; the ledger row then drops to 2.9:1 across 986 call sites |

---

### TOK-23 — AP colour documentation

| Item | Detail |
|---|---|
| AP target | `brain/knowledge/design-system/colour.md` and `index.md` |
| Values | Update: the focus-ring rule (now violet `--focus` / `--focus-halo`, not `gray-8`); the exceptions table (add `--scrim-strong`, `--focus`, `--focus-halo`, `--canvas-dot`); the white-labelling section (colours no longer seeded by platforms); the warning family (yellow, bright `warning-9`); the stock accent (`#ff6900`); the grey anchors and the quiet-text contrast note (TOK-22) |
| Notes | AP writes back into its brain as part of the change; keep the edits short |
