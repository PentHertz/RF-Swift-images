export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="xiong-chiamiov"

plugins=(
	git
	zsh-autosuggestions
	zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

alias a='/opt/arsenal/run'
source $HOME/.atuin/bin/env
eval "$(atuin init zsh)"
export GOPROXY=direct
