---
name: phi-core-leverage-check
description: Verify phi-core leverage compliance for a baby-phi chunk. Runs the §3 positive + forbidden greps from the cycle plan, confirms check-phi-core-reuse.sh exits 0, computes the import-count delta. Used at plan-time (predict), implementation-time (self-check), and audit-time (verify).
version: 1
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

## Reference

baby-phi `CLAUDE.md` phi-core leverage rules 1–5. Per-chunk-template §3.