#!/bin/bash

function join_by {
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}

menu_folder=$DOTFILES/rofi/scripts/
menu_list=$(ls $menu_folder | cut -f 1 -d '.')

action_menu() {
  modes=$(join_by "," $menu_list)
  echo $modes

  rofi -show combi -combi-modes "$modes"
}

action_menu
