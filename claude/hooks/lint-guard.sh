#!/usr/bin/env bash
# Lints what Claude wrote, once per turn, with the repo's own ESLint. Reads the
# hook JSON on stdin.
#
#   lint-guard.sh record   PostToolUse on Edit|Write: remember the file (instant)
#   lint-guard.sh check    Stop: lint the remembered files and report problems
#                          on the lines this working tree changed. Exit 2 sends
#                          them back to Claude to fix; silent when clean.
#
# On top of the repo's config it turns on a few core rules (see EXTRA_RULES)
# that need no plugin. Problems on untouched lines are ignored, so Claude
# doesn't start fixing code it wasn't asked to change. Skips repos without a
# local eslint binary. A failed run never blocks. CLAUDE_LINT_GUARD=0 turns it
# off.
set -uo pipefail

[ "${CLAUDE_LINT_GUARD:-1}" = 0 ] && exit 0
mode="${1:-}"
input="$(cat)"
field() { jq -r "$1 // empty" <<<"$input" 2>/dev/null; }

session="$(field .session_id)"
[ -n "$session" ] || exit 0
state="${XDG_STATE_HOME:-$HOME/.local/state}/claude-lint-guard"
list="$state/$session.files"
rounds="$state/$session.rounds"
mkdir -p "$state"

case "$mode" in
  record)
    file="$(field .tool_input.file_path)"
    case "$file" in
      *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs) echo "$file" >>"$list" ;;
    esac
    exit 0 ;;
  check) ;;
  *) exit 0 ;;
esac

find "$state" -type f -mtime +7 -delete 2>/dev/null
[ -s "$list" ] || exit 0

# Claude is already fixing what an earlier check reported: allow one re-check,
# then let the turn end rather than loop.
if [ "$(field .stop_hook_active)" = true ]; then
  n="$(cat "$rounds" 2>/dev/null || echo 0)"
  if [ "$n" -ge 2 ]; then rm -f "$list" "$rounds"; exit 0; fi
  echo $((n + 1)) >"$rounds"
else
  echo 1 >"$rounds"
fi

EXTRA_RULES=(
  --rule 'no-nested-ternary: error'
  --rule 'no-negated-condition: error'
  --rule 'no-unneeded-ternary: error'
  --rule 'no-implicit-coercion: [error, {boolean: true, number: false, string: false}]'
)

report=""
while IFS= read -r root; do
  [ -x "$root/node_modules/.bin/eslint" ] || continue
  files=()
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    [ "$(git -C "$(dirname "$f")" rev-parse --show-toplevel 2>/dev/null)" = "$root" ] && files+=("$f")
  done < <(sort -u "$list")
  [ "${#files[@]}" -gt 0 ] || continue

  # Lines this working tree adds or changes, as "path:line" (untracked files: all).
  changed="$(
    for f in "${files[@]}"; do
      if git -C "$root" ls-files --error-unmatch -- "$f" >/dev/null 2>&1; then
        git -C "$root" diff -U0 HEAD -- "$f" | awk -v f="$f" '
          /^@@/ { split($3, a, ","); s = substr(a[1], 2); c = (a[2] == "" ? 1 : a[2]);
                  for (i = 0; i < c; i++) print f ":" s + i }'
      else
        awk -v f="$f" '{ print f ":" NR }' "$f"
      fi
    done
  )"
  [ -n "$changed" ] || continue

  out="$(cd "$root" && timeout 110 ./node_modules/.bin/eslint --quiet \
          -f unix "${EXTRA_RULES[@]}" "${files[@]}" 2>/dev/null)"
  [ $? -le 1 ] || continue   # 2+ = config error or timeout: don't block on our own failure

  hits="$(awk -F: 'NR == FNR { keep[$1 ":" $2] = 1; next }
                   ($1 ":" $2) in keep' <(echo "$changed") <(echo "$out"))"
  [ -n "$hits" ] && report+="$hits"$'\n'
done < <(while IFS= read -r f; do git -C "$(dirname "$f")" rev-parse --show-toplevel 2>/dev/null; done < <(sort -u "$list") | sort -u)

if [ -z "$report" ]; then
  rm -f "$list" "$rounds"
  exit 0
fi

{
  echo "lint-guard: ESLint problems on lines you changed this turn. Fix them, or say why a line should stay as it is:"
  printf '%s' "$report"
} >&2
exit 2
