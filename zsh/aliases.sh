#!/usr/bin/env bash
# shopt -s expand_aliases

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
  local project_name=$(ls ~/projects | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g" | fzf)
  if [ -n "$project_name" ]; then
    echo $project_name
  fi
}

po() {
  local project=$(pl)
  if [ -n "$project" ]; then
    local window_name="${2:-dev}"
    kitty @ launch --title $project --cwd "~/projects/$project" --type tab
    kitty @ focus-tab --match title:$project
    kitty @ launch --title $project --cwd "~/projects/$project"
  fi
}
