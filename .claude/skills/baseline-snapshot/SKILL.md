---
name: baseline-snapshot
description: Snapshot the workspace baseline counts at plan-draft / gate-1.5 time — test count, phi-core import count, and numeric citations (struct fields, enum variants, route counts) that the plan body cites. Outputs JSON for downstream consumers. Project-aware via PROJECT_ROOT. Replaces 3 duplicate ad-hoc grep sites (chunk-planner v17 P3 test-count + v19 P4 import-count + outer CLAUDE.md P-orch-3 numeric-citation).
---

# baseline-snapshot

Single-source-of-truth baseline snapshot at plan-draft + gate-1.5 archival time. Captures (a) workspace test count, (b) phi-core import count, (c) numeric-citation grounded values for struct-field-counts + enum-variant-counts + route-counts. Downstream consumers (planner §3 / §6 / §8 + orchestrator gate-1.5 numeric-citation cross-check) read the JSON.

## Why this skill exists

3 prior sites duplicated baseline-extraction logic:
- chunk-planner v17 P3 — carry-forward test-name grep
- chunk-planner v19 P4 — baseline-import-count grep
- outer CLAUDE.md gate-1.5 P-orch-3 — numeric-citation cross-check (test count + struct-field axis)

All three perform variations of `grep -rn 'use phi_core'` + `cargo test --no-run` + struct-field counts against the same source tree. Consolidating into one skill (a) eliminates drift between the variants, (b) produces stable JSON output any caller can read, (c) keeps the cross-references for new axes (route counts, enum variant counts, utoipa path counts) in one place.

## Inputs (caller provides)

1. **PROJECT_ROOT** — `/root/projects/phi/baby-phi` (default) or `/root/projects/phi/i-phi` or `/root/projects/phi/phi-core`. Path layout + cargo manifest path resolved from this.
2. **Citation list** (optional) — array of `{kind, target}` pairs from the plan body that need grounding. Example:
   - `{kind: "struct-field-count", target: "SessionHandle"}` → grep `pub struct SessionHandle` body for pub field lines.
   - `{kind: "enum-variant-count", target: "Composite"}` → count enum variants.
   - `{kind: "route-count", target: "axum_router"}` → count `.route(` invocations.
3. **Mode** (optional, default `full`) — `full` (all axes) / `test-only` / `import-only` / `citations-only`. Allows callers to skip expensive axes.

## Procedure

### Axis A — Workspace test count

```bash
/root/rust-env/cargo/bin/cargo test --manifest-path $PROJECT_ROOT/Cargo.toml --workspace --no-run 2>&1 | tail -3
```

Parse `n binaries with N tests` plus inline test counts. Emit as `{binary_tests: <N>, inline_tests: <M>, total: <N + M>}`. For projects without a `Cargo.toml` at PROJECT_ROOT (e.g., outer phi monorepo), skip axis A + emit `null`.

### Axis B — phi-core import count

```bash
grep -rn "^use phi_core" $PROJECT_ROOT/src/ $PROJECT_ROOT/tests/ 2>/dev/null | wc -l
```

Plus a per-file breakdown to support **leverage-sites** counting (preferred over raw import-lines per chunk-planner v20 P4):

```bash
grep -rln "^use phi_core" $PROJECT_ROOT/src/ $PROJECT_ROOT/tests/ 2>/dev/null
```

Emit `{import_lines: <N>, leverage_sites: <M>, per_file: [{path, lines}, ...]}`.

### Axis C — Numeric citation grounding (struct-field / enum-variant / route counts)

For each `{kind, target}` in the citation list:

- **struct-field-count**: `grep -A 50 '^pub struct <target>' $PROJECT_ROOT/src/**/*.rs | grep -E '^\s+pub ' | wc -l` (50-line lookahead window is heuristic; tune per target if needed).
- **enum-variant-count**: `grep -A 100 '^pub enum <target>' $PROJECT_ROOT/src/**/*.rs | grep -cE '^\s+[A-Z][A-Za-z0-9]*'`.
- **route-count**: `grep -cE '\.route\(' $PROJECT_ROOT/src/**/*.rs` (target unused — global axum-route count).
- **utoipa-path-count**: `grep -cE '#\[utoipa::path\(' $PROJECT_ROOT/src/**/*.rs`.

Emit per-citation `{kind, target, actual, source_file: <first match>}`.

## Output format (JSON)

```json
{
  "project_root": "/root/projects/phi/i-phi",
  "timestamp": "2026-05-26T...",
  "axis_a_test_count": {"binary_tests": 245, "inline_tests": 50, "total": 295},
  "axis_b_import_count": {"import_lines": 56, "leverage_sites": 23, "per_file": [{"path": "src/foo.rs", "lines": 3}]},
  "axis_c_numeric_citations": [
    {"kind": "struct-field-count", "target": "SessionHandle", "actual": 13, "source_file": "src/daemon/sessions/handle.rs"},
    {"kind": "enum-variant-count", "target": "SlashCommand", "actual": 6, "source_file": "src/repl/commands.rs"}
  ]
}
```

Console output (for human inspection):

```
baseline-snapshot:
  Project: <PROJECT_ROOT>
  Test count: <N> (binary <B> + inline <I>)
  Import count: <N> lines / <M> leverage-sites
  Numeric citations grounded: <K>/<K>
  Mismatches vs plan body (if comparison invoked): <list>

  Output JSON: <path or stdout>
  Verdict: ✅ snapshot clean | ⚠ <N> citations diverge from plan
```

## Caller integration

- **chunk-planner v17 P3 + v19 P4**: invoke at plan §3 / §8 draft time. Use `axis_a_test_count.total` for §8 baseline + decomposition (per v30 P-plan-9-v30 binary+inline split). Use `axis_b_import_count.leverage_sites` for §3 prediction. Use citation list for §6 carry-forward grounding.
- **orchestrator gate-1.5 P-orch-3**: invoke immediately before `chunk-archive-plan`. Diff the snapshot against plan body §1/§6 numeric citations; flag mismatches as Trivial-1L plan-edit BEFORE archive.
- **chunk-implementer v15 P-impl-3 (P-SEAL test-count reconciliation)**: optionally re-invoke at P-SEAL to compare actual-vs-predicted per-Tier.

## Quality bar

- JSON output is well-formed + parseable.
- Cargo invocation completes within 60s (use `--no-run` to avoid full test execution).
- Per-citation grep windows are documented; ambiguous targets surface as `actual: null + reason` so callers can investigate.
- Project-agnostic body — operates uniformly on baby-phi + i-phi + phi-core.

## Reference

- chunk-planner v17 P3 — carry-forward test-name grep (origin of axis A).
- chunk-planner v19 P4 — baseline-import-count grep (origin of axis B).
- chunk-planner v20 P4 — leverage-sites methodology (refines axis B per-file aggregation).
- chunk-planner v30 P-plan-9-v30 — §8 baseline binary+inline decomposition (informs axis A output shape).
- chunk-planner v31 P-plan-13-v31 (planner-side struct-field snapshot) + outer CLAUDE.md P-orch-3 extended scope (CH-11a retro proposal #7) — axis C struct-field cross-check origin.
- discipline-archive.md `#ch-05-i-phi-pre-archival-quartet-evidence` (numeric citation drift narrative).
- discipline-archive.md `#ch-11a-i-phi-literal-count-axis-crystallization` (literal-count axis crystallization).