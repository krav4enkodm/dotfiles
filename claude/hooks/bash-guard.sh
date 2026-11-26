#!/usr/bin/env bash
# PreToolUse guard for Bash calls. Reads the hook JSON on stdin. Exit 2 blocks
# the call, and the message on stderr goes back to Claude.
#
#   bash-guard.sh session    every session: no commits on the default branch,
#                            no PRs created as ready for review
#   bash-guard.sh reviewer   readiness-reviewer, rules-reviewer: read-only
#                            commands only
#   bash-guard.sh validator  ticket-validator, design-validator: run anything
#                            except commands that change git state or touch
#                            GitHub
#
# It matches command text, so it catches the forms Claude normally writes, not
# every possible one (`sh -c '...'` gets past it). A guardrail, not a sandbox.
set -uo pipefail

mode="${1:-session}"
input="$(cat)"
cmd="$(jq -r '.tool_input.command // empty' <<<"$input" 2>/dev/null)"
dir="$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null)"
[ -n "$cmd" ] || exit 0
[ -n "$dir" ] || dir="$PWD"

block() { echo "Blocked by bash-guard ($mode): $1" >&2; exit 2; }

resolve() { # resolve <base dir> <path>
  case "$2" in
    /*) echo "$2" ;;
    "~"*) echo "${2/#\~/$HOME}" ;;
    *) echo "$1/$2" ;;
  esac
}

# Text that isn't a command: drop heredoc bodies, and blank out separators
# inside quotes, so a commit message saying "a; gh pr create" isn't split.
code_only() {
  awk '
    skip != "" { t = $0; sub(/^[ \t]+/, "", t); if (t == skip) skip = ""; next }
    { print
      if (match($0, /<<-?[ \t]*["\047]?[A-Za-z_][A-Za-z0-9_]*/) && substr($0, RSTART - 1, 1) != "<") {
        d = substr($0, RSTART, RLENGTH); sub(/^<<-?[ \t]*["\047]?/, "", d); skip = d } }
  ' <<<"$1" | awk '
    { s = s (NR > 1 ? "\n" : "") $0 }
    END {
      q = ""; out = ""
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (q == "") { if (c == "\047" || c == "\"") q = c }
        else if (q == "\"" && c == "\\") { out = out c substr(s, i + 1, 1); i++; continue }
        else if (c == q) q = ""
        else if (c ~ /[;|&\n]/) c = " "
        out = out c
      }
      print out
    }'
}

# One simple command per line: split on && || ; | and newlines, then drop
# leading subshell characters and VAR=value assignments.
segments() {
  code_only "$1" | awk '{
    gsub(/\|\||&&|\|&|;|\|/, "\n")
    n = split($0, parts, "\n")
    for (i = 1; i <= n; i++) {
      s = parts[i]
      sub(/^[ \t($`{]+/, "", s); sub(/[ \t]+$/, "", s)
      while (match(s, /^[A-Za-z_][A-Za-z0-9_]*=[^ \t]*[ \t]+/)) s = substr(s, RLENGTH + 1)
      print s
    }
  }'
}

# parse_git <segment> <dir>: for a git command, sets GDIR (after -C), GSUB (the
# subcommand) and GREST (its arguments), skipping git's global options.
parse_git() {
  local -a w
  read -r -a w <<<"$1"
  GDIR="$2" GSUB="" GREST=""
  [ "${w[0]:-}" = git ] || return 1
  local i=1
  while [ "$i" -lt "${#w[@]}" ]; do
    case "${w[$i]}" in
      -C) i=$((i + 1)); GDIR="$(resolve "$GDIR" "${w[$i]:-.}")" ;;
      -c|--git-dir|--work-tree|--namespace) i=$((i + 1)) ;;
      -*) ;;
      *) GSUB="${w[$i]}"; GREST="${w[*]:$((i + 1))}"; return 0 ;;
    esac
    i=$((i + 1))
  done
}

# on_default_branch <dir>: true when HEAD is the repo's default branch.
# A repo with no commits yet, or a detached HEAD, is never on it.
on_default_branch() {
  local branch default
  git -C "$1" rev-parse --verify -q HEAD >/dev/null 2>&1 || return 1
  branch="$(git -C "$1" symbolic-ref --short -q HEAD 2>/dev/null)" || return 1
  default="$(git -C "$1" symbolic-ref --short -q refs/remotes/origin/HEAD 2>/dev/null)"
  default="${default#origin/}"
  BRANCH="$branch"
  if [ -n "$default" ]; then [ "$branch" = "$default" ]; else [ "$branch" = main ] || [ "$branch" = master ]; fi
}

has_word() { # has_word <words> <word>...
  local words=" $1 " w
  shift
  for w in "$@"; do case "$words" in *" $w "*|*" $w="*) return 0 ;; esac; done
  return 1
}

check_session() { # check_session <segment> <dir>
  local seg="$1"
  if parse_git "$seg" "$2" && [ "$GSUB" = commit ] && on_default_branch "$GDIR"; then
    block "'$BRANCH' is the default branch. Create a branch first (git switch -c <name>), then commit."
  fi
  if [[ "$seg" =~ ^gh([[:space:]]+(-R|--repo)[[:space:]=]+[^[:space:]]+)*[[:space:]]+pr[[:space:]]+create([[:space:]]|$) ]] \
     && ! has_word "$seg" --draft -d --web -w; then
    block "PRs are opened as drafts. Add --draft."
  fi
}

READ_GIT="log show diff blame status rev-parse ls-files ls-tree grep cat-file describe shortlog merge-base rev-list name-rev for-each-ref"
READ_CMDS="cd ls cat head tail grep rg find wc jq sort uniq cut tr file stat tree pwd echo which diff sed basename dirname realpath"

check_reviewer() { # check_reviewer <segment> <dir>
  local seg="$1" first
  first="${seg%%[[:space:]]*}"
  if parse_git "$seg" "$2"; then
    has_word "$READ_GIT" "$GSUB" || block "only read-only git commands ($READ_GIT)."
    return
  fi
  has_word "$READ_CMDS" "$first" || block "'$first' isn't on the read-only list. Use Read, Grep or Glob instead."
  case "$first" in
    find) ! has_word "$seg" -delete -exec -execdir -ok -okdir -fprint -fprintf || block "find may only search." ;;
    sed) ! has_word "$seg" -i --in-place || block "sed may only print." ;;
  esac
}

check_validator() { # check_validator <segment> <dir>
  local seg="$1" first
  first="${seg%%[[:space:]]*}"
  [ "$first" = gh ] && block "the validator doesn't touch GitHub."
  if parse_git "$seg" "$2"; then
    case "$GSUB" in
      commit|push|pull|reset|checkout|switch|stash|rebase|merge|cherry-pick|revert|clean|restore|tag|am|apply|worktree|update-ref)
        block "the validator doesn't change git state ('git $GSUB')." ;;
      branch) ! has_word "$GREST" -d -D -m -M -c -C -f --delete --move --copy --force \
                || block "the validator doesn't change branches." ;;
    esac
  fi
}

if [ "$mode" = reviewer ]; then
  stripped="$(code_only "$cmd" | sed -E "s/\"[^\"]*\"//g; s/'[^']*'//g" \
    | sed -E 's/[0-9&]?>+[[:space:]]*\/dev\/null//g; s/[0-9]>&[0-9]//g')"
  case "$stripped" in *">"*) block "no output redirection. Read-only commands only." ;; esac
fi

while IFS= read -r seg; do
  [ -n "$seg" ] || continue
  if [[ "$seg" =~ ^cd([[:space:]]+(.*))?$ ]]; then
    target="${BASH_REMATCH[2]:-$HOME}"
    target="${target//\"/}"; target="${target//\'/}"
    dir="$(resolve "$dir" "$target")"
  fi
  check_session "$seg" "$dir"
  case "$mode" in
    reviewer) check_reviewer "$seg" "$dir" ;;
    validator) check_validator "$seg" "$dir" ;;
  esac
done < <(segments "$cmd")
exit 0
