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
alias gco='git checkout'
alias ga='git add'
alias gb='git branch'
alias gp='~/config/git-parent.sh'

# FUNCTIONS -------------------------------------------------------------------
fs() {
	local loc="${1:-$PWD}"
	local search_type="${2:-f}"
	echo $(find "$loc" -type "$search_type" | fzf >selected)
}

tw() {
	local loc="${1:-$PWD}"
	local window_name="${2:-dev}"
	local dir=$(find "$loc" -type d -print | fzf)
	DIR="$dir" t w "$window_name"
}
