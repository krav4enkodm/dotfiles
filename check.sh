#!/usr/bin/env bash
# Check the repo is consistent before installing or merging. Touches nothing.
#
#   ./check.sh    exit 1 if any check fails
#
# - shell scripts pass shellcheck at warning level and above (skipped with a
#   warning if it isn't installed)
# - JSON config parses
# - every skill and agent has a frontmatter name matching its path
# - README's Skills and Agents tables list exactly what's in claude/
# - links and ~/.claude/... paths inside claude/ point at files that exist
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO/claude"
cd "$REPO"

FAILED=0
say()  { printf '  \033[%sm%-5s\033[0m %s\n' "$1" "$2" "$3"; }
ok()   { say 32 ok "$1"; }
fail() { FAILED=1; say 31 fail "$1"; }
warn() { say 33 warn "$1"; }

frontmatter_name() { # frontmatter_name <file>: the name: field of its YAML frontmatter
  awk 'NR==1 && $0!="---" {exit} NR>1 && $0=="---" {exit} NR>1 && /^name:/ {sub(/^name:[ \t]*/, ""); print; exit}' "$1"
}

# ------------------------------------------------------------------ shellcheck
echo "Shell"
scripts=(install.sh check.sh claude/statusline-command.sh)
if command -v shellcheck >/dev/null 2>&1; then
  for s in "${scripts[@]}"; do
    if out="$(shellcheck --severity=warning "$s" 2>&1)"; then ok "$s"; else fail "$s"; printf '%s\n' "$out" | sed 's/^/        /'; fi
  done
else
  warn "shellcheck not installed — skipped (CI runs it)"
fi

# ------------------------------------------------------------------------ json
echo
echo "JSON"
for f in claude/*.json; do
  if jq empty "$f" 2>/dev/null; then ok "$f"; else fail "$f does not parse"; fi
done

# ----------------------------------------------------------- skills and agents
echo
echo "Skills and agents"
skills=() agents=()
for d in "$SRC"/skills/*/; do
  name="$(basename "$d")"; skills+=("$name")
  f="$d/SKILL.md"
  if [ ! -f "$f" ]; then fail "skills/$name has no SKILL.md"; continue; fi
  fm="$(frontmatter_name "$f")"
  [ "$fm" = "$name" ] && ok "skills/$name" || fail "skills/$name/SKILL.md has name: '${fm}', expected '$name'"
done
for f in "$SRC"/agents/*.md; do
  name="$(basename "$f" .md)"; agents+=("$name")
  fm="$(frontmatter_name "$f")"
  [ "$fm" = "$name" ] && ok "agents/$name" || fail "agents/$name.md has name: '${fm}', expected '$name'"
done

# ---------------------------------------------------------------------- readme
# Rows look like: | `name` | ... — taken from the "## Skills" / "## Agents" sections.
echo
echo "README tables"
readme_rows() { # readme_rows <section heading>
  awk -v h="## $1" '$0==h {on=1; next} /^## / {on=0} on && /^\| `[^`]+` \|/' README.md \
    | sed -E 's/^\| `([^`]+)`.*/\1/' | sort
}
compare() { # compare <label> <section> <names...>
  local label="$1" section="$2"; shift 2
  local want have
  want="$(printf '%s\n' "$@" | sort)"
  have="$(readme_rows "$section")"
  if [ "$want" = "$have" ]; then ok "$label table matches claude/$label"; return; fi
  comm -23 <(echo "$want") <(echo "$have") | while read -r n; do [ -n "$n" ] && fail "$label: '$n' is missing from README"; done
  comm -13 <(echo "$want") <(echo "$have") | while read -r n; do [ -n "$n" ] && fail "$label: README lists '$n', which isn't in claude/$label"; done
  FAILED=1
}
compare skills Skills "${skills[@]}"
compare agents Agents "${agents[@]}"

# ----------------------------------------------------------------------- links
# Relative markdown links resolve from the file's own directory; ~/.claude/...
# paths resolve against claude/, since that's where the installer copies from.
echo
echo "Links in claude/"
broken=0
while IFS= read -r f; do
  dir="$(dirname "$f")"
  while IFS= read -r target; do
    target="${target%%#*}"
    [ -n "$target" ] || continue
    [ -e "$dir/$target" ] || { fail "$f -> $target"; broken=1; }
  done < <(grep -oE '\]\([^)]+\)' "$f" | sed -E 's/^\]\(|\)$//g' | grep -vE '^(https?:|mailto:|#)' || true)
  # The literal text "~/.claude/..." is what's being matched, so it stays unexpanded.
  # shellcheck disable=SC2088
  while IFS= read -r path; do
    [ -e "$SRC/${path#\~/.claude/}" ] || { fail "$f -> $path"; broken=1; }
  done < <(grep -oE '~/\.claude/(skills|agents)/[A-Za-z0-9_./-]+[A-Za-z0-9_]' "$f" || true)
done < <(find claude -name '*.md' | sort)
[ "$broken" = 0 ] && ok "all links resolve"

# ------------------------------------------------------------------------ done
echo
if [ "$FAILED" = 0 ]; then echo "All checks passed."; else echo "Checks failed."; fi
exit "$FAILED"
