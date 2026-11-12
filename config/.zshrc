export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="agnoster"

plugins=(
	git
	zsh-autosuggestions
	zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

alias a='/opt/arsenal/run'
alias grim='/usr/local/bin/grimoire'
# atuin now lives in /usr/local/bin; the env file only exists in older images
[ -f "$HOME/.atuin/bin/env" ] && source "$HOME/.atuin/bin/env"
command -v atuin > /dev/null && eval "$(atuin init zsh)"
export GOPROXY=direct
export PATH="$PATH:/root/.local/bin"
