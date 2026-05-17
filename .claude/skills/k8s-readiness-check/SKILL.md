---
name: k8s-readiness-check
description: Walk the 7-axis K8s microservice readiness evaluation for a baby-phi chunk. Classifies each axis (in-process state, IPC, pod-local resources, migration runner, trait-shape, cross-pod state, audit hash-chain symmetry). Drafts CHK8S-D-NN deferred-ledger entries when new blocker classes are discovered.
---

# k8s-readiness-check

Run the per-chunk-template §3.B 7-axis evaluation for K8s microservice readiness. Used at plan-time and audit-time.

## The 7 axes (per per-chunk-template §3.B + ADR-0033)

| Axis | What it checks |
|---|---|
| A1 | In-process state (mutexes, RwLocks, in-memory caches that wouldn't transfer across pods) |
| A2 | IPC channels (mpsc, broadcast, watch — assume single-process; multi-pod requires externalization) |
| A3 | Pod-local resources (filesystem paths, sockets, embedded SurrealDB files) |
| A4 | Migration runner conformance (idempotent under repeated runs; doesn't assume single-runner) |
| A5 | Trait-shape requirement (Repository / Storage trait additions must be implementable on remote backend) |
| A6 | Cross-pod state sharing (any read-after-write expectation across pods needs externalized state) |
| A7 | Audit hash-chain symmetry (BLAKE3 canonical bytes byte-stable across pods) |

## Inputs (caller provides)

1. **Cycle plan path** — for the §3.B table draft (plan-time mode) or verification (audit-time).
2. **Mode** — `draft` (plan-time, fill the table) or `verify` (audit-time, confirm classifications hold against actual code).

## Procedure (draft mode)

1. **Read the chunk's deliverables** from plan §1 / §7.
2. **For each axis A1–A7:**
   - Identify whether the deliverables touch this axis (e.g., spawning a tokio task → A1 + A2; adding a Repository method → A5).
   - Classify: `no impact` (axis not touched), `compatible` (touched but multi-pod-safe), `new blocker class` (touched and would break multi-pod).
   - Justify the classification in one sentence with a code anchor.
3. **For every `new blocker class`:**
   - Look up next-free `CHK8S-D-NN` number at `baby-phi/docs/specs/v0/implementation/m7b/architecture/deferred-from-ch-k8s-prep.md`.
   - Draft the ledger entry: chunk slug, axis affected, blocker description, deferral rationale, proposed M7b-era resolution.

## Procedure (verify mode)

1. **Read** the plan's §3.B table.
2. **For each axis:** spot-check the classification against the actual implemented code. ✅ if matches, ❌ if reality contradicts.
3. **For every `new blocker class` row:** verify the ledger entry exists at `m7b/architecture/deferred-from-ch-k8s-prep.md` with the asserted CHK8S-D-NN number; ledger totals bumped to reflect.

## Output format

```
K8s readiness check (<mode>):
  | Axis | Classification | Code anchor | Status |
  |---|---|---|---|
  | A1  | <class>      | <ref>       | ✅/❌  |
  ... (all 7 rows)

  New K8s blockers (if any):
    CHK8S-D-NN: <description>
    - axis: <Ax>
    - chunk: <slug>
    - resolution path: <M7b-era plan>
    - ledger entry status: ✅ exists | ❌ missing | n/a (draft mode)

  Verdict: ✅ all axes resolved (and ledger entries present in verify mode) | ❌ <issues>
```

## Failure modes

- **Classification missing or vague** ("partially impacts" / "TBD") — push back; require concrete classification.
- **`new blocker` without ledger entry** at audit-time — FAIL.
- **Ledger CHK8S-D-NN number conflicts** with existing entry — FAIL; planner must pick the next-free number.

## Reference

per-chunk-template §3.B. ADR-0033 (K8s readiness conformance). `m7b/architecture/deferred-from-ch-k8s-prep.md` (the deferred ledger).