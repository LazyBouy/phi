<!-- Last verified: 2026-05-03 by Claude Code -->

# `.claude/hooks/` — Claude Code PreToolUse hooks

Two hook scripts that gate tool calls for the `/root/projects/phi/` project. They run **before** every Bash / Edit / Write / MultiEdit invocation and can deny the call with an explicit reason.

Companion design doc: [`baby-phi/docs/specs/permissions/project-permissions-hardening-478b9384.md`](../../baby-phi/docs/specs/permissions/project-permissions-hardening-478b9384.md).

## Files

| File | Triggers on | Purpose |
|---|---|---|
| `scope-edits.sh` | `PreToolUse` for `Edit`, `Write`, `MultiEdit` | Hard-deny edits to paths outside the union of allowed roots (project + agent/skill/memory/plan sister roots). Defense-in-depth on top of path-scoped allow rules in `settings.json`. |
| `block-destructive-bash.sh` | `PreToolUse` for `Bash` | Regex-deny destructive commands (rm -rf, sudo, git push/commit/rebase, network I/O, package installs, disk ops). Defense-in-depth on top of `permissions.deny` Bash rules in `settings.json`. |

Both are wired in `settings.json` under `hooks.PreToolUse`.

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

## Future work

See plan §13 in [`project-permissions-hardening-478b9384.md`](../../baby-phi/docs/specs/permissions/project-permissions-hardening-478b9384.md) for the open items list (PostToolUse telemetry, MCP allow rules, NotebookEdit coverage, shellcheck CI, retrospective revisit).
