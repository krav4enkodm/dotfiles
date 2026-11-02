#!/usr/bin/env bash
# Roll this workbench out onto the local machine.
#
#   ./install.sh           apply: copy files, merge settings, install plugins
#   ./install.sh --check   show what would change, touch nothing (exit 1 on drift)
#
# The repo is the source of truth. Files are copied, not linked; settings are
# merged so keys other tools add locally (herdr's hook, autoMode, ...) survive.
# Anything replaced or removed is backed up to ~/.claude/backups/install-<ts>/.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO/claude"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
CLAUDE_JSON="${CLAUDE_JSON:-$HOME/.claude.json}"
MANIFEST="$CLAUDE_DIR/.workbench-manifest"
BACKUP_DIR="$CLAUDE_DIR/backups/install-$(date +%Y%m%d-%H%M%S)"

CHECK=0
case "${1:-}" in
  --check) CHECK=1 ;;
  "") ;;
  *) echo "usage: $0 [--check]" >&2; exit 2 ;;
esac

DRIFT=0
say()  { printf '  \033[%sm%-9s\033[0m %s\n' "$1" "$2" "$3"; }
ok()   { say 32 ok "$1"; }
act()  { DRIFT=1; if [ "$CHECK" = 1 ]; then say 33 "would $1" "$2"; else say 36 "$1" "$2"; fi; }
warn() { say 33 warn "$1"; }
die()  { say 31 error "$1"; exit 1; }
has()  { command -v "$1" >/dev/null 2>&1; }

backup() { # backup <path-relative-to-CLAUDE_DIR or absolute>
  local p="$1" rel
  case "$p" in /*) rel="${p#/}" ;; *) rel="$p"; p="$CLAUDE_DIR/$p" ;; esac
  mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
  mv "$p" "$BACKUP_DIR/$rel"
}

# ---------------------------------------------------------------- prerequisites
echo "Prerequisites"
for cmd in git jq; do
  has "$cmd" && ok "$cmd" || die "$cmd is required — install it and re-run"
done
for cmd in claude gh herdr npx; do
  has "$cmd" && ok "$cmd" || warn "$cmd not found — parts of the workflow won't work"
done
if has gh; then
  gh auth status >/dev/null 2>&1 && ok "gh auth" || warn "gh not logged in — run: gh auth login"
  gh extension list 2>/dev/null | grep -q 'gh-stack' && ok "gh stack" \
    || warn "gh stack not installed (optional, for stacked PRs)"
fi
has avr && ok "avr" || warn "avr not found (optional, for demo videos)"

# ------------------------------------------------------------------------ files
echo
echo "Files -> ${CLAUDE_DIR/#$HOME/\~}"
[ "$CHECK" = 1 ] || mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/agents"

managed=(statusline-command.sh)
for d in "$SRC"/skills/*/; do managed+=("skills/$(basename "$d")"); done
for f in "$SRC"/agents/*.md; do managed+=("agents/$(basename "$f")"); done

for item in "${managed[@]}"; do
  src="$SRC/$item" dest="$CLAUDE_DIR/$item"
  if [ ! -L "$dest" ] && [ -e "$dest" ] && diff -rq "$src" "$dest" >/dev/null 2>&1; then
    ok "$item"
    continue
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    act update "$item"
    [ "$CHECK" = 1 ] && { diff -ru "$dest" "$src" 2>/dev/null | sed 's/^/      /' | head -40 || true; continue; }
    backup "$item"
  else
    act add "$item"
    [ "$CHECK" = 1 ] && continue
  fi
  cp -R "$src" "$dest"
done

# Remove what an earlier install put there but the repo no longer has.
if [ -f "$MANIFEST" ]; then
  while IFS= read -r old; do
    [ -n "$old" ] || continue
    printf '%s\n' "${managed[@]}" | grep -qxF "$old" && continue
    if [ -e "$CLAUDE_DIR/$old" ] || [ -L "$CLAUDE_DIR/$old" ]; then
      act remove "$old"
      [ "$CHECK" = 1 ] || backup "$old"
    fi
  done < "$MANIFEST"
fi
[ "$CHECK" = 1 ] || printf '%s\n' "${managed[@]}" > "$MANIFEST"

# --------------------------------------------------------------------- settings
# Repo keys win; keys only present locally are kept. Objects merge deeply,
# arrays are replaced. Removing a key from the repo does not remove it locally.
echo
echo "Settings"
merge_json() { # merge_json <target-file> <label> <jq-filter> [jq args...]
  local target="$1" label="$2" filter="$3"; shift 3
  local current merged
  current="$( { [ -f "$target" ] && cat "$target"; } || echo '{}')"
  merged="$(jq "$@" "$filter" <<<"$current")"
  if [ "$(jq -S . <<<"$current")" = "$(jq -S . <<<"$merged")" ]; then
    ok "$label"
    return
  fi
  act merge "$label"
  if [ "$CHECK" = 1 ]; then
    diff <(jq -S . <<<"$current") <(jq -S . <<<"$merged") | sed 's/^/      /' || true
    return
  fi
  if [ -e "$target" ] || [ -L "$target" ]; then
    mkdir -p "$BACKUP_DIR"
    cp -L "$target" "$BACKUP_DIR/$(basename "$target")" 2>/dev/null || true
  fi
  local tmp; tmp="$(mktemp)"
  printf '%s\n' "$merged" > "$tmp"
  rm -f "$target"          # drops an old symlink instead of writing through it
  mv "$tmp" "$target"
  chmod 600 "$target" 2>/dev/null || true
}

merge_json "$CLAUDE_DIR/settings.json" "settings.json" '. * $repo[0]' \
  --slurpfile repo "$SRC/settings.json"
merge_json "$CLAUDE_JSON" "mcpServers -> ${CLAUDE_JSON/#$HOME/\~}" \
  '.mcpServers = ((.mcpServers // {}) + $add[0])' --slurpfile add "$SRC/mcp-servers.json"

# ------------------------------------------------------------------ integrations
echo
echo "Integrations"
if has herdr; then
  if herdr integration status 2>/dev/null | grep -q '^claude: current'; then
    ok "herdr claude integration"
  else
    act install "herdr claude integration"
    [ "$CHECK" = 1 ] || herdr integration install claude
  fi
else
  warn "herdr not found — skipping its Claude integration"
fi

if has claude; then
  have_mkts="$(claude plugin marketplace list --json 2>/dev/null | jq -r '.[].name' || true)"
  while IFS=$'\t' read -r name repo; do
    [ -n "$name" ] || continue
    if grep -qxF "$name" <<<"$have_mkts"; then ok "marketplace $name"; continue; fi
    act add "marketplace $name ($repo)"
    [ "$CHECK" = 1 ] || claude plugin marketplace add "$repo"
  done < <(jq -r '.extraKnownMarketplaces // {} | to_entries[]
                  | select(.value.source.source == "github")
                  | [.key, .value.source.repo] | @tsv' "$SRC/settings.json")

  have_plugins="$(claude plugin list --json 2>/dev/null | jq -r '.[].id' || true)"
  while IFS= read -r plugin; do
    [ -n "$plugin" ] || continue
    if grep -qxF "$plugin" <<<"$have_plugins"; then ok "plugin $plugin"; continue; fi
    act install "plugin $plugin"
    [ "$CHECK" = 1 ] || claude plugin install "$plugin" || warn "failed: $plugin — install it from /plugin"
  done < <(jq -r '.enabledPlugins // {} | to_entries[] | select(.value) | .key' "$SRC/settings.json")
else
  warn "claude not found — skipping plugins"
fi

# ------------------------------------------------------------------------- done
echo
if [ "$CHECK" = 1 ]; then
  [ "$DRIFT" = 0 ] && echo "In sync." || echo "Drift found. Run ./install.sh to apply, or copy local changes back into the repo first."
  exit "$DRIFT"
fi
[ -d "$BACKUP_DIR" ] && echo "Backups: ${BACKUP_DIR/#$HOME/\~}"
echo "Done. Restart Claude Code to pick up the changes."
