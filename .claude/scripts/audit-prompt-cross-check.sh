#!/usr/bin/env bash
# audit-prompt-cross-check.sh — gate-3 audit-prompt-authoring cross-check (6-axis)
#
# Usage: audit-prompt-cross-check.sh <plan.md path> <audit-prompt path>
#
# Emits one line per axis: `[axis]<axis-name>: PASS|DIVERGENT - <evidence>`.
# 6 axes (added 2026-05-25 per CH-17-i-phi retro `e764aeca` proposal #1 consolidation
# of axes accreted across CH-04/CH-16b/CH-07a/CH-07b/CH-10/CH-11a):
#
#   1. F-token        — F<N>.<letter> tokens in prompt vs LOCKED rows in plan §1/§3
#   2. lock-body      — non-F-token paraphrases of Code-binding sentences (heuristic)
#   3. test-name      — `test_<name>` tokens in prompt vs plan §8 named-test rows
#   4. method-sig     — `<TypeName>::<method>(...)` tokens vs plan §1+§4 signatures
#   5. arg-shape      — `&mut T` vs `Arc<Mutex<T>>` etc. (heuristic line grep)
#   6. literal-count  — N preceding "variants"/"fields"/"routes"/"paths"/"annotations"/"layers"
#
# Exit codes:
#   0  all axes PASS
#   1  ≥ 1 axis DIVERGENT
#   2  usage / input error

set -uo pipefail

PLAN="${1:-}"
PROMPT="${2:-}"

if [[ -z "$PLAN" || -z "$PROMPT" ]]; then
  echo "usage: $0 <plan.md path> <audit-prompt path>" >&2
  exit 2
fi
if [[ ! -f "$PLAN" ]]; then
  echo "[error] plan file not found: $PLAN" >&2
  exit 2
fi
if [[ ! -f "$PROMPT" ]]; then
  echo "[error] prompt file not found: $PROMPT" >&2
  exit 2
fi

EXIT=0

# Axis 1 — F-token
PROMPT_FTOKENS=$(grep -oE 'F[-A-Za-z0-9]+\.[a-z]' "$PROMPT" | sort -u || true)
PLAN_FTOKENS=$(grep -oE 'F[-A-Za-z0-9]+\.[a-z]' "$PLAN" | sort -u || true)
MISSING_F=$(comm -23 <(echo "$PROMPT_FTOKENS") <(echo "$PLAN_FTOKENS") | grep -v '^$' || true)
if [[ -z "$MISSING_F" ]]; then
  echo "[axis]f-token: PASS - $(echo "$PROMPT_FTOKENS" | wc -l) tokens all present in plan"
else
  echo "[axis]f-token: DIVERGENT - prompt cites unknown tokens: $(echo "$MISSING_F" | tr '\n' ' ')"
  EXIT=1
fi

# Axis 2 — lock-body (heuristic: presence-check anchor phrases per §1)
LOCK_BODY_COUNT=$(grep -cE "^#### F[-A-Za-z0-9]+ = F[-A-Za-z0-9]+\.[a-z]" "$PLAN" || true)
PROMPT_LOCKMENTIONS=$(grep -cE "lock body|locked.*body|Code-(level )?binding|F-LOCKED" "$PROMPT" || true)
if [[ "$LOCK_BODY_COUNT" -gt 0 && "$PROMPT_LOCKMENTIONS" -gt 0 ]]; then
  echo "[axis]lock-body: PASS - plan has $LOCK_BODY_COUNT lock-body subsections; prompt cites $PROMPT_LOCKMENTIONS lock-body references"
else
  echo "[axis]lock-body: DIVERGENT - plan lock-body count=$LOCK_BODY_COUNT prompt lock-mentions=$PROMPT_LOCKMENTIONS (manual review recommended)"
  EXIT=1
fi

# Axis 3 — test-name
PROMPT_TESTS=$(grep -oE 'test_[a-z_0-9]+' "$PROMPT" | sort -u || true)
PLAN_TESTS=$(grep -oE 'test_[a-z_0-9]+' "$PLAN" | sort -u || true)
UNKNOWN_TESTS=$(comm -23 <(echo "$PROMPT_TESTS") <(echo "$PLAN_TESTS") | grep -v '^$' || true)
if [[ -z "$UNKNOWN_TESTS" ]]; then
  echo "[axis]test-name: PASS - $(echo "$PROMPT_TESTS" | grep -c .) tokens all present in plan"
else
  echo "[axis]test-name: DIVERGENT - prompt cites tests not in plan: $(echo "$UNKNOWN_TESTS" | tr '\n' ' ')"
  EXIT=1
fi

# Axis 4 — method-sig
PROMPT_METHODS=$(grep -oE '[A-Z][A-Za-z0-9]+::[a-z_][a-z_0-9]*\([^)]*\)' "$PROMPT" | sort -u || true)
if [[ -z "$PROMPT_METHODS" ]]; then
  echo "[axis]method-sig: PASS - no method signatures cited (nothing to verify)"
else
  MISMATCHED=0
  while IFS= read -r METHOD; do
    [[ -z "$METHOD" ]] && continue
    NAME="${METHOD%%(*}"
    if ! grep -qF "$NAME" "$PLAN"; then
      MISMATCHED=$((MISMATCHED + 1))
    fi
  done <<< "$PROMPT_METHODS"
  if [[ "$MISMATCHED" -eq 0 ]]; then
    echo "[axis]method-sig: PASS - $(echo "$PROMPT_METHODS" | wc -l) method names all present in plan"
  else
    echo "[axis]method-sig: DIVERGENT - $MISMATCHED method name(s) in prompt not in plan (manual signature review recommended)"
    EXIT=1
  fi
fi

# Axis 5 — arg-shape (heuristic)
ARG_SHAPE_PROMPT=$(grep -oE '&mut [A-Za-z]+|Arc<Mutex<[^>]+>>|Arc<RwLock<[^>]+>>|Arc<[A-Z][A-Za-z]+>|&dyn [A-Z]' "$PROMPT" | sort -u || true)
if [[ -z "$ARG_SHAPE_PROMPT" ]]; then
  echo "[axis]arg-shape: PASS - no concurrent-safe arg-shapes cited"
else
  MATCHED=0
  TOTAL=0
  while IFS= read -r SHAPE; do
    [[ -z "$SHAPE" ]] && continue
    TOTAL=$((TOTAL + 1))
    if grep -qF "$SHAPE" "$PLAN"; then
      MATCHED=$((MATCHED + 1))
    fi
  done <<< "$ARG_SHAPE_PROMPT"
  if [[ "$MATCHED" -eq "$TOTAL" ]]; then
    echo "[axis]arg-shape: PASS - $TOTAL arg-shape(s) all present in plan"
  else
    echo "[axis]arg-shape: DIVERGENT - $((TOTAL - MATCHED)) of $TOTAL arg-shape(s) in prompt not in plan"
    EXIT=1
  fi
fi

# Axis 6 — literal-count (numeric tokens preceding variants/fields/routes/paths/annotations/layers/sub-decisions)
LITERAL_RE='[0-9]+[[:space:]-]*(variants?|fields?|routes?|paths?|annotations?|layers?|sub-decisions?|tests?)'
LITERALS_PROMPT=$(grep -oE "$LITERAL_RE" "$PROMPT" | sort -u || true)
if [[ -z "$LITERALS_PROMPT" ]]; then
  echo "[axis]literal-count: PASS - no quantified literals cited"
else
  MATCHED=0
  TOTAL=0
  while IFS= read -r LIT; do
    [[ -z "$LIT" ]] && continue
    TOTAL=$((TOTAL + 1))
    if grep -qF "$LIT" "$PLAN"; then
      MATCHED=$((MATCHED + 1))
    fi
  done <<< "$LITERALS_PROMPT"
  if [[ "$MATCHED" -eq "$TOTAL" ]]; then
    echo "[axis]literal-count: PASS - $TOTAL literal(s) all present verbatim in plan"
  else
    echo "[axis]literal-count: DIVERGENT - $((TOTAL - MATCHED)) of $TOTAL literal(s) in prompt absent from plan (e.g., '5 variants' vs plan's '7 variants')"
    EXIT=1
  fi
fi

exit $EXIT