#!/usr/bin/env bash

# ALIASES ---------------------------------------------------------------------
alias please='sudo'
alias yeet='rm'
alias cd..='cd ..'
alias c='clear'
alias s='source ~/.zshrc'
alias ls='ls --color'
alias hms='home-manager switch'

# TMUX + NVIM ALIASES
alias t=tmuxifier

# GIT ALIASES -----------------------------------------------------------------
alias gs='git status'
alias gc='git commit'
alias gch='git checkout'
alias ga='git add'
alias gb='git checkout -b'
alias gd='git diff'
alias gp='git push'

# FUNCTIONS -------------------------------------------------------------------
pl() {
	local project_name=$(find ~/project_list -maxdepth 1 -exec basename {} \; | fzf)
	if [ -n "$project_name" ]; then
		local project_path=$(readlink -f ~/project_list/$project_name)
		echo $project_path
	fi
}

po() {
	local project=$(pl)
	if [ -n "$project" ]; then
		local layout_type="w"
		local window_name="${2:-dev}"
		DIR="$project" t "$layout_type" "$window_name"
	fi
}
