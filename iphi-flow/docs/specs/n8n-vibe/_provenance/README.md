# _provenance — reference-lane records (builders never read this folder)

This folder belongs to the **reference lane** and the **clean-room auditor** of the
n8n look-and-feel work (plan: `../../../plans/n8n-look-and-feel-clean-room.md`).

It records where each fact in the builder-facing spec came from. It may name n8n
source paths and n8n design-token names, because the auditor needs them. The
builder-facing spec files one folder up (`00-index.md` … `10-motion.md`) must not.

| File | Content | Produced |
|---|---|---|
| (r1 lives at `../design/ap-ui-map.md`) | Map of the Activepieces web visual layer. It holds no n8n material, so builders may read it | 2026-10-09, read-only research agent |
| `r2-n8n-design-system-facts.md` | Facts read from the n8n design system: tokens, type, components, icons, licensing | 2026-10-09, read-only research agent |
| `r3-n8n-editor-facts.md` | Facts read from the n8n editor: canvas, nodes, handles, edges, chrome, step modal, lists, motion | 2026-10-09, read-only research agent |

Rules:
- Facts only, written in our own words. No code, CSS/SCSS text, SVG data or copied files.
- Hex values marked "≈" were converted from OKLCH sources by the research agent.
- The research reports were written from n8n commit `55eb2ce442` (CLI package version 2.43.0).
