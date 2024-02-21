source_if_exists() {
	if test -r "$1"; then
		source "$1"
	fi
}

source_if_exists ~/env_specific.sh
source_if_exists ~/.config/config.zsh
source_if_exists ~/.config/git.zsh
source_if_exists ~/.config/aliases.sh
source_if_exists ~/.fzf.zsh
