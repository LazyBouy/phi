Quoted labels in this file are the reference app's own wording; they are reference-only and must not be copied into any product.

# R1 — Reference data-node behaviour facts

Facts-only observation record for 14 built-in data nodes of the reference workflow app. Nothing here is a design or a recommendation. Every fact was observed in the running reference app (black box), either in its web UI or in the results of workflows run inside it.

## 0. Method and conventions

0.1. Reference app build, as reported by its settings response: 2.43.0. Instance time zone, as reported there: America/New_York. Observed on 2026-10-13.

0.2. Node versions used (the highest version each node offers; the Settings tab of the Filter panel read "Filter node version 2.3 (Latest)"): Filter 2.3, Sort 1, Limit 1, Remove Duplicates 2, Split Out 1.1, Aggregate 1, Summarize 1.1, Compare Datasets 2.3, Merge 3.2, Rename Keys 1, Edit Fields (Set) 3.5, JWT 1, TOTP 1, Compression 1.1.

0.3. Behaviour tests: throwaway workflows were created and run through the endpoints the editor itself uses, then their stored execution records were read. Each test was Manual Trigger → a Code node emitting the test items → the node under test, sometimes followed by a second node (for example sign then verify). Most cases ran in their own workflow, so one failing case could not stop the others. UI facts come from the editor at 1440×900 in light mode, with the throwaway workflows run from the editor's own run button.

0.4. Notation: an item is written as {field: value}. "missing" means the field is absent from the item. Text values are in single quotes. "Kept" and "Discarded" name output lists. Error messages are given in substance, with short literal fragments where the wording itself carries meaning.

0.5. Screenshots are listed at the end (section 16). They are stored in docs/specs/node-equivalents/_ref/.

## G. Facts common to all fourteen nodes

G1. When the upstream node emits zero items, the node under test is not executed at all. It records no run and produces no output, and nothing downstream of it runs. This was seen for Filter, Sort, Limit, Remove Duplicates, Split Out, Aggregate, Summarize, Rename Keys and Edit Fields.

G2. Every node's panel has two tabs, "Parameters" and "Settings". The Settings tab holds "Always Output Data" (off), "Execute Once" (off), "Retry On Fail" (off), "On Error", "Notes" and "Display Note in Flow?" (off), and ends with a line naming the node version.

G3. "On Error" offers three choices: "Stop Workflow" (the default; it halts and fails the run), "Continue" (the error goes on as an item in the regular output) and "Continue (using error output)" (the item goes to an extra error output). What each node actually does in these modes is recorded per node.

G4. "Always Output Data": when the node produces zero items, it outputs a single empty item {} instead. This was seen for Filter with nothing kept, Merge Keep Matches with no match, and Limit at 0. For Filter, the Discarded list still held the two non-matching items.

G5. "Execute Once": the node processes only the first input item. Sort given 3, 1, 2 output just {v: 3}. Edit Fields given 3, 1, 2 output just one item computed from 3.

G6. Every parameter has a "Fixed" / "Expression" toggle, so any value can come from a per-item expression.

G7. When a required parameter is empty, the run is blocked before the node executes: "The '<node name>' node has issues:" followed by a line naming the parameter, for example Parameter "Fields To Split Out" is required.

G8. Some nodes attach non-fatal hints to their run, shown in the output pane. Examples: "The field 'x' wasn't found in any input item" (Split Out, Aggregate) and "The field 'x' does not exist in any items" (Summarize).

G9. A node failure in the editor shows a toast titled "Problem in node '<name>'" with the message. The node turns red on the canvas, and its output pane shows the message plus an "Error details" section.

G10. On the canvas, a node with several output ports shows a label on each port. Item counts appear on connections after a run.

---

## 1. Filter

### A. Purpose
1.A.1. Lets through only the items that satisfy a set of conditions. Items that fail are set aside in a second, "discarded" list.

### B. Parameters
1.B.1. "Conditions" is a condition builder. Each row has a left value (placeholder "value1"), an operator dropdown (defaults to the text-type "is equal to") and a right value (placeholder "value2"). "Add condition" adds a row.

1.B.2. Once there are two or more rows, a single "AND" / "OR" selector appears between them. "AND" is the default, and one combinator applies to the whole list.

1.B.3. The operator dropdown has two levels: first a type group, then the operator. The type groups are "String", "Number", "Date & Time", "Boolean", "Array" and "Object". The operators in each group:
- "String": "exists", "does not exist", "is empty", "is not empty", "is equal to", "is not equal to", "contains", "does not contain", "starts with", "does not start with", "ends with", "does not end with", "matches regex", "does not match regex".
- "Number": "exists", "does not exist", "is empty", "is not empty", "is equal to", "is not equal to", "is greater than", "is less than", "is greater than or equal to", "is less than or equal to".
- "Date & Time": "exists", "does not exist", "is empty", "is not empty", "is equal to", "is not equal to", "is after", "is before", "is after or equal to", "is before or equal to".
- "Boolean": "exists", "does not exist", "is empty", "is not empty", "is true", "is false", "is equal to", "is not equal to".
- "Array": "exists", "does not exist", "is empty", "is not empty", "contains", "does not contain", "length equal to", "length not equal to", "length greater than", "length less than", "length greater than or equal to", "length less than or equal to".
- "Object": "exists", "does not exist", "is empty", "is not empty".

1.B.4. The operators "exists", "does not exist", "is empty", "is not empty", "is true" and "is false" take no right value. They are stored as single-value operators.

1.B.5. The right value's type depends on the operator. The array "contains" / "does not contain" operators take a value of any type. The array "length …" operators take a number. All other operators take the group's own type.

1.B.6. "Convert types where required" is a toggle, off by default. Its help text: when a value's type does not match the comparison, the app tries to cast it. Saving shows the toggle switches the stored validation mode from strict to loose.

1.B.7. "Options" → "Add option" offers a single option, "Ignore Case" (a toggle that is ON when added). Without the option, text comparisons are case-sensitive. With it ON, they are case-insensitive. Saving shows the stored conditions carry "case sensitive = not Ignore Case", so the absent option means case-sensitive.

### C. Input and output shape
1.C.1. The canvas draws one output port, labelled "Kept".

1.C.2. After a run, the output pane shows two tabs: "Kept (n items)" and "Discarded (n item(s))".

1.C.3. The run data holds two output lists: index 0 is Kept and index 1 is Discarded. A connection attached to index 1 in the workflow definition received the discarded items, even though the canvas draws no port for it.

1.C.4. Items pass through unchanged, with no fields added. Kept + Discarded = N, and the input order is preserved within each list.

1.C.5. With an empty condition list, every item is kept.

### D. Measured behaviour
In every row the left value is the item's field, read through an expression.

| # | Input values | Condition | Mode / options | Kept | Discarded / result |
|---|---|---|---|---|---|
| 1 | v: 3, 7, null, missing, 5.5, 5 | Number "is greater than" 5 | strict (default) | 7, 5.5 | 3, null, missing, 5 |
| 2 | v: 3, 7, '8', null, missing, true, 5 | same | strict | — | Error at '8' (wrong type; see E1) |
| 3 | v: 3, 7, '8', null, missing, true, 5, ' 9 ', '', false | same | convert types ON | 7, '8', ' 9 ' | 3, null, missing, true, 5, '', false |
| 4 | the above plus 'abc' | same | convert types ON | — | Error: conversion error for 'abc' (E2) |
| 5 | v: 5, 6 | Number "is equal to" right value '5' (text) | strict | — | Error: wrong type for the right value; the message says to convert "the second field" |
| 6 | v: 5, 6 | same | convert types ON | 5 | 6 |
| 7 | s: 'abc', 'ABC', 'Abc', ' abc', 'abcd', missing, null, '' | String "is equal to" 'abc' | no Ignore Case | 'abc' | all others |
| 8 | same | same | Ignore Case ON | 'abc', 'ABC', 'Abc' | ' abc' (leading space not trimmed), 'abcd', missing, null, '' |
| 9 | same | "contains" 'B' | case-sensitive | 'ABC' | the rest |
| 10 | same | "contains" 'B' | Ignore Case | the 5 non-empty texts containing b | missing, null, '' |
| 11 | same | "does not contain" 'b' | case-sensitive | 'ABC', missing, null, '' | 'abc', 'Abc', ' abc', 'abcd' |
| 12 | same | "is not equal to" 'abc' | Ignore Case | ' abc', 'abcd', missing, null, '' | 'abc', 'ABC', 'Abc' |
| 13 | same | "starts with" 'a' | case-sensitive | 'abc', 'abcd' | rest |
| 14 | same | "ends with" 'd' | — | 'abcd' | rest |
| 15 | same | "matches regex" ^a.c$ | case-sensitive | 'abc' | rest |
| 16 | same | "matches regex" ^a.c$ | Ignore Case | 'abc', 'ABC', 'Abc' | rest |
| 17 | same | "matches regex" written slash-delimited with an i flag (/^ABC$/i) | case-sensitive mode | 'abc', 'ABC', 'Abc' | rest (the slash form and its flags are honoured) |
| 18 | same | String "exists" | — | the 5 texts and '' | missing, null |
| 19 | same | String "does not exist" | — | missing, null | rest |
| 20 | same | String "is empty" | — | missing, null, '' | the 5 texts |
| 21 | same | String "is not empty" | — | the 5 texts | missing, null, '' |
| 22 | s: 5 (number), '5' | String "is equal to" '5' | strict | — | Error: wrong type ("'5' is a number but was expecting a string") |
| 23 | s: 5, '5', true, null | same | convert types ON | 5, '5' | true, null |
| 24 | s: {a: 1} | same | convert types ON | — | discarded (no error) |
| 25 | a.b: {a: {b: 'x'}}, {a: {b: 'y'}}, {a: null}, missing a, {a: {b: 'X'}} | left = nested path a.b, "is equal to" 'x' | case-sensitive | {a: {b: 'x'}} | others; a missing parent gives no error |
| 26 | a.b.c with {a: {}} and missing a | Number "is equal to" 1 | — | {a: {b: {c: 1}}} | the other two, no error |
| 27 | d: '2024-06-01', '2023-12-31', '2024-01-01T00:00:00Z', '2024-01-01T00:00:01Z' | "is after" '2024-01-01' | strict | '2024-06-01' | the other three |
| 28 | d: '2024-01-01T04:59:59Z', '2024-01-01T05:00:01Z' | "is after" '2024-01-01' | strict | 05:00:01Z | 04:59:59Z — a date-only value means midnight in the instance time zone (UTC−5 in January) |
| 29 | d: '2024-01-01' | "is equal to" '2024-01-01T05:00:00Z' | strict | kept | — (same conclusion for a date-only value on the item side) |
| 30 | d: '2024-01-01T00:00:00.000Z', '2024-01-01', '2024-01-01T00:00:00+01:00' | "is equal to" '2024-01-01T00:00:00Z' | strict | the .000Z item | the other two |
| 31 | d: '2023-12-31', '12/31/2023', '2023-12-31 10:00', '2024-01-01T00:00:00.000+02:00' | "is before" '2024-01-01T00:00:00Z' | strict | all four (all these text formats accepted) | — |
| 32 | d: '2024-01-01T00:00:00Z', '2023-12-31T23:59:59Z' | "is after or equal to" the first | strict | the equal one | the earlier one |
| 33 | d: '2024-06-01', 'not a date' | "is after" | strict | — | Error: wrong type, "'not a date' is a string but was expecting a dateTime" |
| 34 | same | same | convert types ON | — | Error: conversion error, cannot convert the string to a dateTime |
| 35 | d: 1717200000000 (epoch milliseconds) | "is after" | strict / ON | — | strict: wrong type (number); ON: conversion error — numbers are never accepted as dates |
| 36 | b: true, false, missing | Boolean "is true" | strict | true | false, missing |
| 37 | b: true, 'true' | "is true" | strict | — | Error: wrong type for 'true' |
| 38 | b: true, 'true', 'false', 1, 0, 'TRUE' | "is true" | convert types ON | true, 'true', 1, 'TRUE' | 'false', 0 |
| 39 | b: 'yes' | "is true" | convert types ON | 'yes' | — |
| 40 | b: true, false, missing, null | "is false" | strict | false, missing, null | true |
| 41 | b: true, false | Boolean "is equal to" false | — | false | true |
| 42 | (s, n): (a,1), (b,9), (a,9), (b,1) | s "is equal to" 'a' OR n "is greater than" 5 | OR | first three | (b,1) |
| 43 | same | same two conditions | AND | (a,9) | other three |
| 44 | v: 4, 5, 6 | "is greater than or equal to" 5 AND "is less than or equal to" 5 | AND | 5 | 4, 6 |
| 45 | arr: ['x','y'], [], ['X'], [1,2], ['xy'] | Array "contains" 'x' | case-sensitive | ['x','y'] | the rest (whole-element match, not substring) |
| 46 | arr: ['x','y'], ['X'] | Array "contains" 'x' | Ignore Case | both | — |
| 47 | arr: [1,2], ['1'] | Array "contains" 1 (number) | strict | [1,2] | ['1'] |
| 48 | arr: ['x'], missing | Array "contains" 'x' | — | ['x'] | missing (no error) |
| 49 | arr: 'x' (text) | Array "contains" 'x' | strict / ON | — | strict: wrong type (expected an array); ON: conversion error |
| 50 | arr: ['x','y'], [], ['X'], missing | Array "length greater than" 1 | — | ['x','y'] | the rest |
| 51 | arr: ['x','y'], [] | Array "length equal to" 0 | — | [] | ['x','y'] |
| 52 | arr: ['x','y'], [], missing | Array "is empty" | — | [], missing | ['x','y'] |
| 53 | arr: ['x','y'], [], missing, null | Array "is not empty" | — | ['x','y'] | [], missing, null |
| 54 | o: {}, {a: 1}, missing | Object "is empty" | — | {}, missing | {a: 1} |
| 55 | o: {}, {a: 1}, missing, null | Object "exists" | — | {}, {a: 1} | missing, null |
| 56 | v: 0, null, missing | Number "is empty" | — | null, missing | 0 |
| 57 | v: 0, null, missing | Number "exists" | — | 0 | null, missing |
| 58 | v: 5, missing | Number "is equal to" 5 | — | 5 | missing (no error) |
| 59 | v: 5, missing, null | Number "is not equal to" 5 | — | missing, null | 5 |
| 60 | any item | fixed left value 'hello' "is equal to" 'hello' | — | every item | — |
| 61 | none (empty input) | — | — | node not executed (G1) | — |

1.D.62. In the UI, with Ignore Case ON and a name condition equal to 'ann' over items named Ann, bob and Ann, the output pane showed "Kept (2 items)" and "Discarded (1 item)".

### E. Errors
1.E.1. Strict mode with a value of the wrong type stops the node: "Wrong type: '<value>' is a <type> but was expecting a <type> [condition i, item j]" (indices start at 0). The description suggests enabling "Convert types where required" or converting the field with a conversion function, and names "first" or "second" field.

1.E.2. With "Convert types where required" ON, a value that cannot be converted stops the node: "Conversion error: the string '<value>' can't be converted to a <type> [condition i, item j]", with the advice to change the comparison type.

1.E.3. With "On Error" = "Continue": input 7, 'x', 9, 1 against "is greater than" 5 gave Kept 7, 9 and Discarded 'x', 1. The failing item went silently into Discarded with no error field, and the run's status was success.

1.E.4. With "Continue (using error output)" on the same input: Kept 7, 9, and the second output carried nothing. Both the failing 'x' and the non-matching 1 vanished. This was checked with nodes attached to both output indexes; the one on index 1 never ran.

---

## 2. Sort

### A. Purpose
2.A.1. Reorders items by one or more field values, randomly, or by a custom comparison script.

### B. Parameters
2.B.1. "Type" offers "Simple" (the default), "Random" and "Code".

2.B.2. With "Simple": "Fields To Sort By" is an empty list with an "Add Field To Sort By" button. Each entry has "Field Name" (text, required; placeholder "e.g. id"; hint "Enter the field name as text") and "Order", either "Ascending" (default) or "Descending". Entries apply in list order, the first being the primary key.

2.B.3. With "Simple": "Options" → "Add Field" offers only "Disable Dot Notation" (toggle, off).

2.B.4. With "Code": a "Code" editor with a default script that compares two items on a placeholder field name. The script returns a negative number, a positive number or zero.

2.B.5. With "Random": no further parameters.

### C. Shape
2.C.1. One output. N items in give the same N items out, unchanged, only reordered.

### D. Measured behaviour
2.D.1. Numbers 3, 1, 2, 10 sort ascending to 1, 2, 3, 10 and descending to 10, 3, 2, 1 (numeric order).

2.D.2. Numeric texts '10', '9', '100', '1' sort ascending to '1', '10', '100', '9' (text order).

2.D.3. Mixed values 3, '10', '2', null, missing, true, 1, 'abc', false sort ascending to null, false, true, 1, 3, '10', '2', (missing), 'abc'. Descending gives exactly the reverse.

2.D.4. Letters: input b, B, a, A, é, e, Z, z sorts ascending to a, A, b, B, e, Z, z, é. Input B, b, A, a, z, Z gives A, a, B, b, z, Z. Letters compare without regard to case, case variants keep their input order, and the accented 'é' sorts after 'z'.

2.D.5. Ties keep input order in both directions. Items (k, id) = (1,a), (0,b), (1,c), (0,d), (1,e) give b, d, a, c, e ascending and a, c, e, b, d descending.

2.D.6. Two keys, k ascending then id descending: (0,d), (0,b), (1,c), (1,a).

2.D.7. A dot path such as a.b sorts by the nested value. With a.b = 2, 1 plus {a: {}} and {}, the ascending result was 1, 2, {a: {}}, {}.

2.D.8. Items missing the sort field do not sort consistently:
- [2, (missing), 1] stayed unchanged.
- [2, 1, (missing), 0, 3] became 0, 1, 2, (missing), 3.
- [(missing), 2, 1] became (missing), 1, 2.
- Descending on a.b with [1, {a: {}}, 2, {}] gave 2, {a: {}}, {}, 1.

2.D.9. Descending with a null: 2, null, 1 became 2, 1, null.

2.D.10. Booleans sort false before true. Negative and decimal numbers sort numerically: -10, -1.5, 0, 2.

2.D.11. Date-like texts sort as text: '2023-12-31', '2024-01-09', '2024-01-09T10:00:00Z', '2024-01-10', 'Jan 5 2024'.

2.D.12. Array and object values ([2], {a: 1}, [1], 1) left the order unchanged.

2.D.13. When an item has both a literal key named 'a.b' and a nested a.b, the literal key decides the order, whether dot notation is on or off.

2.D.14. "Random": two runs over 1–6 gave 6, 1, 4, 2, 5, 3 and 1, 3, 2, 4, 5, 6.

2.D.15. "Code": a script ordering by v descending gave 3, 2, 1. The default script, whose placeholder field does not exist, left the order unchanged with no error. A script returning text also left the order unchanged with no error.

2.D.16. In the UI, sorting name ascending then id descending over (1 Ann), (2 bob), (3 Ann) gave (3 Ann), (1 Ann), (2 bob).

### E. Errors
2.E.1. A sort field missing from every item: "Couldn't find the field '<name>' in the input data".

2.E.2. No sort fields configured: "No sorting specified. Please add a field to sort by".

2.E.3. A Code script that throws: "Sort code doesn't return. Please add a 'return' statement to your code". The message does not reflect the actual thrown error.

2.E.4. With "On Error" = "Continue" and a field missing everywhere, the error is recorded and the input items pass through unsorted.

---

## 3. Limit

### A. Purpose
3.A.1. Lets through at most a set number of items, taken from the start or from the end.

### B. Parameters
3.B.1. "Max Items" is a number, default 1, with a UI minimum of 1. Help: if there are more items than this, some are removed.

3.B.2. "Keep" offers "First Items" (default) and "Last Items".

### C. Shape
3.C.1. One output, items unchanged, original relative order.

### D. Measured behaviour
3.D.1. The default (Max Items 1, first) over 3 items gives the first item only.

3.D.2. Max Items 2 with first items gives items 1 and 2. With last items it gives items 2 and 3, in original order.

3.D.3. Max Items 5 over 2 items gives both, with either Keep setting.

3.D.4. Max Items 0, set in the stored configuration, gives 0 items. With "Always Output Data" it gives a single {}.

3.D.5. Max Items -1 gives 1 item (the first). Max Items 1.5 gives 1 item. An expression producing the text "2" gives 2 items.

3.D.6. With empty input the node is not executed.

### E. Errors
3.E.1. No error conditions were found.

---

## 4. Remove Duplicates

### A. Purpose
4.A.1. Removes items that repeat within the current input, or items whose key value was already seen in earlier runs, or clears that stored memory.

### B. Parameters
4.B.1. "Operation" offers:
- "Remove Items Repeated Within Current Input" (the default; help: removes duplicates from incoming items).
- "Remove Items Processed in Previous Executions" (help: deduplicates items already seen in previous executions).
- "Clear Deduplication History" (help: wipes the store of previous items).

4.B.2. Within-input mode, "Compare": "All Fields" (default), "All Fields Except" or "Selected Fields".

4.B.3. Within-input mode: "Fields To Exclude" (text, comma-separated, placeholder "e.g. email, name") is shown for All Fields Except. "Fields To Compare" (same format) is shown for Selected Fields.

4.B.4. Within-input mode, "Options" → "Add Field": "Disable Dot Notation" and "Remove Other Fields" (both toggles, off). Both are hidden when Compare is All Fields. Help for "Remove Other Fields": drop the fields that are not compared; when off, the values from the first duplicate are kept.

4.B.5. Previous-executions mode, "Keep Items Where":
- "Value Is New" (default; help: removes items whose value was already processed).
- "Value Is Higher than Any Previous Value" (help: for incremental values; removes items up to the stored value).
- "Value Is a Date Later than Any Previous Date" (help: same idea for dates).

4.B.6. Previous-executions mode, "Value to Dedupe On": text and required for Value Is New, a number for Higher, a date-time for Date. It is normally a per-item expression.

4.B.7. Previous-executions mode, "Options" → "Add Field": "Scope" ("Workflow" or "Node"; default Node; help: workflow-wide memory shared by all nodes, or memory only for this node) and "History Size" (number, default 10000, shown only for Value Is New).

4.B.8. Clear mode: "Mode" has the single choice "Clean Database" (help: none of the modes removes input items). Options: "Scope".

### C. Shape
4.C.1. The canvas draws one output port, labelled "Kept".

4.C.2. In within-input mode, the run data has a single output list. The first occurrence is kept, first occurrences stay in input order, and items are unchanged unless Remove Other Fields is on.

4.C.3. In previous-executions mode, the run data has two lists (Kept, Discarded), and the output pane shows the tabs "Kept (n items)" and "Discarded".

4.C.4. In clear mode, all input items pass through unchanged.

### D. Measured behaviour — within the current input
4.D.1. All Fields over {a:1,b:2}, {a:1,b:2}, {b:2,a:1}, {a:1,b:'2'}, {a:1} stops with: "'b' isn't always the same type". Description: the field's type varies between items; in item [2] it is a number and in item [3] a string.

4.D.2. Key order is ignored: {a:1,b:2} and {b:2,a:1} give 1 item.

4.D.3. Comparison is case-sensitive: 'a', 'A', 'a' give 'a', 'A'.

4.D.4. Three items with a null gave one item. null, 1, 1 gave null and 1, with no type error between null and number.

4.D.5. 1 and 1.0 count as equal. 1.5 is distinct.

4.D.6. Arrays compare in order: [1,2], [1,2], [2,1] give [1,2] and [2,1].

4.D.7. All Fields flattens nested objects and arrays into leaf paths, and every item must have the same leaf paths:
- {o:{x:1,y:2}} next to {o:{x:1}} stops with "'o.y' field is missing from some input items".
- tags ['a','b'] next to tags [] stops with "'tags.0' field is missing from some input items". This also appeared as a red node and a toast in the UI.
- [{}, {a:1}, {a:1}] stops with an error about 'a'. [{a:1}, {a:1,b:2}, {a:1}] stops with an error about 'b'.

4.D.8. Empty arrays and empty objects count as equal: {a:1,tags:[]} twice gives 1 item, and {a:1,o:{}}, {a:1,o:{}}, {a:2,o:{}} give 2.

4.D.9. The first duplicate is the one kept: {a:1,'first'}, {a:2,'x'}, {a:1,'second'}, {a:1,'third'} give 'first' and 'x'.

4.D.10. Selected Fields 'a, b' (comma plus space) compares on both fields.

4.D.11. Selected Fields with a nested path 'o.x' compares the nested value. With Remove Other Fields, the output is just {o:{x:1}}.

4.D.12. Selected Fields 'o' with object values {x:1,y:2} and {y:2,x:1} counts them as duplicates (deep comparison, key order ignored).

4.D.13. Selected Fields with "Disable Dot Notation" reads 'o.x' as a literal key.

4.D.14. Selected Fields 'a' with Remove Other Fields: {a:1,b:1}, {a:1,b:2}, {a:2,b:3} give {a:1}, {a:2}.

4.D.15. All Fields Except 'b' compares the remaining fields. With Remove Other Fields, the excluded field is dropped from the output while other fields stay ({a, c}).

4.D.16. Excluding a field that no item has has no effect and raises no error. Excluding the only field makes every item a duplicate, so 1 item is kept.

4.D.17. Excluding a parent name does not exclude its leaf paths. Excluding 'o' still compared o.x, so {a:1,o:{x:1}} and {a:1,o:{x:2}} both stayed. Excluding 'tags' still required tags.0 and failed. Excluding the leaf 'tags.0' or 'o.x' worked.

4.D.18. With empty input the node is not executed.

### D'. Measured behaviour — previous executions
These are repeated manual runs of one workflow, Node scope unless stated.

4.D.19. Value Is New over successive runs:
- Run 1, ids 1, 2: both kept.
- Run 2, ids 2, 3, 3: Kept 3, 3 (duplicates within the same run are not removed), Discarded 2.
- Run 3, ids 1, 4: Kept 4, Discarded 1.
- Run 4, ids '1', '4' as text: both discarded, so stored values are compared as text.

4.D.20. Output order is grouped by value. A first run over the values b, a, b, c, a output b, b, a, a, c. In the UI, Ann, bob, Ann came out as Ann, Ann, bob.

4.D.21. An item without the value field is still recorded. Kept the first time, it was discarded in a later run that again lacked the field.

4.D.22. History Size 2 with 3 items stops with "The number of items to be processed exceeds the maximum history size", advising to raise the size or send fewer items. With History Size 3, run 1 (3 items) succeeded, then run 2 with 1 new item failed with the same error, and so did run 3. No eviction of old values was observed.

4.D.23. Value Is Higher:
- Run 1, values 5, 3: both kept, output reordered ascending to 3, 5.
- Run 2, values 4, 5, 6, 2: Kept 6, Discarded 2, 4, 5 (ascending). Values at or below the stored maximum are removed.
- Run 3, values 7 and '8': both kept (numeric text accepted).
- Run 4, value 'abc': error "The value 'abc' is not a number. Please provide a number."

4.D.24. Value Is a Date Later:
- Run 1, '2024-01-05', '2024-01-03': both kept, input order unchanged.
- Run 2, '2024-01-04', '2024-01-05', '2024-01-06T00:00:00Z': Kept the 06 value, Discarded 04 and 05 (at or below the stored latest).
- 'garbage': error "The value 'garbage' is not a valid date. Please provide a valid date."
- A first run of three dates kept their input order.

4.D.25. Scope:
- Two nodes in Node scope keep separate memories; both kept ids 1, 2 on the first run.
- With Workflow scope, the second node in the same run discarded the values the first node had just stored.

4.D.26. Clear:
- Clearing from a different node in Node scope did not affect another node's Node-scoped memory.
- Clearing in Workflow scope wiped the Workflow-scoped memory, so ids 1, 2 were new again.
- Clearing in Node scope did not wipe a Workflow-scoped memory.

### E. Errors
4.E.1. The type and missing-field errors are in 4.D.1 and 4.D.7. Empty "Fields To Compare" stops with "No fields specified. Please add a field to compare on". The history-size, number and date errors are in 4.D.22–24.

4.E.2. With "On Error" = "Continue" in within-input mode, the whole output becomes a single item {error: "'a' isn't always the same type"}. The input items are not passed through.

---

## 5. Split Out

### A. Purpose
5.A.1. Turns a list held in a field into separate items, one per element.

### B. Parameters
5.B.1. "Fields To Split Out" is text and required (placeholder "Drag fields from the left or type their names"). Its hint says to use the binary keyword to split by binary data. Several comma-separated names are allowed.

5.B.2. "Include" offers "No Other Fields" (default), "All Other Fields" and "Selected Other Fields".

5.B.3. "Fields To Include" (text, comma-separated) is shown for Selected Other Fields.

5.B.4. "Options" → "Add Field": "Disable Dot Notation" (toggle), "Destination Field Name" (text, empty by default) and "Include Binary" (toggle, off).

### C. Shape
5.C.1. One output. The number of output items is the sum of the list lengths.

5.C.2. A primitive element goes into a field with the split field's name (or the destination name). An object element becomes the whole item when no other fields are included.

### D. Measured behaviour
5.D.1. No Other Fields over {id:1,arr:[1,2,3]}, {id:2,arr:[]}, {id:3,arr:['x']} gives {arr:1}, {arr:2}, {arr:3}, {arr:'x'}. The empty list yields nothing.

5.D.2. Object elements with No Other Fields: [{a:1}, {a:2,b:{c:3}}] gives those two objects as the items.

5.D.3. All Other Fields: {id:1,k:'z',arr:[1,2]} gives {id:1,k:'z',arr:1} and {id:1,k:'z',arr:2}. Object elements stay under the field name and are not merged: {id:1,k:'z',arr:{id:'inner',a:1}}.

5.D.4. Selected Other Fields 'id, m' gives {arr:1,id:1,m:'q'}, with the split field first. A selected field that does not exist is silently left out.

5.D.5. A nested path 'o.arr' with All Other Fields: {o:{arr:[1,2]},id:1} gives {o:{}, id:1, 'o.arr':1} and the same with 'o.arr':2. The output key is the literal dotted name, and the list is removed from inside o.

5.D.6. With "Disable Dot Notation", the literal key 'o.arr' is split, giving {'o.arr':7} and {'o.arr':8}.

5.D.7. Non-list values:
- The text 'x' gives one item {arr:'x'}.
- The number 5 with All Other Fields gives {id:1,arr:5}.
- null gives {arr:null}.
- The object {a:1,b:2} is split into its values, giving {arr:1} and {arr:2}.

5.D.8. When the field is missing in some items, those items produce nothing, with no error. When it is missing in all items, the output is 0 items plus the hint "The field 'arr' wasn't found in any input item".

5.D.9. Two fields 'a, b' of equal length are zipped by position: {a:1,b:'x'}, {a:2,b:'y'}. With unequal lengths (3 and 1) and All Other Fields, the result is 3 items: {id:9,a:1,b:'x'}, {id:9,a:2}, {id:9,a:3}. The shorter field is simply absent after it runs out.

5.D.10. Destination Field Name 'item' gives {id:1,item:1}. An object element goes under it ({item:{a:1}}) instead of being spread.

5.D.11. Nested lists [[1,2],[3]] give {"0":1,"1":2} and {"0":3}: inner lists become index-keyed objects.

5.D.12. Binary split: an item with binary files file1 and file2 split by the binary keyword gives two items, each with one file under its original key. The json is {} with No Other Fields, or the item's json with All Other Fields.

5.D.13. "Include Binary" when splitting a json list: every output item carries all binary files of its source item. Off (the default), the binaries are dropped.

5.D.14. An empty field name blocks the run (G7). Empty input means the node is not executed.

5.D.15. In the UI, tags ([a,b], [c], []) split with Selected Other Fields 'id, name' gave 3 output items.

### E. Errors
5.E.1. Only the required-field validation was observed. The continue-on-error modes were not exercised.

---

## 6. Aggregate

### A. Purpose
6.A.1. Gathers values from many items into lists inside one output item.

### B. Parameters
6.B.1. "Aggregate" offers "Individual Fields" (default) and "All Item Data (Into a Single List)".

6.B.2. Individual Fields: "Fields To Aggregate" starts with one empty entry and has an "Add Field To Aggregate" button. Each entry has "Input Field Name" (text; hint "Enter the field name as text") and "Rename Field" (toggle, off). When Rename Field is on, "Output Field Name" appears; left blank, it means the input name.

6.B.3. Individual Fields, "Options" → "Add Field": "Disable Dot Notation", "Merge Lists", "Include Binaries" and "Keep Missing And Null Values". "Keep Only Unique Binaries" appears once Include Binaries is on. Help for "Keep Only Unique Binaries": compare by mime type, file type, size and extension.

6.B.4. All Item Data: "Put Output in Field" (default 'data') and "Include", which offers "All Fields" (default), "Specified Fields" and "All Fields Except", with matching "Fields To Include" / "Fields To Exclude" text fields. Its only option is "Include Binaries".

### C. Shape
6.C.1. One input of N≥1 items gives exactly one output item.

### D. Measured behaviour
6.D.1. Individual 'a' over a: 1, 2, missing, null, 'x', 0, '', false gives {a:[1,2,'x',0,'',false]}. Missing and null are skipped, falsy values are kept, and mixed types are allowed.

6.D.2. With "Keep Missing And Null Values": [1,2,null,null,'x',0,'',false]. A missing value becomes null.

6.D.3. Two fields a and b each get their own list, and the lengths can differ: b:['x','y'].

6.D.4. Rename to 'list' gives {list:[1,2]}. Rename on with a blank output name keeps 'a'.

6.D.5. List values: a = [1,2], [3], 4 gives [[1,2],[3],4]. With "Merge Lists" it gives [1,2,3,4]. The merge is one level only, so [[5]] contributes [5], and an empty list contributes nothing.

6.D.6. Object values give a list of objects.

6.D.7. The dot path 'o.x' gives an output key equal to the last segment: {x:[1,2]}. Renamed, it uses the custom name. With Keep Missing, a null is added for {o:{}}.

6.D.8. "Disable Dot Notation" with a literal 'o.x' key gives {'o.x':[5,6]}.

6.D.9. A field absent everywhere gives {zz:[]} plus the hint "The field 'zz' wasn't found in any input item". With Keep Missing it gives [null,null].

6.D.10. An empty input field name gives {}, with no error.

6.D.11. All Item Data by default gives {data:[{a:1,b:2},{a:3},{}]}, with every item included, even empty ones.

6.D.12. A custom destination 'rows' gives {rows:[…]}. An empty destination gives a key that is the empty string.

6.D.13. Specified Fields 'a, c' keeps only those fields per item, and an item with none of them is dropped entirely, so 3 items gave 2 entries. All Fields Except 'b' turned {b:9} into nothing, which was dropped.

6.D.14. Include and exclude lists do not resolve dot paths. Specified 'o.x' gave data:[], and Except 'o.x' left the item unchanged.

6.D.15. Binaries with Include Binaries, 3 items each with binary 'data': one output item with binary keys data, data_1 and data_2.

6.D.16. Keep Only Unique Binaries, over files a.txt and b.txt (same text, text/plain, 4 B), c.txt (5 B) and d.csv (text/csv, 4 B), kept a.txt, c.txt and d.csv. Names are ignored. When the files carried no size field, all three files collapsed into one even though their contents differed, so content is not compared.

6.D.17. Without Include Binaries, binaries are dropped. All Item Data with Include Binaries gathers binaries the same way (data, data_1).

6.D.18. With empty input the node is not executed. When the upstream sends one {} (Always Output Data), the result is {a:[]} plus the hint.

### E. Errors
6.E.1. The same output field used twice stops with "The 'a' output field is used more than once", described as: make sure each output field name is unique.

---

## 7. Summarize

### A. Purpose
7.A.1. Computes statistics over items, optionally per group: count, unique count, sum, average, min, max, collected list and joined text.

### B. Parameters
7.B.1. "Fields to Summarize" starts with one entry ("Count") and has an "Add Field" button. Each entry has "Aggregation" — "Append", "Average", "Concatenate", "Count" (default), "Count Unique", "Max", "Min", "Sum" — and "Field" (text; placeholder "e.g. cost"). The help for Average and Sum says null, undefined and empty values are ignored; the help for the other kinds says much the same.

7.B.2. "Include Empty Values" (toggle, off) is shown for Append, Concatenate, Count and Count Unique.

7.B.3. "Separator", shown for Concatenate, offers "Comma" (default), "Comma and Space", "New Line", "None", "Space" and "Other". "Other" reveals "Custom Separator" (text).

7.B.4. "Fields to Split By" is text, comma-separated (placeholder "e.g. country, city"). Its label changes to "Fields to Group By" when the single-item output format is chosen.

7.B.5. "Options" → "Add option": "Disable Dot Notation", "Output Format" ("Each Split in a Separate Item" by default, or "All Splits in a Single Item") and "Ignore items without valid fields to group by" (toggle). An older version of the node has an extra "Continue if Field Not Found"; it did not change the result here.

### C. Shape and naming
7.C.1. Output fields are named count_<f>, unique_count_<f>, sum_<f>, average_<f>, min_<f>, max_<f>, appended_<f> and concatenated_<f>. Dots in a path become underscores (sum_o_v).

7.C.2. With grouping, there is one item per group, in order of first appearance. The group fields are copied into each item (dots become underscores, so o.g is written o_g). Without grouping there is one item.

### D. Measured behaviour
7.D.1. Ungrouped, v = 1, 2, 2, null, missing, '', -3.5:

| count_v | unique_count_v | sum_v | average_v | min_v | max_v | appended_v | concatenated_v |
|---|---|---|---|---|---|---|---|
| 4 | 3 | 1.5 | 0.375 | -3.5 | 2 | [1,2,2,-3.5] | "1,2,2,-3.5" |

7.D.2. With Include Empty Values: count 7, unique 6, appended [1,2,2,null,null,'',-3.5] (missing shown as null), concatenated "1,2,2,null,undefined,,-3.5". In the joined text, a missing value is written as the word "undefined" and null as "null". Sum, average, min and max are unaffected.

7.D.3. Texts 'b', 'a', 'b', 'B', null, missing, '': count 4, unique 3, min 'B', max 'b' (code order, uppercase first), appended ['b','a','b','B'], concatenated "b,a,b,B".

7.D.4. Sum and Average ignore anything that is not a number: '3' and 4 give sum 4 and average 4. 'abc' and true are ignored.

7.D.5. Min and Max:
- Numeric texts compare as text: '3', '10', '2' give min '10' and max '3'.
- Mixed 4 and '3' give min '3' and max 4.
- '3', 4, '10' give min '10' and max '10'.
- Booleans give min false and max true.
- Dates compare as text: '2024-1-5' and '2024-01-10' give min '2024-01-10'.

7.D.6. When every value is empty: count 0, unique 0, sum 0, average null, min null, max null, appended [], concatenated "".

7.D.7. Count Unique tells types apart: 1, '1', true, 'true', 1 give 4. Objects and lists are not compared by content: {a:1} twice plus [1] twice give 4.

7.D.8. The average of 1, 2, 2 is 1.6666666666666667, unrounded.

7.D.9. Grouped by 'g' over (g, v, s) = (x,1,a), (x,2,b), (x,3,a), (y,null,null), (y,missing,''), (X,10,c), (missing g,5,d), with count v, sum v and append s:

| g | count_v | sum_v | appended_s |
|---|---|---|---|
| x | 3 | 6 | [a,b,a] |
| y | 0 | 0 | [] |
| X | 1 | 10 | [c] |
| (no g field) | 1 | 5 | [d] |

Groups are case-sensitive ('x' ≠ 'X', 'a' ≠ 'A').

7.D.10. Grouping by 'g, h' gives one item per combination (5 items), and both fields are written.

7.D.11. "Ignore items without valid fields to group by" drops items whose group value is missing, null or ''. Over null, '', missing and 'a', only 'a' remained. With two group fields, an item lacking either one was dropped.

7.D.12. Without that option, null and '' form groups of their own (g:null, g:''), and a missing value gives an item without the group field.

7.D.13. Group values keep their types: 1, '1', true and null are separate groups. List and object group values are written as JSON text ("[1]", "{\"a\":1}").

7.D.14. The single-item format gives one item keyed by group value and nested per extra group field: {x:{count_v:3,sum_v:6}, y:{…}, X:{…}, undefined:{…}}. A missing group value becomes the key "undefined". With g, h the shape is {x:{1:{…},2:{…}}, …}. Numeric group keys come first in ascending order: groups 2, 1, 'b' gave keys 1, 2, b.

7.D.15. Separators: Comma "a,b,c" (empty values skipped), Comma and Space "a, b", New Line "a" newline "b", None "ab", Space "a b", Other ' | ' "a | b". Non-text values join as JSON: 1, {a:1}, [1,2], true give "1,{"a":1},[1,2],true".

7.D.16. A field absent everywhere gives sum_zz: 0 plus the hint "The field 'zz' does not exist in any items", with no error. A field absent from only some items: those items are ignored.

7.D.17. The same aggregation on the same field twice gives a single output field.

7.D.18. A group field named like an output field (grouping by 'sum_v' while summing v): the group value overwrote the sum, giving {sum_v:'g1'}. Counting the group field itself gave {count_g:2, g:'b'}.

7.D.19. Dot paths: summing 'o.v' grouped by 'o.g' gives {sum_o_v:3, o_g:'a'}. With "Disable Dot Notation" and a literal 'o.v', the sum is over the literal key.

7.D.20. With empty input the node is not executed. When the upstream sends one {}, the result is count_a 0 and sum_a 0 plus the hint.

7.D.21. In the UI, summing amount and concatenating name with ' / ', grouped by city, gave Oslo: 17, "Ann / Ann" and Rome: 5, "bob".

### E. Errors
7.E.1. An empty Field, or default parameters, stops with "You need to add at least one aggregation to 'Fields to Summarize' with non empty 'Field'".

---

## 8. Compare Datasets

### A. Purpose
8.A.1. Pairs items from two inputs by key fields and sorts them into four outputs: only in A, same, different, and only in B.

### B. Parameters
8.B.1. A notice at the top explains that items are paired when the match fields agree, and that paired items are then compared on their remaining fields.

8.B.2. "Fields to Match" is a list of pairs, "Input A Field" and "Input B Field" (text). One empty pair is present by default, with an "Add Fields to Match" button.

8.B.3. "When There Are Differences" offers "Use Input A Version", "Use Input B Version", "Use a Mix of Versions" and "Include Both Versions". The default is "Include Both Versions" in this version; older versions default to the B version.

8.B.4. With "Use a Mix of Versions": "Prefer" ("Input A Version" by default, or "Input B Version") and "For Everything Except" (comma-separated field names).

8.B.5. "Fuzzy Compare" is a toggle, off by default. Help: tolerate small type differences such as 3 and '3'.

8.B.6. "Options" → "Add option": "Fields to Skip Comparing" (comma list), "Disable Dot Notation" and "Multiple Matches" ("Include First Match Only" by default, or "Include All Matches").

### C. Shape
8.C.1. The node has two inputs, labelled "Input A" and "Input B", and four outputs: "In A only", "Same", "Different" and "In B only". The output pane tabs read "In A only Branch", "Same Branch", "Different Branch" and "In B only Branch", each with a count.

8.C.2. The A-only and B-only outputs carry items unchanged. A Same item is the A item.

8.C.3. A Different item under "Include Both Versions" has the form {keys:{<A key field>:value}, same:{fields equal on both sides}, different:{field:{inputA:value, inputB:value}}}. A field present on one side only shows null for the other side.

8.C.4. Different under "Use Input A/B Version" is the chosen item, unchanged. Under "Use a Mix of Versions" it takes the preferred side's values, except the listed fields, which come from the other side.

### D. Measured behaviour
In this section A = (id,n,q) (1,a,1), (2,b,2), (3,c,3) and B = (2,b,2), (3,C,30), (4,d,4).

8.D.1. Default: In A only [1], Same [2], Different [{keys:{id:3}, same:{id:3}, different:{n:{inputA:'c',inputB:'C'}, q:{inputA:3,inputB:30}}}], In B only [4].

8.D.2. Different output under each choice:
- A version: (3,c,3).
- B version: (3,C,30).
- Mix, prefer A, except n: (3,C,3).
- Mix, prefer B, except n: (3,c,30).

8.D.3. Different key names, id in A and key in B: the items are paired. Different holds id {inputA:1, inputB:null}, key {inputA:null, inputB:1} and v. The keys object uses the A field name, and same is {}.

8.D.4. An extra field only in B makes the pair Different, with x {inputA:null, inputB:1}.

8.D.5. A key of 1 against '1' is not paired, so the items land in A only and B only. With Fuzzy Compare they pair as Same.

8.D.6. A value of 3 against '3' gives Different. With Fuzzy Compare it is Same, and true against 'true' is also Same.

8.D.7. Skipping 'upd' gives Same despite differing upd values, and the A item is output.

8.D.8. Text is compared with case: keys 'abc' and 'ABC' are not paired, and values 'abc' and 'ABC' make the pair Different.

8.D.9. Nested differences are reported at the top-level field. For o {x:1,…} against {x:2,…}, different.o holds both whole objects. Lists [1,2] against [2,1] are Different (order matters).

8.D.10. Duplicate keys, with A = a1, a2 (id 1) and B = b1, a1 (id 1):
- First match only (the default): Different [a1/b1, a2/b1]; B's second item, a1, went to In B only even though its key matches.
- All matches: Same [a1]; Different [a1/b1, a2/b1, a2/a1]; In B only empty.

8.D.11. A dotted key 'o.id' pairs, but keys is reported as {} while same contains o:{id:1}. With Disable Dot Notation and literal 'o.id' keys, keys is {'o.id':1}.

8.D.12. Items missing the key go to A only or B only; two missing keys do not pair with each other. Two null keys do pair, as Same.

8.D.13. A key field absent everywhere leaves every item unpaired.

8.D.14. Two key pairs (id, t) pair on both fields.

8.D.15. An empty A sends all of B to B only. An empty B sends all of A to A only. The node runs with one empty input.

8.D.16. In the UI, with A = Ann/bob/Ann and B = bob (Paris)/Ann (Oslo, no tags)/Cy: In A only 1, Same 0, Different 2, In B only 1. The Different item for id 2 showed tags {inputA:['c'], inputB:null} and city Rome/Paris.

### E. Errors
8.E.1. With no key configured: 'You need to define at least one pair of fields in "Fields to Match" to match on'.

---

## 9. Merge (data-combining modes)

### A. Purpose
9.A.1. Combines items arriving on two or more inputs: by concatenation, key-based joins, position-based pairing, a cross join, or SQL. It can also pass on one chosen input.

### B. Parameters
9.B.1. "Mode" offers:
- "Append" (the default; help: output each input's items one after the other).
- "Combine" (help: merge matching items together).
- "SQL Query" (help: write a query to do the merge).
- "Choose Branch" (help: output data from a specific branch without modifying it).

9.B.2. "Number of Inputs" (2–10, default 2) is shown for Append, SQL Query, Combine by Position and Choose Branch. Help: the node waits for all connected inputs. The canvas labels the inputs "Input 1", "Input 2" and so on, and the subtitle shows the mode.

9.B.3. With Combine, "Combine By" offers "Matching Fields" (default; help: combine items with the same field values), "Position" (help: combine items based on their order) and "All Possible Combinations" (help: every pairing of every two items, a cross join).

9.B.4. Matching Fields: "Fields To Match Have Different Names" (toggle, off). Off, "Fields to Match" is a single text field (comma-separated; placeholder "e.g. id, name"; hint "Drag or type the input field name"). On, it becomes a list of pairs, "Input 1 Field" and "Input 2 Field".

9.B.5. Matching Fields, "Output Type":
- "Keep Matches" (default; help: matching items merged together, an inner join).
- "Keep Non-Matches" (help: items that don't match).
- "Keep Everything" (help: matches merged, plus non-matching items, an outer join).
- "Enrich Input 1" (help: all of input 1 with input 2's data added, a left join).
- "Enrich Input 2" (help: the right join).

9.B.6. "Output Data From": with Keep Matches, "Both Inputs Merged Together" (default), "Input 1" or "Input 2"; with Keep Non-Matches, "Both Inputs Appended Together" (default), "Input 1" or "Input 2".

9.B.7. Matching Fields, "Options" → "Add option": "Clash Handling", "Disable Dot Notation", "Fuzzy Compare" and "Multiple Matches" ("Include All Matches" by default, or "Include First Match Only"). Clash Handling and Multiple Matches appear only where a merged output is produced.

9.B.8. "Clash Handling" contains three fields:
- "When Field Values Clash": its choices are loaded dynamically. With 2 inputs they are "Always Add Input Number to Field Names", "Prefer Input 1 Version" and "Prefer Input 2 Version". With 3 inputs (Position) they are "Always Add Input Number to Field Names" and "Use Earliest Version". The pre-filled value when the option is added is "Prefer Input 2 Version" for Matching Fields and "Always Add Input Number to Field Names" for Position.
- "Merging Nested Fields": "Deep Merge" (default) or "Shallow Merge".
- "Minimize Empty Fields": toggle, off by default.

The last two are hidden when the suffix choice is selected.

9.B.9. Position options: "Clash Handling" and "Include Any Unpaired Items" (toggle, off). All Possible Combinations options: "Clash Handling" and "Fuzzy Compare".

9.B.10. SQL Query: "Query" is a text editor whose default query selects everything from input1 left-joined to input2 on input1.name = input2.id. A hint says most of the SQL-99 language is supported, and a notice recommends query parameters. Options: "Empty Query Result" ("Success", or "Empty Result" by default) and "Query Parameters" (comma-separated values for ? placeholders).

9.B.11. Choose Branch: "Output Type" has the single choice "Wait for All Inputs to Arrive". "Output" is "Data of Specified Input" (default) or "A Single, Empty Item". "Use Data of Input" offers 1 to N, default 1.

### C. Shape
9.C.1. Merge has a single output. Merged items in the run data carry an empty binary section. Unmerged items pass through unchanged.

### D. Measured behaviour
In this section A = (id, a, shared) (1,x,'A1'), (2,y,'A2'), (3,z,'A3') and B = (id, b, shared) (2,p,'B2'), (3,q,'B3a'), (3,r,'B3b'), (4,s,'B4').

9.D.1. Append: A's items, then B's, unchanged (3 + 1 = 4). With 3 inputs: input 1, input 2, input 3 in turn. With an empty second input: just input 1's items.

9.D.2. Keep Matches, both merged, all matches: 3 items — {id:2,a:'y',shared:'B2',b:'p'}, then the id 3 A item merged once with B3a and once with B3b. Each A item repeats once per B match, and on a clash input 2's value wins. With first match only: 2 items.

9.D.3. Keep Matches from Input 1: A's items 2 and 3, each once and unchanged. From Input 2: B's 2, 3a and 3b.

9.D.4. Keep Non-Matches, both: A's 1 and B's 4, each with an added field _source of 'input1' or 'input2'. From Input 1: A's 1 with no marker. From Input 2: B's 4. With an empty second input, both mode gave A's item with no marker.

9.D.5. Keep Everything: the 3 merged matches first, then the unmatched A item (1), then the unmatched B item (4). Unmatched items carry no marker.

9.D.6. Enrich Input 1: the merged matches (3, input 2 wins clashes), then the unmatched A item 1. With first match only: 3 items.

9.D.7. Enrich Input 2: B's items enriched from A, then the unmatched B item 4. With no clash option set, the shared field took input 1's value ('A2'), and fields were ordered B's first, then A's extras.

9.D.8. Clash choices on Keep Matches:
- "Prefer Input 1 Version": shared from A, giving {id:2,b:'p',shared:'A2',a:'y'}.
- "Always Add Input Number to Field Names": every field gets a suffix, including the key and non-clashing fields: id_1, a_1, shared_1, id_2, b_2, shared_2.

9.D.9. Nested clash, o {x:1,y:1} against o {y:2,z:2} with input 2 preferred: Deep Merge gives {x:1,y:2,z:2}; Shallow Merge gives {y:2,z:2}.

9.D.10. Minimize Empty Fields, with A = v:'keep', w:null, u:'' and B = v:'', w:'B', u:'B': off gives v:'', w:'B', u:'B'; on gives v:'keep', w:'B', u:'B'. An empty preferred value is replaced by the other side's non-empty one.

9.D.11. Key matching:
- 1 against '1' does not match. With Fuzzy Compare it matches, and the output id is input 2's '1'.
- Text keys are case-sensitive.
- Object key values match by content.
- null keys match each other.
- Items without the key are non-matching; in Keep Everything they appear unmerged.

9.D.12. Different names (id against key) give a merged item containing both the id and key fields. Two keys 'id, t' match on both. A nested key 'o.id' matches.

9.D.13. Keep Matches with an empty second input gives no output at all: the output list is absent, not merely empty. Enrich Input 1 with an empty second input gives input 1 unchanged. Keep Everything with an empty first input gives B's items.

9.D.14. Position, with A of 3 items and B of 2: 2 merged items (1+1, 2+2), and the extra A item is dropped. With "Include Any Unpaired Items", {a:3} is also output.

9.D.15. Position with an empty second input gives 0 items plus the hint 'Consider enabling "Include Any Unpaired Items" in options or check your inputs'. With the option on, it gives input 1's items.

9.D.16. A Position clash with no Clash Handling option added: input 2's value wins.

9.D.17. Three inputs by Position:
- Distinct fields with unpaired items included: {a,b,c}, {a,c}, {a}. Without that option, only the full triple.
- In suffix mode: k_1, k_2, k_3 plus an extra unsuffixed k equal to input 3's value.
- With "Use Earliest Version": input 1's value.
- With no option and the same field in all three: the last input's value.

9.D.18. All Possible Combinations: 2 × 3 gives 6 items, ordered by input 1 item then input 2 item. On a clash, input 2's value wins. With an empty second input: 0 items.

9.D.19. SQL default query, with A (name n1, n2) and B (id n1): {name:'n1',v:1,id:'n1',w:9} and {name:'n2',v:2}. Unmatched right-hand columns are omitted, not set to null.

9.D.20. SQL GROUP BY with SUM aliased 'tot' and a LEFT JOIN gave {g:'a',tot:3,label:'Alpha'} and {g:'b',tot:5}. The alias 'total' gave a parse error (a reserved word). UNION ALL works.

9.D.21. A query with no result: "Empty Result" gives 0 items, "Success" gives {success:true}. A ? placeholder with the parameter '2' filtered as expected.

9.D.22. Choose Branch: by default, input 1's items unchanged. "Use Data of Input" 2 gives input 2's items. "A Single, Empty Item" gives one {}.

9.D.23. In the UI, with 3 items on each input: Append 6, Matching Fields 2, Position 3, All Combinations 9, SQL 3, Choose Branch 3.

### E. Errors
9.E.1. No key: 'You need to define at least one pair of fields in "Fields to Match" to match on'.

9.E.2. Invalid SQL: "Issue while executing query", with the parser's line, a caret and the expected tokens.

9.E.3. The Position hint is in 9.D.15.

---

## 10. Rename Keys

### A. Purpose
10.A.1. Renames item fields, either by explicit old-name → new-name pairs or by a regular expression applied to key names.

### B. Parameters
10.B.1. "Keys" is an empty list with an "Add new key" button, and its entries can be reordered. Each entry has "Current Key Name" (placeholder 'currentKey') and "New Key Name" (placeholder 'newKey'). Help: both accept dot-notation paths.

10.B.2. "Additional Options" → "Add option" → "Regex" is a list with an "Add new regular expression" button. Each entry shows a warning that regex renames can also hit keys already renamed by the plain list. Its fields:
- "Regular Expression": placeholder "e.g. [N-n]ame", plus a hint linking to an external regex tester.
- "Replace With": capture groups $1, $2… may be used.
- "Options": "Case Insensitive" (toggle, off) and "Max Depth" (number, default -1; hint: -1 for unlimited, 0 for top level only).

### C. Shape
10.C.1. One output. N items in give N out. A renamed key moves to the end of its object.

### D. Measured behaviour
10.D.1. Renaming a to x: {a:1,b:2} becomes {b:2,x:1}. Items without a are unchanged.

10.D.2. Renaming onto an existing key overwrites it: a to b on {a:1,b:2} gives {b:1}.

10.D.3. A missing current key changes nothing and raises no error.

10.D.4. Paths:
- 'o.a' to 'o.z' renames inside o.
- 'o.a' to 'top' moves the value to the top level.
- 'a' to 'n.m' creates {n:{m:1}}.
- 'arr[0].a' to 'arr[0].b' works.

10.D.5. Pairs read from the original item and do not chain: a to b, then b to c, on {a:1} gives {b:1}. Swapping a to b and b to a on {a:1,b:2} gives {a:2}, and b is lost.

10.D.6. Renaming to the same name, or with an empty new name or an empty current name, changes nothing.

10.D.7. Current-name matching is case-sensitive: 'name' does not match 'Name'.

10.D.8. The regex '^f_(.*)' replaced by 'g_$1', applied to {f_a, F_b, c, o:{f_x, inner:{f_y}}, arr:[{f_z}]}, renamed f_a, o.f_x, o.inner.f_y and arr[0].f_z. Depth is unlimited and reaches into lists of objects. F_b was untouched, because matching is case-sensitive by default.

10.D.9. "Case Insensitive" also renames F_b, to g_b.

10.D.10. "Max Depth" 0 renames only the top level. Max Depth 1 also renames one level down (o.f_x) but not o.inner.f_y or arr[0].f_z.

10.D.11. Only the first match inside a key name is replaced: 'ab' replaced by 'Q' turns 'abcab' into 'Qcab'.

10.D.12. Several regex entries apply in order, each to the previous result: 'a' to 'b' then 'b' to 'c' turns 'abc' into 'cbc'.

10.D.13. The plain list applies before the regex list: a to f_a, then the regex '^f_' to 'h_', gives h_a and h_b.

10.D.14. When two keys map to the same new name, the later one wins: x1:1 and x2:2 become same:2.

10.D.15. With no configuration, items are unchanged. With empty input the node is not executed.

10.D.16. In the UI: name renamed to fullName, plus the regex '^ci(.*)' to 'town$1' (case-insensitive, depth 0), renamed city to town on all 3 items.

### E. Errors
10.E.1. An invalid regex such as '(' fails with "Invalid regular expression: /(/: Unterminated group".

---

## 11. Edit Fields (Set)

### A. Purpose
11.A.1. Adds, overwrites or reshapes item fields, either field by field with declared types or from a JSON template.

### B. Parameters
11.B.1. "Mode" is "Manual Mapping" (default; help: edit item fields one by one) or "JSON" (help: customize item output with JSON). The canvas subtitle shows the mode.

11.B.2. Manual Mapping, "Fields to Set": a drop area "Drag input fields here" with an "Add Field" link. Each field row has a name input (placeholder 'name'), a type selector and a value input (placeholder 'value'). The types are "String" (default), "Number", "Boolean", "Array", "Object" and "Binary Data". For Boolean, the value is a selector with true and false.

11.B.3. JSON mode: a "JSON" editor holding a default template with two example fields.

11.B.4. "Include Other Input Fields" is a toggle, off by default. When on, "Input Fields to Include" appears: "All" (default; help: also include all unchanged input fields), "Selected" (help: only the listed fields) or "All Except" (help: exclude the listed fields). Each comes with "Fields to Include" / "Fields to Exclude" (comma-separated text).

11.B.5. "Options" → "Add option": "Ignore Type Conversion Errors" (Manual Mapping only) and "Support Dot Notation" (ON when added). "Strip Binary Data" (ON when added) appears only when Include Other Input Fields is on.

11.B.6. "Duplicate Item" and "Duplicate Item Count" exist in the stored configuration, with a notice that duplication is ignored in automatic runs. They did not appear in the Parameters tab.

### C. Shape
11.C.1. One output. Each input item gives one output item, unless duplication is used.

11.C.2. By default the output holds only the fields that were set; input fields are dropped. With Include on, input fields come first in their original order, then new fields in list order. An overwritten field keeps its position.

### D. Measured behaviour
11.D.1. Literal values by declared type: String 'hello'; Number '12.5' becomes 12.5; Boolean 'true' becomes true; Array '[1,"two",3]' becomes a list; Object '{"a":1,"b":[2]}' becomes an object.

11.D.2. Expression results are converted to the declared type:
- The number 5 set as String becomes "5".
- An object set as String becomes JSON text '{"p":1,"q":2}'.
- Number from true becomes 1.
- Boolean from the number 1 becomes true, and from 0 becomes false; from 2 it is an error.
- Array from a number is an error.

11.D.3. Number from text:
- ' 7 ' gives 7, '1e3' gives 1000, '0x10' gives 16 and '-0.5' gives -0.5.
- '' gives 0.
- '1,5' and 'abc' are errors.

11.D.4. Boolean from text: 'false' gives false, '1' true, '0' false, 'TRUE' true, 'False' false. 'yes', 'maybe' and '' are errors.

11.D.5. Array from text: '1,2,3' is an error. The single-quoted "['a','b']" is accepted and gives ['a','b'].

11.D.6. Object parsing is relaxed: '{a:1}', with an unquoted key, is accepted as {a:1}. '[1,2]' is an error ("expects a object").

11.D.7. With "Ignore Type Conversion Errors", a failing value is kept as the original text ('abc', 'maybe', '1,2,3') and no error is raised.

11.D.8. Referencing a missing field, or a failing nested access such as a property of a number, gives null for both String and Number types. An expression syntax error stops with "invalid syntax".

11.D.9. Dot notation, on by default:
- 'a.b' creates {a:{b:'v'}}.
- 'o.q' with include All merges into the existing object; the other subkeys stay (o:{p:1,q:9}).
- 'o.p' set on an item where o is 5 replaces it with {p:1}.
- 'list[1].name' creates a list with null at index 0.

When dot notation is off, 'a.b' is a literal key.

11.D.10. Setting an Object-typed field 'o' replaces the whole existing object.

11.D.11. Include options:
- All: input fields plus set fields; set values override (x:6) and new fields are appended.
- Selected 'keep, o': only those plus the set fields. A selected field that is missing is ignored.
- Selected 'o.p': the leaf comes out at the top level as p ({p:1, new:'n'}).
- All Except 'drop,o': those removed.
- Excluding a field that is also being set: the set value is still output.

11.D.12. An empty field name produces a key that is the empty string. No assignments gives {} per item, or the unchanged item when Include is on. The same name twice: the last one wins.

11.D.13. "Binary Data" type: the value names an existing binary property, which is copied under the new name, so both exist. An unknown name stops with "The item has no binary field 'nope' [item 0]" and a hint to check the field name.

11.D.14. Binary passthrough:
- Include off: binary removed.
- Include on with Strip Binary Data explicitly on: binary removed.
- Include on with the option not added, or explicitly off: binary kept.

11.D.15. JSON mode:
- A literal JSON object is output as-is.
- An expression producing an object is evaluated.
- A template with embedded expressions is evaluated, giving {double:10, src:'k'}.
- With Include Other Input Fields on, the output is the input fields plus the JSON fields; the JSON overrides x.
- A trailing comma, '{"a": 1,}', is accepted.
- Dotted keys are expanded ({"a.b":1} becomes {a:{b:1}}).

11.D.16. Duplicate Item with count 2 gave 3 identical items in a manual run.

11.D.17. Several items are evaluated one per item. With empty input the node is not executed. With Execute Once, only the first item is processed.

11.D.18. In the UI: label "<name> from <city>" (String), double = amount×2 (Number), 'meta.ok' = true (Boolean, which became nested meta:{ok:true}), Include All Except 'tags'. Output for item 1: id, name, city, amount, label 'Ann from Oslo', double 20, meta {ok:true}.

### E. Errors
11.E.1. A conversion failure: "'<field>' expects a <type> but we got '<value>' [item i]". The hint says to change the field's type or enable "Ignore Type Conversion Errors". The article is not adjusted: "expects a array", "expects a object".

11.E.2. JSON mode with a JSON list blocks the run: the node has issues, "'jsonOutput' expects a object but we got '[1,2]'".

11.E.3. With "Continue", a failing item is replaced in the regular output by {error: "'n' expects a number but we got 'a' [item 0]"}, and the other items are processed normally.

11.E.4. With "Continue (using error output)", the failing item goes to a second output with its original fields plus an error field ({x:'a', error:'…'}), and the good items go to the main output.

---

## 12. JWT

### A. Purpose
12.A.1. Signs, decodes or verifies JSON Web Tokens with a key stored as a credential.

### B. Parameters
12.B.1. "Credential" is required, of credential type "JWT Auth". Its form has:
- "Key Type": "Passphrase" (default) or "PEM Key".
- "Secret" (masked) for Passphrase, or "Private Key" and "Public Key" (masked) for PEM Key.
- "Algorithm": HS256 (default), HS384, HS512, RS256, RS384, RS512, ES256, ES384, ES512, PS256, PS384, PS512 and none.

12.B.2. "Operation" offers "Decode", "Sign" (default) and "Verify". The canvas subtitle reads "Sign a JWT", "Decode a JWT" or "Verify a JWT".

12.B.3. Sign: "Use JSON to Build Payload" is a toggle, off by default.

12.B.4. Sign with the toggle off: "Payload Claims" → "Add Claim" offers:
- "Audience": text.
- "Expires In": number, default 3600, in seconds.
- "Issuer": text.
- "JWT ID": text.
- "Not Before": number, default 0.
- "Subject": text.

12.B.5. Sign with the toggle on: a "Payload Claims (JSON)" editor with an example object.

12.B.6. Sign: "Header Claims (JSON)", default {}. Help: these are merged with the generated header and take precedence.

12.B.7. Sign options: "Key ID" and "Override Algorithm" (ES256…RS512, the 12 values without none; default HS256).

12.B.8. Decode and Verify: "Token" is required, in a masked text field.

12.B.9. Decode option: "Return Additional Info". Verify options: "Return Additional Info", "Ignore Expiration", "Ignore Not Before Claim", "Clock Tolerance" (seconds, default 0) and "Override Algorithm".

### C. Shape
12.C.1. Sign outputs one item per input, {token:'<three-part token>'}. Input fields are not kept.

12.C.2. Decode and Verify output {payload:{…}}, or {header, payload, signature} with Return Additional Info. Input fields are not kept.

### D. Measured behaviour
These tests used a dummy passphrase credential with HS256.

12.D.1. Sign with no claims: header {alg:'HS256', typ:'JWT'}, payload {iat:<seconds>} only.

12.D.2. Claims added through "Payload Claims" land in the payload under exactly the keys audience, expiresIn, issuer, jwtid, notBefore and subject, plus iat. The registered short claim names are not used. The UI stores claims in the same structure (checked by adding a claim in the UI and saving).

12.D.3. Consequences of 12.D.2: "Expires In" 120 did not produce an expiry, and a token signed with "Not Before" 3600 verified immediately. "Expires In" 0 just appears as expiresIn:0.

12.D.4. A JSON payload, whether a literal or an expression, gives exactly those claims plus iat, with nested objects preserved.

12.D.5. Header Claims {"x5t":"thumb","typ":"custom"} with Key ID 'key-1' gave the header {alg:'HS256', typ:'custom', kid:'key-1', x5t:'thumb'}. The header JSON overrides typ.

12.D.6. Override Algorithm HS512 gives alg HS512 in the header and a longer signature. Verifying that token without an override (credential HS256) fails with "invalid algorithm". With the override set to HS512 it returns the payload.

12.D.7. Several input items get one token each.

12.D.8. Verify with the same credential returns {payload}. With Return Additional Info it returns {header, payload, signature}.

12.D.9. Verify with a credential holding a different secret stops with "The JWT token can't be verified". Description: make sure the token is correctly encoded and matches the selected credentials.

12.D.10. Decode with a different credential succeeds, because decode does not check the signature.

12.D.11. Expiry, using a JSON payload: exp 1 hour in the past gives "jwt expired". "Ignore Expiration" returns the payload. exp 30 s in the past with "Clock Tolerance" 3600 is accepted.

12.D.12. nbf 1 hour in the future gives "jwt not active". "Ignore Not Before Claim" returns the payload.

12.D.13. A malformed token ('not-a-jwt') or an empty one, for decode or verify, stops the node with "Invalid input for 'Token' [item 0]", described as not a valid JWT token.

12.D.14. With no credential: "Node does not have any credentials set".

### E. Errors
12.E.1. The errors are listed in 12.D.6, 12.D.9 and 12.D.11–14.

12.E.2. With "Continue", a failed verify outputs the item {error:"The JWT token can't be verified"}.

---

## 13. TOTP

### A. Purpose
13.A.1. Outputs the current time-based one-time code for a stored secret.

### B. Parameters
13.B.1. "Credential" is required, of type "TOTP API". Its form has "Secret" (required, masked; the placeholder shows a base32 example) and "Label" (optional; placeholder of the form issuer:username).

13.B.2. "Operation" has the single choice "Generate Secret". Despite the name, it outputs a code from the stored secret. The canvas subtitle shows the operation's internal value.

13.B.3. "Options" → "Add option":
- "Algorithm": SHA1 (default), SHA224, SHA256, SHA3-224, SHA3-256, SHA3-384, SHA3-512, SHA384 or SHA512.
- "Digits": default 6.
- "Period": in seconds, default 30.

### C. Shape
13.C.1. One output item per input item: {token:'<digits as text>', secondsRemaining:<integer>}. Input fields are dropped.

### D. Measured behaviour
13.D.1. Every code matched an independent RFC 6238 computation (HMAC over the base32-decoded secret, time step = Period, truncated to Digits). This held for default SHA1/6/30, SHA256, SHA512, SHA3-256, 8 digits, 10 digits, a 60 s period and a 1 s period.

13.D.2. The token is text, and leading zeros are kept ('034368', '0828166706').

13.D.3. secondsRemaining is the time left in the current period. Values from 0 to 42 were observed across the 30 s and 60 s periods.

13.D.4. All items in one run get the same code (3 items, 3 identical tokens).

13.D.5. The Label has no effect on the code.

13.D.6. Digits 0 and Period 0 behave like the defaults (6 digits, 30 s).

### E. Errors
13.E.1. A secret with characters outside base32 stops with "Invalid character found: " followed by the offending character.

13.E.2. With no credential: "Node does not have any credentials set".

---

## 14. Compression

### A. Purpose
14.A.1. Packs binary files into a zip, tar, tar-gzip or gzip archive, or unpacks such archives into separate binary files.

### B. Parameters
14.B.1. "Operation" is "Compress" (help: into a zip or gzip archive) or "Decompress" (the default). The canvas subtitle shows the operation.

14.B.2. Compress: "Input Binary Field(s)" is required, default 'data', and takes a comma-separated list. "Output Format" offers "Gzip", "Tar", "Tar (Gzip)" and "Zip" (default Zip).

14.B.3. Compress: "File Name" is required for Zip, Tar and Tar (Gzip) (placeholder "e.g. data.zip") and optional for Gzip. "Put Output File in Field" defaults to 'data'.

14.B.4. Decompress: "Input Binary Field(s)" (default 'data') and "Output Prefix" (default 'file_').

### C. Shape
14.C.1. Each input item gives one output item. The json is unchanged; the binary section is replaced by the archive (compress) or by the extracted files (decompress).

14.C.2. Binary files show "File Name", "File Extension", "Mime Type" and "File Size" (text such as '146 B' or '2.05 kB'). The run data also holds a byte count.

### D. Measured behaviour
The source files were hello.txt (text/plain, 480 bytes, a repeated sentence) and two.txt (11 bytes).

| Case | Output |
|---|---|
| Zip, one file, name 'out.zip' | data: out.zip, application/zip, zip, 146 B |
| … then Decompress | file_0: hello.txt, text/plain, txt, 480 B |
| Zip, fields 'data,data2' (also 'data, data2') | one archive, 249 B; decompress gives file_0 hello.txt 480 B and file_1 two.txt 11 B |
| Zip, "Put Output File in Field" 'archive' | the binary key is archive |
| Zip, file name 'noext' | name kept as 'noext'; mime application/zip; extension zip; decompress works |
| Zip, file name 'archive.bin' | mime application/octet-stream, extension bin (taken from the name); decompress then fails (format detected by extension) |
| Zip of two files with the same name | after decompress, only one file (the second one's content, 4 B) |
| A file with no name | the entry becomes 'undefined' (zip) or 'undefined.gz' (gzip) |
| Gzip, no name | hello.txt.gz, application/gzip, gz, 48 B; decompress gives hello.txt 480 B (the original name returns) |
| Gzip, name 'custom.txt' | 'custom.txt.txt.gz' (the original extension is appended); decompress gives 'custom.txt'; Output Prefix 'out_' gives key out_0 |
| Gzip, two fields | two separate .gz files under the keys data and data1; decompressing with 'data,data1' gives file_0 and file_1 |
| Tar, one file / two files | out.tar, application/x-tar: 2.05 kB (2048 bytes) / 3.07 kB (3072 bytes); decompress restores all |
| Tar (Gzip), two files | out.tar.gz, application/gzip, gz, 151 B; decompress restores both |
| Older version 1, Gzip | key gz_0, name hello.gzip, extension gzip (that version names outputs by a prefix) |
| Two input items | each item is compressed separately, giving one archive per item |

### E. Errors
14.E.1. A named binary field is missing: "The item has no binary field 'nope' [item 0]", with a hint to check the field name.

14.E.2. The item has no binary at all: "This operation expects the node's input data to contain a binary file 'data', but none was found [item 0]", advising to make sure the previous node outputs a file.

14.E.3. Decompressing a non-archive: 'Unsupported archive format ".txt" for binary data data', listing the supported formats as zip, gzip, tar, tar.gz and tgz.

14.E.4. An empty File Name for Zip or Tar blocks the run (G7).

14.E.5. With "Continue", a decompress failure outputs the item {error:"Unsupported archive format …"}, with its json replaced.

---

## 15. Open questions (not observed, and why)

15.1. The PEM-key credential and the RS, ES and PS algorithms were not tested; only a passphrase with HS256 and HS512 was used. The algorithm "none" was not tested either.

15.2. Remove Duplicates' previous-executions memory was observed only across manual runs of a saved workflow. Whether production (activated) runs share or separate that memory was not observable without activating a workflow, which was out of scope.

15.3. The rule behind Sort's ordering when some items lack the sort field could not be pinned down; the four observed outcomes are recorded in 2.D.8. The rule behind Summarize's min/max on mixed number and text values is likewise only recorded case by case (7.D.5).

15.4. Where the editor exposes Edit Fields' "Duplicate Item" settings was not found. They are not in the Parameters tab, and the Settings tab of that node was not inspected.

15.5. The Filter's second (Discarded) output receives data when connected in the workflow definition, but the canvas draws no port for it. Whether a user can connect it in the editor was not observed.

15.6. The continue-on-error modes were exercised for Filter, Sort, Remove Duplicates, Edit Fields, JWT and Compression only. For Limit, Split Out, Aggregate, Summarize, Compare Datasets, Merge, Rename Keys and TOTP, only the presence of the Settings tab with the same three "On Error" choices was observed.

15.7. Merge with an input that is not connected, or whose branch never runs, was not tested. Only empty-but-executed inputs were tested.

15.8. Compression was not tested with a tgz extension, nested folders inside archives, binary (non-text) payloads, or very large files.

15.9. "Retry On Fail" was not exercised for any node.

15.10. Exact per-item linking metadata (which output item derives from which input item) was recorded in the run data but is not reported here.

## 16. Screenshots

All are light theme, 1440×900, in docs/specs/node-equivalents/_ref/.

- General: node-all-canvas-overview.png
- Filter: node-filter-default.png, node-filter-operator-types.png, node-filter-operators-string.png, node-filter-operators-array.png, node-filter-options-list.png, node-filter-settings-tab.png, node-filter-settings-onerror-options.png, node-filter-ignorecase-convert-on.png, node-filter-canvas-after-run.png, node-filter-configured-run.png, node-filter-two-conditions.png, node-filter-combinator-list.png
- Sort: node-sort-default.png, node-sort-simple-run.png, node-sort-type-list.png, node-sort-random.png, node-sort-code.png
- Limit: node-limit-default.png, node-limit-default-run.png, node-limit-last-run.png
- Remove Duplicates: node-remove-duplicates-default.png, node-remove-duplicates-canvas-error.png, node-remove-duplicates-all-fields-error.png, node-remove-duplicates-operation-list.png, node-remove-duplicates-compare-list.png, node-remove-duplicates-all-except-run.png, node-remove-duplicates-selected-run.png, node-remove-duplicates-history-run.png, node-remove-duplicates-keep-where-list.png, node-remove-duplicates-history-options.png, node-remove-duplicates-clear.png
- Split Out: node-split-out-default.png, node-split-out-run.png, node-split-out-include-list.png, node-split-out-options-list.png
- Aggregate: node-aggregate-default.png, node-aggregate-individual-run.png, node-aggregate-mode-list.png, node-aggregate-individual-options.png, node-aggregate-all-run.png
- Summarize: node-summarize-default.png, node-summarize-run.png, node-summarize-aggregation-list.png, node-summarize-separator-list.png, node-summarize-options-list.png
- Compare Datasets: node-compare-datasets-default.png, node-compare-datasets-canvas-run.png, node-compare-datasets-run.png, node-compare-datasets-resolve-list.png, node-compare-datasets-options-list.png, node-compare-datasets-different-json.png
- Merge: node-merge-default.png, node-merge-canvas-run.png, node-merge-append-run.png, node-merge-mode-list.png, node-merge-fields-run.png, node-merge-combineby-list.png, node-merge-output-type-list.png, node-merge-fields-options-list.png, node-merge-fields-clash-handling.png, node-merge-position-run.png, node-merge-position-clash-default.png, node-merge-all-combinations-run.png, node-merge-sql-run.png, node-merge-choose-branch-run.png
- Rename Keys: node-rename-keys-default.png, node-rename-keys-run.png
- Edit Fields: node-edit-fields-default.png, node-edit-fields-one-field.png, node-edit-fields-type-list.png, node-edit-fields-options-list.png, node-edit-fields-manual-run.png, node-edit-fields-include-list.png, node-edit-fields-options-include-on.png, node-edit-fields-json-run.png
- JWT: node-jwt-default.png, node-jwt-canvas-run.png, node-jwt-sign-run.png, node-jwt-operation-list.png, node-jwt-claims-list.png, node-jwt-sign-options.png, node-jwt-verify-run.png, node-jwt-verify-options.png, node-jwt-decode-run.png, node-jwt-credential-form.png (secret masked)
- TOTP: node-totp-default.png, node-totp-run.png, node-totp-options-list.png, node-totp-credential-form.png (secret masked)
- Compression: node-compression-default.png, node-compression-compress-zip-run.png, node-compression-format-list.png, node-compression-compress-gzip-run.png, node-compression-decompress-run.png
