#!/usr/bin/env bash

# ALIASES ---------------------------------------------------------------------
alias please='sudo'
alias yeet='rm'
alias nv='neovide'
alias cd..='cd ..'
alias dlist='docker ps -aq'
alias dclean='docker rm $(docker ps -aq)'
alias dstop='docker stop $(docker ps -aq)'
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

# GIT ALIASES -----------------------------------------------------------------
alias gc='git commit'
alias gco='git checkout'
alias ga='git add'
alias gb='git branch'


# FUNCTIONS -------------------------------------------------------------------
fs() {
  local loc="${1:-$PWD}"
  local search_type="${2:-f}"
  echo $(find "$loc" -type "$search_type" | fzf > selected)
}