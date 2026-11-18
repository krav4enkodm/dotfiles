#!/usr/bin/env bash
# List the tickets work-work shipped whose PRs merged after a date, oldest
# merge first, so the work-retro skill knows what to look back at.
#
#   merged-tickets.sh [since]    since: an ISO date or time; default: the time
#                                in ~/work-work/retros/last-run, else 14 days ago
#
# Reads the run tables in ~/work-work/<project>/batch*.md (the Ticket, Branch
# and PR columns, found by header name) and asks gh whether each PR merged.
# Prints one tab-separated line per ticket:
#   merged-at  project  ticket  pr-url  workspace  transcripts  coordinator
# workspace is ~/work-work/<project>/<ticket>, transcripts the Claude Code
# folder of that ticket's worktree, and coordinator the sessions that drove
# its run (outside a worktree, ran /work-work, name the ticket), separated by
# spaces. Each is "-" when there is none. Batch files get renamed after a
# run, so the ticket id is the reliable link, not the batch file's path.
set -euo pipefail

root="$HOME/work-work"
since="${1:-}"
if [ -z "$since" ] && [ -s "$root/retros/last-run" ]; then since="$(cat "$root/retros/last-run")"; fi
[ -n "$since" ] || since="$(date -u -d '14 days ago' +%Y-%m-%dT%H:%M:%SZ)"
since="$(date -u -d "$since" +%Y-%m-%dT%H:%M:%SZ)"
echo "since: $since" >&2

# project <tab> ticket <tab> branch <tab> pr, one per PR
rows() {
  for f in "$root"/*/batch*.md; do
    [ -f "$f" ] || continue
    awk -F'|' -v project="$(basename "$(dirname "$f")")" '
      function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
      /^\|/ && !t { for (i = 2; i < NF; i++) { h = trim($i); if (h == "Ticket") t = i; if (h == "Branch") b = i; if (h == "PR") p = i }; next }
      /^\|/ && t && p && match($p, /https:\/\/github\.com\/[^ )|]+\/pull\/[0-9]+/) {
        print project "\t" trim($t) "\t" (b ? trim($b) : "") "\t" substr($p, RSTART, RLENGTH)
      }
      !/^\|/ { t = 0; b = 0; p = 0 }
    ' "$f"
  done | sort -u -t$'\t' -k4,4
}

# Sessions outside herdr worktrees that ran /work-work: the coordinators. The
# command must be a message the user sent; the string alone also turns up in
# tool output (a session that reads this skill, for one).
ran_work_work() {
  jq -e 'select(.type == "user" and (.message.content | type) == "string"
                and (.message.content | test("<command-name>/work-work</command-name>")))' "$1" >/dev/null 2>&1
}
runs=()
while IFS= read -r f; do ran_work_work "$f" && runs+=("$f"); done < <(
  grep -lF '<command-name>/work-work</command-name>' "$HOME"/.claude/projects/*/*.jsonl 2>/dev/null | grep -v -- '-herdr-worktrees-' || true
)
coordinators() { # coordinators <ticket>: the runs that name it, space-separated
  [ "${#runs[@]}" -gt 0 ] || return 0
  grep -lF "$1" "${runs[@]}" 2>/dev/null | tr '\n' ' ' | sed 's/ $//' || true
}

rows | while IFS=$'\t' read -r project ticket branch pr; do
  merged="$(gh pr view "$pr" --json mergedAt --jq '.mergedAt // ""' 2>/dev/null || true)"
  [ -n "$merged" ] && [[ "$merged" > "$since" ]] || continue
  ws="$root/$project/$ticket"; [ -d "$ws" ] || ws=-
  tr=-
  if [ -n "$branch" ]; then
    for d in "$HOME"/.claude/projects/*-"$(printf '%s' "$branch" | sed 's/[^A-Za-z0-9]/-/g')"; do
      [ -d "$d" ] && tr="$d" && break
    done
  fi
  co="$(coordinators "$ticket")"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$merged" "$project" "$ticket" "$pr" "$ws" "$tr" "${co:--}"
done | sort
