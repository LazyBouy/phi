---
name: chunk-template-validate-locked-appendix
description: Validate the `## §1 — Locked fork details` (or `### Locked fork details`) appendix in a chunk plan is present + structurally valid when ≥ 1 `LOCKED at gate-1` row exists in §3. Returns PASS/FAIL. Used at planner end-of-draft (chunk-planner self-check) AND at chunk-archive-plan archive-tier hard-assertion. Project-aware via PROJECT_ROOT.
---

# chunk-template-validate-locked-appendix

Mechanical self-check + archive-tier hard-assertion for the locked-fork-details appendix. Consolidates chunk-planner v22 P13 + v23 P-plan-3 reinforcement (planner self-check) + chunk-archive-plan v3 hard-assertion into one source-of-truth. Project-agnostic — operates only on the plan body.

## Why this skill exists

Pre-CH-05, the locked-fork-details appendix went missing 3 cycles in a row (CH-03 + CH-04 + CH-05 i-phi) despite being mandated by chunk-planner v20 P2. Empirically the prose-only rule is regression-prone; a script-enforced check closes the loop reliably.

## Inputs (caller provides)

1. **Plan path** — absolute path to the cycle plan file (e.g., `/root/projects/phi/i-phi/docs/v0/proposal/plan/build/<slug>-<8hex>/plan.md`).
2. **PROJECT_ROOT** (optional) — `/root/projects/phi/baby-phi` (default) or `/root/projects/phi/i-phi`. Currently unused by this skill (rule is project-agnostic) but accepted for symmetry with sibling skills.

## Procedure (4-step mechanical validation)

1. **Detect locked forks** (v2 — regex extended per CC-01 retro G-6 to detect both post-gate-1 LOCKED state AND v32 iter-1-populated pre-lock state): grep plan body for ≥ 1 lock-or-pre-lock row (case-insensitive). The alternation captures the canonical post-gate-1 wording AND the v32 iter-1 planner-rec pre-lock wording so the skill works at both planner end-of-draft (iter-1) AND chunk-archive-plan (post-lock).
   ```bash
   LOCK_COUNT=$(grep -ciE 'LOCKED at gate-1|LOCKED-CANDIDATE planner-rec|pre-lock draft; finalizes at gate-1 lock|\(LOCKED\)' <plan>)
   ```
   If `LOCK_COUNT == 0`, return PASS (no locked forks → appendix not required). Skill exits cleanly. **Backward-compatible**: continues to match v22-era plans that used only `LOCKED at gate-1` wording.

2. **Appendix heading exists**: grep plan body for `^### Locked fork details` OR `^## Locked fork details` OR `^## §1 — Locked fork details` (any of these heading forms is valid).
   ```bash
   HEADING_COUNT=$(grep -cE '^#{2,3}( §1 —)? Locked fork details' <plan>)
   ```
   If `HEADING_COUNT == 0`, return FAIL with reason "locked forks present but no appendix heading".

3. **Sub-section count ≥ lock count**: count `^#### F<N>` (or `^#### F<token>`) subsection headers WITHIN the appendix region. The simplest scriptable approach is to count `^#### F` headers across the entire plan body (works for canonical plans where these only appear in the appendix). If count < `LOCK_COUNT`, return FAIL with reason "<N> subsections present, ≥ <LOCK_COUNT> required".

4. **Each subsection body ≥ 3 sentences**: for each `#### F<N>` subsection, extract the body until the next `^#### ` or `^### ` heading. Count sentence-terminating punctuation (`. ` / `.\n` / `!` / `?`). If any subsection body has fewer than 3 such terminators, return FAIL with reason "subsection <header> has <N> sentences, ≥ 3 required".

## Output format

```
chunk-template-validate-locked-appendix:
  Plan: <plan path>
  Locked forks detected: <LOCK_COUNT>
  Appendix heading: ✅ found at line <N> / ❌ missing
  Subsection count: <K> (required ≥ <LOCK_COUNT>) ✅ / ❌
  Subsection bodies: <details, e.g., "all subsections have ≥ 3 sentences" or "F<N> body has 2 sentences (< 3 required)">
  Verdict: PASS | FAIL — <one-line reason if FAIL>
```

Exit code: 0 on PASS, 1 on FAIL.

## Caller integration

- **chunk-planner end-of-draft (v22 P13 + v23 P-plan-3 reinforcement)**: invoke this skill BEFORE returning the draft path to orchestrator. If FAIL, planner re-emits the appendix + re-runs the skill until PASS.
- **chunk-archive-plan archive-tier hard-assertion (v3 — added CH-04-i-phi retro P14)**: invoke this skill BEFORE archiving the plan + appending the cycle-index row. If FAIL, abort the archive step + report the error to orchestrator. This is belt-and-suspenders to the planner self-check; both layers fire.

## Quality bar

- Skill is fully scripted (no LLM judgment required); deterministic PASS/FAIL.
- Reports specific gap on FAIL (which subsection is malformed, what's missing).
- Project-agnostic in body — operates only on plan markdown structure.

## Reference

- chunk-planner v22 P13 (locked-fork-details appendix self-check loop) — origin.
- chunk-planner v23 P-plan-3 (ALWAYS-FIRE upgrade) — escalation when v22 P13 alone was insufficient.
- chunk-planner v32 P-plan-1-v32 (iter-1 §1 populated with planner-rec bodies) — origin of the `LOCKED-CANDIDATE planner-rec` pre-lock wording that v2 regex now detects.
- chunk-archive-plan v3 archive-tier hard-assertion (CH-04-i-phi retro P14) — paired defense; v4 invokes this skill instead of inline grep.
- discipline-archive.md `#ch-05-i-phi-pre-archival-quartet-evidence` for the 3-of-3 regression narrative that motivated this skill.
- User memory `feedback_locked_fork_details_appendix.md` — *"Irrespective of whether the locks diverge or not, the plan must have a locked fork details section before it is sent for approval."*

## Version history

- **v1** (initial) — 4-step mechanical validation; grep regex literal `LOCKED at gate-1` only.
- **v2** (2026-05-31, joint-retro CC-01..CC-04 batch P7 LOW) — Step 1 regex extended to alternation `LOCKED at gate-1|LOCKED-CANDIDATE planner-rec|pre-lock draft; finalizes at gate-1 lock` to detect both post-gate-1 LOCKED state AND v32 iter-1-populated pre-lock state. Backward-compatible. Closes CC-01 cycle-audit §6 D-6 tooling observation (skill manually validated PASS structurally at plan-archive time because regex didn't recognize iter-1-populated pre-lock wording).
- **v3** (2026-06-02, CC-09a close) — Step 1 alternation extended with the literal `\(LOCKED\)` token to detect the USER-DIVERGENT fork-table bold-cell wording (`**F1.a USER-DIVERGENT (LOCKED)**`, `**F-SPLIT.b (LOCKED)**`, `**F2.a USER-DIVERGENT (LOCKED)**`). Recurrence of the CC-01 D-6 class: CC-09a (2 USER-DIVERGENT + 1 planner-rec locks) was detected as `LOCK_COUNT==0` by the v2 regex → skill returned PASS via the "no locks → appendix not required" false-negative path rather than genuinely validating the (well-formed) §1 appendix. The token is the literal `(LOCKED)` — matching the bold locked-OPTION cell **once per locked fork** (CC-09a → 3) so Step 3's `subsections ≥ LOCK_COUNT` floor stays correct (do NOT use a bare `\(LOCKED` or `gate-1 locks` — those over-count via section-headers/rationale lines and would false-FAIL Step 3). Backward-compatible (only adds one alternation). Defer broader retro consolidation to the joint CC-09a+CC-09b retrospective.