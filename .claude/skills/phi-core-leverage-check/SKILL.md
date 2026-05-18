---
name: phi-core-leverage-check
description: Verify phi-core leverage compliance for a baby-phi chunk. Runs the §3 positive + forbidden greps from the cycle plan, confirms check-phi-core-reuse.sh exits 0, computes the import-count delta. Used at plan-time (predict), implementation-time (self-check), and audit-time (verify).
---

# phi-core-leverage-check

Run the phi-core leverage audit for the chunk in flight. Outputs ✅/❌ per check with cited grep output.

## Inputs (caller provides)

1. **Cycle plan path** — `baby-phi/docs/specs/plan/build/<slug>-<8hex>/plan.md`. The plan's §3 lists the positive greps + forbidden greps + predicted import delta.
2. **Mode** — `predict` (plan-time, baseline), `self-check` (implementation-time), `verify` (audit-time, post-implementation).

## Procedure

1. **Read plan §3** — extract every grep command and its expected hit count.
2. **For each positive grep** — run it; record `actual / expected`. ✅ if match, ❌ if mismatch.
3. **For each forbidden grep** — run it; expect zero hits. ✅ if zero, ❌ if any hit.
4. **Run** `bash /root/projects/phi/baby-phi/scripts/check-phi-core-reuse.sh`. ✅ if exit 0, ❌ otherwise.
5. **Compute import delta:**
   ```bash
   cd /root/projects/phi
   git diff main -- baby-phi/modules/crates | grep -c '^\+use phi_core::'
   git diff main -- baby-phi/modules/crates | grep -c '^-use phi_core::'
   ```
   Net delta = added − removed. Compare to plan §3's predicted delta.

## Output format

```
phi-core leverage check (<mode>):
  Positive greps: <N>/<M> ✅
  Forbidden greps: <N>/<M> ✅
  check-phi-core-reuse.sh: ✅ exit 0 | ❌ exit <code>
  Import delta: predicted <+/-N>, actual <+/-M>: ✅ match | ❌ mismatch

  Mismatches (if any):
    - <grep>: expected <X>, got <Y>
    - <line range from script output>

  Verdict: ✅ green | ⚠ yellow (predict-mode mismatch acceptable for future delta) | ❌ red
```

## Failure modes

- **Plan §3 missing or stub-only** — cannot run; report "plan §3 incomplete; planner must fill before this check applies".
- **Grep returns more than expected** — surface the file paths + line numbers; suggests partial implementation or accidental new usage.
- **Grep returns less than expected** — surface; suggests incomplete implementation.
- **Forbidden grep returns hits** — high-priority finding; phi-core duplication may have crept in.

## Prediction methodology — leverage-sites not import-lines (added 2026-05-18 per CH-03-i-phi retro P4, cycle hex `c542648f`)

Plan §3 expected-delta SHOULD be expressed in **leverage-sites** (semantically distinct uses of phi-core), NOT raw `use phi_core` line counts. Example:

- Bad form: *"compose.rs adds 1 `use phi_core` line; tests adds 1; mod.rs adds 1; watcher.rs adds 1 → 4 new imports"*.
- Good form: *"+1 leverage-site at compose.rs (composer-builder consuming `PromptBlockDef + SystemPromptStrategy + CustomPromptStrategy + SystemPrompt` in one `use` statement); +1 leverage-site at tests/identity_test.rs (test-time consumer using `MinimalPromptStrategy + SystemPromptStrategy`); 0 at watcher.rs (callback signature uses only i-phi types)."*

**Tolerance**: **±3 leverage-sites** at chunk-close. Outside that range → surface as deviation in cycle-audit §6.

Rationale: import-line counting is noisy (one `use` statement importing 4 types = 1 line; one `use` statement per type = 4 lines; both have the same semantic leverage). The leverage-site count tracks semantic use, which is the real reuse signal. CH-03 evidence: predicted 15-16 import lines; actual 13 (-2 to -3 deviation); leverage-site count was 2 (compose + tests), predicted as 2 — exact match.

Forbidden-duplication greps stay unchanged (they're the inverse contract — verify NO parallel implementations of phi-core types under the project root, regardless of line count).

## Reference

baby-phi `CLAUDE.md` phi-core leverage rules 1–5. Per-chunk-template §3.