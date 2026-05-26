---
name: interface-contract-verify
description: 4-axis interface-contract verification for `<TypeName>::<method_name>(...)` deliverables in plans + audit prompts. Confirms method exists, impl block exists, body lives inside impl, signature matches. Used by chunk-implementer (P-IMPL self-check), chunk-auditor (Audit-A interface-contract claim), orchestrator (gate-3 method-signature paraphrase cross-check). Project-aware via PROJECT_ROOT.
---

# interface-contract-verify

Mechanical 4-axis verification of method-form deliverables. Consolidates 3-layer defense (implementer + auditor + orchestrator) for the method-vs-free-function interface-drift class into one source-of-truth skill.

## Why this skill exists

CH-07b-i-phi (cycle `283d3949`) shipped the free function `harvest_from_subagent_session(...)` at `src/agent_factory/harvest.rs:77` correctly per plan §8 P-HARVEST deliverable 2 but did NOT add an `impl AgentHandle { pub async fn harvest_from_subagent_session(...) }` delegate. Plan §8 + forward-scope item 10 + ADR-0010a §"For CH-07b" all called for the method form. Surfaced at Audit C iter-1 Claim 5 FAIL; orchestrator-applied Trivial-multi 37-LOC delegate patch.

3 prior tier-specific rules duplicate the verification logic:
- chunk-implementer v20 P-impl-1-v20 (implementer-tier self-check at phase boundary).
- chunk-auditor v13 Audit-A interface-contract claim (auditor-tier).
- outer CLAUDE.md gate-3 method-signature paraphrase cross-check (orchestrator-tier).

Consolidating into one skill (a) eliminates drift between the three sites, (b) lets any caller invoke the same axes, (c) keeps the precedent narrative in `discipline-archive.md`.

## Inputs (caller provides)

1. **PROJECT_ROOT** — `/root/projects/phi/baby-phi` (default) or `/root/projects/phi/i-phi`.
2. **Method-form deliverable** — string of the shape `<TypeName>::<method_name>(...) -> <RetType>` extracted from plan §1 / §4 / §8 / forward-scope / ADR. Multiple method-form deliverables may be passed; skill runs the 4 axes per item.
3. **Mode** (optional, default `verify`) — `predict` (plan-draft time; only axes a + b checked since impl may not be landed yet) / `verify` (implementer P-IMPL or auditor or orchestrator gate-3).

## Procedure (4-axis verification)

For each method-form deliverable `<TypeName>::<method_name>(...)`:

### Axis (a) — Method definition exists

```bash
grep -rn "fn <method_name>" $PROJECT_ROOT/src/ | head -10
```

PASS if ≥ 1 hit; FAIL with the file:line list (or empty list).

### Axis (b) — Impl block exists for the type

```bash
grep -rn "^impl <TypeName>" $PROJECT_ROOT/src/ | head -10
grep -rn "^impl[[:space:]]*<.*>[[:space:]]*<TypeName>" $PROJECT_ROOT/src/ | head -10  # generic impls
```

PASS if ≥ 1 hit; FAIL with file:line list. Capture all matching impl blocks for axis (c) lookup.

### Axis (c) — Method body lives INSIDE one of the matching impl blocks

For each impl block in axis (b) result:
1. Capture the impl block's file + start line.
2. Find the matching closing brace (next `^}` at same indentation level — heuristic; for nested impl bodies, scan lines until brace-counter returns to 0).
3. Within the captured range, grep for `fn <method_name>`.
4. PASS if ≥ 1 impl block contains the method body; FAIL otherwise (method exists as free function but NOT exposed on the type).

**Note**: this axis is the highest-value check. Free-function-with-similar-name is the canonical failure mode (CH-07b precedent). Skill output explicitly distinguishes "method body found inside `impl <TypeName>` at file:line" (PASS) vs "method body found at file:line but NOT inside any `impl <TypeName>`" (FAIL).

### Axis (d) — Signature arg-list + return-type matches plan literal

Extract the cited signature from the input deliverable string:

```
<TypeName>::<method_name>(arg1: T1, arg2: T2, ...) -> RetType
```

Compare against the actual fn signature found in axis (c) PASS location:

1. Match arg count (positional, ignoring `&self` / `&mut self`).
2. Match arg type literals (allow whitespace / alias normalization).
3. Match return type literal.

PASS if all match; PARTIAL if arg count matches but type literals differ (likely semantic-equivalent — e.g., `&T` vs `&dyn TraitObject<T>` per CH-10 arg-shape divergence refinement); FAIL if arg count mismatches.

**Disambiguation rule** (per CH-07b extended scope): semantic equivalence preserved is acceptable (e.g., AgentHandle's `harvest_from_subagent_session` shipped with 4-arg form deriving `session_store` + `extractor` from `&self` — semantically equivalent to the 2-arg literal in plan because AgentHandle doesn't carry those fields). Mark PARTIAL with explanation, NOT FAIL.

## Output format

```
interface-contract-verify:
  Method: <TypeName>::<method_name>(...)
  Axis (a) method-exists: ✅ <N> hit(s) / ❌ 0 hits
  Axis (b) impl-block-exists: ✅ <N> hit(s) / ❌ 0 hits — impl files: <list>
  Axis (c) method-inside-impl: ✅ PASS at <file:line> / ❌ FAIL (method body at <file:line> but NOT inside any impl <TypeName>)
  Axis (d) signature-match: ✅ PASS / ⚠ PARTIAL (<reason>) / ❌ FAIL (arg count mismatch: plan <N> vs actual <M>)

  Verdict: PASS | PARTIAL | FAIL
```

Exit code: 0 PASS, 1 FAIL, 2 PARTIAL.

## Caller integration

- **chunk-implementer v20 P-impl-1-v20**: invoke at each phase boundary AFTER source files land but BEFORE commit. If any method-form deliverable from plan §8 returns FAIL on (c), emit phase-commit blocker → escalate to orchestrator OR add the impl-block method delegate.
- **chunk-auditor v13 Audit-A**: invoke when audit prompt's `## Code-correctness claims` list cites a method form. Skill output drives the per-claim verdict (PASS / FAIL / PARTIAL).
- **orchestrator gate-3**: invoke as part of `audit-prompt-cross-check.sh` axis 4 (method-sig). If skill returns DIVERGENT (axis 4 in cross-check.sh), apply Trivial-1L plan-edit BEFORE auditor dispatch OR escalate as Trivial-multi if a delegate method is missing.

## Quality bar

- 4-axis output is deterministic given identical inputs + source tree.
- Axis (c) impl-block lookup handles nested impl bodies + generic impls correctly.
- Axis (d) PARTIAL is well-distinguished from FAIL (semantic-equivalence vs structural-mismatch).
- Project-agnostic body.

## Reference

- chunk-implementer v20 P-impl-1-v20 — origin (CH-07b retro proposal #3).
- chunk-auditor v13 Audit-A interface-contract claim — auditor-tier defense (CH-07b retro proposal #4).
- outer CLAUDE.md gate-3 method-signature paraphrase cross-check — orchestrator-tier defense (extended 2026-05-24 per CH-07b retro proposal #6; extended 2026-05-24 per CH-10 retro proposal #6 to arg-shape divergence).
- discipline-archive.md `#ch-07b-i-phi-interface-contract-drift` for the canonical failure-mode narrative.
- discipline-archive.md `#ch-10-i-phi-arg-shape-divergence` for axis (d) PARTIAL precedent.