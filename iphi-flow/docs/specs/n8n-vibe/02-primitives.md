# 02 — Primitives (PRM)

One block per shared primitive. All colours are AP steps or the exceptions in TOK-08; all sizes are px with the AP utility that produces them. Variant and size names stay AP's; each block maps them onto the target look. Motion is in MOT; this file only names the MOT block.

Shared rules for every primitive:

- Remove AP's neutral focus ring (`ring-gray-8`, `border-gray-8` on focus) and use the focus recipes in TOK-11.
- Keep AP's invalid rule: `aria-invalid` gives a `danger-9` border (and a `danger-9` halo at 20%).
- `dark:` colour utilities stay legal inside `packages/web/src/components/ui/` (AP's rule); several blocks need one because the target puts a role on different steps in the two themes.
- Paths are relative to `iphi-flow/activepieces/packages/web/src/`.

---

### PRM-01 — Button

**Sizes** (AP size name → target)

| AP size | Height | Horizontal padding | Radius | Font | Icon | Icon–label gap |
|---|---|---|---|---|---|---|
| `xs` | 24 (`h-6`) | 8 (`px-2`) | 4 (`rounded-sm`) | 12 (`text-xs`) | 10 (`size-2.5`) | 6 (`gap-1.5`) |
| `sm` | 28 (`h-7`) | 12 (`px-3`) | 4 | 13 (`text-xsm`) | 12 (`size-3`) | 6 |
| `default` | 32 (`h-8`) | 12 (`px-3`) | 4 | 14 (`text-sm`) | 14 (`size-3.5`) | 6 |
| `lg` | 36 (`h-9`) | 16 (`px-4`) | 6 (`rounded-md`) | 14 (`text-sm`) | 16 (`size-4`) | 6 |
| `xl` | 40 (`h-10`) | 16 (`px-4`) | 8 (`rounded-lg`) | 16 (`text-base`) | 20 (`size-5`) | 6 |

All sizes: weight 500 (`font-medium`), line height 1 (`leading-none`), no wrapping. The padding stays the same when an icon sits next to the label (drop AP's reduced padding when the button holds an icon).

**Variants** (AP variant → target look)

| AP variant | Target look | Rest | Hover | Pressed / open | Text |
|---|---|---|---|---|---|
| `default` | Solid orange | `bg-accent-9`, 1px inset ring `accent-9`, `shadow-xs` | `bg-accent-10`, ring `accent-10` | `bg-accent-11`, ring `accent-11` | `text-on-accent` |
| `destructive` | Solid red | `bg-danger-9`, ring `danger-9`, `shadow-sm` | `bg-danger-11`, ring `danger-11` | same as hover | `text-on-danger` |
| `secondary` | Subtle | `bg-panel`, 1px inset ring `gray-6`, `shadow-xs` | `bg-gray-4`, ring `gray-7` | `bg-gray-5`, ring `gray-8` | `text-gray-12` |
| `outline` | Subtle | same as `secondary` | same | same | `text-gray-12` |
| `accent` | Outline (no fill, no shadow) | transparent, ring `gray-6` | `bg-gray-4`, ring `gray-7` | `bg-gray-5`, ring `gray-8` | `text-gray-12` |
| `ghost` | Ghost | transparent, no ring | `bg-gray-4` | `bg-gray-5` | `text-gray-12` |
| `basic` | Ghost with orange label | transparent | `bg-gray-4` | `bg-gray-5` | `text-accent-9` |
| `link` | Text link | no padding | underline, `text-accent-10` | — | `text-accent-9` |
| `transparent` | Orange text, no fill change | transparent | no change | no change | `text-accent-9` |

| Item | Detail |
|---|---|
| States | Pressed applies on press and while the button is the open trigger of a menu or popover (`aria-expanded` true or open state). Disabled: 50% opacity, not-allowed cursor, no hover or pressed change. Loading: the spinner takes the size's icon size and sits centred; the label stays in the layout but is invisible so the width does not change; the button ignores clicks (AP already does). Spinner colour: `on-accent` (default), `on-danger` (destructive), `gray-12` (others); one turn per 400ms, see MOT-09. Focus: recipe A; for `default`, `destructive`, `secondary`, `outline` and `accent` the inset ring also turns `--focus` (recipe B) |
| Light/Dark | `default` and `destructive` render as light islands so their three fills are the same oranges and reds in both themes (the dark ramp's steps 10–11 are light tints). The other variants follow the theme: dark `panel` is `#262626`, dark hover `#323232`, dark pressed `#3a3a3a` |
| AP target | `components/ui/button.tsx` |
| Notes | The inset ring is a 1px box-shadow drawn inside the button, not a border, so heights stay exact. Keep the keyboard-shortcut chip (`text-on-accent/70` on the solid). AP's default size was 36px; it becomes 32px, as the plan's height list requires |

---

### PRM-02 — Icon button

| Item | Detail |
|---|---|
| Values | Square. `icon-xs` 24×24, icon 10–12; `icon-sm` 28×28, icon 12–14; `icon` 32×32, icon 14–16; `icon-lg` 36×36, icon 16. Radius 4 for 24–32, 6 for 36 |
| States | Same as the variant it uses (PRM-01). Default variant for toolbar and row actions is `ghost`: hover `bg-gray-4`, pressed `bg-gray-5`, icon `text-gray-12` |
| Light/Dark | As PRM-01 |
| AP target | `components/ui/button.tsx` (the `icon*` sizes) |
| Notes | Every icon-only button needs an accessible name (aria-label or a tooltip with the label). Canvas control buttons (36×36, ghost, 16px icons) are specified by CAN |

---

### PRM-03 — Input

| Item | Detail |
|---|---|
| Values | Default height 36 (`h-9`), radius 6 (`rounded-md`), horizontal padding 12 (`px-3`), font 14 (`text-sm`; keep AP's 16px on small screens to stop mobile zoom), text `gray-12`, placeholder `gray-11`. Border 1px `gray-6`. No shadow (drop AP's `shadow-xs`). Background `bg-panel` in light, `gray-1` in dark. The `thin` option: 28 tall, 8 padding, 13px |
| Other heights (call sites that size inputs) | 24 / radius 4 / 12px / padding 8; 28 / 4 / 13px / 8; 32 / 4 / 14px / 12; 36 / 6 / 14px / 12; 40 / 6 / 16px / 12 |
| States | Hover (not focused, not disabled): border `gray-7`. Focus (focus-within): recipe B, border `--focus` plus the 2px halo. Disabled: 60% opacity, not-allowed cursor. Invalid: border `danger-9` |
| Affixes | Leading/trailing icons 16px in `gray-12` at 70% opacity, 6px from the text. Add-on segments (text glued to the input): background `gray-4` in both themes, 1px `gray-6` divider, 12px padding |
| Light/Dark | Light: white field with `#e5e5e5` border. Dark: `#171717` field with `#3a3a3a` border, placeholder `#bbbbbb` |
| AP target | `components/ui/input.tsx` (`inputClass`, also used by the file-input look) |
| Notes | The target's placeholder is `#999999` in light; AP uses quiet text `gray-11` (TOK-22) |

---

### PRM-04 — Textarea

| Item | Detail |
|---|---|
| Values | Same colours, border, radius 6, focus and states as PRM-03. Padding 12 on all sides (`p-3`), font 14, line height 1.3, background `bg-panel` (light) / `gray-1` (dark). User resize: vertical only (where the autosize allows it) |
| States | As PRM-03 |
| AP target | `components/ui/textarea.tsx` |
| Notes | Code editors and the mention input keep their own components; they take the same border, radius and focus treatment where they draw a field frame |

---

### PRM-05 — Select (trigger, panel, option)

| Part | Detail |
|---|---|
| Trigger | Same frame as PRM-03: height 36 for `default`, 32 for `sm`; radius 6 at 36px, 4 at 32px; padding 12; font 14; `bg-panel` / dark `gray-1`; border `gray-6` → hover `gray-7` → focus recipe B; open state shows the focus border. Value text `gray-12`, placeholder `gray-11`. Icon: a single chevron pointing down (Lucide chevron-down), 16px, `gray-11`, at the right; replace AP's up-down chevrons. No shadow |
| Panel | `bg-panel`, radius 6 (`rounded-md`), `shadow-float`, no border (the float shadow carries the 1px ring), inner padding 4 (`p-1`), minimum width = the larger of the trigger width and 128px, maximum height 288px then scroll. Floating layer z 70 (TOK-20) |
| Option | Minimum height 32, padding 8 left / 32 right (room for the check), radius 6, font 14, line height 1.25, `gray-12`. Highlight (pointer or keyboard): `bg-gray-4`. Selected: a 16px check at the right in `accent-9`, label weight 500. Disabled: `gray-8`, no highlight |
| Group label | 12px, weight 500, `gray-11`, padding 8 / 6 |
| Separator | 1px `gray-6`, 2px vertical margin, bleeding 4px into the panel padding |
| Light/Dark | Dark panel `#262626`, highlight `#323232`, ring white 10% |
| AP target | `components/ui/select.tsx`; the same panel and option look applies to `components/custom/searchable-select.tsx` and `components/ui/command.tsx` lists |
| Notes | Motion: MOT-05 (open), close is immediate. The panel's scrollbar is the hover-only kind (PRM-23) |

---

### PRM-06 — Tabs (underline)

| Item | Detail |
|---|---|
| Values | Tab list: a row with no gap between tabs and no bottom border of its own. Tab: padding 0 16px, 8px bottom padding plus a 2px bottom border (transparent when inactive, so active and inactive tabs have equal height); label 14px, weight 500; optional leading icon 16px with a 4px gap. Compact form (for panel headers such as the step modal, NDV): label 12px, weight 600, 12px bottom padding |
| States | Rest: subtle text (`text-gray-12/87`). Hover: label `text-accent-9`. Active: label `text-accent-9`, bottom border `accent-9`. Disabled: `gray-8`, no hover. Focus: recipe D (1px inset `--focus` outline). A small unread dot, when used: 5px circle `accent-9` after the label |
| Light/Dark | Same orange in both themes; rest label ≈ `#424242` light, ≈ `#e3e3e3` dark |
| AP target | `components/ui/tabs.tsx`, the `outline` variant of `TabsList` and `TabsTrigger` |
| Notes | The active indicator does not slide between tabs; it switches. Page-level tab rows (SHL/PAG) use this variant. Overflowing tab rows scroll horizontally with a hidden scrollbar |

---

### PRM-07 — Segmented control (new)

A single-choice control drawn as a track with segments. Used by the builder header (Editor | Runs, SHL), data-view modes (Schema | Table | JSON, NDV), and by AP's existing compact tab switchers.

| Item | Detail |
|---|---|
| Track | Inline row, height 32 (default), padding 2, gap 2 between segments, radius 6. Background `gray-5` in light (`#e5e5e5`), `gray-4` in dark (`#323232`) |
| Segment | Radius 4, padding 0 12px, label 12px weight 500, line height 1, centred, no wrapping; equal flex share. Optional 14–16px icon; icon-only segments are square (no padding) |
| Sizes | 24 tall: 10px label, padding 0 8px. 28: 10px, 0 8px. 32 (default): 12px, 0 12px. 36: 13px, 0 12px. 40: 14px, 0 16px |
| States | Rest: subtle text (`text-gray-12/87`), transparent. Hover (not selected, pointer devices only): text `gray-12`, background `gray-4` light / `gray-3` dark. Selected: background `bg-panel` in light (white) and `gray-1` in dark (`#171717`), text `gray-12`, no shadow. Disabled segment: `gray-8` text, not-allowed. Whole control disabled: track `gray-5`, not-allowed. Focus: recipe C on the focused segment, drawn above its neighbours. While the keyboard is moving through the segments, the pointer-hover styling is suppressed |
| Behaviour | Radio-group semantics: one value, arrow keys move and select, Home/End jump. Built on Radix (radio group or a single-type toggle group), both already in `radix-ui` |
| Light/Dark | As listed per state |
| AP target | New file `components/ui/segmented-control.tsx` (props: items with value, label, optional icon, optional disabled; value; value-change callback; size). The same look replaces the `default` variant of `TabsList` / `TabsTrigger` in `components/ui/tabs.tsx` (32 track, 2 padding, 12px/500 segments), so existing compact tab switchers match without call-site edits |
| Notes | AP's `TabsList` default track was 36px with 4px padding and a `gray-3` fill; it becomes the 32px track above. Header placement (straddling the header's bottom border) is SHL |

---

### PRM-08 — Tooltip

| Item | Detail |
|---|---|
| Values | Background black (TW black `#000000`) in both themes; text the island's `gray-12` (white; target `#f5f5f5`); 13px (`text-xsm`), weight 500, line height 1.3; padding 4 vertical / 6 horizontal; minimum height 28 (content centred); maximum width 180px, text wraps; radius 8; `shadow-md`; **no arrow** (remove the arrow element). Icons inside at 70% opacity |
| Placement | Default side top, 8px from the trigger. Delay 0 (AP's provider already uses 0). Content is hoverable |
| States | Opens and closes instantly (no fade, no zoom; MOT-06). A keyboard-shortcut chip inside uses the dark island's `gray-4` fill and `gray-11` text |
| Light/Dark | Identical: the tooltip is a dark island whose surface is pure black, because the island's darkest step equals the dark page and would lose the bubble edge |
| AP target | `components/ui/tooltip.tsx` |
| Notes | Replaces AP's `bg-gray-12` bubble, which colour.md forbids for dark-in-both-themes surfaces. Canvas tooltips with a longer delay are CAN/NOD. Optional action row: 16px below the text, 8px gap |

---

### PRM-09 — Dropdown menu and context menu

| Part | Detail |
|---|---|
| Panel | `bg-panel`, radius 8 (`rounded-lg`), `shadow-float`, no border, padding 4, minimum width 128, maximum height = the smaller of the available space and 75% of the viewport, then scroll (hover-only scrollbar, PRM-23). Optional 16px fade at the bottom edge when more items are hidden. Floating layer z 70 |
| Item | Row with 8px gap, minimum height 32, padding 8, radius 6, font 14, line height 1.25, text `gray-12`, icons 16px `gray-11` |
| Item states | Highlight (pointer or keyboard): `bg-gray-4`. Disabled: text `gray-8`, no highlight. Destructive item: text `danger-11`, highlight `bg-danger-3`. Open sub-trigger: `bg-gray-4` |
| Checkbox / radio items | Indicator column 32px on the left; check 16px `gray-12`, radio dot 8px |
| Section label | Padding 8 top and sides, 6 bottom; 12px, weight 500, `gray-11` |
| Separator | 1px `gray-6`, 2px vertical margin, bleeding 4px into the panel padding |
| Shortcut | 12px `gray-11`, wide tracking, right-aligned |
| Sub-menu | Same panel, maximum width 384px |
| Light/Dark | Dark: panel `#262626`, ring white 10%, highlight `#323232`, destructive highlight dark `danger-3` |
| AP target | `components/ui/dropdown-menu.tsx`, `components/ui/context-menu.tsx`; `components/ui/command.tsx` items use the same item look (their larger cmdk padding becomes 8) |
| Notes | Motion: MOT-05; close is immediate. The keep-open race fix in AP's dropdown (`noAnimationOnOut`) becomes moot because there is no exit animation |

---

### PRM-10 — Popover (and hover card)

| Item | Detail |
|---|---|
| Values | `bg-panel`, radius 8, `shadow-float`, no border, padding 16 (`p-4`), default width 288 (`w-72`), 4px from the trigger, no arrow. Title 14px weight 500 `gray-12`; description `gray-11` |
| States | Opens with MOT-05, closes immediately. Floating layer z 70 |
| Light/Dark | Dark panel `#262626` with white 10% ring |
| AP target | `components/ui/popover.tsx`, `components/ui/hover-card.tsx` |
| Notes | A popover opened inside a dialog stays `modal` (AP gotcha in `design-system/index.md`) |

---

### PRM-11 — Dialog

| Item | Detail |
|---|---|
| Overlay | `bg-scrim` (black 30% light, 60% dark) with an 8px backdrop blur (`backdrop-blur-sm`) |
| Frame | Centred, fixed; radius 8; padding 24 (`p-6`); background `bg-panel` in light and `gray-4` in dark (`#323232`); no border; `shadow-dialog` (TOK-13) |
| Widths | From 640px viewport (`sm:`): small 360, medium 480 (the default), large 564, xlarge 640, 2xlarge 780. Below 640: viewport width minus 24px |
| Header | Column, gap 8. Title 18px (`text-lg`), weight 500, line height 1.35, `gray-12`, left-aligned at every width. Description 14px, subtle text (`text-gray-12/87`) |
| Body / footer | Content gap 16. Footer: right-aligned row, 8px gap, 20px above it (16 gap plus 4) |
| Close button | 24×24, 16px from the top and right edges, radius 4, 16px icon `gray-11`; hover `bg-gray-4` and `gray-12` icon; focus recipe A |
| States | Opens and closes with MOT-07. Escape and overlay click close (AP behaviour). Dialog layer z 50 |
| Light/Dark | As listed |
| AP target | `components/ui/dialog.tsx`. Default width changes from AP's 512px to 480px; add an optional size prop with the five widths (additive) |
| Notes | AP's DialogHeader centred text on small screens; the target is left-aligned everywhere (AP's F-pattern rule agrees) |

---

### PRM-12 — Sheet and drawer

| Item | Detail |
|---|---|
| Values | Side sheet: `bg-panel`, no radius, 1px `gray-6` border on the inner edge, `shadow-drawer` (TOK-13), overlay `bg-scrim` without blur. Width: AP's current (three quarters of the viewport, at most 384px) unless the caller sets one. Header padding 16, title 18px weight 500 `gray-12`, description 14px `gray-11`. Close button as PRM-11 |
| Bottom drawer | Same surface; top corners radius 8 |
| States | Slide and fade with MOT-08. Dialog layer z 50 |
| Light/Dark | Dark: `#262626` surface, `#3a3a3a` edge |
| AP target | `components/ui/sheet.tsx`, `components/ui/drawer.tsx` |
| Notes | The piece panel is not a sheet: it has no overlay and slides below the header (PCK) |

---

### PRM-13 — Badge

**Base**: pill (`rounded-full`), height 24 (`h-6`), padding 0 8px, gap 4, 1px border (same colour as the fill unless the variant says otherwise), font 12px (`text-xs`) weight 500, line height 1, icons 14px at 90% opacity, no wrapping; long labels truncate with an ellipsis.

**Variants**

| AP variant | Target look | Fill | Border | Text | Theme |
|---|---|---|---|---|---|
| `default` | Primary | `accent-9` | `accent-9` | `on-accent` | Both |
| `secondary` | Filled grey | `gray-5` light, `gray-7` dark | same as fill | subtle (`text-gray-12/87`) | Theme-aware |
| `accent` | Filled grey | as `secondary` | | | Theme-aware |
| `destructive` | Danger | `danger-5` | `danger-5` | `danger-12` | Light island |
| `success` | Success | `success-5` | `success-5` | `success-12` | Light island |
| `warning` | Warning | `warning-5` | `warning-5` | `warning-12` | Light island |
| `info` | Info (blue) | `swatch-11-surface` | `swatch-11-line` | `swatch-11-ink` | Theme-aware |
| `neutral` | Subtle | `panel` | `gray-6` | subtle | Theme-aware, plus `shadow-xs` |
| `outline` | Outline | transparent | `gray-6` | `gray-12` | Theme-aware |
| `ghost` | Ghost | transparent | transparent | `gray-12` | Theme-aware |
| `link` | Link | transparent | transparent | `accent-9`, underline on hover | — |
| `inverted` | Brand tint | `accent-3` | `accent-3` | `accent-11` | Theme-aware |

| Item | Detail |
|---|---|
| Other sizes (by class at call sites) | 20 tall / 12px / padding 8; 28 / 13px / 8; 32 / 13px / 12; 36 / 14px / 16; 40 / 14px / 16; icons 20px at 36–40 |
| States | Clickable badges (rendered as a link or button) darken on hover and press, as the target does in both themes: `default` → `accent-10` then `accent-11`; status variants → step 6 then step 7 (and border alike); `secondary` / `accent` → `gray-7` in light and `gray-6` in dark, for both hover and press; `neutral`, `outline`, `ghost` → `bg-gray-4`. Disabled: 60% opacity, not-allowed. Focus: recipe B (border turns `--focus`) |
| Light/Dark | Status badges stay pastel in dark mode, like the target, by being light islands |
| AP target | `components/ui/badge.tsx` |
| Notes | AP's badge was about 18px tall; it becomes 24px. Dense tables that need smaller badges use the 20px size. The target's info badge is TW blue-200 fill and blue-900 text; AP has no blue scale, so swatch 11 (blue) stands in |

---

### PRM-14 — Tag / chip

AP has no tag primitive. Add a `tag` variant to the badge (additive; no rename).

| Item | Detail |
|---|---|
| Values | Radius 4 (`rounded-sm`, not a pill), 1px border, weight 400. Sizes: default 20 tall, padding 0 4px, 12px; medium 24 tall, padding 4/8, 13px; large 28 tall, padding 4/8, 13px. Text subtle (`text-gray-12/87`) |
| Light | Fill `gray-3` (`#f5f5f5`), border `gray-4` (`#f0f0f0`) |
| Dark | Fill `gray-7` (`#444444`), border `gray-4` (`#323232`) |
| States | Hover: fill `gray-4`, border `gray-5` (light); border `gray-8` (dark). Active / selected: fill `gray-5`, border `gray-7` (light). Fill changes animate over 300ms (MOT-04). A remove control, when present: 12px × icon `gray-11` → `gray-12` on hover. Overflow chip ("+N") uses the same look |
| AP target | `components/ui/badge.tsx` (new `tag` variant); call sites in `features/automations/components/` adopt it (PAG) |
| Notes | Tag rows show up to 3 tags then the "+N" chip (PAG) |

---

### PRM-15 — Card

| Item | Detail |
|---|---|
| Values | Radius 8 (`rounded-lg`), 1px border `gray-6`, background `bg-panel` (was `bg-gray-1`), text `gray-12`, no shadow at rest (drop `shadow-xs`). Header, content and footer padding 16 (`p-4`, was 24); header items 6px apart. Title 14px weight 600; description 12px `gray-11`. Optional icon column 24px wide with 16px gap |
| Variants | `default`: as above. `interactive`: pointer cursor; hover adds `shadow-lift` (warm 0 2 8 shadow) over 300ms; border unchanged. `isSelected`: border `accent-9` |
| States | Disabled / archived cards (PAG): background `gray-1`, text `gray-11` |
| Light/Dark | Light white card with `#e5e5e5` border on the `#fafafa` page; dark `#262626` card with `#3a3a3a` border on `#171717` |
| AP target | `components/ui/card.tsx` |
| Notes | List rows as cards (automations list) are PAG; they use this look |

---

### PRM-16 — Table and data table

| Part | Detail |
|---|---|
| Container | Radius 8, 1px border `gray-6`, clipped corners, background `bg-panel`. Table body text 14px |
| Header row | Sticky at the top above the rows, height 36 (`h-9`), background `gray-3` (light `#f5f5f5`, dark `#2b2b2b`), 1px bottom border `gray-6`, no top border inside a bordered container. Header cell: padding 0 8px, first cell left padding 16, last cell right padding 16; label 12px weight 600, subtle text (`text-gray-12/87`); sort icon 14px `gray-11` |
| Body row | Height 48 (`h-12`), background `bg-panel`, 1px bottom border `gray-6` (none on the last row). Cell: padding 0 8px, first 16 left, last 16 right; text 14px `gray-12`. Checkbox columns keep AP's 16 left / 8 right |
| Row states | Hover: background `gray-1` (light `#fafafa`, dark `#171717`) — rows without a click action do not hover. Selected: `gray-3`. Clickable rows: pointer cursor |
| Loading | First load: skeleton rows (PRM-24), 48px tall. Refresh while rows are shown: a 2px `accent-9` indeterminate bar under the header (AP's indeterminate-progress animation) and the rows dimmed to 38% opacity |
| Empty / error | AP's existing empty text and `DataFetchErrorState` placement are unchanged; text sizes follow PRM-25 |
| Pagination | Bottom-right row, 8px gaps: "rows per page" select at 32px (PRM-05), previous/next as ghost buttons; a selected page number uses `bg-gray-5` |
| Light/Dark | As listed |
| AP target | `components/ui/table.tsx`; `components/custom/data-table/index.tsx` (bordered container, row heights, loading), `data-table-column-header.tsx` (12px/600 subtle label), `data-table-skeleton.tsx` (48px rows), `data-table-toolbar.tsx` |
| Notes | AP's header and cell first/last padding was 32px; it becomes 16px. The virtualizer's row-size estimate changes from 53 to 49 (48 + 1px border). Header labels keep AP's wording and casing. The tables feature grid (`routes/tables/id/react-data-grid.css`) is PAG |

---

### PRM-17 — Switch

| Item | Detail |
|---|---|
| Sizes | `sm` and `default`: track 32×16, thumb 12. `lg`: track 40×20, thumb 16. `xl`: track 48×24, thumb 20 (no target size; proportional). The thumb sits 2px inside the track |
| Track | Pill. Off: light `gray-8` (`#bbbbbb`); dark `gray-1` (`#171717`) with a 1px inset `gray-7` ring. On (`color` default): `success-9` (`#00a63e`). On (`color` secondary): `gray-12` (unchanged). Indeterminate: unchanged (`accent-5` fill, `accent-8` border) |
| Thumb | Light: `bg-panel` (white). Dark: `gray-12` (white; target `#f5f5f5`). Shadow 0 1px 2px black 20% |
| States | Hover and press stretch the thumb by 2px toward the centre. Disabled: 60% opacity, not-allowed. Focus: recipe E (2px `--focus` ring, no offset; drop AP's 2px offset). Label next to it: 14px (12px for `sm`), line height 1.25, 8px gap |
| Motion | MOT-10 |
| AP target | `components/ui/switch.tsx` |
| Notes | The target's on colour is TW green-500 `#00c950`, which is not a step; `success-9` is the nearest step |

---

### PRM-18 — Checkbox

| Item | Detail |
|---|---|
| Values | 16×16, radius 4, 1px border `gray-6`, background `bg-panel`, no shadow (drop `shadow-xs` and the dark translucent fill) |
| States | Hover (unchecked): border `accent-9`. Checked and indeterminate (`primary`): fill and border `accent-9`, white tick or dash 12px (`text-on-accent`). `secondary` variant unchanged (`gray-12`). Disabled unchecked: fill `gray-3`, border `gray-6`. Disabled checked: fill and border `gray-5`, tick `gray-8`. Focus: recipe E. Invalid: border `danger-9` |
| Light/Dark | Dark: `#262626` box with `#3a3a3a` border; checked orange is the same in both themes |
| AP target | `components/ui/checkbox.tsx` |
| Notes | Label to the right: 14px, 8px gap |

---

### PRM-19 — Radio

| Item | Detail |
|---|---|
| Values | Control 16×16, circle, background `bg-panel`, 1px border `gray-6`. Checked: fill `accent-9`, border `accent-10`, centre dot 6px in `bg-panel` (white in light, `#262626` in dark) |
| States | Hover (unchecked, enabled): border `accent-9`. Disabled unchecked: border `gray-4`. Disabled checked: fill and border `gray-5`. Disabled label `gray-8`. Focus: recipe C |
| Item layout | Control and label 8px apart; label 14px weight 500, line height 1.35, `gray-12`; optional description 12px subtle text, 2px under the label (control aligns to the label's first line). Group gap 12 (AP's) |
| AP target | `components/ui/radio-group.tsx` (replace the inner `accent-11` circle icon with the 6px panel-coloured dot on the orange fill) |
| Notes | — |

---

### PRM-20 — Callout (AP alert)

| Item | Detail |
|---|---|
| Values | Grid with the icon in its own column; 12px gap between icon and text; padding 12 (`p-3`); radius 4 (`rounded-sm`); 1px border; text 12px (`text-xs`), line height 1.5; icons 14px aligned with the first line. Title 12px weight 600. Slim form (inline use): padding 6 / 8 via class |
| Variants | `default` → info: fill `bg-panel`, border `gray-6`, text subtle (`text-gray-12/87`), icon `gray-9`. `success`: fill `success-2`, border `success-5`, text and icon `success-11`. `warning`: fill `warning-2`, border `warning-5`, text and icon `warning-11`. `destructive` → danger: fill `danger-2`, border `danger-3`, text and icon `danger-11`. `primary` → brand tint: fill `accent-2`, border `accent-5`, text and icon `accent-11` |
| Links inside | Weight 500, underlined, colour of the callout text; `gray-12` on hover (AP's current behaviour) |
| Light/Dark | Dark uses the theme's deep tints (steps 2, 3, 5 are dark surfaces) with light step-11 text, matching the target's "deep shade with light text" |
| AP target | `components/ui/alert.tsx` |
| Notes | AP's alert was 14px with 16/12 padding and radius 12; it becomes the compact callout. The target's success, warning and danger text are the step-9 tones; AP uses step 11 for text (AA). The target's violet "secondary" callout has no AP equivalent and is not built |

---

### PRM-21 — Notice banner

AP gap: no primitive. Add a second variant axis to the alert, `layout` with values `callout` (default, PRM-20) and `notice`, so every existing tone combines with it (additive; no rename).

| Item | Detail |
|---|---|
| Values | Text 12px, line height 1.25, `gray-12`; padding 8; vertical margin 16 (set by the caller); 1px border on top, right and bottom and a 7px border on the left, all in the tone's border colour; radius 2 (`rounded-xs`) |
| Tones | `warning` (the notice default): fill `warning-2`, border `warning-5`. `destructive`: fill `danger-2`, border `danger-3`. `success`: fill `success-2`, border `success-5`. `default` → info: fill `gray-3`, border `gray-6` |
| Links inside | Weight 600, `text-accent-9` |
| Light/Dark | Dark uses the deep tints; the left edge keeps the tone's step-5 colour |
| AP target | `components/ui/alert.tsx` (new `layout` axis) |
| Notes | Where notices appear (builder banners, step modal hints) is decided by SHL, CAN and NDV |

---

### PRM-22 — Toast (sonner)

| Item | Detail |
|---|---|
| Position | Bottom-right (AP's), 16px from the right and bottom edges; toast layer z 60 (TOK-20) |
| Values | Width 330; padding 14 top, 26 right, 14 bottom, 13 left; radius 8 (AP's `--radius`); background `bg-panel`; 1px border `gray-4`; `shadow-toast`. Title 16px weight 600 `gray-12`; description 14px, line height 1.5, `gray-12`. Status icon 24px, 13px gap to the text: success `success-9`, error `danger-9`, warning `warning-10`, info `gray-11`, loading spinner `gray-11`. Close control top 18 / right 15, `gray-11` → `gray-12` on hover |
| States | Text stays neutral for every type; only the icon carries the colour (remove AP's per-type text colouring) |
| Motion | MOT-13 |
| Light/Dark | Dark: `#262626` toast with `#323232` border |
| AP target | `components/ui/sonner.tsx` (the Toaster's CSS variables for background, border, text and radius, its icons, width, offsets and z-index) |
| Notes | Durations and stacking behaviour stay AP's |

---

### PRM-23 — Scrollbar

| Item | Detail |
|---|---|
| Values | Width and height 6px; thumb radius 5 (a pill at this width); track and corner transparent. Thumb colour: the per-theme scrollbar variables (TOK-08): rest light `gray-6` `#e5e5e5` / dark `gray-8` `#737373`; hover light `gray-9` `#999999` / dark `gray-11` `#bbbbbb`. Firefox: thin width, thumb colour on a transparent track |
| Visibility | Pages and panes: the thumb is visible at rest (replaces AP's hidden-until-hover rule). Floating menus, select panels, command lists and popovers: hover-only (transparent until the container is hovered) |
| Radix scroll area | Bar 6px, inset 2px from the edge, radius 4, same thumb colours; the bar fades in when the area is hovered and out when the pointer leaves (MOT-17) |
| States | Thumb hover darkens as listed |
| AP target | `styles.css` base layer (global scrollbar rules) and `components/ui/scroll-area.tsx` |
| Notes | The `scrollbar-none` opt-out stays. The sticky-note scrollbar is CAN |

---

### PRM-24 — Skeleton

| Item | Detail |
|---|---|
| Values | Radius 8 (`rounded-lg`); default line height 16 (`h-4`); a horizontal sheen: `gray-3` at 25%, `gray-1` at 37%, `gray-3` at 63% of a band four times the element width, swept right to left (MOT-14). Lines in a list sit 16px apart. Heading line 20 tall. The last paragraph line is 61% wide; a heading line 40% |
| States | Reduced motion: flat `gray-3`, no sweep |
| Light/Dark | Same steps: light `#f5f5f5` / `#fafafa`, dark `#2b2b2b` / `#171717` |
| AP target | `components/ui/skeleton.tsx` (replace AP's opacity pulse), `components/custom/data-table/data-table-skeleton.tsx` |
| Notes | — |

---

### PRM-25 — Empty state

| Item | Detail |
|---|---|
| Frame | 2px dashed border `gray-6`, radius 8, padding 64 vertical / 32 horizontal (`py-16 px-8`), column, centred, gap 20 (`gap-5`), transparent background. Callers that already frame the empty state pass no border |
| Glyph | 40px Lucide icon (`size-10`), stroke 1.5, colour `gray-9` in light (`#999999`) and `gray-11` in dark (`#bbbbbb`). AP's `icon` tile variant (`gray-3` tile) stays available |
| Text | Heading 20px (`text-xl`), weight 400, `gray-12`, centred. Description 14px, subtle text (`text-gray-12/87`), centred, at most 512px wide; heading and description 8px apart |
| Action | The primary action is a solid button at `lg` size (36px, PRM-01) |
| Light/Dark | Dark frame `#3a3a3a` on the `#171717` page |
| AP target | `components/ui/empty.tsx` |
| Notes | The first-run "action cards" empty state and its staggered entrance are PAG (motion MOT-16) |

---

### PRM-26 — Toggle

| Item | Detail |
|---|---|
| Values | Same heights and radii as buttons: `sm` 28 (radius 4), `default` 32 (radius 4), `lg` 36 (radius 6); minimum width = height; padding 0 8px; label 14px weight 500; icons 16px |
| Variants | `default` → ghost: transparent, hover `bg-gray-4`, on (pressed) `bg-gray-5` with `gray-12` text. `outline` → subtle: `bg-panel`, inset ring `gray-6`, `shadow-xs`; hover `bg-gray-4`; on `bg-gray-5` |
| States | Disabled 50% opacity. Focus recipe A |
| AP target | `components/ui/toggle.tsx` |
| Notes | — |

---

### PRM-27 — Field label and form messages

| Item | Detail |
|---|---|
| Values | Label 14px, weight 500, `gray-12`, 4–8px above the field (AP's form item spacing 4px stays). Required marker: `danger-11` asterisk. Helper text 12px `gray-11`. Error text 12px `danger-11` |
| States | Error label: `danger-11` (AP's) |
| AP target | `components/ui/label.tsx`, `components/ui/form.tsx` (`FormDescription` becomes 12px) |
| Notes | Parameter rows inside the step modal add hover controls (NDV) |
