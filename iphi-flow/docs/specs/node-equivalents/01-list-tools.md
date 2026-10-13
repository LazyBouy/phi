# 01 — List Tools (LST)

One piece, "List Tools", with actions for everyday list work: filter, sort, limit, de-duplicate, expand, collect, group and summarise, compare, combine, rename and edit. Every action follows the conventions in `00-index.md` (CNV-01 to CNV-06). `PIECE` below means `packages/pieces/custom/list-tools`.

## Requirements

### LST-01 — The piece

- **Values:** Display name "List Tools"; description "Filter, sort, de-duplicate, reshape and combine lists of items"; categories CORE; no connection (`PieceAuth.None()`); minimum supported release as the core pieces use. Actions in this order: Filter List, Sort List, Limit List, Remove Duplicates, Keep New Items, Forget Seen Items, Expand Nested List, Collect Values, Group and Summarize, Compare Lists, Combine Lists, Rename Fields, Set Fields.
- **AP target file(s):** `PIECE/src/index.ts`, `PIECE/package.json`, `tsconfig.base.json`.
- **Notes:** Logo: a list glyph drawn for this project, or Lucide "ListFilter", as a data URI.

### LST-02 — Filter List

- **Values:** Keeps the items that meet the conditions and returns the rest separately.

  | Property | Type | Default | Notes |
  |---|---|---|---|
  | List | JSON | required | CNV-02; entries must be objects |
  | Conditions | repeating rows: "Field" (text, a path), "Operator" (dropdown), "Value" (text) | one empty row | at least one row with a field |
  | Match | dropdown: "All conditions" / "Any condition" | All conditions | one setting for the whole list |
  | Case sensitive | checkbox | off | text operators only |

  Operators, in this order: "Exists", "Does not exist", "Is empty", "Is not empty", "Exactly matches (Text)", "Does not exactly match (Text)", "Contains (Text)", "Does not contain (Text)", "Starts with (Text)", "Does not start with (Text)", "Ends with (Text)", "Does not end with (Text)", "Matches pattern (Text)", "Is equal to (Number)", "Is not equal to (Number)", "Is greater than (Number)", "Is greater than or equal to (Number)", "Is less than (Number)", "Is less than or equal to (Number)", "Is true (Boolean)", "Is false (Boolean)", "Before (Date/time)", "After (Date/time)", "Equals (Date/time)", "Contains (List)", "Does not contain (List)", "Is empty (List)", "Is not empty (List)", "Has length (List)" (value = a number).

- **Rules:**
  - "Exists": the path is present and not null. "Is empty": CNV-04 empty.
  - Text operators read the field as text (numbers and booleans as their text form; objects and lists never match). "Matches pattern" takes a regular expression; the "Case sensitive" option controls its case too.
  - Number, date and boolean operators: if the field or the value cannot be read as that type (CNV-04), the condition is false for that item. Boolean reads true/false, the texts "true"/"false" (any case), and 1/0.
  - List operators: "Contains (List)" is true when one entry equals the value (deep equality; text entries follow the case option).
  - An item with no conditions to test (no row has a field) stops the step: "Add at least one condition with a field."
  - Order is kept in both outputs.
- **Output:** `{ kept: [...], removed: [...], keptCount, removedCount }`.
- **Errors:** an invalid pattern stops the step: "The pattern in condition {n} is not a valid regular expression."
- **AP target file(s):** `PIECE/src/lib/actions/filter-list.ts`, `PIECE/src/lib/common/conditions.ts`, `PIECE/src/lib/common/values.ts`.
- **Notes:** Operator labels reuse the Router step's style so users meet one vocabulary.

### LST-03 — Sort List

- **Values:**

  | Property | Type | Default | Notes |
  |---|---|---|---|
  | List | JSON | required | entries must be objects, unless "Sort by" is "The entries themselves" |
  | Sort by | dropdown: "Fields" / "The entries themselves" / "Random order" | Fields | |
  | Sort keys | repeating rows: "Field" (path), "Direction" ("Ascending" / "Descending"), "Compare as" ("Automatic" / "Text" / "Number" / "Date") | one row, Ascending, Automatic | shown for Fields; the first row is the main key |
  | Direction | "Ascending" / "Descending" | Ascending | shown for "The entries themselves" |
  | Case sensitive | checkbox | off | text comparisons |

- **Rules:**
  - "Automatic" compares as numbers when both values are numbers (CNV-04), otherwise as text. "Text" uses natural order, so "item 2" comes before "item 10". "Date" uses CNV-04 dates.
  - Missing, null and values that cannot be read as the chosen type go last, in both directions, keeping their original order.
  - The sort is stable: equal keys keep their input order.
  - "Random order" shuffles uniformly.
- **Output:** `{ items: [...], count }`.
- **Errors:** "Fields" with no field in any row: "Add at least one field to sort by."
- **AP target file(s):** `PIECE/src/lib/actions/sort-list.ts`, `PIECE/src/lib/common/compare.ts`.
- **Notes:** —

### LST-04 — Limit List

- **Values:** "List" (JSON, required, any entries); "How many" (number, required, default 10; a whole number of 0 or more); "Keep" ("The first entries" / "The last entries", default the first).
- **Rules:** Returns at most "How many" entries, in their original order. 0 returns an empty list. A negative or fractional number stops the step: "How many must be a whole number of 0 or more."
- **Output:** `{ items: [...], count, removedCount }`.
- **AP target file(s):** `PIECE/src/lib/actions/limit-list.ts`.
- **Notes:** —

### LST-05 — Remove Duplicates

- **Values:**

  | Property | Type | Default | Notes |
  |---|---|---|---|
  | List | JSON | required | any entries |
  | Compare | "Whole entries" / "Only these fields" / "All fields except" | Whole entries | the field options need object entries |
  | Fields | text, comma-separated paths | — | shown for the two field options |
  | Keep | "The first occurrence" / "The last occurrence" | The first occurrence | |
  | Output only the compared fields | checkbox | off | shown for "Only these fields" |
  | Case sensitive | checkbox | on | text values |

- **Rules:** Two entries are duplicates when the compared values are equal (CNV-04: deep, key order ignored, `1` and `'1'` differ; text follows the case option). Missing fields compare as missing (two missing values are equal); entries may have different shapes. "All fields except" removes the named paths (a parent name excludes everything under it) before comparing. The kept entries stay in their original relative order.
- **Output:** `{ items: [...], count, removedCount }`.
- **Errors:** a field option with an empty Fields list: "List the fields to compare, separated by commas."
- **AP target file(s):** `PIECE/src/lib/actions/remove-duplicates.ts`, `PIECE/src/lib/common/equality.ts`.
- **Notes:** —

### LST-06 — Keep New Items

- **Values:** Keeps only entries whose key has not been seen in earlier runs of the flow, and remembers the keys it lets through.

  | Property | Type | Default | Notes |
  |---|---|---|---|
  | List | JSON | required | |
  | Key field | text path | required | the value that identifies an entry; use the entry itself when the list holds plain values (leave empty) |
  | Remember for | "This flow" / "All flows in this project" | This flow | storage scope |
  | Memory name | text | "seen-items" | separates independent memories in the same scope |
  | Memory size | number | 10000 | the oldest keys are forgotten first once the size is reached |

- **Rules:** Keys are compared as their JSON text (so `1` and `'1'` differ). Within one run, a repeated key is kept once (the first). Entries whose key is missing are kept and not remembered. The memory is updated only after the step succeeds.
- **Output:** `{ items: [...], count, skipped: [...], skippedCount }`.
- **AP target file(s):** `PIECE/src/lib/actions/keep-new-items.ts`, `PIECE/src/lib/common/seen-store.ts` (uses `context.store`).
- **Notes:** Test runs in the builder use the same memory as live runs; the description says so.

### LST-07 — Forget Seen Items

- **Values:** "Remember for" and "Memory name" as LST-06; "Forget" ("Everything" / "These keys"); "Keys" (JSON list, shown for "These keys").
- **Rules:** Clears the named memory, or only the listed keys. Clearing a memory that does not exist is not an error.
- **Output:** `{ forgottenCount }`.
- **AP target file(s):** `PIECE/src/lib/actions/forget-seen-items.ts`, `PIECE/src/lib/common/seen-store.ts`.
- **Notes:** —

### LST-08 — Expand Nested List

- **Values:** Turns a list held in a field of each entry into separate entries.

  | Property | Type | Default | Notes |
  |---|---|---|---|
  | List | JSON | required | entries must be objects |
  | Field to expand | text path | required | |
  | Keep other fields | "No" / "All" / "Only these" | All | |
  | Fields to keep | text, comma-separated | — | shown for "Only these" |
  | Put each element in | text | the last segment of the expanded path | the name of the field that receives each element |

- **Rules:** Each element of the list at the path becomes one output entry: the kept fields (with the expanded field removed), plus the element under "Put each element in". With "Keep other fields" = "No", an object element becomes the entry itself and a plain value is put under the field name. A value that is not a list counts as a one-element list; a missing or empty list produces no entries for that item. Output order: by input entry, then by element.
- **Output:** `{ items: [...], count }`.
- **AP target file(s):** `PIECE/src/lib/actions/expand-nested-list.ts`.
- **Notes:** —

### LST-09 — Collect Values

- **Values:** Gathers values from every entry into lists.

  | Property | Type | Default | Notes |
  |---|---|---|---|
  | List | JSON | required | entries must be objects |
  | Fields | repeating rows: "Field" (path), "Save as" (text, optional) | one row | "Save as" defaults to the path with dots replaced by underscores |
  | Flatten lists | checkbox | off | a value that is itself a list adds its entries, one level |
  | Keep empty values | checkbox | off | when on, missing and null become null entries |
  | Unique values only | checkbox | off | removes repeats (CNV-04 equality), keeping the first |

- **Output:** `{ <save-as name>: [...], ... }` — one list per row.
- **Errors:** two rows saving to the same name: "Each field must be saved under a different name."
- **AP target file(s):** `PIECE/src/lib/actions/collect-values.ts`.
- **Notes:** —

### LST-10 — Group and Summarize

- **Values:**

  | Property | Type | Default | Notes |
  |---|---|---|---|
  | List | JSON | required | entries must be objects |
  | Group by | text, comma-separated paths | empty | empty = one summary over all entries |
  | Calculations | repeating rows: "Field" (path), "Calculation" (dropdown), "Save as" (text, optional) | one row: Count | |
  | Join with | text | ", " | separator for "Join as text" |
  | Skip entries without a group value | checkbox | off | |

  Calculations: "Count", "Count unique", "Sum", "Average", "Minimum", "Maximum", "List of values", "Join as text", "First value", "Last value".

- **Rules:**
  - Count, Count unique, List of values and Join as text ignore empty values (CNV-04). Sum and Average use numbers only (numeric text counts; other values are skipped); with no numbers, Sum is 0 and Average is null. Minimum and Maximum compare numbers when every non-empty value is a number, dates when every value is a date, otherwise text; with no values they are null.
  - "Save as" defaults to the field name plus the calculation in camel case, for example `amountSum`, `amountAverage`, `customerCountUnique`; dots in the path become underscores.
  - With grouping: one result per distinct combination of group values, in order of first appearance; each result carries the group fields under their own names (dots become underscores) and the calculated fields. Group values compare as CNV-04 equality (text is case-sensitive). Without "Skip entries…", a missing group value forms its own group with the field set to null.
- **Output:** `{ groups: [...], count }`; without grouping, `groups` holds one entry.
- **Errors:** two calculations saving to the same name: "Each calculation must be saved under a different name."
- **AP target file(s):** `PIECE/src/lib/actions/group-and-summarize.ts`, `PIECE/src/lib/common/calculations.ts`.
- **Notes:** Averages are not rounded.

### LST-11 — Compare Lists

- **Values:** Pairs entries of two lists by key and sorts them into four groups.

  | Property | Type | Default | Notes |
  |---|---|---|---|
  | First list | JSON | required | objects |
  | Second list | JSON | required | objects |
  | Match on | repeating rows: "Field in first list", "Field in second list" (paths) | one row | all rows must match |
  | Ignore these fields when comparing | text, comma-separated | empty | |
  | Treat numbers and numeric text as equal | checkbox | off | keys and values |
  | Case sensitive | checkbox | on | |

- **Rules:** Each first-list entry pairs with the first not-yet-paired second-list entry whose keys match. Keys that are missing never match. A paired couple is "same" when every field (except the ignored ones and the key fields) is equal, otherwise "different".
- **Output:** `{ onlyInFirst: [...], onlyInSecond: [...], same: [...], different: [...] , counts: { onlyInFirst, onlyInSecond, same, different } }`. A "same" entry is the first list's entry. A "different" entry is `{ first: <entry>, second: <entry>, changedFields: [<top-level field names>] }`.
- **Errors:** no key row with both fields: "Add at least one pair of fields to match on."
- **AP target file(s):** `PIECE/src/lib/actions/compare-lists.ts`, `PIECE/src/lib/common/equality.ts`.
- **Notes:** —

### LST-12 — Combine Lists

- **Values:**

  | Property | Type | Default | Notes |
  |---|---|---|---|
  | First list | JSON | required | |
  | Second list | JSON | required | |
  | How | "One after the other" / "Match by fields" / "Pair by position" / "Every combination" | One after the other | |
  | Match on | rows as LST-11 | — | shown for "Match by fields" |
  | Keep | "Matches only" / "All from the first list" / "All from the second list" / "All from both lists" | Matches only | shown for "Match by fields" |
  | When both have a field | "Use the second list's value" / "Use the first list's value" / "Keep both, renamed" | Use the second list's value | shown for the three combining modes; "Keep both, renamed" saves them as `first_<name>` and `second_<name>` |
  | Merge nested objects | checkbox | on | combines nested objects field by field instead of replacing them |
  | Keep unpaired entries | checkbox | off | shown for "Pair by position" |
  | Treat numbers and numeric text as equal | checkbox | off | "Match by fields" |
  | Case sensitive | checkbox | on | "Match by fields" |

- **Rules:**
  - One after the other: the first list's entries, then the second's.
  - Match by fields: every pair of matching entries becomes one merged entry; an entry matching several entries on the other side produces one merged entry per match, in first-list order. Unmatched entries are included as they are according to "Keep".
  - Pair by position: the i-th entries are merged; with "Keep unpaired entries", the leftovers of the longer list follow.
  - Every combination: every first-list entry merged with every second-list entry, in first-list order.
  - Plain (non-object) entries are allowed only for "One after the other".
- **Output:** `{ items: [...], count }`.
- **AP target file(s):** `PIECE/src/lib/actions/combine-lists.ts`, `PIECE/src/lib/common/merge.ts`.
- **Notes:** This combines data inside one step; flows still run as a tree, so joining two branches of a flow is not part of this action.

### LST-13 — Rename Fields

- **Values:**

  | Property | Type | Default | Notes |
  |---|---|---|---|
  | List | JSON | required | objects |
  | Renames | repeating rows: "From" (path), "To" (path) | empty | |
  | Rename by pattern | repeating rows: "Pattern" (regular expression), "Replace with" (text; $1, $2… insert matched groups), "Case sensitive" (checkbox, on), "Nested levels" (number, empty = all levels) | empty | applied after "Renames" |

- **Rules:**
  - All "Renames" read from the original entry at once, so swapping two fields works. A missing "From" is skipped. Renaming onto an existing field replaces it.
  - Pattern rules apply in order, each to the keys produced by the rules before it, replacing every match in a key. "Nested levels" 0 means top-level keys only.
  - A renamed key keeps its position in the object.
- **Output:** `{ items: [...], count }`.
- **Errors:** an invalid pattern: "Pattern {n} is not a valid regular expression."
- **AP target file(s):** `PIECE/src/lib/actions/rename-fields.ts`.
- **Notes:** —

### LST-14 — Set Fields

- **Values:** Sets, copies or removes fields on every entry.

  | Property | Type | Default | Notes |
  |---|---|---|---|
  | List | JSON | required | objects |
  | Set fields | repeating rows: "Field" (path), "Value from" ("A fixed value" / "Another field of the entry" / "A text template"), "Value" (text), "Type" ("Keep as is" / "Text" / "Number" / "True or false" / "List" / "Object") | empty | |
  | Keep existing fields | "All" / "Only these" / "All except" / "None" | All | |
  | Fields | text, comma-separated | — | shown for "Only these" and "All except" |
  | Stop on conversion errors | checkbox | on | off keeps the unconverted text |

- **Rules:**
  - "A fixed value" uses the Value as written (mapped values from earlier steps work as usual). "Another field of the entry" reads the path in Value from the same entry. "A text template" replaces each `{path}` in Value with that field of the entry (missing becomes empty text); braces that do not hold a plain path are left as they are.
  - Type conversion: Text writes numbers and booleans in their text form and objects and lists as JSON. Number follows CNV-04. "True or false" accepts true/false (any case), 1/0 and their text. List and Object accept their JSON text.
  - Kept fields come first in their original order, then set fields in row order; a set field that already exists keeps its position. Setting a nested path creates the missing objects.
- **Output:** `{ items: [...], count }`.
- **Errors:** a failed conversion with "Stop on conversion errors" on: "Entry {n}: {field} cannot be converted to {type}."
- **AP target file(s):** `PIECE/src/lib/actions/set-fields.ts`, `PIECE/src/lib/common/templates.ts`.
- **Notes:** Activepieces resolves mapped values once per step, not once per entry; per-entry values come from "Another field of the entry" and "A text template".

### LST-15 — Place in the piece panel

- **Values:** In the "+" panel's Transform data category (`08-piece-panel.md` PCK-15 in the look-and-feel spec), a section "Work with lists" (new key), placed second, holding List Tools. In trigger mode nothing changes (the piece has no triggers).
- **AP target file(s):** `WEB/features/pieces/utils/piece-search-utils.ts` (the category map), its test.
- **Notes:** The look-and-feel spec already reserves this section (PCK-15 note).

### LST-16 — Tests

- **Values:** Unit tests (vitest) for every action and helper: each rule above, empty lists, missing fields, mixed types, nested paths, case options, stability of order, and a 10,000-entry performance smoke test per list action (finishes in well under a second on the dev host).
- **AP target file(s):** `PIECE/test/*.test.ts`.
- **Notes:** —
