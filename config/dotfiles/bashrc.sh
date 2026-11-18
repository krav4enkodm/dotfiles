# Sourced from ~/.bashrc (install.sh adds the line). Keep machine-specific
# bits in ~/.bashrc itself; this file is overwritten on every install.
# shellcheck shell=bash

case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac

# nvm: the Arch package and the upstream install script put it in different places.
if [ -s /usr/share/nvm/init-nvm.sh ]; then
  . /usr/share/nvm/init-nvm.sh
elif [ -s "$HOME/.nvm/nvm.sh" ]; then
  export NVM_DIR="$HOME/.nvm"
  . "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
fi

if [ -d "$HOME/.bun" ]; then
  export BUN_INSTALL="$HOME/.bun"
  case ":$PATH:" in *":$BUN_INSTALL/bin:"*) ;; *) export PATH="$BUN_INSTALL/bin:$PATH" ;; esac
fi

export EDITOR=nvim VISUAL=nvim

command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"
