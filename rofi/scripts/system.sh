#!/usr/bin/env bash

if [ $# -gt 0 ]; then
  # If arguments given, use those as the selection
  selection="${@}"
else
  # Otherwise, use the CLI passed choice if given
  if [ -n "${selectionID+x}" ]; then
    selection="${messages[$selectionID]}"
  fi
fi

if [ -z "${selection+x}" ]; then
  # Present options for screen captures
  echo -en "\0prompt\x1fSystem\t>\n"
  echo -e "  Lock"
  echo -e "󱄄  Screensaver"
  echo -e "󰤄  Suspend"
  echo -e "  Relaunch"
  echo -e "󰜉  Restart"
  echo -e "󰐥  Shutdown"

else
  # We've picked an option, so do something with it
  case "$@" in
  *Lock*) swaylock ;;
  *Screensaver*) notify-send "NOT IMPLEMENTED YET" ;;
  *Suspend*) systemctl suspend ;;
  *Relaunch*) notify-send "NOT IMPLEMENTED YET" ;; # uwsm stop
  *Restart*) systemctl reboot ;;
  *Shutdown*) systemctl poweroff ;;
  esac

  exit 0
fi
