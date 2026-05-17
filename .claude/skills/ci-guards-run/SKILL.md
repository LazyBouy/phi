---
name: ci-guards-run
description: Run all 4 baby-phi CI guard scripts and report exit codes + offending output. Used by implementer at chunk-close and by auditor at verify-time.
---

# ci-guards-run

Execute the 4 CI guard scripts in baby-phi/scripts/. Report exit code per script and any offending output.

## Procedure

```bash
cd /root/projects/phi/baby-phi
bash scripts/check-doc-links.sh
echo "EXIT: $?"
bash scripts/check-ops-doc-headers.sh
echo "EXIT: $?"
bash scripts/check-phi-core-reuse.sh
echo "EXIT: $?"
bash scripts/check-spec-drift.sh
echo "EXIT: $?"
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

baby-phi/scripts/*.sh — the canonical guard scripts.