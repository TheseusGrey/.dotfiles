#!/bin/bash

# System controls menu — opens the shell's finder/panel commands via qsh.
QSH=/home/ashe/.local/bin/qsh

entries=(
  "App Launcher"
  "Screen Capture"
  "Power Menu"
  "Lock Session"
)

selection=$(printf "%s\n" "${entries[@]}" | $QSH pick --prompt "controls" 2>/dev/null)
[ -z "$selection" ] && exit 1

case "$selection" in
  "App Launcher")   $QSH finder apps ;;
  "Screen Capture") $QSH finder screenshot ;;
  "Power Menu")     $QSH panel open power ;;
  "Lock Session")   $QSH lock ;;
esac