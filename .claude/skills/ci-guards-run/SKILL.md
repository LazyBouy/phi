---
name: ci-guards-run
description: Run the CI guard scripts under `<PROJECT_ROOT>/scripts/check-*.sh` and report exit codes + offending output. Used by implementer at chunk-close and by auditor at verify-time. Project-aware via PROJECT_ROOT.
---

# ci-guards-run

Execute the CI guard scripts in `<PROJECT_ROOT>/scripts/`. Report exit code per script and any offending output.

## Project context (v2 — project-aware path resolution; added 2026-05-26 per Chunk C consolidation 6)

The caller passes `PROJECT_ROOT` in the runtime context:
- **Unset / absent** → `/root/projects/phi/baby-phi` (back-compat default; 4 guards `check-{doc-links,ops-doc-headers,phi-core-reuse,spec-drift}.sh`).
- **`/root/projects/phi/i-phi`** → i-phi post-CH-07a guards (`check-{doc-links,verified-headers,phi-core-reuse,spec-drift}.sh` per ADR-0010a §D10.13). i-phi pre-CH-07a had no guards; mark `NOT-EXECUTED-IN-AUDIT` if the project's `scripts/` directory is absent.
- **`/root/projects/phi/phi-core`** → phi-core has no equivalent guard set at v0; skip with paperwork-side note.

## Procedure

Enumerate `<PROJECT_ROOT>/scripts/check-*.sh` at invocation time, then invoke each:

```bash
# baby-phi (default; 4 guards):
bash /root/projects/phi/baby-phi/scripts/check-doc-links.sh
bash /root/projects/phi/baby-phi/scripts/check-ops-doc-headers.sh
bash /root/projects/phi/baby-phi/scripts/check-phi-core-reuse.sh
bash /root/projects/phi/baby-phi/scripts/check-spec-drift.sh

# i-phi (post-CH-07a; 4 guards — different names):
bash /root/projects/phi/i-phi/scripts/check-doc-links.sh
bash /root/projects/phi/i-phi/scripts/check-verified-headers.sh
bash /root/projects/phi/i-phi/scripts/check-phi-core-reuse.sh
bash /root/projects/phi/i-phi/scripts/check-spec-drift.sh
```

Each script must exit 0. Any non-zero is a CI-failing condition.

## Output format

```
CI guards:
  check-doc-links.sh: ✅ exit 0 | ❌ exit <code>
    <offending lines if non-zero>
  check-ops-doc-headers.sh: ✅ exit 0 | ❌ exit <code>
    <offending lines if non-zero>
  check-phi-core-reuse.sh: ✅ exit 0 | ❌ exit <code>
    <offending lines if non-zero>
  check-spec-drift.sh: ✅ exit 0 | ❌ exit <code>
    <offending lines if non-zero>

  Verdict: ✅ all green | ❌ <N>/4 green
```

## Failure modes

- **Script not found** — repo state is broken; STOP and report. Never auto-create or modify a guard script.
- **Non-zero exit** — record stderr/stdout verbatim. Implementer / auditor uses this to triage.

## Reference

- `<PROJECT_ROOT>/scripts/check-*.sh` — the canonical guard scripts per project.
- baby-phi: `scripts/check-{doc-links,ops-doc-headers,phi-core-reuse,spec-drift}.sh`.
- i-phi: `scripts/check-{doc-links,verified-headers,phi-core-reuse,spec-drift}.sh` (post-CH-07a per ADR-0010a §D10.13).
- phi-core: no guard set at v0.