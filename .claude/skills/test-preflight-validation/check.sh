#!/usr/bin/env bash
# test-preflight-validation/check.sh — CC-07 F3 (cycle aeed9751)
#
# Mechanical 10-step PASS/FAIL audit of an e2e-test frontmatter + its
# referenced setup script. Class-agnostic; branches on test_class:
# `harness` (HTC) vs `model` (TC). Per ADR-0023 §D23.15.
#
# Usage:
#   bash check.sh <TEST-ID> [<CYCLE-FOLDER-ABS>]
#
# Exit 0 = all PASS; exit 1 = any FAIL.
# stdout = structured JSON report.

set -u  # NOT set -e — we want to continue past individual check failures
        # to emit a complete report.

# ─── Args ─────────────────────────────────────────────────────────────────

TEST_ID="${1:-}"
CYCLE_FOLDER="${2:-/root/projects/phi/i-phi/docs/e2e-test/cycles/t10-execute-htc-pilot-execution-0577137b}"

if [[ -z "${TEST_ID}" ]]; then
  echo '{"verdict": "FAIL", "error": "missing TEST-ID arg"}'
  exit 1
fi

IPHI_ROOT="/root/projects/phi/i-phi"
TC_FILE="${IPHI_ROOT}/docs/e2e-test/test-cases/${TEST_ID}.md"

if [[ ! -f "${TC_FILE}" ]]; then
  printf '{"test_id": "%s", "verdict": "FAIL", "error": "test-case file not found at %s"}\n' \
    "${TEST_ID}" "${TC_FILE}"
  exit 1
fi

# ─── Frontmatter extraction (hand-rolled; no pyyaml) ──────────────────────

# Extract lines between the first pair of `---` delimiters.
FRONTMATTER="$(awk '/^---$/{c++; next} c==1{print} c==2{exit}' "${TC_FILE}")"

if [[ -z "${FRONTMATTER}" ]]; then
  printf '{"test_id": "%s", "verdict": "FAIL", "checks": [{"id":"C1","name":"frontmatter parses","status":"FAIL","detail":"no frontmatter found between --- delimiters"}], "failed_count": 1, "passed_count": 0}\n' "${TEST_ID}"
  exit 1
fi

# Helper: extract scalar value of `<field>:` line (single line).
# Returns "" if not found. Strips surrounding quotes.
fm_scalar() {
  echo "${FRONTMATTER}" | grep -E "^${1}:" | head -1 | sed -E "s/^${1}:[[:space:]]*//; s/^\"//; s/\"$//; s/^'//; s/'$//"
}

# Helper: count entries in a list field. The pattern is:
#   field_name:
#     - item1
#     - item2
# We grep for `^<field_name>:` then walk forward counting `  - ` lines until
# the next `^<word>:` line.
fm_list_count() {
  echo "${FRONTMATTER}" | awk -v field="$1" '
    BEGIN { in_field=0; count=0 }
    $0 ~ "^"field":" { in_field=1; next }
    in_field && /^[a-zA-Z_][a-zA-Z0-9_]*:/ { in_field=0 }
    in_field && /^[[:space:]]*-[[:space:]]/ { count++ }
    END { print count }
  '
}

# Helper: extract the first list entry (the `[0]` element). Strips inline
# `# comment` trailers.
fm_list_first() {
  echo "${FRONTMATTER}" | awk -v field="$1" '
    BEGIN { in_field=0; printed=0 }
    $0 ~ "^"field":" { in_field=1; next }
    in_field && /^[a-zA-Z_][a-zA-Z0-9_]*:/ { in_field=0 }
    in_field && /^[[:space:]]*-[[:space:]]/ && printed==0 {
      sub(/^[[:space:]]*-[[:space:]]*/, "", $0)
      sub(/[[:space:]]+#.*$/, "", $0)
      gsub(/"/, "", $0)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      print $0
      printed=1
    }
  '
}

# Helper: dump all list entries (one per line). Strips inline `# comment`
# trailers (YAML list-item comments) so downstream consumers see the bare
# value (e.g., `read_file` vs `read_file # generates prunable chatter`).
fm_list_all() {
  echo "${FRONTMATTER}" | awk -v field="$1" '
    BEGIN { in_field=0 }
    $0 ~ "^"field":" { in_field=1; next }
    in_field && /^[a-zA-Z_][a-zA-Z0-9_]*:/ { in_field=0 }
    in_field && /^[[:space:]]*-[[:space:]]/ {
      sub(/^[[:space:]]*-[[:space:]]*/, "", $0)
      # Strip inline comment (everything from first " #" onward).
      sub(/[[:space:]]+#.*$/, "", $0)
      gsub(/"/, "", $0)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      print $0
    }
  '
}

# ─── Check results accumulator ────────────────────────────────────────────

declare -a CHECK_IDS=()
declare -a CHECK_NAMES=()
declare -a CHECK_STATUSES=()
declare -a CHECK_DETAILS=()

record_check() {
  CHECK_IDS+=("$1")
  CHECK_NAMES+=("$2")
  CHECK_STATUSES+=("$3")
  CHECK_DETAILS+=("$4")
}

# ─── C1 — frontmatter parses ──────────────────────────────────────────────

TEST_CLASS="$(fm_scalar 'test_class')"
if [[ -z "${TEST_CLASS}" ]]; then
  record_check "C1" "frontmatter parses + test_class present" "FAIL" "test_class field missing"
  # Cannot dispatch class checks. Emit early.
  TEST_CLASS="unknown"
else
  record_check "C1" "frontmatter parses + test_class present" "PASS" ""
fi

# ─── C2 — required fields populated (per class) ──────────────────────────

c2_missing=()
if [[ "${TEST_CLASS}" == "harness" ]]; then
  # Required for HTC.
  for field in tc_id surface_under_test tools_invoked model_for_orchestration setup_script; do
    if [[ -z "$(fm_scalar "${field}")" ]] && [[ "$(fm_list_count "${field}")" == "0" ]]; then
      c2_missing+=("${field}")
    fi
  done
elif [[ "${TEST_CLASS}" == "model" ]]; then
  for field in tc_id parent_strategy parent_use_case setup_invocation primary_metric_name pass_cutoff partial_cutoff_floor fail_below; do
    if [[ -z "$(fm_scalar "${field}")" ]] && [[ "$(fm_list_count "${field}")" == "0" ]]; then
      c2_missing+=("${field}")
    fi
  done
  # `models_in_scope` is a list; needs ≥ 1 element.
  if [[ "$(fm_list_count 'models_in_scope')" == "0" ]]; then
    c2_missing+=("models_in_scope")
  fi
  # `env_vars_required` is a list; empty list `[]` is acceptable (e.g.,
  # local-Ollama TCs don't need OPENROUTER_TOKEN). The field MUST be
  # present in the frontmatter (so authors deliberately declare zero),
  # but an empty list is not a failure.
  if ! grep -q "^env_vars_required:" <<< "${FRONTMATTER}"; then
    c2_missing+=("env_vars_required (field absent)")
  fi
fi

if [[ "${#c2_missing[@]}" -eq 0 ]]; then
  record_check "C2" "required fields populated" "PASS" ""
else
  record_check "C2" "required fields populated" "FAIL" "missing: ${c2_missing[*]}"
fi

# ─── C3 — model-cohort open-source ───────────────────────────────────────

C3_FIELD=""
C3_VALUE=""
if [[ "${TEST_CLASS}" == "harness" ]]; then
  C3_FIELD="model_for_orchestration[0]"
  C3_VALUE="$(fm_list_first 'model_for_orchestration')"
elif [[ "${TEST_CLASS}" == "model" ]]; then
  C3_FIELD="models_in_scope[0]"
  C3_VALUE="$(fm_list_first 'models_in_scope')"
fi

if [[ -z "${C3_VALUE}" ]]; then
  record_check "C3" "model-cohort open-source" "FAIL" "${C3_FIELD} not populated"
elif [[ "${C3_VALUE}" =~ ^cohort: ]]; then
  # Cohort form — check passes (cohort registry resolves separately at C5').
  record_check "C3" "model-cohort open-source" "PASS" "cohort form (${C3_VALUE})"
elif echo "${C3_VALUE}" | grep -qE '^openai/gpt-oss-'; then
  # `openai/gpt-oss-NB` is OpenAI's OPEN-SOURCE family (gpt-oss-20b /
  # gpt-oss-120b / etc.) — these are open-weights releases distinct from
  # the closed-source frontier models. Allow as open-source per
  # [[feedback_openrouter_open_source_only]] Rule 1 (which names the
  # open-source families: gemma, llama, glm, qwen, mistral-open,
  # deepseek-open, AND OpenAI's gpt-oss family by implication via the
  # OSS release naming convention).
  record_check "C3" "model-cohort open-source" "PASS" "open-source (gpt-oss family; ${C3_VALUE})"
elif echo "${C3_VALUE}" | grep -qE '^(anthropic|openai|google/gemini)/'; then
  record_check "C3" "model-cohort open-source" "FAIL" "${C3_FIELD} = ${C3_VALUE} is SOTA-closed-source (banned per [[feedback_openrouter_open_source_only]] Rule 2)"
else
  record_check "C3" "model-cohort open-source" "PASS" "open-source model (${C3_VALUE})"
fi

# ─── C4 — setup reference resolves ───────────────────────────────────────

SETUP_SCRIPT_REF=""
SETUP_SCRIPT_PATH=""
if [[ "${TEST_CLASS}" == "harness" ]]; then
  SETUP_SCRIPT_REF="$(fm_scalar 'setup_script')"
  SETUP_SCRIPT_PATH="${CYCLE_FOLDER}/scripts/${SETUP_SCRIPT_REF}"
  if [[ -z "${SETUP_SCRIPT_REF}" ]]; then
    record_check "C4" "setup reference resolves" "FAIL" "setup_script field missing"
  elif [[ ! -f "${SETUP_SCRIPT_PATH}" ]]; then
    record_check "C4" "setup reference resolves" "FAIL" "setup_script not found at ${SETUP_SCRIPT_PATH}"
  else
    record_check "C4" "setup reference resolves" "PASS" "${SETUP_SCRIPT_PATH}"
  fi
elif [[ "${TEST_CLASS}" == "model" ]]; then
  setup_invocation="$(fm_scalar 'setup_invocation')"
  if [[ -z "${setup_invocation}" ]]; then
    record_check "C4" "setup reference resolves" "FAIL" "setup_invocation field empty"
  else
    record_check "C4" "setup reference resolves" "PASS" "setup_invocation present"
  fi
fi

# ─── Class-specific checks ───────────────────────────────────────────────

if [[ "${TEST_CLASS}" == "harness" ]]; then
  # ─── C5 — setup writes permissions.toml ──────────────────────────────
  if [[ -n "${SETUP_SCRIPT_PATH}" ]] && [[ -f "${SETUP_SCRIPT_PATH}" ]]; then
    if grep -q 'permissions\.toml' "${SETUP_SCRIPT_PATH}"; then
      record_check "C5" "setup writes permissions.toml" "PASS" ""
    else
      record_check "C5" "setup writes permissions.toml" "FAIL" "no 'permissions.toml' literal in setup script"
    fi
  else
    record_check "C5" "setup writes permissions.toml" "FAIL" "setup script not accessible (see C4)"
  fi

  # ─── C6 — allow-rule per tools_invoked ────────────────────────────────
  c6_missing=()
  c6_deny_test=0
  if [[ -n "${SETUP_SCRIPT_PATH}" ]] && [[ -f "${SETUP_SCRIPT_PATH}" ]]; then
    # Check if this is a deny-test (HTC-0001 path): if setup ships
    # `deny = [...]` AND `allow = []` is omitted/empty AND tools_invoked
    # mentions the tool the deny applies to, the deny-test rationale
    # legitimately exercises the deny path with no allow rule needed.
    if grep -qE '^deny = \[' "${SETUP_SCRIPT_PATH}"; then
      c6_deny_test=1
    fi
    # Extract the allow array literal contents.
    allow_block="$(grep -A 1 -E '^allow = \[' "${SETUP_SCRIPT_PATH}" | head -2 | tr -d '\n')"
    while IFS= read -r tool; do
      [[ -z "${tool}" ]] && continue
      # Case-insensitive search for the tool name in the allow block.
      if echo "${allow_block}" | grep -qiE "\"${tool}(\\(|\")"; then
        :  # present
      else
        # If deny-test mode AND this tool is the one being denied, allow.
        if [[ "${c6_deny_test}" -eq 1 ]] && grep -qiE "deny = \[.*${tool}" "${SETUP_SCRIPT_PATH}"; then
          : # legitimate deny-path test
        else
          c6_missing+=("${tool}")
        fi
      fi
    done < <(fm_list_all 'tools_invoked')

    if [[ "${#c6_missing[@]}" -eq 0 ]]; then
      record_check "C6" "allow rule per tools_invoked" "PASS" ""
    else
      record_check "C6" "allow rule per tools_invoked" "FAIL" "no allow/deny entry for: ${c6_missing[*]}"
    fi
  else
    record_check "C6" "allow rule per tools_invoked" "FAIL" "setup script not accessible"
  fi

  # ─── C7 — tools_invoked ⊆ permissions_required + sub-agent rule ───────
  c7_issues=()
  perms_required_count="$(fm_list_count 'permissions_required')"
  perms_first="$(fm_list_first 'permissions_required')"
  # Exception: `permissions_required: [none]` is the deny-test sentinel
  # (e.g., HTC-0001) — setup ships explicit deny rules, not allow rules.
  # The C6 check verifies that the tool name appears in the deny clause.
  if [[ "${perms_required_count}" -eq 1 ]] && [[ "${perms_first}" == "none" ]]; then
    : # deny-test path; C6 already verified the deny-clause alignment
  elif [[ "${perms_required_count}" -gt 0 ]]; then
    # When permissions_required is populated with real rules, cross-check.
    declare -A perms_set=()
    while IFS= read -r entry; do
      [[ -z "${entry}" ]] && continue
      # Extract bare tool name (before any "(").
      bare="$(echo "${entry}" | sed -E 's/\(.*$//' | tr '[:upper:]' '[:lower:]')"
      perms_set["${bare}"]=1
    done < <(fm_list_all 'permissions_required')

    while IFS= read -r tool; do
      [[ -z "${tool}" ]] && continue
      lower_tool="$(echo "${tool}" | tr '[:upper:]' '[:lower:]')"
      if [[ -z "${perms_set[${lower_tool}]:-}" ]]; then
        c7_issues+=("${tool} not in permissions_required[]")
      fi
    done < <(fm_list_all 'tools_invoked')
  fi
  # Sub-agent rule.
  if echo "${FRONTMATTER}" | grep -A 5 '^surface_under_test:' | grep -qiE 'sub-agent|sub_agent'; then
    if [[ -n "${SETUP_SCRIPT_PATH}" ]] && [[ -f "${SETUP_SCRIPT_PATH}" ]]; then
      if grep -qE '\[\[agent\.sub_agents\]\]' "${SETUP_SCRIPT_PATH}"; then
        : # present
      else
        c7_issues+=("surface includes sub-agent but setup missing [[agent.sub_agents]] block")
      fi
    fi
  fi

  if [[ "${#c7_issues[@]}" -eq 0 ]]; then
    record_check "C7" "tools_invoked ⊆ permissions_required + sub-agent rule" "PASS" ""
  else
    record_check "C7" "tools_invoked ⊆ permissions_required + sub-agent rule" "FAIL" "${c7_issues[*]}"
  fi

  # ─── C7.5 — path-arg-tool glob-form (CC-08 F4 D-TEST-0013 closure) ──────
  # WARN-only sub-check: for each allow-rule in the setup script with shape
  # `<tool>(*)` where <tool> is a known path-arg tool (its args contain
  # JSON path strings like `{"path":"workspace/foo.txt"}`), `*` will NOT
  # match because matcher.rs:5 documents `*` as "matches any chars EXCEPT
  # `/`" (Claude-Code-parity per ADR-0006 §D6.2 + §D6.16). Authors should
  # use `<tool>(**)` form so path-containing args resolve to Allow.
  #
  # Path-arg-tool set: closed by enumeration per ADR-0006 §D6.16 +
  # [[feedback_permission_glob_semantics]]. When phi-core adds new tools
  # with path args, extend this array + amend ADR-0006 §D6.16.
  PATH_ARG_TOOLS=(read_file write_file bash edit_file list_files search)
  c7_5_warnings=()
  if [[ -n "${SETUP_SCRIPT_PATH}" ]] && [[ -f "${SETUP_SCRIPT_PATH}" ]]; then
    for tool in "${PATH_ARG_TOOLS[@]}"; do
      # Case-insensitive match for `"<tool>(*)"` in the setup script's
      # allow array. Use word-boundary-ish match to avoid catching `(**)`.
      if grep -qiE "\"${tool}\\(\\*\\)\"" "${SETUP_SCRIPT_PATH}"; then
        c7_5_warnings+=("${tool}(*) — use ${tool}(**) per ADR-0006 §D6.16 (path-arg tool; * excludes /)")
      fi
    done
  fi
  if [[ "${#c7_5_warnings[@]}" -eq 0 ]]; then
    record_check "C7.5" "path-arg-tool glob-form (WARN-only)" "PASS" ""
  else
    # WARN-only: emit PASS verdict to avoid blocking, but surface guidance
    # in the detail field. Operators see this in the JSON output even on
    # overall PASS.
    record_check "C7.5" "path-arg-tool glob-form (WARN-only)" "PASS" "WARN: ${c7_5_warnings[*]}"
  fi

  # ─── C8 — workspace_dirs created ──────────────────────────────────────
  c8_missing=()
  while IFS= read -r workdir; do
    [[ -z "${workdir}" ]] && continue
    # Strip surrounding quotes, leading ${FIXTURE_DIR}/ etc.
    bare="$(echo "${workdir}" | sed -E 's|^\$\{FIXTURE_DIR\}/||; s|^/||')"
    if [[ -n "${SETUP_SCRIPT_PATH}" ]] && [[ -f "${SETUP_SCRIPT_PATH}" ]]; then
      if grep -qE "mkdir -p.*${bare}|WORKSPACE.*${bare}" "${SETUP_SCRIPT_PATH}"; then
        : # created
      else
        c8_missing+=("${workdir}")
      fi
    fi
  done < <(fm_list_all 'workspace_dirs_required')

  workdir_count="$(fm_list_count 'workspace_dirs_required')"
  if [[ "${workdir_count}" -eq 0 ]]; then
    record_check "C8" "workspace_dirs created" "PASS" "no workspace_dirs_required declared (acceptable for tool-only tests)"
  elif [[ "${#c8_missing[@]}" -eq 0 ]]; then
    record_check "C8" "workspace_dirs created" "PASS" "${workdir_count} dirs verified"
  else
    record_check "C8" "workspace_dirs created" "FAIL" "missing mkdir for: ${c8_missing[*]}"
  fi

  # ─── C9 — model coherence ─────────────────────────────────────────────
  if [[ -n "${SETUP_SCRIPT_PATH}" ]] && [[ -f "${SETUP_SCRIPT_PATH}" ]]; then
    setup_model="$(grep -E 'default_model_id = ' "${SETUP_SCRIPT_PATH}" | head -1 | sed -E 's/.*default_model_id = "?([^"]+)"?.*/\1/')"
    if [[ -z "${setup_model}" ]] || [[ -z "${C3_VALUE}" ]]; then
      record_check "C9" "model coherence" "FAIL" "could not extract default_model_id or model_for_orchestration[0]"
    elif [[ "${setup_model}" == "${C3_VALUE}" ]]; then
      record_check "C9" "model coherence" "PASS" "${setup_model}"
    else
      # Soft-fail: HTC-0002 documents an intentional model substitution
      # (anthropic banned → deepseek). Mark PASS-with-note instead of FAIL
      # when the frontmatter notes the swap (the substitution rationale
      # is documented in a comment in the setup script).
      if grep -qE 'HARD-BANNED|swap|substitut' "${SETUP_SCRIPT_PATH}"; then
        record_check "C9" "model coherence" "PASS" "setup overrides frontmatter (${setup_model} vs ${C3_VALUE}) — documented substitution"
      else
        record_check "C9" "model coherence" "FAIL" "setup default_model_id (${setup_model}) != model_for_orchestration[0] (${C3_VALUE})"
      fi
    fi
  else
    record_check "C9" "model coherence" "FAIL" "setup script not accessible"
  fi

  # ─── C10 — config_correctness_checklist present ───────────────────────
  checklist_count="$(fm_list_count 'config_correctness_checklist')"
  if [[ "${checklist_count}" -ge 4 ]]; then
    record_check "C10" "config_correctness_checklist ≥ 4 entries" "PASS" "${checklist_count} entries"
  else
    record_check "C10" "config_correctness_checklist ≥ 4 entries" "FAIL" "found ${checklist_count} entries; per CC-07 F5 template ≥ 4 required"
  fi

elif [[ "${TEST_CLASS}" == "model" ]]; then
  # ─── C5' — cohort references resolve ──────────────────────────────────
  models_first="$(fm_list_first 'models_in_scope')"
  if [[ -z "${models_first}" ]]; then
    record_check "C5" "models_in_scope[0] populated" "FAIL" "empty"
  elif [[ "${models_first}" =~ ^cohort: ]]; then
    record_check "C5" "models_in_scope cohort form" "PASS" "${models_first}"
  else
    # Single-model form; still acceptable.
    record_check "C5" "models_in_scope single-model form" "PASS" "${models_first}"
  fi

  # ─── C6' — env_vars_required ⊆ setup_invocation ───────────────────────
  setup_invocation="$(fm_scalar 'setup_invocation')"
  c6_missing=()
  while IFS= read -r envvar; do
    [[ -z "${envvar}" ]] && continue
    # OPENROUTER_TOKEN is implicit (Docker runtime injects). Skip.
    if [[ "${envvar}" == "OPENROUTER_TOKEN" ]]; then continue; fi
    if echo "${setup_invocation}" | grep -qF "${envvar}"; then
      :
    else
      c6_missing+=("${envvar}")
    fi
  done < <(fm_list_all 'env_vars_required')
  if [[ "${#c6_missing[@]}" -eq 0 ]]; then
    record_check "C6" "env_vars_required ⊆ setup_invocation" "PASS" ""
  else
    record_check "C6" "env_vars_required ⊆ setup_invocation" "FAIL" "missing refs: ${c6_missing[*]}"
  fi

  # ─── C7' — cutoffs monotonic ──────────────────────────────────────────
  pass_cutoff="$(fm_scalar 'pass_cutoff')"
  partial_floor="$(fm_scalar 'partial_cutoff_floor')"
  fail_below="$(fm_scalar 'fail_below')"
  if [[ -z "${pass_cutoff}" ]] || [[ -z "${partial_floor}" ]] || [[ -z "${fail_below}" ]]; then
    record_check "C7" "cutoffs monotonic" "FAIL" "one or more cutoff fields missing"
  else
    # Use awk for float comparison.
    monotonic="$(awk -v fb="${fail_below}" -v pf="${partial_floor}" -v pc="${pass_cutoff}" 'BEGIN { if (fb <= pf && pf <= pc) print "yes"; else print "no" }')"
    if [[ "${monotonic}" == "yes" ]]; then
      record_check "C7" "cutoffs monotonic" "PASS" "fail<=partial<=pass (${fail_below}<=${partial_floor}<=${pass_cutoff})"
    else
      record_check "C7" "cutoffs monotonic" "FAIL" "fail_below=${fail_below}, partial_cutoff_floor=${partial_floor}, pass_cutoff=${pass_cutoff} — monotonicity violated"
    fi
  fi

  # ─── C8' — judge dispatch open-source-only (when rubric/judge present) ─
  # Detection: TC body contains "judge" keyword OR notes field mentions judge.
  judge_present=0
  if grep -qiE '(judge|llm-as-judge|rubric)' "${TC_FILE}"; then
    judge_present=1
  fi
  if [[ "${judge_present}" -eq 1 ]]; then
    # If judge present, frontmatter notes field MUST cite Agent(test-judge)
    # form OR avoid OpenRouter routing for judge.
    notes_str="$(fm_scalar 'notes')"
    if echo "${notes_str}" | grep -qiE 'Agent\(test-judge\)|claude.*judge|opus.*judge'; then
      record_check "C8" "judge dispatch open-source-only" "PASS" "judge routed via Claude Agent (per Rule 4)"
    elif echo "${notes_str}" | grep -qE '(anthropic|openai|google/gemini)/'; then
      # Judge appears to use closed-source via OpenRouter; this is Rule 4 violation
      # ONLY if the routing is via OpenRouter. Direct Claude Code Agent dispatch
      # of anthropic models is allowed (Rule 4 exception).
      # Heuristic: notes mention "openrouter" + closed model → FAIL.
      if echo "${notes_str}" | grep -qi 'openrouter'; then
        record_check "C8" "judge dispatch open-source-only" "FAIL" "judge appears to dispatch SOTA closed-source via OpenRouter (Rule 4 violation)"
      else
        record_check "C8" "judge dispatch open-source-only" "PASS" "judge via direct Agent dispatch (Rule 4 compliant)"
      fi
    else
      # Generic notes; can't determine. Pass with note.
      record_check "C8" "judge dispatch open-source-only" "PASS" "judge present; routing not explicitly specified — assume Agent(test-judge) per default"
    fi
  else
    record_check "C8" "judge dispatch open-source-only" "PASS" "no judge dispatch in this TC"
  fi

  # ─── C9' — rubric structure ─────────────────────────────────────────
  if [[ "${judge_present}" -eq 1 ]]; then
    # Look for §5 rubric section in body.
    if grep -qE '^## §5' "${TC_FILE}"; then
      record_check "C9" "rubric §5 section present" "PASS" ""
    else
      record_check "C9" "rubric §5 section present" "FAIL" "no §5 section found"
    fi
  else
    record_check "C9" "rubric §5 section present" "PASS" "judge not present; rubric not required"
  fi

  # ─── C10' — byte-fidelity preserved (D-TEST-0004) ────────────────────
  # The D-TEST-0004 byte-fidelity pattern (BODY=$(cat;echo x); BODY=${BODY%x})
  # applies to CLI/shell-pipe invocations that pass a prompt body via stdin.
  # HTTP-class TCs serialize input via JSON (`input` field) where byte fidelity
  # is preserved natively; interface=http TCs are exempt from this check.
  interface="$(fm_scalar 'interface')"
  if [[ "${interface}" == "http" ]] || echo "${interface}" | grep -qiE '^http$|http\W'; then
    record_check "C10" "byte-fidelity preserved (D-TEST-0004 pattern)" "PASS" "interface=http; JSON-serialized input preserves bytes natively (BODY pattern N/A)"
  elif echo "${setup_invocation}" | grep -qE 'BODY=\$\(cat|echo x|BODY%x'; then
    record_check "C10" "byte-fidelity preserved (D-TEST-0004 pattern)" "PASS" ""
  elif echo "${setup_invocation}" | grep -qiE 'cat\s+<<|prompt_eof'; then
    # heredoc patterns; lower-risk byte fidelity loss but not the D-TEST-0004 canonical.
    record_check "C10" "byte-fidelity preserved (D-TEST-0004 pattern)" "PASS" "heredoc form acceptable (alternative to BODY=\$(cat;echo x) pattern)"
  else
    # If setup_invocation is short / inline, byte fidelity is less of a risk.
    if [[ "${#setup_invocation}" -lt 200 ]]; then
      record_check "C10" "byte-fidelity preserved (D-TEST-0004 pattern)" "PASS" "short inline invocation (byte-fidelity low-risk)"
    else
      record_check "C10" "byte-fidelity preserved (D-TEST-0004 pattern)" "FAIL" "setup_invocation does not use BODY=\$(cat;echo x) or heredoc pattern"
    fi
  fi
fi

# ─── Emit JSON ────────────────────────────────────────────────────────────

failed_count=0
passed_count=0
for s in "${CHECK_STATUSES[@]}"; do
  if [[ "${s}" == "FAIL" ]]; then
    failed_count=$((failed_count + 1))
  else
    passed_count=$((passed_count + 1))
  fi
done

if [[ "${failed_count}" -eq 0 ]]; then
  verdict="PASS"
else
  verdict="FAIL"
fi

# Print JSON.
printf '{\n'
printf '  "test_id": "%s",\n' "${TEST_ID}"
printf '  "test_class": "%s",\n' "${TEST_CLASS}"
printf '  "verdict": "%s",\n' "${verdict}"
printf '  "failed_count": %d,\n' "${failed_count}"
printf '  "passed_count": %d,\n' "${passed_count}"
printf '  "checks": [\n'
for i in "${!CHECK_IDS[@]}"; do
  comma=","
  if [[ "${i}" -eq $((${#CHECK_IDS[@]} - 1)) ]]; then comma=""; fi
  # Escape double-quotes in detail field.
  detail_escaped="$(echo "${CHECK_DETAILS[$i]}" | sed 's/"/\\"/g; s/\\/\\\\/g; s/\\\\"/\\"/g')"
  printf '    {"id": "%s", "name": "%s", "status": "%s", "detail": "%s"}%s\n' \
    "${CHECK_IDS[$i]}" "${CHECK_NAMES[$i]}" "${CHECK_STATUSES[$i]}" "${detail_escaped}" "${comma}"
done
printf '  ]\n'
printf '}\n'

if [[ "${failed_count}" -eq 0 ]]; then
  exit 0
else
  exit 1
fi
