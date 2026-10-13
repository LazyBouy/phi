# Node equivalents — builder-facing spec

New Activepieces pieces, written from scratch, for everyday data operations that the reference product has as built-in nodes and Activepieces lacks. Plan: `iphi-flow/docs/plans/node-equivalents-clean-room.md`.

Facts behind this spec were gathered black-box from the running reference app and are kept in `_provenance/` (reference-only, never read by builders). Everything below is Activepieces design in Activepieces wording. Where the reference behaves in a surprising way, this spec deliberately defines simpler, predictable behaviour instead.

## Files

| File | ID prefix | Piece |
|---|---|---|
| `01-list-tools.md` | LST | List Tools |
| `02-security-tokens.md` | SEC | JSON Web Tokens; One-Time Passwords |
| `03-compression.md` | CMP | Gzip |

## Never use

- The reference product's name, logo, icons or node artwork.
- Its UI wording: labels, descriptions, help texts, error messages and examples. Every string here is new Activepieces wording.
- Its source code, expression syntax or parameter naming scheme.
- The audit's forbidden-text list (`iphi-flow/tools/clean-room-forbidden.txt`) applies to every added line.

## Conventions for every piece (CNV)

### CNV-01 — Packaging

- **Values:** Each piece is a new package under `packages/pieces/custom/<folder>/`, scaffolded like a core piece: `package.json`, `tsconfig.json`, `tsconfig.lib.json`, `.eslintrc.json`, `vitest.config.ts`, `src/index.ts`, one file per action under `src/lib/actions/`, pure helpers under `src/lib/common/`, `src/i18n/translation.json` (English keys mapped to themselves), tests under `test/`. A path alias in `tsconfig.base.json`.

  | Folder | Package name | Display name | Version |
  |---|---|---|---|
  | `list-tools` | `@iphi-flow/piece-list-tools` | List Tools | 0.1.0 |
  | `json-web-tokens` | `@iphi-flow/piece-json-web-tokens` | JSON Web Tokens | 0.1.0 |
  | `one-time-passwords` | `@iphi-flow/piece-one-time-passwords` | One-Time Passwords | 0.1.0 |
  | `gzip` | `@iphi-flow/piece-gzip` | Gzip | 0.1.0 |

- **Notes:** Imports only `@activepieces/pieces-framework` and `@activepieces/pieces-common` (the per-piece lint forbids the rest). Every action carries `audience`, `classification` and `aiMetadata { description, idempotent }`, as the repo's piece-builder rules require. Action names are permanent once shipped. All four pieces declare the `CORE` category. Logos are drawn for this project (a simple glyph on a plate) or taken from Lucide (ISC licence, already used by the app), embedded as a data URI; never copied from any other product.

### CNV-02 — Lists in, lists out

- **Values:** A list action takes its list from a property named "List" (a JSON property): a mapped list from an earlier step, or JSON text that parses to a list. Anything else stops the step with "The List input must be a list (for example a step output that is a list, or JSON text starting with [)." List entries that are not objects are allowed where the action says so; otherwise they stop the step with a message naming the entry's position (counting from 1).
- **Output:** Every action returns one object with named fields (for example `items`, `count`), never a bare list, so later steps can map the parts they need and the output schema can describe them. Each action declares an `outputSchema`.
- **Notes:** Inputs are never changed in place; outputs are new objects.

### CNV-03 — Field paths

- **Values:** Where an action asks for a field, the user types a path: a field name, or names joined by dots for nested fields (`customer.address.city`); a number segment selects a list position, counting from 0 (`lines.0.sku`). A key that itself contains a dot is reached only if the option "Treat dots as part of the name" is on (where offered). A path that does not exist on an item reads as "missing" (no error), unless the action says otherwise.

### CNV-04 — Values and types

- **Values:** "Empty" means missing, null, empty text, an empty list or an empty object. Text comparisons are case-insensitive unless the action's "Case sensitive" option is on (the Activepieces CSV piece uses the same default). Numbers: a number, or text that is a plain decimal number after trimming spaces (`' 7 '`, `-0.5`, `1e3`); anything else is not a number. Dates: ISO 8601 text (a date without a time means midnight UTC), or a number of milliseconds since 1970. Equality of objects and lists is deep, and object key order is ignored.
- **Notes:** These rules apply to every comparison in these pieces, so behaviour is the same everywhere.

### CNV-05 — Errors and empty input

- **Values:** An empty list is valid input: the action returns its normal output with empty lists and zero counts. Configuration mistakes (a missing required field, an invalid pattern, an unknown option) stop the step with a message that says what to fix, in plain words. Data problems that the action defines as non-fatal (for example a value that is not a number in a sum) are skipped, never fatal.
- **Notes:** Activepieces' step settings already offer "continue on failure"; the pieces add nothing of their own for it.

### CNV-06 — Text

- **Values:** All display names, descriptions, option labels and messages are written in Activepieces' voice, as in this spec. Option labels for operators follow the Router step's style, with the value type in brackets.
- **Notes:** Translations: the identity-mapped `translation.json` per piece; other locales fall back to English.

## Spec ID → AP file map

Generated by `iphi-flow/tools/spec-index.mjs` from the requirement blocks (27 requirements in 3 files). Re-run it after any spec edit. Paths are relative to the AP fork; `WEB` = `packages/web`, `BUILDER` = `WEB/src/app/builder`.

| ID | Requirement | Spec file | AP target |
|---|---|---|---|
| LST-01 | The piece | `01-list-tools.md` | `PIECE/src/index.ts`, `PIECE/package.json`, `tsconfig.base.json` |
| LST-02 | Filter List | `01-list-tools.md` | `PIECE/src/lib/actions/filter-list.ts`, `PIECE/src/lib/common/conditions.ts`, `PIECE/src/lib/common/values.ts` |
| LST-03 | Sort List | `01-list-tools.md` | `PIECE/src/lib/actions/sort-list.ts`, `PIECE/src/lib/common/compare.ts` |
| LST-04 | Limit List | `01-list-tools.md` | `PIECE/src/lib/actions/limit-list.ts` |
| LST-05 | Remove Duplicates | `01-list-tools.md` | `PIECE/src/lib/actions/remove-duplicates.ts`, `PIECE/src/lib/common/equality.ts` |
| LST-06 | Keep New Items | `01-list-tools.md` | `PIECE/src/lib/actions/keep-new-items.ts`, `PIECE/src/lib/common/seen-store.ts`, `context.store` |
| LST-07 | Forget Seen Items | `01-list-tools.md` | `PIECE/src/lib/actions/forget-seen-items.ts`, `PIECE/src/lib/common/seen-store.ts` |
| LST-08 | Expand Nested List | `01-list-tools.md` | `PIECE/src/lib/actions/expand-nested-list.ts` |
| LST-09 | Collect Values | `01-list-tools.md` | `PIECE/src/lib/actions/collect-values.ts` |
| LST-10 | Group and Summarize | `01-list-tools.md` | `PIECE/src/lib/actions/group-and-summarize.ts`, `PIECE/src/lib/common/calculations.ts` |
| LST-11 | Compare Lists | `01-list-tools.md` | `PIECE/src/lib/actions/compare-lists.ts`, `PIECE/src/lib/common/equality.ts` |
| LST-12 | Combine Lists | `01-list-tools.md` | `PIECE/src/lib/actions/combine-lists.ts`, `PIECE/src/lib/common/merge.ts` |
| LST-13 | Rename Fields | `01-list-tools.md` | `PIECE/src/lib/actions/rename-fields.ts` |
| LST-14 | Set Fields | `01-list-tools.md` | `PIECE/src/lib/actions/set-fields.ts`, `PIECE/src/lib/common/templates.ts` |
| LST-15 | Place in the piece panel | `01-list-tools.md` | `WEB/features/pieces/utils/piece-search-utils.ts` |
| LST-16 | Tests | `01-list-tools.md` | `PIECE/test/*.test.ts` |
| SEC-01 | JSON Web Tokens piece and connection | `02-security-tokens.md` | `JWT/src/index.ts`, `JWT/src/lib/auth.ts`, `JWT/package.json`, `tsconfig.base.json` |
| SEC-02 | Create Token | `02-security-tokens.md` | `JWT/src/lib/actions/create-token.ts` |
| SEC-03 | Verify Token | `02-security-tokens.md` | `JWT/src/lib/actions/verify-token.ts` |
| SEC-04 | Read Token | `02-security-tokens.md` | `JWT/src/lib/actions/read-token.ts` |
| SEC-05 | One-Time Passwords piece and connection | `02-security-tokens.md` | `OTP/src/index.ts`, `OTP/src/lib/auth.ts`, `OTP/package.json`, `tsconfig.base.json` |
| SEC-06 | Generate Code | `02-security-tokens.md` | `OTP/src/lib/actions/generate-code.ts`, `OTP/src/lib/common/totp.ts` |
| SEC-07 | Place in the piece panel and tests | `02-security-tokens.md` | `WEB/features/pieces/utils/piece-search-utils.ts`, `JWT/test/*.test.ts`, `OTP/test/*.test.ts` |
| CMP-01 | The piece | `03-compression.md` | `GZ/src/index.ts`, `GZ/package.json`, `tsconfig.base.json` |
| CMP-02 | Compress File | `03-compression.md` | `GZ/src/lib/actions/compress-file.ts` |
| CMP-03 | Decompress File | `03-compression.md` | `GZ/src/lib/actions/decompress-file.ts` |
| CMP-04 | Place in the piece panel and tests | `03-compression.md` | `WEB/features/pieces/utils/piece-search-utils.ts`, `GZ/test/*.test.ts` |

Every requirement names an AP target.
