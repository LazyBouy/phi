# 03 — Gzip (CMP)

One piece, "Gzip", for gzip compression of files. Zip archives are already covered by the core Files Helper piece (zip and unzip); tar archives are out of scope for this plan. Conventions: `00-index.md`. `GZ` = `packages/pieces/custom/gzip`.

## Requirements

### CMP-01 — The piece

- **Values:** Display name "Gzip"; description "Compress and decompress files with gzip"; categories CORE; no connection. Actions: Compress File, Decompress File.
- **AP target file(s):** `GZ/src/index.ts`, `GZ/package.json`, `tsconfig.base.json`.
- **Notes:** Uses Node's built-in zlib; no third-party library.

### CMP-02 — Compress File

- **Values:** "File" (file, required); "File name" (text, optional; default the input name plus `.gz`); "Compression level" (dropdown "Fastest" / "Balanced" / "Smallest", default Balanced).
- **Rules:** Writes a `.gz` file through the Activepieces file service, storing the original name inside the gzip header. A given name without `.gz` gets it added once.
- **Output:** `{ file, fileName, originalSize, compressedSize }`.
- **AP target file(s):** `GZ/src/lib/actions/compress-file.ts`.
- **Notes:** —

### CMP-03 — Decompress File

- **Values:** "File" (file, required); "File name" (text, optional).
- **Rules:** Detects gzip by its content (the two magic bytes), not by the extension. The output name is, in order: the given name, the original name stored in the gzip header, the input name without `.gz`, or `file`.
- **Output:** `{ file, fileName, size }`.
- **Errors:** content that is not gzip: "This file is not gzip-compressed."
- **AP target file(s):** `GZ/src/lib/actions/decompress-file.ts`.
- **Notes:** —

### CMP-04 — Place in the piece panel and tests

- **Values:** Transform data → "Formats and files". Unit tests: round trip of text and binary content, names, levels, non-gzip input, an empty file.
- **AP target file(s):** `WEB/features/pieces/utils/piece-search-utils.ts`, `GZ/test/*.test.ts`.
- **Notes:** —
