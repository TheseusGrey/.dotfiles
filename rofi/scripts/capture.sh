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
  echo -en "\0icon\x1f\n"
  echo -en "\0prompt\x1fCapture\t>\n"
  echo -e "  Screenshot"
  echo -e "  Screen Record"
  echo -e "󰃉  Color"

else
  # We've picked an option, so do something with it
  case "$@" in
  *Screenshot*) notify-send "NOT IMPLEMENTED YET" ;;
  *Screenrecord*) notify-send "NOT IMPLEMENTED YET" ;;
  *Color*) pkill hyprpicker || hyprpicker | wl-copy -n ;;
  esac

  exit 0
fi
