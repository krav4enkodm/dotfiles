#!/usr/bin/env bash
# Bootstrap my terminal setup on a fresh Ubuntu/Debian machine.
# Idempotent: every step is skipped when the tool is already present,
# and anything a symlink would overwrite is backed up first.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN" "$HOME/.config"
export PATH="$LOCAL_BIN:$HOME/.asdf/shims:/usr/local/bin:$PATH"

info() { printf '  \033[32m%-8s\033[0m %s\n' "$1" "$2"; }
warn() { printf '  \033[33m%-8s\033[0m %s\n' "$1" "$2"; }
have() { command -v "$1" >/dev/null 2>&1; }
gh_latest() { curl -fsSL "https://api.github.com/repos/$1/releases/latest" | grep -oP '"tag_name":\s*"\K[^"]+'; }

# ---------------------------------------------------------------- packages
echo "Packages"
sudo apt-get update -qq
sudo apt-get install -y -qq zsh git curl wget fzf direnv btop
info "ok" "apt packages"

if ! have gh; then
  sudo mkdir -p -m 755 /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  sudo apt-get update -qq && sudo apt-get install -y -qq gh
  info "install" "gh"
else info "ok" "gh"; fi

if ! have docker; then
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker "$USER"
  info "install" "docker (log out and in for group membership)"
else info "ok" "docker"; fi

if ! have tailscale; then
  curl -fsSL https://tailscale.com/install.sh | sh
  info "install" "tailscale (run: sudo tailscale up)"
else info "ok" "tailscale"; fi

# ---------------------------------------------------------------- binaries
echo "Binaries"
if ! have starship; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y >/dev/null
  info "install" "starship"
else info "ok" "starship"; fi

if ! have nvim; then
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/nvim.tar.gz" https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
  sudo rm -rf /opt/nvim-linux-x86_64
  sudo tar -C /opt -xzf "$tmp/nvim.tar.gz"
  rm -rf "$tmp"
  info "install" "neovim -> /opt/nvim-linux-x86_64"
else info "ok" "neovim"; fi

if ! have lazygit; then
  ver="$(gh_latest jesseduffield/lazygit)"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/lazygit.tar.gz" "https://github.com/jesseduffield/lazygit/releases/download/${ver}/lazygit_${ver#v}_Linux_x86_64.tar.gz"
  tar -C "$tmp" -xzf "$tmp/lazygit.tar.gz" lazygit
  sudo install "$tmp/lazygit" /usr/local/bin/lazygit
  rm -rf "$tmp"
  info "install" "lazygit $ver"
else info "ok" "lazygit"; fi

if ! have asdf; then
  ver="$(gh_latest asdf-vm/asdf)"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/asdf.tar.gz" "https://github.com/asdf-vm/asdf/releases/download/${ver}/asdf-${ver}-linux-amd64.tar.gz"
  tar -C "$LOCAL_BIN" -xzf "$tmp/asdf.tar.gz" asdf
  rm -rf "$tmp"
  info "install" "asdf $ver"
else info "ok" "asdf"; fi

if ! have herdr; then
  curl -fsSL https://herdr.dev/install.sh | sh
  info "install" "herdr"
else info "ok" "herdr"; fi

if ! have claude; then
  curl -fsSL https://claude.ai/install.sh | bash
  info "install" "claude code"
else info "ok" "claude code"; fi

# ---------------------------------------------------------------- oh my zsh
echo "Oh My Zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc >/dev/null
  info "install" "oh-my-zsh"
else info "ok" "oh-my-zsh"; fi

ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
for plugin in zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting; do
  name="${plugin#*/}"
  if [ ! -d "$ZSH_CUSTOM/plugins/$name" ]; then
    git clone -q --depth 1 "https://github.com/$plugin" "$ZSH_CUSTOM/plugins/$name"
    info "install" "$name"
  else info "ok" "$name"; fi
done

# ---------------------------------------------------------------- symlinks
echo "Symlinks"
link() {
  local src="$REPO/$1" dest="$HOME/$2"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then info "ok" "~/$2"; return; fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$2")"
    mv "$dest" "$BACKUP_DIR/$2"
    warn "backup" "~/$2 -> ${BACKUP_DIR#"$HOME"/}/$2"
  fi
  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  info "link" "~/$2"
}
link zshrc                .zshrc
link gitconfig            .gitconfig
link tool-versions        .tool-versions
link config/starship.toml .config/starship.toml
link config/nvim          .config/nvim

# Claude Code skills: one symlink per folder under claude/skills/.
for skill in "$REPO"/claude/skills/*/; do
  name="$(basename "$skill")"
  link "claude/skills/$name" ".claude/skills/$name"
done

# ---------------------------------------------------------------- node & npm tools
echo "Node"
asdf plugin list 2>/dev/null | grep -qx nodejs || asdf plugin add nodejs
(cd "$HOME" && asdf install)
info "ok" "node $(tr '\n' ' ' < "$HOME/.tool-versions")"

for pkg in pnpm @openai/codex; do
  if ! npm ls -g --depth=0 "$pkg" >/dev/null 2>&1; then
    npm install -g "$pkg" >/dev/null
    info "install" "$pkg"
  else info "ok" "$pkg"; fi
done
asdf reshim nodejs

# pnpm completion as a custom oh-my-zsh plugin (regenerated each run).
mkdir -p "$ZSH_CUSTOM/plugins/pnpm"
pnpm completion zsh > "$ZSH_CUSTOM/plugins/pnpm/_pnpm"
: > "$ZSH_CUSTOM/plugins/pnpm/pnpm.plugin.zsh"
info "ok" "pnpm completion plugin"

# ---------------------------------------------------------------- shell
if [ "$(basename "$SHELL")" != "zsh" ]; then
  chsh -s "$(command -v zsh)"
  info "chsh" "login shell -> zsh (takes effect on next login)"
fi

echo
echo "Done. Manual steps left:"
echo "  gh auth login          # GitHub token (also used as git credential helper)"
echo "  ~/.gitconfig.local     # machine-specific git settings, if any (see README)"
echo "  sudo tailscale up      # if this machine joins the tailnet"
echo "  nvim                   # first launch installs LazyVim plugins from lazy-lock.json"
echo "  install a Nerd Font and select it in your terminal (starship preset uses its icons)"
