<!-- Last verified: 2026-05-03 by Claude Code (added log-tool-use.sh per plan tool-use-logging-and-permissions-audit-skill-18564835.md) -->

# `.claude/hooks/` — Claude Code hook scripts

Three hook scripts for the `/root/projects/phi/` project: two PreToolUse gates (deny destructive ops + scope edits) + one telemetry collector (PostToolUse / PostToolUseFailure / PermissionRequest).

Companion design docs:
- Gates: [`baby-phi/docs/specs/permissions/project-permissions-hardening-478b9384.md`](../../baby-phi/docs/specs/permissions/project-permissions-hardening-478b9384.md).
- Telemetry: [`baby-phi/docs/specs/permissions/tool-use-logging-and-permissions-audit-skill-18564835.md`](../../baby-phi/docs/specs/permissions/tool-use-logging-and-permissions-audit-skill-18564835.md).

## Files

| File | Triggers on | Purpose |
|---|---|---|
| `scope-edits.sh` | `PreToolUse` for `Edit`, `Write`, `MultiEdit` | Hard-deny edits to paths outside the union of allowed roots (project + agent/skill/memory/plan sister roots). Defense-in-depth on top of path-scoped allow rules in `settings.json`. |
| `block-destructive-bash.sh` | `PreToolUse` for `Bash` | Regex-deny destructive commands (rm -rf, sudo, git push/commit/rebase, network I/O, package installs, disk ops). Defense-in-depth on top of `permissions.deny` Bash rules in `settings.json`. |
| `log-tool-use.sh` | `PostToolUse`, `PostToolUseFailure`, `PermissionRequest` (matcher: `.*` — every tool) | Append a JSONL telemetry record per tool call to `.claude/tool-use.log`. **Never blocks the workflow** (always exits 0). Consumed by the `permissions-audit` skill at retro time. |

All wired in `settings.json` under `hooks.{PreToolUse,PostToolUse,PostToolUseFailure,PermissionRequest}`.

## How they work

Claude Code hooks receive a JSON envelope on stdin containing the tool name and inputs. Example for Bash:

```json
{
  "tool_name": "Bash",
  "tool_input": { "command": "rm -rf /tmp/foo" },
  "tool_use_id": "toolu_01...",
  "turn_index": 0
}
```

The hook script reads stdin, decides whether to block or pass through, and outputs a JSON `hookSpecificOutput` to stdout for blocking decisions:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "rm with destructive flags blocked; use Edit/Write tool or ask user explicitly."
  }
}
```

Exit code is always `0` for our scripts — we use the JSON decision channel, not exit codes (per Anthropic docs: exit 2 also blocks but exposes stderr to the user; the JSON channel is more explicit and user-friendly).

## Allowed roots (`scope-edits.sh`)

Anything under these paths is allowed; everything else is denied:

- `/root/projects/phi/**` — the project itself.
- `/root/.claude/agents/**` — agent definitions (orchestrator may update via retrospectives).
- `/root/.claude/skills/**` — skill definitions.
- `/root/.claude/projects/-root-projects-phi/memory/**` — auto-memory.
- `/root/.claude/plans/**` — plan-mode plan files.

These must stay in sync with `settings.json` allow rules + `additionalDirectories`. If you add a sister root in one, add it in both.

## Blocked patterns (`block-destructive-bash.sh`)

Each pattern is a `grep -qE` regex (POSIX extended). Adding a new pattern: append a line of the form:

```bash
echo "$COMMAND" | grep -qE 'YOUR_REGEX' && deny "REASON STRING"
```

Current blocked categories:

| Category | Pattern | Reason |
|---|---|---|
| Destructive rm | `\brm\s+-[rRfF]+` | rm with destructive flags blocked. |
| Privilege escalation | `\bsudo\b|\bsu\s` | sudo / su blocked. |
| Destructive git | `\bgit\s+(commit\|push\|reset\s+--hard\|rebase\|merge\|tag\|clean\s+-[df]\|checkout\s+--)` | User owns commit/push/rebase. |
| Network I/O | `\b(curl\|wget\|nc\|ssh\|scp\|rsync\|sftp\|telnet)\b` | Use WebFetch tool for URL access. |
| Package install | `\b(npm\|yarn\|pnpm)\s+(install\|i\|add)\b\|\bpip3?\s+install\b\|...` | User authorizes installs. |
| Disk / FS | `\bdd\s+(if\|of)=\|\bmkfs(\.|\b)\|>\s*/dev/sd[a-z]` | Disk-level ops blocked. |
| Permissive chmod | `\bchmod\s+-?R?\s*777\b` | chmod 777 blocked. |
| Destructive find | `\bfind\b.*-delete\b` | `find -delete` blocked (closes the safety gap from the blanket `Bash(find:*)` allow rule added 2026-05-04 alongside read-only utility rules). |

## Testing

Run the §11 verification recipe from the plan archive. Quick smoke tests:

```bash
# Allow path: should exit 0 with no JSON output.
echo '{"tool_name":"Edit","tool_input":{"file_path":"/root/projects/phi/baby-phi/CLAUDE.md"}}' | bash .claude/hooks/scope-edits.sh

# Deny path: should output a deny JSON + exit 0.
echo '{"tool_name":"Edit","tool_input":{"file_path":"/etc/passwd"}}' | bash .claude/hooks/scope-edits.sh

# Allow Bash: should exit 0 with no JSON output.
echo '{"tool_name":"Bash","tool_input":{"command":"echo hello"}}' | bash .claude/hooks/block-destructive-bash.sh

# Deny Bash: should output a deny JSON + exit 0.
echo '{"tool_name":"Bash","tool_input":{"command":"rm -rf /tmp/foo"}}' | bash .claude/hooks/block-destructive-bash.sh
```

After editing either script, re-run the smoke tests and (if the change is non-trivial) restart the Claude Code session so the new logic loads.

## When to update

- **Adding a new sister root** — update `scope-edits.sh` allow_match cases AND `settings.json` (allow rules + additionalDirectories).
- **Adding a new destructive Bash category** — append a `grep -qE ... && deny "..."` line to `block-destructive-bash.sh`.
- **Whitelist exception** — DO NOT add per-command exceptions in the hook. Use `settings.json` allow rules instead (precedence: deny > hook-deny > allow). The hook is a safety net, not a granular allow mechanism.

## Failure modes

- **Hook script not found** → settings.json hook config is broken; tool calls still execute (Claude Code logs the missing-hook warning). Fix the path in settings.json.
- **Hook timeout** (default 5s in settings.json) → call is treated as non-blocking failure; the call proceeds with a stderr warning. Investigate by running the script manually with the failing payload.
- **Hook script crash** → same as timeout: non-blocking failure. Run shellcheck + bats unit tests if you suspect a bug.
- **Hook outputs malformed JSON** → Claude Code logs the parse error and treats it as non-blocking. Always validate JSON output via `jq -n ...`.

---

## `log-tool-use.sh` — telemetry capture (PostToolUse + PostToolUseFailure + PermissionRequest)

**Purpose:** capture every tool call's metadata so the `permissions-audit` skill can analyze patterns at retro time. Never blocks the workflow (always exits 0).

**Wiring:** registered three times in `settings.json` (`hooks.PostToolUse` / `hooks.PostToolUseFailure` / `hooks.PermissionRequest`), each registration passing the event name as `$1`. The script differentiates events from the positional arg (schema-version-independent), with the stdin envelope's `hook_event_name` as belt-and-suspenders cross-check.

**Output schema (JSONL, one line per call):**

```json
{
  "ts": "2026-05-04T01:23:45.678Z",
  "event": "PostToolUse | PostToolUseFailure | PermissionRequest",
  "tool": "Bash | Edit | Write | MultiEdit | Read | Grep | Glob | Agent | WebFetch | ...",
  "tool_use_id": "toolu_01...",
  "turn_index": 12,
  "input_signature": "cargo:test",
  "input_full": "...",
  "outcome": "success | failure | prompted",
  "duration_ms": 8421,
  "output_summary": "...",
  "error_summary": null,
  "redacted": false,
  "version": 1
}
```

Schema versioning: `version: 1`. Bump on breaking changes; the audit skill should tolerate older versions.

**Output destination:** `.claude/tool-use.log` (gitignored — see `/root/projects/phi/.gitignore`).

**Rotation:** when the log exceeds 10 MB, rotated to `.log.1`, `.log.2`, ..., `.log.5` (oldest dropped). Override via `ROTATE_BYTES_OVERRIDE` env var for testing.

**Concurrency:** `flock -w 1` on `.claude/tool-use.log.lock` for the rotation+append critical section. On contention beyond 1s, the entry is silently skipped — never blocks the tool call.

**Redaction:** env-var assignments matching `\b(SECRET|TOKEN|PASSWORD|KEY|CREDENTIAL)[A-Z_]*=[^[:space:]]+` have their values replaced with `<redacted>`. The `redacted: true` field flags affected entries.

**Truncation:** `input_full` truncated to 1000 chars (with `…` marker). Full original input is NOT preserved.

**Self-skip:** any envelope referencing `.claude/tool-use.log*` is silently skipped (avoids meta-recursion when reading/editing the log file itself).

**Fail-safe contract:** if anything goes wrong (jq missing, flock contention, disk full, malformed envelope), the script still exits 0. Logging is best-effort; the workflow is sacred.

**Consumed by:** `.claude/skills/permissions-audit.md` at retro time. The skill reads + filters by cycle window + cross-references against `settings.json` rules + emits the §A–§H markdown report that lands in §3.5 of the cycle retrospective.

**Testing the script:**

```bash
# PostToolUse smoke
echo '{"hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"echo hi"},"tool_output":"hi","duration_ms":42,"tool_use_id":"toolu_test","turn_index":0}' \
  | bash .claude/hooks/log-tool-use.sh PostToolUse
tail -1 .claude/tool-use.log | jq .

# PostToolUseFailure smoke
echo '{"hook_event_name":"PostToolUseFailure","tool_name":"Bash","tool_input":{"command":"false"},"error":"exit 1","tool_use_id":"toolu_test_2","turn_index":0}' \
  | bash .claude/hooks/log-tool-use.sh PostToolUseFailure

# PermissionRequest smoke
echo '{"hook_event_name":"PermissionRequest","tool_name":"Bash","tool_input":{"command":"new-cmd --help"},"tool_use_id":"toolu_test_3","turn_index":0}' \
  | bash .claude/hooks/log-tool-use.sh PermissionRequest

# Redaction smoke
echo '{"hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"SECRET_TOKEN=abc123 cargo run"},"tool_output":"","duration_ms":1,"tool_use_id":"toolu_redact","turn_index":0}' \
  | bash .claude/hooks/log-tool-use.sh PostToolUse
tail -1 .claude/tool-use.log | jq '.input_full, .redacted'
# Expect: "SECRET_TOKEN=<redacted> cargo run", true
```

**When to update:**
- Add a new redaction pattern → edit the script's `grep -qE` + `sed -E` regex.
- Add a new tool that needs special signature handling → extend the `compute_signature` helper's case statement.
- Schema change → bump `version: 1 → 2` in the JSONL line; update audit skill to handle both.

---

## Future work

See plan §13 in [`project-permissions-hardening-478b9384.md`](../../baby-phi/docs/specs/permissions/project-permissions-hardening-478b9384.md) and §9 in [`tool-use-logging-and-permissions-audit-skill-18564835.md`](../../baby-phi/docs/specs/permissions/tool-use-logging-and-permissions-audit-skill-18564835.md) for the open-items lists (MCP allow rules, NotebookEdit coverage, shellcheck CI, per-cycle log slicing, trend dashboards, prompt-outcome correlation).
