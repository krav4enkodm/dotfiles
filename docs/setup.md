# New machine setup

From a fresh Arch or Debian/Ubuntu install to my terminal setup: Ghostty,
herdr, Starship, btop, LazyVim and Claude Code, all in Catppuccin Macchiato,
with JetBrainsMono Nerd Font.

Order matters only loosely: install the packages, then run `install.sh`, which
lays down every config. The desktop (window manager, login screen, drivers) is
not covered.

## 1. Packages

### Arch

Everything is in the official repos.

```sh
sudo pacman -S --needed base-devel git jq curl unzip wl-clipboard \
  ghostty starship btop neovim tree-sitter-cli lazygit \
  fzf ripgrep fd github-cli ttf-jetbrains-mono-nerd nvm chromium
```

### Debian / Ubuntu

apt covers the small tools. Ghostty, Starship, Neovim and lazygit come from
their own releases, because the apt versions are missing or too old (LazyVim
needs Neovim 0.11.2 or newer).

Chromium is for Claude's browser (the `chrome-devtools` MCP launches
`/usr/bin/chromium`). Debian's apt package installs it there. Ubuntu's
`chromium` is a snap, which lives in `/snap/bin` and can't write the agent's
profile under `~/.cache`, so on Ubuntu install a non-snap build at that path.

```sh
sudo apt install build-essential git jq curl unzip fontconfig wl-clipboard \
  btop fzf ripgrep fd-find gh chromium
mkdir -p ~/.local/bin && ln -sf "$(command -v fdfind)" ~/.local/bin/fd   # Debian names it fdfind

# Starship
curl -sS https://starship.rs/install.sh | sh

# Neovim (official build)
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64 && sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim

# lazygit (Ubuntu 25.10+ can just `sudo apt install lazygit`)
LG=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | jq -r .tag_name | tr -d v)
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LG}/lazygit_${LG}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit && sudo install lazygit -D -t /usr/local/bin/

# Ghostty: no official .deb. Snap works on both; see ghostty.org/docs/install/binary
sudo snap install ghostty --classic

# JetBrainsMono Nerd Font
mkdir -p ~/.local/share/fonts/JetBrainsMono
curl -L https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz \
  | tar -xJ -C ~/.local/share/fonts/JetBrainsMono && fc-cache -f

# nvm (upstream script)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
```

### Both

```sh
curl -fsSL https://claude.ai/install.sh | bash     # Claude Code, into ~/.local/bin
curl -fsSL https://herdr.dev/install.sh | sh       # herdr; updates itself with `herdr update`
```

For the `agent-login` skill, install the 1Password CLI (`op`) from
[its guide](https://developer.1password.com/docs/cli/get-started/) and turn on
**Settings → Developer → Integrate with 1Password CLI** in the desktop app, so
`op` asks for approval there instead of a separate sign-in.

Then, in a new shell: `nvm install --lts`, and on Debian/Ubuntu also
`npm i -g tree-sitter-cli` (LazyVim uses it to build parsers).

## 2. Dotfiles

```sh
git clone https://github.com/krav4enkodm/dotfiles ~/Projects/dotfiles
cd ~/Projects/dotfiles
git config user.name "…" && git config user.email "…"   # no global identity on purpose
gh auth login
./install.sh --check    # what would change
./install.sh
```

What it puts in `~/.config/` (from [`config/`](../config/)):

| Tool | What the repo sets |
|---|---|
| Ghostty | `ghostty/config.ghostty`: Catppuccin Macchiato, JetBrainsMono Nerd Font, copy on select |
| Starship | `starship.toml`: Catppuccin powerline prompt, Macchiato palette |
| btop | the Macchiato theme file, plus the `color_theme` and a few display keys in `btop.conf`; btop keeps the rest |
| LazyVim | clones the stock starter if `~/.config/nvim` is missing, adds `lua/plugins/colorscheme.lua` (catppuccin-macchiato) and turns on the TypeScript, JSON and Markdown extras in `lazyvim.json` |
| herdr | `herdr/config.toml`: catppuccin-mocha (herdr has no Macchiato), onboarding off; installs the worktree-setup plugin and the Claude integration |
| bash | `dotfiles/bashrc.sh`, sourced from one line added to `~/.bashrc`: `~/.local/bin` on PATH, nvm, bun, `EDITOR=nvim`, Starship |
| Claude Code | everything under `claude/`, see the [README](../README.md) |

## 3. First run

1. Open a new Ghostty window so the shell picks up `bashrc.sh`.
2. `claude` and log in.
3. `nvim` once: lazy.nvim installs the plugins and the extras' language servers. Quit and reopen when it's done.
4. `herdr`, then start `claude` in a pane.
5. Make Ghostty the terminal your desktop opens (its own keybinding or default-terminal setting).

If the machine already had a `~/.bashrc` with starship, nvm or bun lines,
delete those; `bashrc.sh` does the same and they'd otherwise run twice.

## Changing a config

Same loop as the Claude files: edit under `config/`, run `./install.sh`. If you
changed something live (say, through btop's menu or `:LazyExtras`),
`./install.sh --check` shows the difference; copy it into the repo first.
