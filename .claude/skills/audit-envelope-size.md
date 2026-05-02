---
name: audit-envelope-size
description: Pick the audit envelope (1, 2, or 3 audit agents) and draft per-letter audit prompt scaffolds for plan §11. Used by chunk-planner only.
version: 1
---

# audit-envelope-size

Apply the per-chunk-template §11 sizing rule to the chunk's phase count, then draft the per-audit-letter prompt scaffolds.

## Inputs (caller provides)

1. **Phase count** — from plan §7 (count the `### P<N>` headers).

## Procedure

1. **Apply the sizing rule:**
   | Phases | Audit envelope | Letters |
   |---|---|---|
   | ≤ 2 | Small (1) | A only (combined code + concept + docs) |
   | 3–5 | Medium (2) | A (code + phi-core + K8s) + B (concept + docs + ADR) |
   | 6+ | Large (3) | A (code + phi-core + K8s) + B (concept + docs + ADR) + C (carry-forward regression) |

2. **Draft the per-letter audit prompt scaffold** for §11. Each scaffold is ≤ 600 words and lists numbered claims. Templates:

### Audit A (code + phi-core + K8s) scaffold

```
You are auditing CH-NN in baby-phi at /root/projects/phi/baby-phi/. Read-only on source. Plan at <cycle-folder>/plan.md.

Verify each claim with file:line citation:
1. <chunk-specific code claim from plan §7 deliverables>
2. <phi-core leverage claim from plan §3>
3. <K8s axis claim from plan §3.B>
4. cargo test --workspace -- --test-threads=1 green at expected count <N>.
5. CI guards green; check-phi-core-reuse.sh exit 0; no new `use phi_core::` imports beyond §3 prediction.
6. <prior-chunk invariants intact from plan §6>

PASS/FAIL each. ≤ 600 words.
```

### Audit B (concept + docs + ADR) scaffold

```
You are auditing CH-NN's concept-fidelity + docs-fidelity. Read-only.

Verify each claim:
1. ADR-NNNN Accepted at <ADR path> with sub-decisions D<N>.1..D<N>.<M>.
2. Drift D-new-NN Status = remediated; lifecycle entry for CH-NN chunk-seal present.
3. drifts/README.md row updated; "Closes at" → CH-NN ✓.
4. _concept-audit-matrix.md row flipped <from> → <to>.
5. Concept doc <path> verified-header bumped (CH-NN amendment line). Body unchanged unless plan authorized.
6. K8s deferred ledger entry <CHK8S-D-NN> if new blocker class.
7. Plan archive at <cycle-folder>/plan.md exists with cycle hex <8hex>.
8. <prior-chunk doc invariants intact>

PASS/FAIL each. ≤ 600 words.
```

### Audit C (carry-forward regression — large only) scaffold

```
You are auditing CH-NN's carry-forward regression posture. Read-only.

Verify each claim:
1. Acceptance suite <name> still green: cargo test -p server --test <name>.
2. Acceptance suite <name> still green: cargo test -p server --test <name>.
3. Migration runner test version <N> + slug <slug>: cargo test -p store --test migrations_test.
4. <other carry-forward suites named in plan §6>

PASS/FAIL each. ≤ 600 words.
```

## Output format

```
audit-envelope-size:
  Phase count: <N>
  Envelope: Small (1) | Medium (2) | Large (3)
  Audit letters: A | A,B | A,B,C
  Scaffolds drafted: <comma-separated letter list>

  Reasoning: <one-line justification>
```

## Quality bar

- Each scaffold is ≤ 600 words.
- Each scaffold's claims are numbered.
- Each scaffold cites concrete plan sections (§3, §3.B, §5, §6, §7, §8) rather than handwaving.
- The "carry-forward" scaffold (Audit C) only appears when phase count ≥ 6.

## Reference

per-chunk-template §11 — canonical sizing rule + audit prompt structure.