#!/usr/bin/env bash
# Claude Code status line — mirrors key Powerlevel10k segments:
#   dir | git branch | model | context remaining

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# Shorten home directory to ~
home="$HOME"
short_cwd="${cwd/#$home/\~}"

# Git branch (skip optional locks to avoid blocking)
git_branch=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  git_branch=$(git -C "$cwd" -c core.fsmonitor=false symbolic-ref --short HEAD 2>/dev/null \
    || git -C "$cwd" -c core.fsmonitor=false rev-parse --short HEAD 2>/dev/null)
fi

# Directory segment
printf '\033[34m%s\033[0m' "$short_cwd"

# Git segment
if [ -n "$git_branch" ]; then
  printf ' \033[90mon\033[0m \033[35m%s\033[0m' "$git_branch"
fi

# Model segment
if [ -n "$model" ]; then
  printf ' \033[90m|\033[0m \033[36m%s\033[0m' "$model"
fi

# Context remaining segment
if [ -n "$remaining" ]; then
  remaining_int=$(printf '%.0f' "$remaining")
  if [ "$remaining_int" -le 20 ]; then
    color='\033[31m'   # red when low
  elif [ "$remaining_int" -le 50 ]; then
    color='\033[33m'   # yellow when medium
  else
    color='\033[32m'   # green when plenty
  fi
  printf ' \033[90m|\033[0m %bctx: %d%%\033[0m' "$color" "$remaining_int"
fi

printf '\n'
