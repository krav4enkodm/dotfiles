# dotfiles

Shell and toolchain for a fresh Linux machine. Configs live here and are
symlinked into `$HOME`, so editing `~/.zshrc` edits the repo. Commit and push.

```sh
git clone https://github.com/krav4enkodm/dotfiles ~/dotfiles
~/dotfiles/install.sh
```

`install.sh` targets Ubuntu/Debian. It is safe to re-run: installed tools are
skipped, and anything a symlink would replace is moved to
`~/.dotfiles-backup/<timestamp>/` first.

## What is here

| Path | Goes to | Notes |
|---|---|---|
| `zshrc` | `~/.zshrc` | oh-my-zsh plugins, PATH, starship init; sources `~/.zshrc.local` if present |
| `gitconfig` | `~/.gitconfig` | identity, gh as credential helper; includes `~/.gitconfig.local` if present |
| `tool-versions` | `~/.tool-versions` | global asdf versions (Node) |
| `config/starship.toml` | `~/.config/starship.toml` | pastel-powerline preset |
| `config/nvim/` | `~/.config/nvim` | LazyVim; `lazy-lock.json` pins every plugin |
| `claude/skills/*` | `~/.claude/skills/*` | one symlink per skill; must stay employer-neutral |

## What install.sh installs

- apt: zsh, git, curl, wget, fzf, direnv, btop
- GitHub CLI, Docker, Tailscale from their official repos/scripts
- starship, neovim (`/opt`), lazygit, asdf, herdr, Claude Code
- oh-my-zsh plus zsh-autosuggestions and zsh-syntax-highlighting
- Node via asdf, then pnpm and `@openai/codex` as global npm packages
- pnpm zsh completion as a custom oh-my-zsh plugin

## Deliberately not here

- **Secrets and machine state**: `~/.config/gh/hosts.yml`, SSH keys,
  `~/.claude/.credentials.json`, `~/.codex/auth.json`, `.envrc` files.
  Log in once per machine.
- **Machine-specific config**: `~/.gitconfig.local` and `~/.zshrc.local` are
  sourced when present and never tracked. Put per-directory git identities
  (`includeIf`) and extra PATH entries there.
- **Claude Code and Codex settings**: both tools manage their own config.
- **Work-specific Claude skills**: live untracked in `~/.claude/skills/` next to
  the ones linked from here.
- **Nerd Font**: the starship preset needs one; install and select it by hand.
