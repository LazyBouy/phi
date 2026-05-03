<!-- Last verified: 2026-05-02 by Claude Code -->

# Agent + skill changelog

Records every prompt or procedure change to files under `/root/projects/phi/.claude/agents/` and `/root/projects/phi/.claude/skills/`. Each entry cites the source retrospective + the gap it closes.

Format: `YYYY-MM-DD | target | from-version → to-version | source retrospective hex | summary`.

## Entries

| Date | Target | Version | Source retro | Change |
|---|---|---|---|---|
| 2026-05-02 | (initial landing) | n/a → v1 | meta-plan `agentic-workflow/multi-agent-chunk-pipeline-0853574c.md` | First cut: 4 agents (chunk-planner / chunk-implementer / chunk-auditor / chunk-retrospector), 6 skills (phi-core-leverage-check / k8s-readiness-check / chunk-template-fill / ci-guards-run / chunk-archive-plan / audit-envelope-size) |
| 2026-05-03 | `chunk-auditor.md` | v1 → v2 | CH-11 retro `ch-11-per-session-consent-gating-d5428c43/retrospective.md` §5 row 1 | Added "Sandbox-blocked invocations" subsection. `RUSTFLAGS="-Dwarnings" cargo clippy ...` + `bash scripts/check-*.sh` are routinely sandbox-blocked from sub-agent shells; auditor must mark NOT-EXECUTED-IN-AUDIT + provide grep equivalents + defer to orchestrator's final cycle re-audit. Closes the gap from CH-11 Audit A iter 1 claims 15 + 16. |
| 2026-05-03 | `chunk-planner.md` | v1 → v2 | CH-11 retro §5 row 4 | Added "Cascade fan-out estimation" subsection. Planner MUST paste exact `git grep -n` invocation + raw matched-line count when predicting literal-struct fan-out; pause-discipline trigger expressed as `> 1.5× predicted` (percentage), not absolute count. Closes the cascade-undercount gap (CH-11 Grant: planned ~6 / actual ~28; Organization: planned ~10–15 / actual ~27). |
| 2026-05-03 | `CLAUDE.md` (×2: repo + baby-phi) | n/a (not versioned) | CH-11 retro §5 rows 2 + 5 | Two changes to "Multi-agent chunk pipeline" section: (a) gate 4 explicit MUST-RUN list (clippy + 4 CI guards) — sub-agent sandbox cannot run these; (b) Trivial FAIL split into Trivial-1L (orchestrator verifies in cycle-audit, no re-spawn) vs Trivial-multi (re-spawn auditor). Closes audit-fix-loop ambiguity from CH-11. |
| 2026-05-03 | `per-chunk-planning-template.md` | n/a (not versioned) | CH-11 retro §5 rows 3 + 6 + 7 | Three changes: (a) §10 close criteria: P4 paperwork checklist requires verified-header description matches body diff; (b) §8 tests summary: × 1.10–1.15 buffer factor for healthy implementer over-shoot, ±15% accept band at orchestrator per-phase gate; (c) §9 reading list: conditional bullet — engine-touching chunks must read launch.rs + preview.rs bodies. Closes 3 gaps from CH-11 (audit-B-claim-7 verified-header overpromise; tests-delta calibration; pre-existing M5 manifest-shape drift). |
| 2026-05-03 | `chunk-retrospector.md` | v1 → v2 | meta-plan `permissions/tool-use-logging-and-permissions-audit-skill-18564835.md` §4 | Frontmatter `skills: (none) → permissions-audit`. Added procedure step 5b that invokes the skill with cycle window + prior retros. Added new §3.5 "Permissions audit findings" section to the retrospective template (Hot candidates / Dead rules / Hook FP flags / Cross-cycle trend / Audit-driven standards updates). Added "Appendix — Permissions audit (full)" at end of template. Quality bar bumped to require all 7 sections + appendix. Length budget raised 1–4 KB → 4–10 KB. Output handoff now includes 5-line audit summary block. |
| 2026-05-03 | `permissions-audit` (skill, NEW) | n/a → v1 | meta-plan `permissions/tool-use-logging-and-permissions-audit-skill-18564835.md` §3 | New skill at `.claude/skills/permissions-audit.md`. Reads `.claude/tool-use.log` + settings.json, filters by cycle window, cross-references rules, classifies findings into 8-section markdown report (§A tool distribution, §B hot candidates, §C auto-approved, §D rule utilization, §E hook denials, §F high-frequency rejects, §G cross-cycle trends, §H standards updates). Invoked by retrospector v2 at procedure step 5b. |
| 2026-05-03 | `log-tool-use.sh` (hook, NEW) | n/a → v1 | meta-plan `permissions/tool-use-logging-and-permissions-audit-skill-18564835.md` §2 | New hook script at `.claude/hooks/log-tool-use.sh`. Wired three times in settings.json (PostToolUse / PostToolUseFailure / PermissionRequest), each registration passing the event name as `$1` for schema-version-independent differentiation. Emits JSONL to `.claude/tool-use.log` (gitignored). Features: env-var redaction (SECRET/TOKEN/PASSWORD/KEY/CREDENTIAL), 1000-char truncation, 10MB rotation (5 retained), flock-based concurrency safety with 1s timeout (skip-on-contention), self-skip on log-file references. Fail-safe: always exits 0 even on error. |

## Versioning rules

- **Bump version on**: any meaningful change to an agent's quality bar / procedure / constraints / output format, OR a skill's procedure / output format.
- **Don't bump on**: typo fixes, frontmatter description tweaks that don't change semantics.
- **Source retro required**: every bump cites the retro hex that proposed the change. If no retro proposed it (rare — emergency fix), cite "out-of-band: <reason>".
- **Coordinated bumps**: when a retro proposes changes to multiple files, list each file's bump separately on its own row, but cite the same retro hex.

## Reading the index

Most-recent first. Old entries stay; the changelog is durable history.