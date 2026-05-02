<!-- Last verified: 2026-05-02 by Claude Code -->

# Agent + skill changelog

Records every prompt or procedure change to files under `/root/projects/phi/.claude/agents/` and `/root/projects/phi/.claude/skills/`. Each entry cites the source retrospective + the gap it closes.

Format: `YYYY-MM-DD | target | from-version → to-version | source retrospective hex | summary`.

## Entries

| Date | Target | Version | Source retro | Change |
|---|---|---|---|---|
| 2026-05-02 | (initial landing) | n/a → v1 | meta-plan `agentic-workflow/multi-agent-chunk-pipeline-0853574c.md` | First cut: 4 agents (chunk-planner / chunk-implementer / chunk-auditor / chunk-retrospector), 6 skills (phi-core-leverage-check / k8s-readiness-check / chunk-template-fill / ci-guards-run / chunk-archive-plan / audit-envelope-size) |

## Versioning rules

- **Bump version on**: any meaningful change to an agent's quality bar / procedure / constraints / output format, OR a skill's procedure / output format.
- **Don't bump on**: typo fixes, frontmatter description tweaks that don't change semantics.
- **Source retro required**: every bump cites the retro hex that proposed the change. If no retro proposed it (rare — emergency fix), cite "out-of-band: <reason>".
- **Coordinated bumps**: when a retro proposes changes to multiple files, list each file's bump separately on its own row, but cite the same retro hex.

## Reading the index

Most-recent first. Old entries stay; the changelog is durable history.