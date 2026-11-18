#!/usr/bin/env bash
# Print what a human put into a ticket's worker sessions, oldest first, so the
# work-retro skill reads a short timeline instead of the raw transcripts.
#
#   interventions.sh [--since <iso time>] [worktree | transcripts folder | session.jsonl ...]
#       default: the git root of the current dir
#
# Reads every session transcript Claude Code kept for that worktree
# (~/.claude/projects/<path with every non-alphanumeric char as ->/*.jsonl).
# A folder under ~/.claude/projects/ is read as is, so a worktree that was
# already removed still works; .jsonl files (e.g. a coordinator session) are
# read as given. --since drops entries before that time.
# Each entry is tagged:
#   you          a message typed in the pane (or a suggestion you accepted)
#   coordinator  a message work-work sent through herdr (it types into the same
#                pane, so only its wording tells them apart: the "Coordinator:"
#                prefix, or the phrases it uses when it forgot the prefix);
#                shown short, as context
#   command      a slash command you ran
#   shell        a command you ran with ! (its output is left out)
#   interrupted  you stopped the agent mid-turn
#   rejected     you turned down a tool call
#   blocked      a hook, permission rule or the auto-mode classifier stopped one
#   worker asked the worker ended a turn with WORK-WORK: BLOCKED (its question)
set -euo pipefail

since=""
if [ "${1:-}" = "--since" ]; then since="$2"; shift 2; fi

files=()
if [ "$#" -gt 0 ] && [[ "$1" == *.jsonl ]]; then
  worktree="sessions given"
  for f in "$@"; do [ -f "$f" ] || { echo "no such session: $f" >&2; exit 1; }; done
else
  worktree="${1:-$(git rev-parse --show-toplevel)}"
  if [ -d "$worktree" ]; then worktree="$(cd "$worktree" && pwd -P)"; fi
  case "$worktree" in
    "$HOME"/.claude/projects/*) dir="$worktree" ;;
    *) dir="$HOME/.claude/projects/$(printf '%s' "$worktree" | sed 's/[^A-Za-z0-9]/-/g')" ;;
  esac
  [ -d "$dir" ] || { echo "no transcripts for $worktree (looked in $dir)" >&2; exit 1; }
  set -- "$dir"/*.jsonl
fi
while IFS= read -r f; do files+=("$f"); done < <(
  for f in "$@"; do
    printf '%s\t%s\n' "$(jq -r 'select(.timestamp) | .timestamp' "$f" 2>/dev/null | head -1)" "$f"
  done | sort | cut -f2-
)

echo "worktree: $worktree"
echo "sessions: ${#files[@]}"
if [ "$worktree" != "sessions given" ]; then
  brief="$(cat "${files[@]}" | grep -oE "$HOME/work-work/[^ \"\\\\]+/brief\\.md" | head -1 || true)"
  [ -n "$brief" ] && echo "workspace: $(dirname "$brief")"
fi

# Messages work-work sends through herdr, with or without its prefix.
coord='^\[?Coordinator|^Read \S+/brief\.md and follow it|^[—-]?\s*(The app( slot)? is yours|Validation (PASSED|FAILED|passed|failed)|ticket\.md changed|Rebase \+|Answers \(ticket\.md changed)'

# shellcheck disable=SC2016  # $vars below are jq's, not the shell's
jq -r --slurp --arg since "$since" --arg coord "$coord" '
  def body: if type == "string" then . else ([.[]? | select(.type == "text") | .text] | join("\n")) end;
  def unpaste: gsub("<pasted_content[^>]*>\\s*|\\s*</pasted_content>"; "") | sub("^\\s+"; "");
  def cut($n): if length > $n then .[0:$n] + " […]" else . end;
  def e($tag; $text): {ts: .timestamp, tag: $tag, text: $text};

  [ .[] | select((.isSidechain | not) and (.isMeta | not) and (.isCompactSummary | not))
        | select(.timestamp and .timestamp >= $since)
        | select(.type == "user" or (.type == "assistant" and (.message.content | body | test("WORK-WORK: BLOCKED\\s*$"))))
        | (.message.content | body | unpaste) as $text
        | if .type == "assistant" then e("worker asked"; $text | cut(1500))
          elif .toolDenialKind == "user-rejected" then e("rejected"; "")
          elif .toolDenialKind then
            e("blocked"; [.message.content[]? | select(.type == "tool_result") | .content | body] | join(" ") | cut(300))
          elif (.message.content | type) == "array" and any(.message.content[]; .type == "tool_result") then empty
          elif .origin.kind != null and .origin.kind != "human" then empty
          elif ($text | test("^\\[Request interrupted")) then e("interrupted"; "")
          elif ($text | test("<local-command-|<command-message>(clear|compact|exit)<|^<bash-std(out|err)>|^/(clear|compact|exit)\\s*$")) then empty
          elif ($text | test("^<bash-input>")) then e("shell"; $text | sub("^<bash-input>"; "") | sub("</bash-input>.*"; "") | cut(300))
          elif ($text | test("<command-name>")) then
            e("command"; $text | capture("<command-name>(?<n>[^<]*)</command-name>(.*<command-args>(?<a>[^<]*)</command-args>)?") | "\(.n) \(.a // "")")
          elif ($text | test($coord)) then e("coordinator"; $text | cut(500))
          elif $text == "" then empty
          else e(if .promptSource == "suggestion_accepted" then "you (accepted suggestion)" else "you" end; $text | cut(3000))
          end ]
  # the same message sent again right after (a retry, a resend after /compact) shows once
  | reduce .[] as $x ([]; if length > 0 and .[-1].tag == $x.tag and .[-1].text == $x.text and $x.text != "" then . else . + [$x] end)
  | .[] | "--- \(.ts[0:16] | sub("T"; " ")) · \(.tag)\n\(.text)"
' "${files[@]}"
