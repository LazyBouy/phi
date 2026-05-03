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

## Versioning rules

- **Bump version on**: any meaningful change to an agent's quality bar / procedure / constraints / output format, OR a skill's procedure / output format.
- **Don't bump on**: typo fixes, frontmatter description tweaks that don't change semantics.
- **Source retro required**: every bump cites the retro hex that proposed the change. If no retro proposed it (rare — emergency fix), cite "out-of-band: <reason>".
- **Coordinated bumps**: when a retro proposes changes to multiple files, list each file's bump separately on its own row, but cite the same retro hex.

## Reading the index

Most-recent first. Old entries stay; the changelog is durable history.