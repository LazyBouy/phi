---
name: permissions-audit
description: Read .claude/tool-use.log + settings.json, classify findings (hot allow-rule candidates, dead rules, hook denials, workflow issues), output a markdown report for the retrospector. Used at end-of-cycle.
version: 3
---

# permissions-audit

Analyze tool-use telemetry for a cycle window + cross-reference `settings.json` rules. Produce a markdown report with proposed standards updates that the retrospector embeds in §3.5 of the cycle retrospective.

Reference: design specifies in plan archive `baby-phi/docs/specs/permissions/tool-use-logging-and-permissions-audit-skill-18564835.md` §3.

## Inputs (caller provides)

1. **Cycle hex** — for the report header.
2. **Cycle window** — `start_ts` (ISO 8601), `end_ts` (ISO 8601). If absent, default to:
   - `start_ts = $(date -u -d "@$(stat -c %Y <cycle folder>/plan.md)" +%Y-%m-%dT%H:%M:%SZ)`
   - `end_ts = $(date -u -d "@$(stat -c %Y <cycle folder>/cycle-audit.md)" +%Y-%m-%dT%H:%M:%SZ)` (or `now` if cycle-audit not yet written).
   - Final fallback: last 7 days.
3. **Settings path** — default `$CLAUDE_PROJECT_DIR/.claude/settings.json`.
4. **Prior retros** — list of paths to prior `retrospective.md` files for §G cross-cycle trends. Default: empty (skip §G with "n/a").

## Procedure

### Step 1 — load + filter the log

```bash
LOG_PATH="${CLAUDE_PROJECT_DIR}/.claude/tool-use.log"
# Concat current + rotations.
cat "${LOG_PATH}" "${LOG_PATH}".* 2>/dev/null \
  | jq -c "select(.ts >= \"$start_ts\" and .ts <= \"$end_ts\") | .version == 1" \
  > /tmp/audit-cycle-${cycle_hex}.jsonl
```

If parsing fails on a line, skip silently (`jq -c '. // empty'`) — never block on malformed entries.

### Step 2 — aggregate

For each unique `(event, tool, input_signature)`:
- `count` (entries matching this triple)
- `first_ts`, `last_ts`
- `sample_inputs` (3 deduplicated `input_full` values, most recent first)
- `tool_use_ids` (set of tool_use_id values, for correlation)

### Step 3 — cross-reference settings.json rules

Parse `settings.json` allow + deny lists into a flat list of `(rule, action, tool_kind, pattern)`. Then for each unique `(tool, input_signature)` aggregate:

1. Pick a representative `input_full` (most recent sample).
2. Walk allow + deny rules in declaration order.
3. Match patterns per Claude Code semantics:
   - `Bash(prefix:*)` → command starts with `prefix ` (space matters).
   - `Bash(prefix *)` → equivalent to `Bash(prefix:*)`.
   - `Bash(exact)` → command equals `exact` (whitespace-trimmed).
   - `Edit(/proj-path)` → file_path matches gitignore-style `/proj-path` resolved against project root.
   - `Edit(//abs-path)` → file_path matches absolute glob.
   - `WebFetch(domain:X)` → URL host equals X.
   - `Agent(name)` → subagent_type equals `name`.
4. Record the FIRST matching rule. Per Claude Code precedence: deny > hook-deny > allow > prompt.
5. If no rule matched, classify by mode:
   - `Edit/Write/MultiEdit` to a path under working-dir or `additionalDirectories` → `auto-approved-by-mode (acceptEdits)`.
   - Anything else with no rule match → `would-prompt`.

### Step 4 — correlate PermissionRequest ↔ PostToolUse

Group entries by `tool_use_id`. For each group:
- `PermissionRequest` only → user prompted, call did not proceed (denied or abandoned).
- `PermissionRequest` + `PostToolUse` → user prompted, then approved.
- `PostToolUse` only → auto-approved (rule or mode).
- `PostToolUseFailure` only → call denied (likely by deny-rule or hook-deny).

### Step 5 — classify into report sections

- **§A Tool distribution** — count + % per `tool` value.
- **§B Hot allow-rule candidates** — input_signatures with `PermissionRequest` count ≥ 3 AND no allow-rule match. Propose a rule pattern derived from the signature (see "Proposed rule synthesis" below).
  - **Regression-protection step** (added per CH-07 retro §5 row 7, cycle hex `cc912d07`): when prior-retro input lists a hot-allow-rule candidate that had a standards update applied (e.g., a settings.json rule added or refined), verify in the current cycle that PermissionRequest count for that signature is **0**. If non-zero, escalate as **`rule-pattern-failed-validation`** in §B with **high priority** + propose a refined rule pattern. Rationale: CH-07 caught the bash-check rule's continued failure post-CH-13-rule-addition (3 prompts despite the rule existing) — empirically the matcher's `*` glob in space-form patterns doesn't span the `2>&1 | tail -N` redirect+pipe combo. Surfacing rule-validation failures as a high-priority §B finding ensures the next cycle catches the gap rather than re-discovering it cycle-after-cycle. See `baby-phi/docs/specs/permissions/granular-bash-discipline-ab19399b.md` §2.4 for the empirical-quirk record.
  - **Matcher-semantics-investigation escalation** (added per CH-08 retro §5 row 7, cycle hex `7cbe74a4`): when a hot-allow-rule signature persists across **≥ 2 cycles** post-standards-update (i.e., the rule was added, then retro N+1 found regression, then retro N+2 still finds it), escalate the finding from `rule-pattern-failed-validation` to **`matcher-semantics-investigation`** with **highest priority**. The next standards update MUST include an **empirical test-harness step** before the rule is committed: (a) propose a candidate rule pattern; (b) run representative invocations matching the hot signature against a test settings.json carrying the candidate; (c) capture post-edit telemetry to confirm 0 PermissionRequest fires; (d) only then commit. Rationale: CH-08 caught the bash-check cluster regressing 3 cycles in a row (CH-13 → CH-07 → CH-08) despite two prior rule-pattern fixes — the matcher's `*.sh` glob interpretation is not what the rule-author expected. Skipping empirical validation re-introduces the same bug. See `baby-phi/docs/specs/permissions/granular-bash-discipline-ab19399b.md` §2.5 for the 3-cycle-pattern record + recommended workaround (literal script names OR drop the prefix-glob).
  - **Matcher-bug-confirmed escalation** (added per CH-14 retro §5 row 7, cycle hex `5803bb94`): when a hot-allow-rule signature persists across **≥ 3 cycles post-standards-update** despite multiple rule-pattern revisions, escalate from `matcher-semantics-investigation` to **`matcher-bug-confirmed`** with **highest priority + STOP-iterating-the-rule-pattern**. The retrospector MUST: (a) capture an isolated reproducer (rule + invocation pair) demonstrating the matcher mismatch; (b) file an upstream Claude Code rule-matcher bug-report (link the reproducer); (c) document the root cause + workaround in `baby-phi/docs/specs/permissions/granular-bash-discipline-ab19399b.md`; (d) propose a behaviourally-equivalent literal-script-name workaround OR a script-refactor that sidesteps the matcher quirk entirely (e.g., consolidate multi-stage pipelines into a single shell script). **Cross-cycle PermissionRequest trend-analysis fairness rule**: once a cluster is at `matcher-bug-confirmed`, the next cycle's permissions-audit MUST mark it as `external-bug-pending` and **subtract** it from the cross-cycle PermissionRequest count for trend reporting (otherwise the upstream-bug-tied prompts mask genuine workflow regressions). Rationale: CH-14 caught the bash-check cluster regressing **4 cycles in a row** (CH-13 → CH-07 → CH-08 → CH-14) despite two prior rule-pattern fixes — the matcher's `*.sh` glob interpretation is empirically not addressable from inside settings.json patterns. Iterating further on the rule pattern wastes a cycle slot per attempt. See granular-bash-discipline-ab19399b.md §2.6 for the 4-cycle data series + recommended workaround.
  - **Resolved-via-workaround terminal state** (added per CH-15 retro §5 row 8, cycle hex `c3f46f17`): when a `matcher-bug-confirmed` cluster's PermissionRequest count drops to **0 for ≥ 1 cycle post-workaround-commit**, downgrade the classification from `matcher-bug-confirmed` → **`resolved-via-workaround`**. The retrospector MUST: (a) record the validation cycle's prompt count (0); (b) update `granular-bash-discipline-ab19399b.md` with the validation data point + the new lifecycle state; (c) **drop the cluster from cross-cycle trend tracking** (it is no longer noise — keeping it inflates trend reports with permanently-zero rows). **No upstream Claude Code rule-matcher bug-report is needed** when this state is reached — the workaround empirically closes the gap without requiring upstream changes. **Regression handling**: if a future cycle's permissions-audit finds the cluster prompts > 0 again post-workaround, re-elevate to `matcher-bug-confirmed` and file the upstream bug-report at that point (the workaround failed under new conditions). Rationale: CH-15 was the first cycle to run under CH-14's 5 literal-script-name rules; bash-check cluster prompts dropped from 43 (CH-14) → 0 (CH-15), validating the workaround empirically. Without a terminal state, perpetual `external-bug-pending` markers accrete on resolved clusters.
- **§C Auto-approved (mode-driven)** — input_signatures decided by `acceptEdits` mode without explicit rule. Visibility-only.
- **§D Allow-rule utilization** — every allow rule from settings.json with hit count this cycle. Rules with 0 hits flagged "unused this cycle". After ≥ 3 consecutive cycles of zero hits (requires prior-retro input), flag as "removal candidate".
- **§E Hook denials** — entries with `event=PostToolUseFailure` AND `error_summary` contains "scope-edits hook" or "block-destructive-bash hook". Group by hook name + reason. Apply false-positive heuristic (see "Heuristics" below).
- **§F High-frequency rejected patterns** — input_signatures denied ≥ 5×. Workflow issue.
- **§G Cross-cycle trends** — if prior retros provided, extract their headline metrics + tabulate deltas.
- **§H Skill findings + proposed standards updates** — actionable list synthesized from §B / §D / §E / §F.

### Step 6 — emit markdown to stdout

Per the output template (next section).

## Heuristics

- **Hot candidate threshold**: PermissionRequest count ≥ 3 AND zero allow-rule matches AND zero auto-approve-by-mode for the same signature.
- **Dead rule policy**: zero hits this cycle = "unused this cycle". Removal candidate ONLY after ≥ 3 consecutive cycles. Without prior-retro data, mark "unused" (informational); never propose removal blindly.
- **False-positive hook denial flag**: same input_signature denied ≥ 2 times within 60 seconds → "yes (likely test/verification — review)". Otherwise default "no" unless other signal present.
- **High-frequency reject**: same input_signature denied ≥ 5 times in cycle. Output suggests reviewing the workflow that's repeatedly attempting the blocked operation, not adding an allow rule.

## Proposed rule synthesis

For Bash signatures of form `prog:firstarg`:
- If `prog` is a well-known CLI (`cargo`, `git`, `npm`, etc.), propose `Bash(prog firstarg:*)` (subcommand-scoped).
- Else propose `Bash(prog:*)` (program-scoped).

For Edit/Write/Read signatures of form `/path/segment1/segment2/...`:
- Propose `Edit(/path/segment1/segment2/**)` or absolute `Edit(//path/segment1/segment2/**)` based on whether the path is project-relative or absolute.

For WebFetch:
- Propose `WebFetch(domain:<extracted host>)`.

Always cite the proposed rule in valid Claude Code rule syntax (per the §3 reference in the prior plan).

## Output template

```markdown
# Permissions Audit — Cycle <hex>

**Window:** <start ISO> → <end ISO> (UTC)
**Total tool calls observed:** <N>
**Total unique input_signatures:** <M>
**Log file size:** <bytes> (across <K> files: current + <K-1> rotations)

## §A — Tool distribution
> Share of total tool calls captured in the cycle window. Helps spot anomalies.

| Tool | Calls | % of total |
|---|---|---|

## §B — Hot allow-rule candidates (≥ 3 prompts in cycle, no rule match)
> Patterns the user was prompted for ≥ 3 times — likely missing allow rules.

| Pattern | Prompts | First seen | Sample input | Proposed rule |
|---|---|---|---|---|

## §C — Auto-approved by mode (visibility only)

| Tool | Pattern | Count | Notes |
|---|---|---|---|

## §D — Allow-rule utilization

| Rule | Hits | Status |
|---|---|---|

## §E — Hook denials (review for false-positives)

| Hook | Pattern | Count | Sample reason | False-positive? |
|---|---|---|---|---|

## §F — High-frequency rejected patterns (workflow issue, not rule issue)

| Pattern | Reject count | Likely cause |
|---|---|---|

## §G — Cross-cycle trends

| Metric | 2 cycles ago | 1 cycle ago | This cycle | Δ vs prior |
|---|---|---|---|---|

## §H — Skill findings + proposed standards updates

> Roll these into the retrospective's §5 Standards updates table.

1. ...
2. ...

---
*Generated by `.claude/skills/permissions-audit.md` v1 from `.claude/tool-use.log`.*
```

## Quality bar

- All sections §A–§H present (with "(none this cycle)" rows when empty).
- Every "Proposed rule" cell shows valid Claude Code rule syntax.
- Every "False-positive?" cell has yes / no / unclear classification + one-line rationale.
- Cross-cycle table populated with available data; cells marked "n/a" when prior cycle data missing.
- Proposed standards updates in §H cite the originating section (§B row #, §D rule, §E pattern).

## Failure modes

- **Log file empty / missing** → emit a minimal report: "no telemetry data for this window. (Likely first cycle under telemetry, or the hook didn't fire.)" Skip §A–§F; populate §G only if prior retros provided.
- **settings.json malformed** → emit warning at top of report; proceed without rule cross-reference (§D becomes "(unable to parse settings.json)").
- **Prior retros missing** → §G gets "n/a (no prior retros provided)" row.

## Reference

- Hook script: `.claude/hooks/log-tool-use.sh` — JSONL emitter, schema v1.
- Settings rules + defaultMode: `.claude/settings.json` — read-only by this skill.
- Plan archive: `baby-phi/docs/specs/permissions/tool-use-logging-and-permissions-audit-skill-18564835.md`.
- Companion plan archive: `baby-phi/docs/specs/permissions/project-permissions-hardening-478b9384.md` (the rule + hook layer this skill audits).