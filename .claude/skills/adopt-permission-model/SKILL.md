# adopt-permission-model

A portable, self-contained instruction for any Claude Code agent in any project to adopt the phi-project permission model (`settings.json` + 3 hooks + telemetry) and customize it for that project.

This file is BOTH a slash-command skill in the phi project AND a stand-alone instruction package. Copy-paste it (or just this file) into another project's `.claude/skills/` and it will work there with no inter-project dependencies — every template is embedded inline below.

---

## Who this is for

You are a Claude Code agent operating in some **target project** that needs disciplined, low-friction permissions. The user has pointed you here because the phi project's setup has converged through ~7 months of multi-cycle iteration on a few load-bearing principles:

1. **`defaultMode: "dontAsk"`** — the agent does NOT prompt the user on every tool call. The permission surface is governed by allow/deny rules + 2 PreToolUse hook gates.
2. **User owns destructive ops** (`git commit/push/rebase`, `rm -rf`, package installs, network I/O). The agent NEVER mutates remote state without explicit user invocation.
3. **Defense-in-depth**: every deny is encoded BOTH as a rule in `settings.json` (declarative) AND as a regex in `block-destructive-bash.sh` (procedural). If a rule slips, the hook still catches.
4. **Scope-restricted edits** — `Edit/Write/MultiEdit` are restricted to the project + a small set of sister roots (agent/skill/memory/plan paths under `~/.claude/`). The hook hard-denies any edit outside those roots.
5. **Full telemetry, never blocking** — every tool call is appended to a JSONL log (`PostToolUse + PostToolUseFailure + PermissionRequest`) with redaction + rotation + lock-protected appends. The log is consumed by a per-cycle audit skill that proposes new allow rules.
6. **Granular Bash discipline** — one logical operation per Bash call. Multi-stage pipelines, `&&` chains, and `cd <abs> && <cmd>` compounds all break allow-rule matching. The model enforces this by NOT allow-listing compound shapes; the agent learns to write granular calls naturally.

You will: install the model, run the smoke tests, then **customize 3 extension points** (allow rules, edit-scope roots, redaction patterns) for the target project.

---

## What you will produce

When you finish:

```
<target-project>/.claude/
├── settings.json                       # NEW — adopted + customized
├── settings.local.json                 # OPTIONAL — local overrides (gitignored)
├── hooks/
│   ├── README.md                       # NEW — explains the 3 hooks
│   ├── scope-edits.sh                  # NEW — PreToolUse for Edit/Write/MultiEdit
│   ├── block-destructive-bash.sh       # NEW — PreToolUse for Bash
│   └── log-tool-use.sh                 # NEW — telemetry capture
├── tool-use.log                        # GENERATED at first tool call (gitignored)
└── .gitignore                          # UPDATED — adds tool-use.log* + settings.local.json
```

Plus one update to the target project's root `.gitignore` (covers `.claude/tool-use.log*`).

---

## Step-by-step procedure

Work through these in order. Do NOT skip the verification at each step — silent breakage in the permission model is hard to debug later.

### Step 0 — Inputs you need from the user

Before writing any files, gather:

| Input | Used for | Example |
|---|---|---|
| **Target project root** (absolute path) | `additionalDirectories` + edit-scope hook + allow-rule path literals | `/home/alice/work/foobar` |
| **Build/test toolchain** | Cargo/npm/pip/etc. allow rules | `cargo`, `pnpm`, `pytest` |
| **CI guard scripts** (if any) | Allow-list for `bash scripts/check-*.sh` etc. | `scripts/check-lint.sh` |
| **Sister roots** (optional) | Extra paths the agent can edit (e.g., shared agent registry, memory dir) | `/home/alice/.claude/agents` |
| **GitHub/remote workflows** (yes/no) | Whether to allow `bash /path/gh-rest.sh *` style wrappers | "yes, via `gh` CLI" |
| **WebFetch domains** the agent legitimately needs | `WebFetch(domain:...)` allow rules | `docs.python.org`, `github.com` |

If any are unknown, ask the user before proceeding. Don't guess defaults — the goal is a tight, custom-fitted policy, not a generic one that prompts on everything.

### Step 1 — Create `.claude/hooks/` directory and write the 3 hook scripts verbatim

Each script below is a load-bearing safety net. Do NOT modify the logic during initial install — only customize the CALL-OUT extension points marked `# CUSTOMIZE:`. You can iterate later once the smoke tests pass.

#### 1a. `scope-edits.sh`

```bash
#!/bin/bash
# .claude/hooks/scope-edits.sh — PreToolUse for Edit / Write / MultiEdit.
# Hard-deny edits to paths outside the allowed roots.

set -euo pipefail

PAYLOAD=$(cat)
TOOL_NAME=$(echo "$PAYLOAD" | jq -r '.tool_name // ""')
FILE_PATH=$(echo "$PAYLOAD" | jq -r '.tool_input.file_path // .tool_input.path // ""')

[[ -z "$FILE_PATH" ]] && exit 0

# Normalize: leading "//" → "/" for consistent matching.
PATH_NORM="${FILE_PATH#//}"
PATH_NORM="/${PATH_NORM#/}"

allow_match() {
  case "$1" in
    # CUSTOMIZE: list each allowed edit root below as a `case` arm.
    # Match using shell-glob: `<path>/*` matches anything inside that root.
    # MUST keep in sync with settings.json `permissions.additionalDirectories`
    # and the Edit/Write/MultiEdit allow rules.
    <TARGET_PROJECT_ROOT>/*) return 0 ;;
    /root/.claude/agents/*) return 0 ;;
    /root/.claude/skills/*) return 0 ;;
    /root/.claude/plans/*) return 0 ;;
    # Add: memory dir, sibling project shared roots, etc.
  esac
  return 1
}

if allow_match "$PATH_NORM"; then
  exit 0
fi

jq -n --arg path "$PATH_NORM" --arg tool "$TOOL_NAME" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: ("scope-edits hook: " + $tool + " to " + $path + " is outside the allowed project + sister roots.")
  }
}'
exit 0
```

**Customize**: replace `<TARGET_PROJECT_ROOT>` with the absolute path. Add `case` arms for every sister root the user listed (Step 0).

#### 1b. `block-destructive-bash.sh`

```bash
#!/bin/bash
# .claude/hooks/block-destructive-bash.sh — PreToolUse for Bash.
# Defense-in-depth: regex-deny destructive bash even if rules slip through.

set -euo pipefail

PAYLOAD=$(cat)
TOOL_NAME=$(echo "$PAYLOAD" | jq -r '.tool_name // ""')
COMMAND=$(echo "$PAYLOAD" | jq -r '.tool_input.command // ""')

[[ "$TOOL_NAME" != "Bash" ]] && exit 0
[[ -z "$COMMAND" ]] && exit 0

deny() {
  jq -n --arg cmd "$COMMAND" --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: ("block-destructive-bash hook: " + $reason + " Command: " + $cmd)
    }
  }'
  exit 0
}

# Destructive rm
echo "$COMMAND" | grep -qE '\brm\s+-[rRfF]+' && deny "rm with destructive flags blocked; use Edit/Write tool or ask user explicitly."
# Privilege escalation
echo "$COMMAND" | grep -qE '\bsudo\b|\bsu\s' && deny "Privilege escalation blocked."
# Git destructive (user owns these)
echo "$COMMAND" | grep -qE '\bgit\s+(commit|push|reset\s+--hard|rebase|merge|tag|clean\s+-[df]|checkout\s+--)' && deny "Destructive git operation blocked; user owns commit/push/rebase."
# Network I/O
echo "$COMMAND" | grep -qE '\b(curl|wget|nc|ssh|scp|rsync|sftp|telnet)\b' && deny "Network I/O blocked; use WebFetch tool for URL access."
# Package install — anchored on COMMAND POSITION (start of command after VAR=val
# env-assignments), NOT substring. So `grep "npm install"` is not blocked.
INSTALL_CMD="$(echo "$COMMAND" | sed -E 's/^([[:space:]]*[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]+[[:space:]]+)+//')"
echo "$INSTALL_CMD" | grep -qE '^(npm|yarn|pnpm)[[:space:]]+(install|i|add)\b|^pip3?[[:space:]]+install\b|^brew[[:space:]]+(install|uninstall)\b|^(apt|apt-get)[[:space:]]+(install|remove)\b|^dpkg[[:space:]]+-i\b|^cargo[[:space:]]+install\b' && deny "Package install blocked; user authorizes installs in their terminal."
# Disk / filesystem
echo "$COMMAND" | grep -qE '\bdd\s+(if|of)=|\bmkfs(\.|\b)|>\s*/dev/sd[a-z]' && deny "Disk-level operation blocked."
# Permissive chmod
echo "$COMMAND" | grep -qE '\bchmod\s+-?R?\s*777\b' && deny "chmod 777 blocked."
# find -delete (blanket `Bash(find:*)` allow rule has this safety gap)
echo "$COMMAND" | grep -qE '\bfind\b.*-delete\b' && deny "find -delete blocked; use rm via the Edit/Write tool or ask the user explicitly."

# CUSTOMIZE: add target-project-specific deny patterns here.
# Examples:
#   echo "$COMMAND" | grep -qE '\bterraform\s+(apply|destroy)\b' && deny "terraform mutates real infra; user owns."
#   echo "$COMMAND" | grep -qE '\bkubectl\s+(delete|apply|patch)\b' && deny "kubectl mutation blocked; user owns."
#   echo "$COMMAND" | grep -qE '\baws\s+s3\s+rm\b' && deny "aws s3 rm blocked."

exit 0
```

**Customize**: leave the canonical 8 patterns as-is, then add target-project-specific ones at the bottom marker. Don't loosen the canonical ones unless the user explicitly directs.

#### 1c. `log-tool-use.sh`

```bash
#!/bin/bash
# .claude/hooks/log-tool-use.sh — PostToolUse / PostToolUseFailure / PermissionRequest.
# Append a JSONL telemetry record per tool call. Never blocks the workflow.
#
# Wired three times in settings.json, once per event, each passing the event name as $1.

set -uo pipefail   # NOT set -e: per fail-safe contract.

LOG_PATH="${CLAUDE_PROJECT_DIR:-$(pwd)}/.claude/tool-use.log"
LOCK_PATH="${LOG_PATH}.lock"
ROTATE_BYTES="${ROTATE_BYTES_OVERRIDE:-$((10 * 1024 * 1024))}"  # 10 MB
KEEP_ROTATIONS=5

compute_signature() {
  local tool="$1" input="$2"
  case "$tool" in
    Bash)
      local cmd first_word first_arg
      cmd=$(echo "$input" | awk '{$1=$1; print}')
      first_word=$(echo "$cmd" | awk '{print $1}')
      first_arg=$(echo "$cmd" | awk '{for(i=2;i<=NF;i++) if(substr($i,1,1)!="-") {print $i; exit}}')
      echo "${first_word##*/}:${first_arg:0:50}"
      ;;
    Edit|Write|MultiEdit|Read|NotebookEdit)
      echo "$input" | awk -F/ '{out=""; for(i=1;i<=NF && i<=5;i++) out=out (i>1?"/":"") $i; print out (NF>5?"/...":"")}'
      ;;
    Grep|Glob)
      echo "${input:0:80}"
      ;;
    Agent|WebFetch)
      echo "$input" | head -c 80
      ;;
    *)
      echo "${tool}:${input:0:50}"
      ;;
  esac
}

PAYLOAD=$(cat 2>/dev/null || echo '{}')

# Self-skip: don't log calls that touch the log file itself (avoid recursion).
case "$PAYLOAD" in
  *tool-use.log*) exit 0 ;;
esac

EVENT="${1:-unknown}"
ENVELOPE_EVENT=$(echo "$PAYLOAD" | jq -r '.hook_event_name // .event_name // empty' 2>/dev/null || echo "")
if [[ -n "$ENVELOPE_EVENT" && "$ENVELOPE_EVENT" != "$EVENT" ]]; then
  echo "log-tool-use.sh: event mismatch — arg=$EVENT, envelope=$ENVELOPE_EVENT (trusting arg)" >&2
fi

TOOL=$(echo "$PAYLOAD" | jq -r '.tool_name // ""' 2>/dev/null || echo "")
TOOL_USE_ID=$(echo "$PAYLOAD" | jq -r '.tool_use_id // ""' 2>/dev/null || echo "")
TURN_INDEX=$(echo "$PAYLOAD" | jq -r '.turn_index // 0' 2>/dev/null || echo "0")
DURATION_MS=$(echo "$PAYLOAD" | jq -r '.duration_ms // null' 2>/dev/null || echo "null")

INPUT_FULL=$(echo "$PAYLOAD" | jq -r '
  if .tool_input.command then .tool_input.command
  elif .tool_input.file_path then .tool_input.file_path
  elif .tool_input.path then .tool_input.path
  elif .tool_input.pattern then .tool_input.pattern
  elif .tool_input.url then .tool_input.url
  elif .tool_input.subagent_type then ("Agent(" + .tool_input.subagent_type + "): " + (.tool_input.description // ""))
  else (.tool_input | tojson)
  end // ""
' 2>/dev/null || echo "")

# CUSTOMIZE: redaction patterns. Default covers SECRET/TOKEN/PASSWORD/KEY/CREDENTIAL.
# Add target-project-specific secret-name patterns here if needed (e.g. STRIPE_KEY,
# DATABASE_URL, etc.). Keep the alternation form for performance.
REDACTED=false
if echo "$INPUT_FULL" | grep -qE '\b(SECRET|TOKEN|PASSWORD|KEY|CREDENTIAL)[A-Z_]*=[^[:space:]]+'; then
  INPUT_FULL=$(echo "$INPUT_FULL" | sed -E 's/\b(SECRET|TOKEN|PASSWORD|KEY|CREDENTIAL)([A-Z_]*)=[^[:space:]]+/\1\2=<redacted>/g')
  REDACTED=true
fi

if [[ ${#INPUT_FULL} -gt 1000 ]]; then
  INPUT_FULL="${INPUT_FULL:0:1000}…"
fi

INPUT_SIGNATURE=$(compute_signature "$TOOL" "$INPUT_FULL")

case "$EVENT" in
  PostToolUse) OUTCOME=success ;;
  PostToolUseFailure) OUTCOME=failure ;;
  PermissionRequest) OUTCOME=prompted ;;
  *) OUTCOME=unknown ;;
esac

OUTPUT_SUMMARY=$(echo "$PAYLOAD" | jq -r '.tool_output // ""' 2>/dev/null | head -c 200 | tr '\n' ' ' | sed 's/[[:space:]]*$//')
ERROR_SUMMARY=$(echo "$PAYLOAD" | jq -r '.error // .tool_error // ""' 2>/dev/null | head -c 200 | tr '\n' ' ' | sed 's/[[:space:]]*$//')

LINE=$(jq -nc \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)" \
  --arg event "$EVENT" \
  --arg tool "$TOOL" \
  --arg tool_use_id "$TOOL_USE_ID" \
  --argjson turn "$TURN_INDEX" \
  --arg sig "$INPUT_SIGNATURE" \
  --arg input "$INPUT_FULL" \
  --arg outcome "$OUTCOME" \
  --argjson duration "$DURATION_MS" \
  --arg out "$OUTPUT_SUMMARY" \
  --arg err "$ERROR_SUMMARY" \
  --argjson redacted "$REDACTED" \
  '{ts:$ts, event:$event, tool:$tool, tool_use_id:$tool_use_id, turn_index:$turn,
    input_signature:$sig, input_full:$input, outcome:$outcome,
    duration_ms:$duration, output_summary:$out, error_summary:$err,
    redacted:$redacted, version:1}' 2>/dev/null) || exit 0

[[ -z "$LINE" ]] && exit 0

(
  if flock -w 1 9; then
    if [[ -f "$LOG_PATH" ]] && [[ $(stat -c%s "$LOG_PATH" 2>/dev/null || echo 0) -gt $ROTATE_BYTES ]]; then
      for i in $(seq $((KEEP_ROTATIONS - 1)) -1 1); do
        [[ -f "${LOG_PATH}.${i}" ]] && mv "${LOG_PATH}.${i}" "${LOG_PATH}.$((i+1))"
      done
      mv "$LOG_PATH" "${LOG_PATH}.1"
    fi
    echo "$LINE" >> "$LOG_PATH"
  fi
) 9>"$LOCK_PATH" 2>/dev/null

exit 0
```

**Customize**: only the redaction patterns (marked `# CUSTOMIZE:`). The rest is generic.

#### 1d. Make all three executable

```bash
chmod +x .claude/hooks/scope-edits.sh
chmod +x .claude/hooks/block-destructive-bash.sh
chmod +x .claude/hooks/log-tool-use.sh
```

### Step 2 — Write `.claude/settings.json`

This is the canonical structure. Customize the 4 marked sections (`additionalDirectories`, project-specific allow rules, WebFetch domains, deny extras) for the target project; leave the rest as-is.

```json
{
  "outputStyle": "Crisp",
  "permissions": {
    "defaultMode": "dontAsk",
    "additionalDirectories": [
      "<TARGET_PROJECT_ROOT>",
      "/root/.claude/agents",
      "/root/.claude/skills",
      "/root/.claude/plans"
    ],
    "allow": [
      "Bash(git status *)",
      "Bash(git diff *)",
      "Bash(git log *)",
      "Bash(git show *)",
      "Bash(git grep *)",
      "Bash(git ls-files *)",
      "Bash(git rev-parse *)",
      "Bash(git config --get *)",
      "Bash(git check-ignore *)",
      "Bash(git stash list)",
      "Bash(git -C <TARGET_PROJECT_ROOT> *)",

      "Bash(mkdir -p *)",
      "Bash(cp *)",
      "Bash(mv *)",
      "Bash(touch *)",
      "Bash(echo *)",
      "Bash(awk *)",
      "Bash(sed -n *)",
      "Bash(jq *)",
      "Bash(tr *)",
      "Bash(sort *)",
      "Bash(uniq *)",
      "Bash(cut *)",
      "Bash(test -f *)",
      "Bash(test -d *)",
      "Bash([ -f *)",
      "Bash([ -d *)",
      "Bash(grep *)",
      "Bash(ls *)",
      "Bash(find *)",
      "Bash(wc *)",
      "Bash(head *)",
      "Bash(tail *)",
      "Bash(paste *)",
      "Bash(bc *)",
      "Bash(stat *)",
      "Bash(cat *)",
      "Bash(diff *)",
      "Bash(ps *)",
      "Bash(xargs *)",
      "Bash(openssl rand *)",

      "Read(/**)",
      "Edit(<TARGET_PROJECT_ROOT>/**)",
      "Write(<TARGET_PROJECT_ROOT>/**)",
      "MultiEdit(<TARGET_PROJECT_ROOT>/**)",

      "WebSearch",
      "Agent(general-purpose)",
      "Agent(Explore)",
      "Agent(Plan)"
    ],
    "deny": [
      "Bash(rm -rf *)",
      "Bash(rm -fr *)",
      "Bash(rm -r *)",
      "Bash(rm -f / *)",
      "Bash(sudo *)",
      "Bash(su *)",
      "Bash(chmod -R 777 *)",
      "Bash(chown -R *)",
      "Bash(dd *)",
      "Bash(mkfs *)",
      "Bash(git commit *)",
      "Bash(git push *)",
      "Bash(git reset --hard *)",
      "Bash(git checkout -- *)",
      "Bash(git clean -f *)",
      "Bash(git clean -d *)",
      "Bash(git rebase *)",
      "Bash(git merge *)",
      "Bash(git tag *)",
      "Bash(git branch -D *)",
      "Bash(git remote add *)",
      "Bash(git remote rm *)",
      "Bash(git stash drop *)",
      "Bash(git stash pop *)",
      "Bash(git config --set *)",
      "Bash(git config --unset *)",
      "Bash(git config --replace-all *)",
      "Bash(curl *)",
      "Bash(wget *)",
      "Bash(nc *)",
      "Bash(ssh *)",
      "Bash(scp *)",
      "Bash(rsync *)",
      "Bash(ftp *)",
      "Bash(sftp *)",
      "Bash(telnet *)",
      "Bash(npm install *)",
      "Bash(npm i *)",
      "Bash(yarn add *)",
      "Bash(yarn install *)",
      "Bash(pnpm add *)",
      "Bash(pnpm install *)",
      "Bash(cargo install *)",
      "Bash(pip install *)",
      "Bash(pip3 install *)",
      "Bash(brew install *)",
      "Bash(brew uninstall *)",
      "Bash(apt install *)",
      "Bash(apt-get install *)",
      "Bash(apt remove *)",
      "Bash(apt-get remove *)",
      "Bash(dpkg -i *)",
      "Edit(//root/.ssh/**)",
      "Edit(//root/.aws/**)",
      "Edit(//root/.gnupg/**)",
      "Edit(//root/.netrc)",
      "Edit(//root/.npmrc)",
      "Edit(//root/.gitconfig)",
      "Edit(//etc/**)",
      "Edit(//usr/**)",
      "Edit(//var/**)",
      "Edit(/.env)",
      "Edit(/.env.*)",
      "Edit(/**/credentials.json)",
      "Edit(/**/secrets.json)",
      "Edit(/**/.git/config)",
      "Write(//root/.ssh/**)",
      "Write(//root/.aws/**)",
      "Write(//root/.gnupg/**)",
      "Write(//root/.netrc)",
      "Write(/.env)",
      "Write(/.env.*)",
      "Write(/**/credentials.json)",
      "Write(/**/secrets.json)",
      "Read(//root/.ssh/**)",
      "Read(//root/.aws/**)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/scope-edits.sh", "timeout": 5 }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/block-destructive-bash.sh", "timeout": 5 }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": ".*",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/log-tool-use.sh PostToolUse", "timeout": 3 }
        ]
      }
    ],
    "PostToolUseFailure": [
      {
        "matcher": ".*",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/log-tool-use.sh PostToolUseFailure", "timeout": 3 }
        ]
      }
    ],
    "PermissionRequest": [
      {
        "matcher": ".*",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/log-tool-use.sh PermissionRequest", "timeout": 3 }
        ]
      }
    ]
  }
}
```

**4 customization tasks**:

1. **`additionalDirectories`** — replace `<TARGET_PROJECT_ROOT>` with the absolute path. Add sister roots (memory, agent registry) if the user wants them.

2. **Project-specific allow rules** — ADD allow entries for:
   - Toolchain commands (per Step 0 inputs):
     - **Rust**: `Bash(cargo test *)` `Bash(cargo build *)` `Bash(cargo fmt *)` `Bash(cargo clippy *)` `Bash(cargo check *)` `Bash(cargo tree *)` `Bash(RUSTFLAGS="-Dwarnings" cargo clippy *)` `Bash(cargo --version *)` (intentionally OMIT `cargo install` — deny-listed)
     - **Node.js**: `Bash(npm test *)` `Bash(npm run *)` `Bash(npx *)` `Bash(node *)` `Bash(pnpm run *)` `Bash(pnpm test *)` (intentionally OMIT `npm install` / `pnpm add` — deny-listed)
     - **Python**: `Bash(python *)` `Bash(python3 *)` `Bash(pytest *)` `Bash(ruff *)` `Bash(mypy *)` (intentionally OMIT `pip install` — deny-listed)
     - **Go**: `Bash(go test *)` `Bash(go build *)` `Bash(go vet *)` `Bash(gofmt *)`
   - CI guard scripts the user listed: `Bash(bash <project>/scripts/check-*.sh*)`
   - Wrapper scripts the user listed: `Bash(bash <project>/scripts/<wrapper>.sh*)`
   - Specific binary invocations (e.g. `Bash(<project>/target/release/<bin> *)`)

3. **WebFetch domains** — for each domain the user listed in Step 0, add a `WebFetch(domain:<domain>)` allow rule. The catchall pattern is `WebFetch(domain:<host>)`. Don't add `WebFetch` (bare) — that allows any host.

4. **Additional deny extras** — for the target project's specific risk surface, ADD deny entries. Examples:
   - Infrastructure mutators: `Bash(terraform apply *)` `Bash(terraform destroy *)` `Bash(kubectl delete *)` `Bash(kubectl apply *)`
   - Cloud-specific: `Bash(aws s3 rm *)` `Bash(aws ec2 terminate-instances *)`
   - Database mutators: `Bash(psql -c "DROP *)` `Bash(mysql -e "DROP *)`
   - Whatever the user's blast radius is.

**Validation step**: `jq . .claude/settings.json > /dev/null` — confirms the JSON parses. Then `grep -c '<TARGET_PROJECT_ROOT>' .claude/settings.json` MUST be 0 — confirms no placeholders left.

### Step 3 — Write `.claude/hooks/README.md`

Document the 3 hooks so future maintainers (humans + agents) understand the safety-net layer. Template:

```markdown
# .claude/hooks/ — Claude Code hook scripts

Three hook scripts that compose the project's safety-net permission model:

| File | Triggers on | Purpose |
|---|---|---|
| `scope-edits.sh` | PreToolUse for Edit, Write, MultiEdit | Hard-deny edits outside the allowed roots. Defense-in-depth on top of path-scoped allow rules in settings.json. |
| `block-destructive-bash.sh` | PreToolUse for Bash | Regex-deny destructive commands. Defense-in-depth on top of settings.json deny rules. |
| `log-tool-use.sh` | PostToolUse, PostToolUseFailure, PermissionRequest | Append JSONL telemetry per tool call. Never blocks the workflow. |

## Allowed roots (`scope-edits.sh`)

Edit/Write/MultiEdit must target paths under:
- `<TARGET_PROJECT_ROOT>` — the project itself
- `/root/.claude/agents/` `/root/.claude/skills/` `/root/.claude/plans/` — sister roots

These MUST stay in sync with `settings.json`'s allow rules + `additionalDirectories`.

## Blocked Bash categories

| Category | Reason |
|---|---|
| `rm -[rRfF]*` | Destructive rm blocked; use Edit/Write or explicit user direction |
| `sudo`/`su` | Privilege escalation blocked |
| Destructive git (commit/push/reset --hard/rebase/merge/tag/clean -[df]/checkout --) | User owns these |
| Network (curl/wget/nc/ssh/scp/rsync/sftp/telnet/ftp) | Use WebFetch tool |
| Package install (npm/yarn/pnpm/pip/brew/apt/cargo install) | User authorizes installs |
| Disk ops (dd if/of=, mkfs, >/dev/sd*) | Disk-level blocked |
| `chmod 777` | Permissive chmod blocked |
| `find -delete` | Blocked; use rm via Edit/Write or user direction |

## Smoke tests

```bash
# Should exit 0 with no JSON output:
echo '{"tool_name":"Edit","tool_input":{"file_path":"<TARGET_PROJECT_ROOT>/README.md"}}' | bash .claude/hooks/scope-edits.sh

# Should output a deny JSON + exit 0:
echo '{"tool_name":"Edit","tool_input":{"file_path":"/etc/passwd"}}' | bash .claude/hooks/scope-edits.sh

# Should exit 0:
echo '{"tool_name":"Bash","tool_input":{"command":"echo hello"}}' | bash .claude/hooks/block-destructive-bash.sh

# Should output a deny JSON + exit 0:
echo '{"tool_name":"Bash","tool_input":{"command":"rm -rf /tmp/foo"}}' | bash .claude/hooks/block-destructive-bash.sh
```

## When to update

- **New sister root** → add to `scope-edits.sh`'s `allow_match` cases AND `settings.json` (`additionalDirectories` + Edit/Write/MultiEdit allow rules).
- **New destructive category** → add a `grep -qE ... && deny` line to `block-destructive-bash.sh`.
- **Whitelist exception** → DO NOT add per-command exceptions in the hook. Use `settings.json` allow rules instead.

## Failure modes

| Mode | Symptom | Fix |
|---|---|---|
| Script not found | Tool calls proceed; CC logs missing-hook warning | Check path in settings.json `hooks.<event>.hooks[].command` |
| Script timeout (default 5s) | Tool call proceeds with stderr warning | Run script manually with failing payload to reproduce |
| Script crash | Same as timeout | Check shell syntax, dependencies (`jq` required) |
| Malformed JSON output | CC logs parse error; treats as non-blocking | Always use `jq -n ...` to compose output |

The 3-hook model is a **safety net + telemetry**, not a granular allow mechanism. Granular allow lives in `settings.json`.
```

**Customize**: replace `<TARGET_PROJECT_ROOT>` in the smoke-test examples + the allowed-roots list.

### Step 4 — Update `.gitignore`

Add these patterns to the target project's root `.gitignore`:

```gitignore
# Claude Code telemetry — keep local, don't ship
.claude/tool-use.log
.claude/tool-use.log.*
.claude/tool-use.log.lock

# Local-only settings overrides
.claude/settings.local.json
```

### Step 5 — Verify the install

Run all 4 smoke tests from Step 3's README. All MUST pass.

Then do a live verification by triggering a real call inside Claude Code:

1. **Allow-path Edit**: ask the agent to write a small note to a path inside the project. Expect: succeeds with no permission prompt.
2. **Deny-path Edit**: ask the agent to write to `/etc/passwd`. Expect: hook denies with the "outside the allowed roots" message.
3. **Allow Bash**: ask the agent to run `git status`. Expect: succeeds, no prompt.
4. **Deny Bash**: ask the agent to run `git commit -m test`. Expect: hook denies.
5. **Telemetry**: after running 4-5 tool calls, check `.claude/tool-use.log`. Expect: one JSONL line per call, with redacted secrets, valid JSON.

If any of these fail, the install is broken — re-read the hooks + settings.json before continuing.

### Step 6 — Tell the user

When the install is complete, summarize:
- What's installed (files + paths)
- What the user owns (the deny rules — list them concisely)
- What the agent can do without prompting (the allow rules — list categories, not every line)
- How to extend (point at the hook README + the customize markers in settings.json)

Then OFFER to add the granular Bash discipline section to the project's `CLAUDE.md` (see optional Step 7 below).

### Step 7 — OPTIONAL: Granular Bash discipline section for `CLAUDE.md`

The phi project codified this discipline because compound shells (`&& chains`, `cd <abs> && <cmd>` compounds, 4-stage pipelines) defeat allow-rule matching even when each component is allowed. The model handles this by NOT allow-listing compound shapes, so the agent learns to write granular calls.

If the target project doesn't already have a `CLAUDE.md` discipline section, propose adding this verbatim (customizing the project paths in the examples):

```markdown
## Granular Bash discipline

Each Bash tool invocation runs **one logical operation**. Multiple operations = multiple invocations.

**Allowed shapes:**
- Single command + flags + paths.
- Single command + 1 trailing viewing/aggregating pipe (`cmd | head -N`, `cmd | wc -l`, `cmd | tail -N`).
- Single command with redirects paired with a downstream pipe (`<build-cmd> 2>&1 | tail -20`).

**Discouraged shapes (break into separate Bash calls):**
- Multi-line bash scripts (newlines split into fragments).
- `&&` / `||` / `;` chains (each statement = separate Bash call).
- Pipelines beyond 2 stages.
- Trailing `2>&1` without a downstream pipe.
- `cd <abs> && <cmd>` compounds (use absolute paths in the command itself).

**Tool-specific absolute-path forms:**
- `git -C <project-root> <subcmd>` instead of `cd <project-root> && git <subcmd>`.
- `<toolchain> --manifest-path <project-root>/<manifest> ...` instead of cd-into form.
- `bash <project-root>/scripts/<name>.sh` instead of `cd <project-root> && bash scripts/<name>.sh`.

**For multi-step scripts**: write to a file via the Write tool, then run `bash /abs/path/<script>.sh` as a single Bash call. Each line of the script runs in the bash process; only the outer `bash <file>` call is matched against allow rules.

Reasoning: the allow-rule matcher operates on the FULL command string. A compound like `cd /foo && git status` does NOT match an allow rule `Bash(git status *)` — the matcher sees `cd /foo && git status` as the full pattern, which is unallow-listed. This forces the agent to use single-command-per-call shapes that match cleanly. The discipline emerges naturally from the model, no separate enforcement needed.
```

---

## Customization principles

When extending later (the user adds a new tool, sister root, etc.), follow these:

1. **Deny is sticky; allow is loose**. Never loosen a deny rule without explicit user direction. Adding allow rules is reversible; removing deny rules can cause irreversible damage.

2. **Allow rules are append-only across cycles** — when you discover a new tool-call shape the agent uses repeatedly (e.g., `Bash(/usr/local/bin/some-tool *)`), append it. Don't replace or condense existing rules; that breaks tooling that audits them.

3. **Path literals stay absolute** in allow rules. Never use `~`, never use relative paths. If a path could be wrong, prompt the user.

4. **Glob discipline**:
   - `*` matches a single path segment (anything except `/`).
   - `**` matches any number of segments (including `/`).
   - For tools with path args (Read/Edit/Write/Bash with paths), use `**` to traverse. `Bash(read_file(*))` is a trap — it does NOT match `read_file(workspace/foo.txt)` because of the `/`. Use `**` form.
   - This is a real bug class: the phi project filed a multi-cycle D-TEST drift on it. See [[feedback_permission_glob_semantics]] in the source project's memory.

5. **Hook deny patterns are regex** (extended POSIX), not glob. They match anywhere in the command string. Anchor your regex (`^`, `\b`, `$`) appropriately to avoid false positives (e.g., `grep "install"` should not be blocked by an install regex).

6. **Telemetry is sacred** — never let `log-tool-use.sh` block the workflow. If you ever extend it, preserve the `set -uo pipefail` (no `-e`), the fail-safe exits, and the `flock -w 1` timeout. The phi project's audit skill depends on this log being lossy-but-non-blocking.

---

## Source attribution

This model came from the **phi project** at `/root/projects/phi/`, refined across ~7 months and ~60 chunk-pipeline cycles. Empirical evidence for each rule lives in:
- `phi/CLAUDE.md` — Granular Bash discipline section + audit cross-check skill
- `phi/baby-phi/docs/specs/permissions/project-permissions-hardening-478b9384.md` — hook gates design
- `phi/baby-phi/docs/specs/permissions/tool-use-logging-and-permissions-audit-skill-18564835.md` — telemetry + audit design
- `phi/.claude/hooks/README.md` — runtime semantics

If you're adopting this for a project that interacts with the phi project (e.g., a sibling consumer of `phi-core`), consider sharing the `additionalDirectories` list so cross-project edits don't trigger denies. Otherwise, treat the target as fully isolated.

---

## Quality bar

When you finish:
- All 5 smoke tests in Step 5 pass.
- `jq . .claude/settings.json` succeeds (valid JSON).
- `grep -rn '<TARGET_PROJECT_ROOT>' .claude/` returns 0 hits (no placeholders left).
- The hook README accurately reflects the actual `allow_match` cases in `scope-edits.sh`.
- `.gitignore` covers `tool-use.log*` + `settings.local.json`.
- A `git status` is clean: the only new files are the 5 you intentionally created (`settings.json`, 3 hooks, `hooks/README.md`) + the `.gitignore` line additions.
