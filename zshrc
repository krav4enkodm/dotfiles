# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""   # prompt is handled by starship below
plugins=(git direnv fzf pnpm gh zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"

# Prompt
eval "$(starship init zsh)"

# Machine-specific additions (work tools, extra PATH) — not tracked.
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
