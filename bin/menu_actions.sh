#!/bin/bash

# System actions menu — power/session actions via qsh pick.
QSH=/home/ashe/.local/bin/qsh

entries=(
  "Lock"
  "Suspend"
  "Restart"
  "Shutdown"
)

selection=$(printf "%s\n" "${entries[@]}" | $QSH pick --prompt "actions" 2>/dev/null)
[ -z "$selection" ] && exit 1

case "$selection" in
  "Lock")     hyprlock &>/dev/null ;;
  "Suspend")  systemctl suspend ;;
  "Restart")  systemctl reboot ;;
  "Shutdown") systemctl poweroff ;;
esac