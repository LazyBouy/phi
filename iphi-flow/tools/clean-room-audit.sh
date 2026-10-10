#!/usr/bin/env bash
# clean-room-audit.sh — phase-gate audit for the n8n look-and-feel work
# (plan: iphi-flow/docs/plans/n8n-look-and-feel-clean-room.md, "Audit gate").
# Compares what the Activepieces fork changed against the n8n reference tree, with three checks:
#   1. asset hashes   — sha256 of every added/changed asset vs every n8n file of the same kinds
#   2. code overlap   — 30-token shingle overlap of changed text files vs n8n/packages/frontend
#                       (shingles already present in the same files at BASE are excluded)
#   3. forbidden text — added diff lines vs clean-room-forbidden.txt
# Usage:
#   clean-room-audit.sh [BASE] [HEAD]   audit committed range BASE...HEAD (default main...dev);
#                                       file versions are read from git, not from the working tree
#   clean-room-audit.sh BASE WORKTREE   audit uncommitted working-tree changes (incl. untracked files)
# This is the ONLY script the clean-room guard hook lets touch iphi-flow/n8n.
# Exit 0 = all clean; 1 = at least one finding (review each; some may be false positives).
set -uo pipefail

AP=/root/projects/phi/iphi-flow/activepieces
N8N=/root/projects/phi/iphi-flow/n8n
TOOLS=/root/projects/phi/iphi-flow/tools
BASE="${1:-main}"
HEAD="${2:-dev}"
WORK=$(mktemp -d)
status=0
ASSET_RE='\.(svg|png|jpe?g|gif|webp|ico|woff2?|ttf|otf|eot|mp4|webm|lottie|json)$'

echo "== clean-room audit: $AP $BASE..$HEAD"
if [[ "$HEAD" == "WORKTREE" ]]; then
  git -C "$AP" diff --name-only --diff-filter=AM "$BASE" -- > "$WORK/tracked.txt" || { echo "ERROR: git diff against $BASE failed"; exit 2; }
  git -C "$AP" ls-files --others --exclude-standard > "$WORK/untracked.txt" || { echo "ERROR: git ls-files failed"; exit 2; }
  cat "$WORK/tracked.txt" "$WORK/untracked.txt" | grep -vE '(^|/)\.env' | sort -u > "$WORK/changed-rel.txt"
  mkdir -p "$WORK/head"
  while IFS= read -r rel; do
    [[ -z "$rel" || ! -f "$AP/$rel" ]] && continue
    mkdir -p "$WORK/head/$(dirname "$rel")"
    cp "$AP/$rel" "$WORK/head/$rel"
  done < "$WORK/changed-rel.txt"
  { git -C "$AP" diff -U0 "$BASE" -- . ':(exclude).env*' | grep -E '^\+[^+]';
    git -C "$AP" ls-files --others --exclude-standard | grep -vE '(^|/)\.env' \
      | while IFS= read -r rel; do sed 's/^/+/' "$AP/$rel"; done; } > "$WORK/added.txt" || true
else
  git -C "$AP" diff --name-only --diff-filter=AM "$BASE...$HEAD" -- > "$WORK/changed-rel.txt" || { echo "ERROR: git diff $BASE...$HEAD failed"; exit 2; }
  mkdir -p "$WORK/head"
  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    mkdir -p "$WORK/head/$(dirname "$rel")"
    git -C "$AP" show "$HEAD:$rel" > "$WORK/head/$rel"
  done < "$WORK/changed-rel.txt"
  git -C "$AP" diff -U0 "$BASE...$HEAD" -- | grep -E '^\+[^+]' > "$WORK/added.txt" || true
fi
sed "s#^#$WORK/head/#" "$WORK/changed-rel.txt" > "$WORK/changed.txt"
echo "changed files: $(wc -l < "$WORK/changed.txt")"

echo "== 1. asset hashes"
grep -iE "$ASSET_RE" "$WORK/changed.txt" > "$WORK/assets.txt" || true
if [[ -s "$WORK/assets.txt" ]]; then
  xargs -d '\n' sha256sum < "$WORK/assets.txt" | awk '{print $1}' | sort -u > "$WORK/ap-hashes.txt"
  find "$N8N" -type f -regextype posix-extended -iregex ".*$ASSET_RE" -not -path '*/node_modules/*' -print0 \
    | xargs -0 sha256sum | sort > "$WORK/n8n-hashes.txt"
  matches=$(awk 'NR==FNR{h[$1]=1; next} ($1 in h){print $2}' "$WORK/ap-hashes.txt" "$WORK/n8n-hashes.txt")
  if [[ -n "$matches" ]]; then
    echo "FINDING: changed AP assets identical to n8n files:"
    echo "$matches"
    status=1
  else
    echo "assets checked: $(wc -l < "$WORK/assets.txt"); identical to n8n: 0"
  fi
else
  echo "no changed assets"
fi

echo "== 2. code overlap (30-token shingles vs n8n/packages/frontend; overlap already on $BASE excluded)"
mkdir -p "$WORK/base"
: > "$WORK/baseline.txt"
while IFS= read -r rel; do
  [[ -z "$rel" ]] && continue
  if git -C "$AP" cat-file -e "$BASE:$rel" 2>/dev/null; then
    mkdir -p "$WORK/base/$(dirname "$rel")"
    git -C "$AP" show "$BASE:$rel" > "$WORK/base/$rel"
    echo "$WORK/base/$rel" >> "$WORK/baseline.txt"
  fi
done < "$WORK/changed-rel.txt"
node "$TOOLS/clean-room-overlap.mjs" "$WORK/changed.txt" "$N8N/packages/frontend" 30 "$WORK/baseline.txt" || status=1

echo "== 3. forbidden text in added lines"
grep -vE '^\s*(#|$)' "$TOOLS/clean-room-forbidden.txt" > "$WORK/forbidden.txt"
hits=$(grep -inEf "$WORK/forbidden.txt" "$WORK/added.txt" || true)
if [[ -n "$hits" ]]; then
  echo "FINDING: forbidden text in added lines:"
  echo "$hits" | head -40
  status=1
else
  echo "added lines checked: $(wc -l < "$WORK/added.txt"); forbidden hits: 0"
fi

rm -r "$WORK"
if [[ $status -eq 0 ]]; then echo "RESULT: PASS"; else echo "RESULT: FINDINGS — review above"; fi
exit $status
