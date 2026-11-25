#!/usr/bin/env bash
# Roll these dotfiles out onto the local machine.
#
#   ./install.sh           apply: copy files, merge settings, install plugins
#   ./install.sh --check   show what would change, touch nothing (exit 1 on drift)
#
# The repo is the source of truth. Files are copied, not linked; settings are
# merged so keys other tools add locally (herdr's hook, autoMode, ...) survive.
# Arrays are replaced, except hook lists: there a local entry survives unless
# the repo has an entry with the same matcher.
# config/ mirrors ~/.config/ the same way (terminal, prompt, editor, shell
# snippet); btop.conf and lazyvim.json are merged, since those tools rewrite them.
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
fi
has avr && ok "avr" || warn "avr not found (optional, for demo videos)"
[ -x /usr/bin/chromium ] && ok "chromium" || warn "/usr/bin/chromium not found — the chrome-devtools MCP launches it; see docs/setup.md"
for cmd in ghostty starship btop nvim; do
  has "$cmd" && ok "$cmd" || warn "$cmd not found — its config is installed anyway; see docs/setup.md"
done

# ------------------------------------------------------------------------ files
echo
echo "Files -> ${CLAUDE_DIR/#$HOME/\~}"
[ "$CHECK" = 1 ] || mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/agents" "$CLAUDE_DIR/rules" "$CLAUDE_DIR/hooks"

managed=(CLAUDE.md statusline-command.sh)
for d in "$SRC"/skills/*/; do managed+=("skills/$(basename "$d")"); done
for f in "$SRC"/agents/*.md; do managed+=("agents/$(basename "$f")"); done
for f in "$SRC"/rules/*.md; do managed+=("rules/$(basename "$f")"); done
# One file at a time: herdr keeps its own hook script in the same folder.
for f in "$SRC"/hooks/*.sh; do managed+=("hooks/$(basename "$f")"); done

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
# arrays are replaced. Hook lists (hooks.<event>) are the exception: the repo's
# entries replace local entries with the same matcher, and local entries with
# other matchers are appended after them. Removing a key from the repo does not remove it locally:
# list it (dotted path, e.g. "voice.mode") in settings-removed.json for that.
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

merge_json "$CLAUDE_DIR/settings.json" "settings.json" \
  '. as $cur
   | (. * $repo[0])
   | reduce ($repo[0].hooks // {} | keys[]) as $ev (.;
       .hooks[$ev] += [ ($cur.hooks[$ev] // [])[]
         | select(.matcher as $m | $repo[0].hooks[$ev] | any(.[]; .matcher == $m) | not) ])
   | reduce ($rm[0][] | split(".")) as $p (.; delpaths([$p]))' \
  --slurpfile repo "$SRC/settings.json" --slurpfile rm "$SRC/settings-removed.json"
merge_json "$CLAUDE_JSON" "mcpServers -> ${CLAUDE_JSON/#$HOME/\~}" \
  '.mcpServers = ((.mcpServers // {}) + $add[0])' --slurpfile add "$SRC/mcp-servers.json"

# ---------------------------------------------------------------------- configs
# config/ mirrors ~/.config/. Files are copied like the Claude files above,
# except two that their tools rewrite: btop.conf only gets the repo's keys set,
# and lazyvim.json only gets the repo's extras added.
CFG="$REPO/config"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
CONFIG_MANIFEST="$CONFIG_DIR/dotfiles/.manifest"
MERGED_CONFIGS=(btop/btop.conf nvim/lazyvim.json)
echo
echo "Configs -> ${CONFIG_DIR/#$HOME/\~}"

# LazyVim is the stock starter plus the repo's files, so lay the starter down first.
if [ ! -e "$CONFIG_DIR/nvim" ]; then
  act clone "nvim (LazyVim starter)"
  if [ "$CHECK" != 1 ]; then
    git clone -q --depth 1 https://github.com/LazyVim/starter "$CONFIG_DIR/nvim" \
      || die "could not clone the LazyVim starter"
    rm -rf "$CONFIG_DIR/nvim/.git"
  fi
fi

configs=()
while IFS= read -r f; do
  printf '%s\n' "${MERGED_CONFIGS[@]}" | grep -qxF "$f" || configs+=("$f")
done < <(cd "$CFG" && find . -type f | sed 's|^\./||' | sort)

for item in "${configs[@]}"; do
  src="$CFG/$item" dest="$CONFIG_DIR/$item"
  if [ ! -L "$dest" ] && [ -f "$dest" ] && cmp -s "$src" "$dest"; then
    ok "$item"
    continue
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    act update "$item"
    [ "$CHECK" = 1 ] && { diff -u "$dest" "$src" 2>/dev/null | sed 's/^/      /' | head -40 || true; continue; }
    backup "$dest"
  else
    act add "$item"
    [ "$CHECK" = 1 ] && continue
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
done

if [ -f "$CONFIG_MANIFEST" ]; then
  while IFS= read -r old; do
    [ -n "$old" ] || continue
    printf '%s\n' "${configs[@]}" | grep -qxF "$old" && continue
    if [ -e "$CONFIG_DIR/$old" ] || [ -L "$CONFIG_DIR/$old" ]; then
      act remove "$old"
      [ "$CHECK" = 1 ] || backup "$CONFIG_DIR/$old"
    fi
  done < "$CONFIG_MANIFEST"
fi
[ "$CHECK" = 1 ] || { mkdir -p "$(dirname "$CONFIG_MANIFEST")"; printf '%s\n' "${configs[@]}" > "$CONFIG_MANIFEST"; }

set_keys() { # set_keys <repo-file> <target> <label>: set each `key = value` line of the repo file in target
  local src="$1" target="$2" label="$3" current merged line key
  current="$( { [ -f "$target" ] && cat "$target"; } || true)"
  merged="$current"
  while IFS= read -r line; do
    case "$line" in ''|'#'*) continue ;; esac
    key="${line%%=*}"; key="${key%"${key##*[! ]}"}"
    if grep -qE "^${key}[[:space:]]*=" <<<"$merged"; then
      merged="$(K="$key" L="$line" awk '$0 ~ "^" ENVIRON["K"] "[ \t]*=" {print ENVIRON["L"]; next} {print}' <<<"$merged")"
    else
      merged="${merged:+$merged$'\n'}$line"
    fi
  done < "$src"
  if [ "$current" = "$merged" ]; then ok "$label"; return; fi
  act merge "$label"
  if [ "$CHECK" = 1 ]; then
    diff <(printf '%s\n' "$current") <(printf '%s\n' "$merged") | sed 's/^/      /' || true
    return
  fi
  if [ -f "$target" ]; then mkdir -p "$BACKUP_DIR"; cp "$target" "$BACKUP_DIR/$(basename "$target")"; fi
  mkdir -p "$(dirname "$target")"
  printf '%s\n' "$merged" > "$target"
}
set_keys "$CFG/btop/btop.conf" "$CONFIG_DIR/btop/btop.conf" "btop/btop.conf (theme keys)"

# A new lazyvim.json needs LazyVim's current format version, or LazyVim treats
# the extras as the old short names and rewrites them.
merge_json "$CONFIG_DIR/nvim/lazyvim.json" "nvim/lazyvim.json (extras)" \
  '(if .version == null then {version: 8, install_version: 8} + . else . end)
   | .extras = (((.extras // []) + $repo[0].extras) | unique)' \
  --slurpfile repo "$CFG/nvim/lazyvim.json"

BASHRC="$HOME/.bashrc"
# The literal text is what goes into ~/.bashrc, so it stays unexpanded here.
# shellcheck disable=SC2016
SOURCE_LINE='[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/bashrc.sh" ] && . "${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/bashrc.sh"'
if grep -qF 'dotfiles/bashrc.sh' "$BASHRC" 2>/dev/null; then
  ok ".bashrc sources dotfiles/bashrc.sh"
else
  act add "source line to ~/.bashrc"
  if [ "$CHECK" != 1 ]; then
    if [ -f "$BASHRC" ]; then mkdir -p "$BACKUP_DIR"; cp "$BASHRC" "$BACKUP_DIR/.bashrc"; fi
    printf '\n# Shared shell setup from the dotfiles repo\n%s\n' "$SOURCE_LINE" >> "$BASHRC"
  fi
fi

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
  if herdr plugin list 2>/dev/null | grep -q '^- tdi.worktree-setup '; then
    ok "herdr plugin worktree-setup"
  else
    act install "herdr plugin worktree-setup (tdi/herdr-worktree-setup)"
    [ "$CHECK" = 1 ] || herdr plugin install --yes tdi/herdr-worktree-setup \
      || warn "failed: herdr plugin — run: herdr plugin install tdi/herdr-worktree-setup"
  fi
else
  warn "herdr not found — skipping its Claude integration and plugin"
fi

if has gh; then
  if gh extension list 2>/dev/null | grep -q 'gh-stack'; then
    ok "gh stack"
  else
    act install "gh stack (github/gh-stack)"
    [ "$CHECK" = 1 ] || gh extension install github/gh-stack || warn "failed: gh stack — run: gh extension install github/gh-stack"
  fi
else
  warn "gh not found — skipping gh stack"
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
echo "Done. Restart Claude Code and open a new shell to pick up the changes."
