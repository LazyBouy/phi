# 10 — Motion (MOT)

Shared motion tokens and the motion of every primitive in `02-primitives.md`. Canvas, graph, step-modal, piece-panel, logs and shell motion are owned by their own files; MOT-18 lists them by prefix only.

The overall feel: short (200ms is the standard), decelerating, small distances (2–8px), opacity plus a little scale or blur, and no exit animation on menus and tooltips.

---

### MOT-01 — Durations

| ms | Role |
|---|---|
| 100 | Micro fades; the reduced-motion cross-fade |
| 120 | Scroll-area bar fade-out |
| 200 | The standard: hover, press and colour changes; popover and menu open; dialog open and close; overlay fade; button loading swap; switch slide; input focus; collapsibles |
| 250 | Short fade-outs that should linger slightly |
| 300 | Card hover shadow; tag fill; toast slide and fade; sheet slide |
| 340 | Scroll-area bar fade-in |
| 350 | Blur reveal of expanding regions |
| 400 | Entrance of larger elements; one turn of the button spinner |
| 1000 | Long holds (for example "hide after 1s") |
| 1400 | Skeleton sweep |
| 1500 | Slow loops (AP's existing indeterminate bar) |

| Item | Detail |
|---|---|
| AP target | Tailwind's numeric `duration-*` utilities accept any integer, so no theme key is needed; AP's existing `--transition-duration-1500` stays |
| Notes | Durations named by other files (for example the 4.5s waiting ring) are owned there (MOT-18) |

---

### MOT-02 — Easing curves

| AP `@theme` key (new) | cubic-bezier numbers | Character | Use |
|---|---|---|---|
| `--ease-cubic-out` | 0.215, 0.61, 0.355, 1 | Standard deceleration (Penner's ease-out-cubic) | Default for UI transitions, popovers, switches, collapsibles, loading swap |
| `--ease-cubic-in` | 0.55, 0.055, 0.675, 0.19 | Acceleration | Elements leaving quickly (rare) |
| `--ease-cubic-in-out` | 0.645, 0.045, 0.355, 1 | Symmetric | Input focus border |
| `--ease-back-out` | 0.34, 1.56, 0.64, 1 | About 10% overshoot | Playful pops (optional, for small elements only) |
| `--ease-quart-out` | 0.165, 0.84, 0.44, 1 | Stronger deceleration | — |
| `--ease-quint-out` | 0.23, 1, 0.32, 1 | Lands fast, settles softly | Icon swaps (copy → check) |
| `--ease-expo-out` | 0.19, 1, 0.22, 1 | Very strong deceleration | Hover scale-ups (NDV neighbours) |
| `--ease-reveal` | 0.32, 0.72, 0, 1 | Drawer-like reveal | Blur reveal (MOT-16) |
| `--ease-standard` | 0.25, 0.1, 0.25, 1 | Same as the CSS keyword "ease" | Overlay fades, sheets, toasts, card hover |
| `--ease-decelerate` | 0, 0, 0.58, 1 | Same as the CSS keyword "ease-out" | Dialog frame, scroll-area bar |

| Item | Detail |
|---|---|
| AP target | `packages/web/src/styles.css` `@theme`. AP clears Tailwind's easing keys and keeps only `--ease-expand-out`; add the keys above next to it (that one stays) |
| Notes | `linear` stays available for loops |

---

### MOT-03 — Default transition

| Item | Detail |
|---|---|
| Values | Default transition duration 200ms (Tailwind's is 150ms); default timing `--ease-cubic-out` (Tailwind's is 0.4, 0, 0.2, 1) |
| AP target | `styles.css` `@theme`: the default transition duration and timing-function keys. Every `transition-colors`, `transition-all`, `transition-opacity` and `transition-shadow` without an explicit duration picks this up |
| Notes | Use `transition-colors` (not `transition-all`) where only colours change |

---

### MOT-04 — Hover, press and colour feedback

| Element | Motion |
|---|---|
| Buttons, toggles, menu rows, segmented segments, tabs (label colour), badges | Background, border, ring and text colour: 200ms, `--ease-cubic-out` (MOT-03). Press is immediate on pointer down |
| Card hover shadow (PRM-15) | Shadow: 300ms, `--ease-standard` |
| Tag fill (PRM-14) | Background and border: 300ms, `--ease-standard` |
| Table row hover (PRM-16) | Background: 200ms |
| Disabled elements | No motion |

| Item | Detail |
|---|---|
| AP target | The primitives in `packages/web/src/components/ui/` |
| Notes | No hover lift (no translate) on buttons or rows |

---

### MOT-05 — Floating surfaces: popover, dropdown and context menu, select panel, hover card, command panel

| Item | Detail |
|---|---|
| Open | 200ms, `--ease-cubic-out`: opacity 0 → 1, scale 0.96 → 1, and a 2px offset that settles to 0. The offset is along the side the surface opened on, starting 2px further away from the trigger (below a trigger: starts 2px lower; above: 2px higher; right: 2px further right; left: 2px further left). With start/end alignment on a top or bottom side, the start also shifts 2px toward that aligned edge. Transform origin is the surface edge that faces the trigger |
| Close | Immediate: no fade, no scale |
| AP target | `components/ui/popover.tsx`, `dropdown-menu.tsx`, `context-menu.tsx`, `select.tsx`, `hover-card.tsx`, `command.tsx` (when shown in a popover) |
| Notes | Replace AP's tw-animate fade + zoom-95 + 8px slide classes. AP's global rule in `styles.css` (utilities layer) resets the enter and exit translate variables of every open and closed Radix part, which cancels tw-animate slide utilities; so build the open motion as one dedicated keyframe animation in `@theme` that reads the side from the component, not from tw-animate's slide utilities. Radix already exposes the trigger-facing transform origin, which AP's primitives use |

---

### MOT-06 — Tooltip

| Item | Detail |
|---|---|
| Values | Show and hide are instant: no fade, no zoom, no slide. Show delay 0 (AP's provider value) |
| AP target | `components/ui/tooltip.tsx` (remove the animate-in and animate-out classes) |
| Notes | Canvas tooltips that wait before showing are CAN / NOD |

---

### MOT-07 — Dialog

| Item | Detail |
|---|---|
| Overlay | Fades 0 → 1 on open and 1 → 0 on close, 200ms, `--ease-standard` |
| Frame open | 200ms, `--ease-decelerate`: from opacity 0, 8px lower, scale 0.98, to rest |
| Frame close | 200ms, `--ease-decelerate`: back to opacity 0, 8px lower, scale 0.98 |
| AP target | `components/ui/dialog.tsx` (replace the zoom-95 and slide-from-48% classes) |
| Notes | The step modal (NDV) opens and closes without animation; that is NDV's rule, not this one |

---

### MOT-08 — Sheet and drawer

| Item | Detail |
|---|---|
| Values | Open: the panel moves from fully off its edge (100% of its size) to rest while fading 0 → 1, 300ms, `--ease-standard`. Close: the reverse, 300ms. Overlay fades with it, 300ms |
| AP target | `components/ui/sheet.tsx` (AP uses 500ms open / 300ms close today; both become 300ms), `components/ui/drawer.tsx` |
| Notes | AP's existing exception in `styles.css` that keeps the sheet's slide distance at 100% stays |

---

### MOT-09 — Button loading

| Item | Detail |
|---|---|
| Swap | When loading starts, the label (and its icon) fades out while moving 4px down and blurring by 2px; the spinner fades in from 4px below and 2px blur to sharp; both over 200ms, `--ease-cubic-out`. When loading ends, the reverse. The button keeps its width throughout |
| Spinner | One full turn per 400ms, linear, infinite |
| AP target | `components/ui/button.tsx` (with `components/custom/spinner.tsx` for the spinner glyph) |
| Notes | Reduced motion: MOT-19 |

---

### MOT-10 — Switch

| Item | Detail |
|---|---|
| Values | Thumb slides between ends: 200ms, `--ease-cubic-out`. Track colour change: 200ms. On hover and on press the thumb grows 2px wider (toward the centre) over 200ms and shrinks back on release |
| AP target | `components/ui/switch.tsx` |

---

### MOT-11 — Instant state switches

| Element | Rule |
|---|---|
| Underline tabs (PRM-06) | The active underline jumps to the new tab; it does not slide. Label colour follows MOT-04 |
| Segmented control (PRM-07) | The selected segment's fill jumps; it does not slide |
| Checkbox and radio (PRM-18, PRM-19) | Tick, dash and dot appear instantly; fill and border colour follow MOT-04 |
| Focus rings (TOK-11) | Appear and disappear instantly |

| Item | Detail |
|---|---|
| AP target | `tabs.tsx`, `segmented-control.tsx`, `checkbox.tsx`, `radio-group.tsx` |

---

### MOT-12 — Field focus

| Item | Detail |
|---|---|
| Values | Inputs, textarea and select trigger: border colour change (rest → hover → focus) over 200ms, `--ease-cubic-in-out`. The 2px halo appears instantly |
| AP target | `components/ui/input.tsx`, `textarea.tsx`, `select.tsx` |

---

### MOT-13 — Toasts

| Item | Detail |
|---|---|
| Enter | Slides in from the right edge (starting fully outside, 100% of its width to the right) while fading in, 300ms, `--ease-standard` |
| Exit | Fades out, 300ms |
| Re-stack | When a toast leaves or arrives, the others move to their new vertical place over 300ms |
| AP target | `components/ui/sonner.tsx` and, if the library's own animation must be overridden, the toast rules in `styles.css` |
| Notes | Sonner's default motion is vertical; it is replaced by the horizontal slide |

---

### MOT-14 — Loading indicators

| Element | Motion |
|---|---|
| Skeleton (PRM-24) | The sheen band's position moves from 100% to 0% (right to left) over 1400ms, `--ease-standard`, repeating |
| Table refresh bar (PRM-16) | AP's existing indeterminate progress (1500ms, ease-in-out, repeating) |
| Table rows while refreshing | Opacity to 38% over 200ms, back on completion |
| Button spinner | MOT-09 |
| Page and panel spinners | AP's existing spinner speed |

| Item | Detail |
|---|---|
| AP target | `components/ui/skeleton.tsx` (new sweep keyframe in `@theme`), `components/custom/data-table/` |

---

### MOT-15 — Collapsible and accordion

| Item | Detail |
|---|---|
| Values | Height opens and closes over 200ms, `--ease-cubic-out` |
| AP target | `styles.css` `@theme` animation keys for accordion and collapsible (today 0.2s with the CSS "ease-out" keyword; only the easing changes) |
| Notes | Settings regions that expand with a soft blur use MOT-16 (blur reveal) |

---

### MOT-16 — Shared entrance recipes

| Recipe | Motion | Typical use |
|---|---|---|
| Fade up | Opacity 0 → 1, 4px rise, blur 2px → 0; 200ms, `--ease-cubic-out` | Swapped content, inline messages |
| Fade in | Opacity 0 → 1, 8px rise, blur 2px → 0; 200ms, `--ease-cubic-out` | Page sections appearing |
| Blur reveal | Height 0 → content height with opacity 0 → 1 and blur 4px → 0 (reverse on close); 350ms, `--ease-reveal` | Expanding settings rows |
| Staggered entrance | Each item runs "fade in" over 400ms, `--ease-cubic-out`, starting 160ms + 80ms × its index | First-run action cards (PAG) |

| Item | Detail |
|---|---|
| AP target | `styles.css` `@theme` animation keys (AP already has fade, fade-in-up and slide-up keyframes; add these alongside or retune the existing ones) |
| Notes | AP's chat streaming fades keep their own timing |

---

### MOT-17 — Scroll-area bar

| Item | Detail |
|---|---|
| Values | In Radix scroll areas the bar fades in when the area is hovered (340ms, `--ease-decelerate`) and fades out when the pointer leaves (120ms, `--ease-decelerate`). Thumb colour change on hover: 300ms |
| AP target | `components/ui/scroll-area.tsx` |

---

### MOT-18 — Motion owned by other files

These are specified in their own files and are listed here only so nothing is specified twice.

| Motion | Owner |
|---|---|
| Canvas first appearance, minimap show and hide, zoom and fit transitions, pan to selection, spotlight dimming, canvas tooltip delay | CAN |
| Node hover toolbar, trigger-button swap, running and waiting rings, status changes | NOD |
| Handle hover, plus-stub appear and disappear | HDL |
| Edge colour change, edge toolbar show and hide, connection drag line | EDG |
| Step modal open and close, neighbour hover, parameter hover controls, drag-and-drop mapping | NDV |
| Piece panel slide, sub-view push and pop | PCK |
| Logs panel open, collapse and resize | LOG |
| Sidebar collapse and expand | SHL |
| List-card hover, empty-state card stagger placement | PAG |

---

### MOT-19 — Reduced motion

When the user's system asks for reduced motion:

| Category | Behaviour |
|---|---|
| Entrance and exit keyframes (MOT-05, MOT-07, MOT-08, MOT-13, MOT-16) | Off: the element appears and disappears in its final state |
| Transform, size, filter transitions (switch thumb slide, collapsibles, sheets, sidebar width) | Instant |
| Colour and opacity transitions (MOT-04, MOT-12) | Allowed, at most 100ms |
| Button loading swap (MOT-09) | Opacity cross-fade only, 100ms; no movement, no blur |
| Loops: spinners, skeleton sweep, indeterminate bar, running and waiting rings | Stopped: the spinner shows as a still glyph, the skeleton as a flat `gray-3` block, the bar as a still bar |
| Canvas viewport moves | Jump instantly (CAN) |
| The `motion` library | Follows the system setting app-wide |

| Item | Detail |
|---|---|
| AP target | `styles.css` (one reduced-motion section for the new keyframes and the global transition override; AP's existing chat and gradient reduced-motion rules stay); the app root `packages/web/src/app/app.tsx` (configure the `motion` library to respect the user setting) |
| Notes | Focus rings and state changes (MOT-11) are unaffected; they are already instant |
