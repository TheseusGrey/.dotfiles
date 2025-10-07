#!/bin/bash

function join_by {
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}

menu_folder=$DOTFILES/rofi/scripts/
menu_list=$(ls $menu_folder | cut -f 1 -d '.')

menu() {
  local prompt="$1"
  local options=$(join_by "\n" "${@:2}")

  echo -e "$options" | rofi -dmenu -p "$prompt…" "$options"
}

app_menu() {
  rofi -show drun
}

action_menu() {
  modes=$(join_by "," $menu_list)
  echo $modes

  rofi -show combi -combi-modes "$modes"
}

everything_menu() {
  modes="drun,$(join_by "," $menu_list)"

  rofi -show combi -combi-modes $modes
}

system_menu() {
  # Uppercase first letter to make things look alil nicer
  menu_list_text=""
  for i in ${menu_list[@]}; do menu_list_text="${menu_list_text}${i^}\n"; done

  modes="${menu_list_text}Apps\n"
  selection=$(echo -e $modes | rofi -dmenu -p "Controls...")

  # Only show sub menu if something was actually picked
  if ! [ ${#selection} -eq 0 ]; then
    case $selection in
    Apps) rofi -show drun ;;
    *) rofi -show ${selection,} ;;
    esac
  fi
}

system_menu
