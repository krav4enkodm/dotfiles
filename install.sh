#!/usr/bin/env bash
# Link this workbench into ~/.claude on a fresh machine.
# Idempotent: safe to re-run. Anything it would overwrite is backed up first.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
BACKUP_DIR="$CLAUDE_DIR/backups/install-$(date +%Y%m%d-%H%M%S)"

info() { printf '  \033[32m%-8s\033[0m %s\n' "$1" "$2"; }
warn() { printf '  \033[33m%-8s\033[0m %s\n' "$1" "$2"; }

mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/agents"

# link <source-in-repo> <target-in-~/.claude>
link() {
  local src="$REPO/$1" dest="$CLAUDE_DIR/$2"

  # Already pointing where we want it.
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    info "ok" "$2"
    return
  fi

  # Something real is in the way — preserve it before replacing.
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$2")"
    mv "$dest" "$BACKUP_DIR/$2"
    warn "backup" "$2 -> ${BACKUP_DIR#"$HOME"/}/$2"
  fi

  ln -s "$src" "$dest"
  info "link" "$2"
}

echo "Linking Claude harness from $REPO"

link claude/settings.json          settings.json
link claude/statusline-command.sh  statusline-command.sh

for skill in "$REPO"/claude/skills/*/; do
  name="$(basename "$skill")"
  link "claude/skills/$name" "skills/$name"
done

for agent in "$REPO"/claude/agents/*.md; do
  name="$(basename "$agent")"
  link "claude/agents/$name" "agents/$name"
done

# MCP servers live in ~/.claude.json alongside machine state, so merge rather
# than replace. Existing servers with the same name are overwritten.
CONFIG="$HOME/.claude.json"
if command -v jq >/dev/null 2>&1; then
  [ -f "$CONFIG" ] || echo '{}' > "$CONFIG"
  cp "$CONFIG" "$BACKUP_DIR-claude.json" 2>/dev/null || true
  tmp="$(mktemp)"
  jq --slurpfile add "$REPO/claude/mcp-servers.json" \
    '.mcpServers = ((.mcpServers // {}) + $add[0])' "$CONFIG" > "$tmp"
  mv "$tmp" "$CONFIG"
  info "merge" "mcpServers -> ~/.claude.json ($(jq -r 'keys | join(", ")' "$REPO/claude/mcp-servers.json"))"
else
  warn "skip" "jq not found — merge claude/mcp-servers.json into ~/.claude.json by hand"
fi

echo
echo "Done. Remaining manual step:"
echo "  Plugins are installed by Claude Code, not by symlink. Inside Claude Code run:"
echo "    /plugin marketplace add anthropics/claude-plugins-official"
echo "    /plugin install figma@claude-plugins-official"
echo
echo "Then restart Claude Code and check: /status"
