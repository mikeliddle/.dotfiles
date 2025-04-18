export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="Simple"
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 13

eval "$(/opt/homebrew/bin/brew shellenv)"

plugins=(git)
pluginx=(xcode)

export LANG=en_US.UTF-8

source ~/.zsh/aliases

eval "$(oh-my-posh init zsh --config ~/.config/miliddle.omp.json)"
