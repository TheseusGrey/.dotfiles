#!/bin/bash

menu_folder=$DOTFILES/bin/menus/
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
  modes=""
  for menu in $menu_list; do
    modes="${modes},${menu}:${menu_folder}${menu}.sh"
  done

  rofi -show combi -combi-modes $modes -modes combi
}

everything_menu() {
  modes="drun"
  for menu in $menu_list; do
    modes="${modes},${menu}:${menu_folder}${menu}.sh"
  done

  # modes="${modes:1}"
  rofi -show combi -combi-modes $modes -modes combi
}

# Okay, list of things we want:
# 1. The drun menu we're used to for launching apps
# 2. A "master" menu for all the sub menus we are creating in the /menus folder
# 3. A "Full" menu that uses -combi-modes to combine all the sub menues we've created

everything_menu
