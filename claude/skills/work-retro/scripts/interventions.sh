#!/usr/bin/env bash
# Print what a human put into a ticket's worker sessions, oldest first, so the
# work-retro skill reads a short timeline instead of the raw transcripts.
#
#   interventions.sh [worktree path]    default: the git root of the current dir
#
# Reads every session transcript Claude Code kept for that worktree
# (~/.claude/projects/<path with every non-alphanumeric char as ->/*.jsonl).
# Each entry is tagged:
#   you          a message typed in the pane (or a suggestion you accepted)
#   coordinator  a message work-work sent through herdr (it types into the same
#                pane, so only its "Coordinator" / "Read .../brief.md" wording
#                tells them apart); shown short, as context
#   command      a slash command you ran
#   interrupted  you stopped the agent mid-turn
#   rejected     you turned down a tool call
#   blocked      a hook, permission rule or the auto-mode classifier stopped one
#   worker asked the worker ended a turn with WORK-WORK: BLOCKED (its question)
# Stops at the first /work-retro, so the retro doesn't read itself.
set -euo pipefail

worktree="${1:-$(git rev-parse --show-toplevel)}"
if [ -d "$worktree" ]; then worktree="$(cd "$worktree" && pwd -P)"; fi
dir="$HOME/.claude/projects/$(printf '%s' "$worktree" | sed 's/[^A-Za-z0-9]/-/g')"
[ -d "$dir" ] || { echo "no transcripts for $worktree (looked in $dir)" >&2; exit 1; }

files=()
while IFS= read -r f; do files+=("$f"); done < <(
  for f in "$dir"/*.jsonl; do
    printf '%s\t%s\n' "$(jq -r 'select(.timestamp) | .timestamp' "$f" 2>/dev/null | head -1)" "$f"
  done | sort | cut -f2-
)

echo "worktree: $worktree"
echo "sessions: ${#files[@]}"
brief="$(cat "${files[@]}" | grep -oE "$HOME/work-work/[^ \"\\\\]+/brief\\.md" | head -1 || true)"
[ -n "$brief" ] && echo "workspace: $(dirname "$brief")"

# shellcheck disable=SC2016  # $vars below are jq's, not the shell's
jq -r --slurp '
  def body: if type == "string" then . else ([.[]? | select(.type == "text") | .text] | join("\n")) end;
  def unpaste: gsub("<pasted_content[^>]*>\\s*|\\s*</pasted_content>"; "") | sub("^\\s+"; "");
  def cut($n): if length > $n then .[0:$n] + " […]" else . end;
  def line($tag; $text): "--- \(.timestamp[0:16] | sub("T"; " ")) · \($tag)\n\($text)";

  [ .[] | select((.isSidechain | not) and (.isMeta | not) and (.isCompactSummary | not))
        | select(.type == "user" or (.type == "assistant" and (.message.content | body | test("WORK-WORK: BLOCKED\\s*$")))) ]
  | (map(.type == "user" and (.message.content | body | test("<command-name>/work-retro</command-name>"))) | index(true)) as $stop
  | (if $stop then .[0:$stop] else . end)[]
  | (.message.content | body | unpaste) as $text
  | if .type == "assistant" then line("worker asked"; $text | cut(1500))
    elif .toolDenialKind == "user-rejected" then line("rejected"; "")
    elif .toolDenialKind then
      line("blocked"; [.message.content[]? | select(.type == "tool_result") | .content | body] | join(" ") | cut(300))
    elif (.message.content | type) == "array" and any(.message.content[]; .type == "tool_result") then empty
    elif .origin.kind != null and .origin.kind != "human" then empty
    elif ($text | test("^\\[Request interrupted")) then line("interrupted"; "")
    elif ($text | test("<local-command-|<command-message>(clear|compact|exit)<")) then empty
    elif ($text | test("<command-name>")) then
      line("command"; $text | capture("<command-name>(?<n>[^<]*)</command-name>(.*<command-args>(?<a>[^<]*)</command-args>)?") | "\(.n) \(.a // "")")
    elif ($text | test("^\\[?Coordinator|^Read \\S+/brief\\.md and follow it")) then line("coordinator"; $text | cut(500))
    elif $text == "" then empty
    else line(if .promptSource == "suggestion_accepted" then "you (accepted suggestion)" else "you" end; $text | cut(3000))
    end
' "${files[@]}"
