#!/usr/bin/env bash
# spec-lint.sh — gate for the facts-only n8n look-and-feel spec.
# Checks every builder-facing spec file (iphi-flow/docs/specs/n8n-vibe/*.md and design/*.md)
# for material the clean-room protocol forbids: code fences, n8n source paths, n8n token or
# component names, and the n8n logo colour. _provenance/ and _ref/ are excluded on purpose:
# they are reference-lane records that builders never read.
# Exit 0 = clean, 1 = findings.
set -uo pipefail

SPEC_DIR="${1:-/root/projects/phi/iphi-flow/docs/specs/n8n-vibe}"
mapfile -t FILES < <(find "$SPEC_DIR" -maxdepth 2 -name '*.md' -not -path '*/_provenance/*' -not -path '*/_ref/*' | sort)

declare -A RULES=(
  ['code fence']='^[[:space:]]*```'
  ['n8n source path']='packages/frontend|editor-ui/|design-system/src|@n8n/|nodes-base/'
  ['n8n token name']='--color--|--canvas--|--node--|--spacing--|--radius--|--font-size--|--text-color--|--background--|--border-color--|--icon-color--'
  ['n8n component name']='\bN8n[A-Z][A-Za-z]+|\.vue\b|NodeCreator|NodeDetailsView|CanvasNode[A-Z]|vue-flow'
  ['n8n logo colour']='#?ff6d5a|255, ?109, ?90'
  ['SVG path data']='\b[Mm] ?-?[0-9.]+[ ,]-?[0-9.]+ ?[LlCcQqAaHhVv] ?-?[0-9.]'
)

findings=0
for rule in "${!RULES[@]}"; do
  pattern="${RULES[$rule]}"
  targets=("${FILES[@]}")
  if [[ "$rule" == 'n8n logo colour' ]]; then
    # 00-index.md carries the never-use list, which must name the colour it forbids.
    targets=()
    for f in "${FILES[@]}"; do [[ "$(basename "$f")" != '00-index.md' ]] && targets+=("$f"); done
  fi
  hits=$(grep -nE "$pattern" "${targets[@]}" 2>/dev/null || true)
  if [[ -n "$hits" ]]; then
    count=$(echo "$hits" | wc -l)
    findings=$((findings + count))
    echo "== $rule: $count hit(s)"
    echo "$hits" | head -20
  fi
done

echo "-- files checked: ${#FILES[@]}"
for f in "${FILES[@]}"; do
  mentions=$(grep -oi 'n8n' "$f" | wc -l)
  echo "   $(basename "$f"): mentions of the word n8n = $mentions (informational)"
done

if [[ $findings -gt 0 ]]; then
  echo "RESULT: FAIL ($findings finding(s))"
  exit 1
fi
echo "RESULT: PASS"
exit 0
