#!/usr/bin/env bash

# ALIASES ---------------------------------------------------------------------
alias please='sudo'
alias yeet='rm'
alias cd..='cd ..'
alias c='clear'
alias s='source ~/.zshrc'

alias work="timer 60m && terminal-notifier -message 'Pomodoro'\
        -title 'Work Timer is up! Take a Break 😊'\
        -appIcon '~/Pictures/pumpkin.png'\
        -sound Crystal"

alias rest="timer 10m && terminal-notifier -message 'Pomodoro'\
        -title 'Break is over! Get back to work 😬'\
        -appIcon '~/Pictures/pumpkin.png'\
        -sound Crystal"

# TMUX + NVIM ALIASES
alias t=tmuxifier

# GIT ALIASES -----------------------------------------------------------------
alias gc='git commit'
alias gch='git checkout'
alias ga='git add'
alias gb='git branch'
alias gp='~/config/git-parent.sh'

# FUNCTIONS -------------------------------------------------------------------
fs() {
	local loc="${1:-$PWD}"
	local search_type="${2:-f}"
	echo $(find "$loc" -type "$search_type" | fzf >selected)
}

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

tw() {
	local loc="${1:-$(pl)}"
	if [ -n "$loc" ]; then
		local layout_type="w"
		local window_name="${2:-dev}"
		DIR="$dir" t "$layout_type" "$window_name"
	fi
}
