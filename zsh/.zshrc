source_if_exists() {
	if test -r "$1"; then
		source "$1"
	fi
}

fpath+=${ZDOTDIR:-~}/.zsh_functions

source_if_exists ~/.config/zsh/config.zsh
source_if_exists ~/.config/zsh/git.zsh
source_if_exists ~/.config/zsh/aliases.sh
source_if_exists ~/.env.sh

eval "$(tmuxifier init -)"
