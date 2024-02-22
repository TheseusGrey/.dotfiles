source_if_exists() {
	if test -r "$1"; then
		source "$1"
	fi
}

source_if_exists ~/.config/config.zsh
source_if_exists ~/.config/git.zsh
source_if_exists ~/.config/aliases.sh
source_if_exists ~/.fzf.zsh

PROMPT="%{$(tput setaf 121)%}%n%{$(tput sgr0)%}@%{$(tput setaf 121)%}%m%{$(tput sgr0)%}: "
RPROMPT="%{$(tput setaf 121)%}%~%{$(tput sgr0)%} |%{$(tput setaf 63)%}%t%{$(tput sgr0)%}"

