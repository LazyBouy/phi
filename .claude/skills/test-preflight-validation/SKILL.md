# test-preflight-validation

Pre-execution validator for e2e-test cases. Reads the frontmatter of `HTC-NNNN.md` (`test_class: harness`) or `TC-NNNN.md` (`test_class: model`), runs 10 mechanical PASS/FAIL checks, and emits structured PASS/FAIL JSON. Caller (orchestrator's T-cycle Phase 0 step 7.5) cycles BLOCKED if ANY scheduled test FAILs.

Ships at CH-CC-07 F3 (cycle `aeed9751`) per ADR-0023 §D23.15 + the orchestrator plan §4.3. Closes the systemic "setup writes config that doesn't actually exercise the surface" failure class surfaced by T10-execute cycle `0577137b` (4 HTCs reported `event_check PASS` while 0-of-3 tool-specific surfaces had actually executed).

## Invocation

```bash
bash /root/projects/phi/.claude/skills/test-preflight-validation/check.sh <TEST-ID> [<CYCLE-FOLDER-ABS>]
```

- `<TEST-ID>` — `HTC-0001` / `TC-0007` / etc. Resolves to `<i-phi>/docs/e2e-test/test-cases/<TEST-ID>.md`.
- `<CYCLE-FOLDER-ABS>` — optional. When set, HTC class-specific checks resolve `setup_script` against `<CYCLE-FOLDER-ABS>/scripts/<setup_script>`. Defaults to `/root/projects/phi/i-phi/docs/e2e-test/cycles/t10-execute-htc-pilot-execution-0577137b` (T10-execute) for back-compat; future T-cycles supply their own.

Exit code: 0 on all-PASS, 1 on any FAIL.

Stdout: structured JSON.

```json
{
  "test_id": "HTC-0001",
  "test_class": "harness",
  "verdict": "PASS|FAIL",
  "checks": [
    {"id": "C1", "name": "frontmatter parses", "status": "PASS", "detail": ""},
    {"id": "C2", "name": "required fields populated", "status": "PASS", "detail": ""},
    ...
  ],
  "failed_count": 0,
  "passed_count": 10
}
```

## Universal checks (both HTC + TC)

| ID | Name | Predicate |
|---|---|---|
| C1 | frontmatter parses | YAML frontmatter (between two `---` lines) extracts cleanly |
| C2 | required fields populated | per-class required-field set (below) are present + non-empty |
| C3 | model-cohort open-source | `model_for_orchestration[0]` (HTC) / `models_in_scope[0]` (TC) is NOT in SOTA-closed-source deny list `^(anthropic|openai|google/gemini)/` per `[[feedback_openrouter_open_source_only]]` Rule 2 |
| C4 | setup reference resolves | `setup_script` file exists (HTC) / `setup_invocation` field present + non-empty (TC) |

## HTC-specific checks (`test_class: harness`)

| ID | Name | Predicate |
|---|---|---|
| C5 | setup writes permissions.toml | grep `setup_script` for `permissions.toml` literal |
| C6 | allow-rule per tools_invoked | each entry in `tools_invoked[]` has a matching `<tool>(*)` or `<tool>` (case-insensitive) literal in the script's `allow = [...]` array. Skip check if `deny`-test rationale documented (HTC-0001 deny path semantic) |
| C7 | tools_invoked ⊆ permissions_required + sub_agent ⇒ table | each entry of `tools_invoked[]` is listed in `permissions_required[]` (when field present); `sub-agent` in `surface_under_test` ⇒ setup writes `[[agent.sub_agents]]` block |
| C8 | workspace_dirs created | each entry of `workspace_dirs_required[]` (when field present) appears in `setup_script` via `mkdir -p` or equivalent |
| C9 | model coherence | `model_for_orchestration[0]` matches `default_model_id` literal in the setup script's credentials block |
| C10 | config_correctness_checklist present | `config_correctness_checklist[]` field present with ≥ 4 entries (HTC field; per harness-tc.md.template) |

## TC-specific checks (`test_class: model`)

| ID | Name | Predicate |
|---|---|---|
| C5' | cohort references resolve | `models_in_scope[0]` is `cohort:<name>` form OR a single model id; if cohort, the name appears to match a known cohort registry pattern |
| C6' | env_vars_required ⊆ setup_invocation | each entry in `env_vars_required[]` appears in `setup_invocation` (substring grep) OR is the canonical `OPENROUTER_TOKEN` (always implicitly available) |
| C7' | cutoffs monotonic | `fail_below ≤ partial_cutoff_floor ≤ pass_cutoff` (when all three present) |
| C8' | judge dispatch open-source-only | if rubric/judge present: judge field references `Agent(test-judge)` form, NOT an OpenRouter model id (per `[[feedback_openrouter_open_source_only]]` Rule 4) |
| C9' | rubric parses to scorable form | §5 rubric section in the TC body is present + has ≥ 1 score axis (skipped if `test_class` doesn't require rubric) |
| C10' | byte-fidelity preserved | `setup_invocation` uses `BODY=\"$(cat; echo x)\"; BODY=\"${BODY%x}\"` pattern OR the test body explicitly attests byte-fidelity preservation per D-TEST-0004 |

## Required-fields sets

**HTC** (`test_class: harness`): `tc_id`, `test_class`, `surface_under_test`, `tools_invoked`, `model_for_orchestration`, `setup_script`. NEW post-CC-07: `permissions_required`, `sub_agents_required`, `workspace_dirs_required`, `config_correctness_checklist` (added by F5 template extension).

**TC** (`test_class: model`): `tc_id`, `parent_strategy`, `parent_use_case`, `models_in_scope`, `setup_invocation`, `env_vars_required`, `primary_metric_name`, `pass_cutoff`, `partial_cutoff_floor`, `fail_below`. NEW post-CC-07: `cohort_correctness_verified`, `config_correctness_checklist` (added by F5 template extension).

## Implementation notes

- Hand-rolled YAML parser (no `pyyaml` runtime dep; matches existing `assert-htc.py` precedent + the i-phi `.claude/skills/` 100% bash convention).
- Frontmatter is extracted via `awk '/^---$/{c++; next} c==1{print}'` (line-walker between the two `---` delimiters).
- Field extraction via `grep + sed` for scalars; list extraction via `awk` state-machine over the indented `  - <item>` pattern.
- The skill is read-only on disk; no writes; idempotent.
- The skill PASS/FAIL output is deterministic given the same inputs (frontmatter + setup script bodies).

## Failure modes

- **Frontmatter not found / malformed**: emits `C1 FAIL` + abort remaining checks; output `verdict: FAIL`.
- **`test_class` field missing**: emits `C1 FAIL` (cannot dispatch class-specific checks).
- **Setup script not found**: emits `C4 FAIL` for HTC; non-blocking for TC where the field is optional.
- **Cycle folder not given + setup script not in default cycle**: emits `C4 FAIL`.

## Caller integration

Orchestrator (Claude with full conversation context) at T-cycle Phase 0 step 7.5:

```bash
for test in $(scheduled_tests); do
  bash /root/projects/phi/.claude/skills/test-preflight-validation/check.sh "${test}" "${cycle_folder}"
  status=$?
  if [[ "${status}" -ne 0 ]]; then
    echo "Cycle BLOCKED: ${test} preflight FAIL"
    exit 1
  fi
done
```

Cycle BLOCKED on any FAIL; do NOT proceed to execution with structurally-broken setup.

## References

- ADR-0006 §D6.15 (allow-rule authoring discipline) — drives C5 + C6 + C7
- ADR-0023 §D23.15 (HTC + TC setup-script class-correctness invariants) — drives the skill's overall structure
- `[[feedback_openrouter_open_source_only]]` Rule 2 + Rule 4 — drives C3 + C8'
- `[[feedback_test_setup_correctness]]` (NEW at CC-07 F5) — operator-facing reminder
- `[[feedback_test_preflight_blocks_cycle]]` (NEW at CC-07 F5) — orchestrator-side discipline
- D-TEST-0010 + D-TEST-0011 + D-TEST-0012 — the precedent failure modes this skill exists to prevent
