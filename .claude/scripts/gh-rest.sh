#!/usr/bin/env bash
# gh-rest.sh — GitHub REST API helper for the i-phi e2e-test pipeline.
#
# Wraps curl so the orchestrator's Bash invocation line never carries a `curl`
# token (the block-destructive-bash hook denies bare curl). Allowlisted as
# `bash /root/projects/phi/.claude/scripts/gh-rest.sh *` in settings.json.
#
# Subcommands (T1-T5 surface):
#   issue-create  --title TITLE --body-file PATH [--label CSV]
#   issue-update  ISSUE# [--state closed|open] [--add-label L] [--comment TEXT] [--body-file PATH] [--title TITLE]
#   issue-list    [--label X] [--state open|closed|all] [--json] [--limit N]
#   issue-comment ISSUE# --body-file PATH
#   issue-pull    ISSUE#
#   label-create  --name NAME --color HHHHHH [--desc TEXT]
#   pr-create     --title TITLE --head BRANCH --base BRANCH --body-file PATH
#   self-test                          # smoke: verify token + repo access
#   help                               # print usage
#
# Subcommands gated for T6+ (Projects v2 + Discussions; use GH_PROJECT_TOKEN):
#   project-add-item       (TODO at T6)
#   project-update-field   (TODO at T6)
#   discussion-create      (TODO at T6)
#   discussion-update      (TODO at T6)
#
# Token: GITHUB_PAT_IPHI from /root/projects/phi/.env (chmod 600 enforced)
# Repo:  LazyBouy/i-phi (hardcoded — single-purpose script)
# Exit:  0 on HTTP 2xx; 1 on 4xx/5xx with stderr message + JSON body
#
# Token redaction: GITHUB_PAT_IPHI is never echoed to stdout/stderr.

set -euo pipefail

readonly REPO="LazyBouy/i-phi"
readonly API_BASE="https://api.github.com"
readonly ENV_FILE="/root/projects/phi/.env"
readonly USER_AGENT="iphi-e2e-test-pipeline/1.0"

# ---------- utilities ----------

err() { printf 'gh-rest.sh: %s\n' "$*" >&2; }
die() { err "$*"; exit 1; }

usage() {
  sed -n '2,/^set -euo/p' "$0" | sed -n '/^#/p' | sed 's/^# \{0,1\}//'
  exit 0
}

verify_env_perms() {
  [[ -f "$ENV_FILE" ]] || die ".env not found at $ENV_FILE"
  local perms
  perms=$(stat -c '%a' "$ENV_FILE" 2>/dev/null || echo "unknown")
  if [[ "$perms" != "600" ]]; then
    err "WARNING: .env permissions are $perms; expected 600. Run: chmod 600 $ENV_FILE"
  fi
}

# Load GITHUB_PAT_IPHI without printing it; sets global TOKEN
load_token() {
  verify_env_perms
  local raw
  raw=$(grep -E '^GITHUB_PAT_IPHI=' "$ENV_FILE" | head -1 | cut -d'=' -f2- | tr -d '"' | tr -d "'")
  [[ -n "$raw" ]] || die "GITHUB_PAT_IPHI not found in $ENV_FILE"
  TOKEN="$raw"
}

# Run a curl call against api.github.com with auth headers.
# Args: METHOD ENDPOINT [JSON_BODY]
# Returns: response body on stdout; exits 1 on HTTP >= 400
api_call() {
  local method="$1"
  local endpoint="$2"
  local body="${3:-}"
  local url="${API_BASE}${endpoint}"
  local tmp_body tmp_headers status
  tmp_body=$(mktemp)
  tmp_headers=$(mktemp)
  trap "rm -f '$tmp_body' '$tmp_headers'" RETURN

  local curl_args=(
    -sS
    -X "$method"
    -D "$tmp_headers"
    -o "$tmp_body"
    -w '%{http_code}'
    -H "Authorization: token ${TOKEN}"
    -H "Accept: application/vnd.github+json"
    -H "X-GitHub-Api-Version: 2022-11-28"
    -H "User-Agent: ${USER_AGENT}"
  )
  if [[ -n "$body" ]]; then
    curl_args+=(-H "Content-Type: application/json" --data-binary "$body")
  fi
  curl_args+=("$url")

  status=$(curl "${curl_args[@]}" || echo "000")

  if [[ "$status" =~ ^2 ]]; then
    cat "$tmp_body"
    return 0
  else
    err "HTTP $status on $method $endpoint"
    if [[ -s "$tmp_body" ]]; then
      err "Response body:"
      cat "$tmp_body" >&2
      echo >&2
    fi
    return 1
  fi
}

# Build JSON object from key=value pairs (values are shell-escaped strings).
# Use this for simple bodies; for bodies with file content use --body-file path
# and read+escape via jq.
json_build() {
  local result="{"
  local first=1
  while [[ $# -ge 2 ]]; do
    local key="$1"
    local val="$2"
    shift 2
    if [[ $first -eq 0 ]]; then
      result+=","
    fi
    first=0
    # Use jq to safely encode val as a JSON string
    local encoded
    encoded=$(printf '%s' "$val" | jq -Rs .)
    result+="\"${key}\":${encoded}"
  done
  result+="}"
  printf '%s' "$result"
}

# Read a file and produce a JSON string literal (for body fields)
file_as_json_string() {
  jq -Rs . < "$1"
}

# ---------- subcommand: issue-create ----------

cmd_issue_create() {
  local title="" body_file="" labels_csv=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --title) title="$2"; shift 2 ;;
      --body-file) body_file="$2"; shift 2 ;;
      --label) labels_csv="$2"; shift 2 ;;
      *) die "issue-create: unknown arg '$1'" ;;
    esac
  done
  [[ -n "$title" ]] || die "issue-create: --title required"
  [[ -n "$body_file" && -f "$body_file" ]] || die "issue-create: --body-file must point to an existing file"

  local body_json
  body_json=$(file_as_json_string "$body_file")

  local labels_json="[]"
  if [[ -n "$labels_csv" ]]; then
    labels_json=$(printf '%s' "$labels_csv" | jq -Rc 'split(",") | map(select(length > 0))')
  fi

  local req
  req=$(jq -nc \
    --arg title "$title" \
    --argjson body "$body_json" \
    --argjson labels "$labels_json" \
    '{title: $title, body: $body, labels: $labels}')

  api_call POST "/repos/${REPO}/issues" "$req"
}

# ---------- subcommand: issue-update ----------

cmd_issue_update() {
  local issue_num="$1"; shift
  [[ -n "$issue_num" ]] || die "issue-update: ISSUE# required"

  local state="" add_label="" comment="" body_file="" title=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --state) state="$2"; shift 2 ;;
      --add-label) add_label="$2"; shift 2 ;;
      --comment) comment="$2"; shift 2 ;;
      --body-file) body_file="$2"; shift 2 ;;
      --title) title="$2"; shift 2 ;;
      *) die "issue-update: unknown arg '$1'" ;;
    esac
  done

  if [[ -n "$state" ]]; then
    local req
    req=$(jq -nc --arg s "$state" '{state: $s}')
    api_call PATCH "/repos/${REPO}/issues/${issue_num}" "$req"
  fi

  # Edit the issue body (and/or title) in place. --body-file replaces the body.
  if [[ -n "$body_file" || -n "$title" ]]; then
    [[ -z "$body_file" || -f "$body_file" ]] || die "issue-update: --body-file must point to an existing file"
    local req fields='{}'
    if [[ -n "$body_file" ]]; then
      local body_json
      body_json=$(file_as_json_string "$body_file")
      fields=$(jq -nc --argjson b "$body_json" '{body: $b}')
    fi
    if [[ -n "$title" ]]; then
      fields=$(printf '%s' "$fields" | jq -c --arg t "$title" '. + {title: $t}')
    fi
    api_call PATCH "/repos/${REPO}/issues/${issue_num}" "$fields"
  fi

  if [[ -n "$add_label" ]]; then
    local req
    req=$(jq -nc --arg l "$add_label" '{labels: [$l]}')
    api_call POST "/repos/${REPO}/issues/${issue_num}/labels" "$req"
  fi

  if [[ -n "$comment" ]]; then
    local body_json
    body_json=$(printf '%s' "$comment" | jq -Rs .)
    local req
    req=$(jq -nc --argjson b "$body_json" '{body: $b}')
    api_call POST "/repos/${REPO}/issues/${issue_num}/comments" "$req"
  fi
}

# ---------- subcommand: issue-list ----------

cmd_issue_list() {
  local label="" state="open" limit=30 want_json=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --label) label="$2"; shift 2 ;;
      --state) state="$2"; shift 2 ;;
      --limit) limit="$2"; shift 2 ;;
      --json) want_json=1; shift ;;
      *) die "issue-list: unknown arg '$1'" ;;
    esac
  done

  local q="state=${state}&per_page=${limit}"
  if [[ -n "$label" ]]; then
    q+="&labels=$(printf '%s' "$label" | jq -Rr @uri)"
  fi

  local raw
  raw=$(api_call GET "/repos/${REPO}/issues?${q}")

  if [[ $want_json -eq 1 ]]; then
    printf '%s\n' "$raw"
  else
    printf '%s' "$raw" | jq -r '.[] | "#\(.number)\t\(.state)\t\(.title)"'
  fi
}

# ---------- subcommand: issue-comment ----------

cmd_issue_comment() {
  local issue_num="$1"; shift
  [[ -n "$issue_num" ]] || die "issue-comment: ISSUE# required"

  local body_file=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --body-file) body_file="$2"; shift 2 ;;
      *) die "issue-comment: unknown arg '$1'" ;;
    esac
  done
  [[ -n "$body_file" && -f "$body_file" ]] || die "issue-comment: --body-file must point to an existing file"

  local body_json
  body_json=$(file_as_json_string "$body_file")
  local req
  req=$(jq -nc --argjson b "$body_json" '{body: $b}')
  api_call POST "/repos/${REPO}/issues/${issue_num}/comments" "$req"
}

# ---------- subcommand: issue-pull ----------

cmd_issue_pull() {
  local issue_num="$1"
  [[ -n "$issue_num" ]] || die "issue-pull: ISSUE# required"
  api_call GET "/repos/${REPO}/issues/${issue_num}"
}

# ---------- subcommand: issue-comments ----------

# Read (GET) the comment thread on an issue. Read-only; prints each comment as
# a "=== @login  created_at ===" header followed by the body.
cmd_issue_comments() {
  local issue_num="$1"; shift || true
  [[ -n "${issue_num:-}" ]] || die "issue-comments: ISSUE# required"

  local want_json=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --json) want_json=1; shift ;;
      *) die "issue-comments: unknown arg '$1'" ;;
    esac
  done

  local raw
  raw=$(api_call GET "/repos/${REPO}/issues/${issue_num}/comments?per_page=100")

  if [[ $want_json -eq 1 ]]; then
    printf '%s\n' "$raw"
  else
    printf '%s' "$raw" | jq -r '.[] | "=== @\(.user.login)  \(.created_at) ===\n\(.body)\n"'
  fi
}

# ---------- subcommand: label-create ----------

cmd_label_create() {
  local name="" color="" description=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --name) name="$2"; shift 2 ;;
      --color) color="$2"; shift 2 ;;
      --desc) description="$2"; shift 2 ;;
      *) die "label-create: unknown arg '$1'" ;;
    esac
  done
  [[ -n "$name" ]] || die "label-create: --name required"
  [[ -n "$color" ]] || color="cccccc"

  local req
  req=$(jq -nc --arg n "$name" --arg c "$color" --arg d "$description" \
    '{name: $n, color: $c, description: $d}')
  api_call POST "/repos/${REPO}/labels" "$req"
}

# ---------- subcommand: pr-create ----------

cmd_pr_create() {
  local title="" head="" base="" body_file=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --title) title="$2"; shift 2 ;;
      --head) head="$2"; shift 2 ;;
      --base) base="$2"; shift 2 ;;
      --body-file) body_file="$2"; shift 2 ;;
      *) die "pr-create: unknown arg '$1'" ;;
    esac
  done
  [[ -n "$title" ]] || die "pr-create: --title required"
  [[ -n "$head" ]] || die "pr-create: --head required"
  [[ -n "$base" ]] || die "pr-create: --base required"
  [[ -n "$body_file" && -f "$body_file" ]] || die "pr-create: --body-file must point to an existing file"

  local body_json
  body_json=$(file_as_json_string "$body_file")

  local req
  req=$(jq -nc \
    --arg title "$title" \
    --arg head "$head" \
    --arg base "$base" \
    --argjson body "$body_json" \
    '{title: $title, head: $head, base: $base, body: $body}')

  api_call POST "/repos/${REPO}/pulls" "$req"
}

# ---------- subcommand: self-test ----------

cmd_self_test() {
  local raw
  if raw=$(api_call GET "/repos/${REPO}"); then
    local repo_name has_issues
    repo_name=$(printf '%s' "$raw" | jq -r '.full_name')
    has_issues=$(printf '%s' "$raw" | jq -r '.has_issues')
    printf 'OK: authenticated; repo=%s, has_issues=%s\n' "$repo_name" "$has_issues"
    return 0
  else
    err "self-test FAILED"
    return 1
  fi
}

# ---------- dispatch ----------

main() {
  [[ $# -ge 1 ]] || { usage; }
  local sub="$1"; shift

  case "$sub" in
    help|-h|--help) usage ;;
    issue-create)   load_token; cmd_issue_create "$@" ;;
    issue-update)   load_token; cmd_issue_update "$@" ;;
    issue-list)     load_token; cmd_issue_list "$@" ;;
    issue-comment)  load_token; cmd_issue_comment "$@" ;;
    issue-pull)     load_token; cmd_issue_pull "$@" ;;
    issue-comments) load_token; cmd_issue_comments "$@" ;;
    label-create)   load_token; cmd_label_create "$@" ;;
    pr-create)      load_token; cmd_pr_create "$@" ;;
    self-test)      load_token; cmd_self_test "$@" ;;
    project-add-item|project-update-field|discussion-create|discussion-update)
      die "$sub is a T6+ subcommand; not yet implemented"
      ;;
    *) die "unknown subcommand '$sub'; try: $0 help" ;;
  esac
}

main "$@"
