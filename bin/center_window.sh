#!/bin/bash

last_count=-1
# Infinite loop to check the current workspace
while true; do
  # Workspace info
  workspace=$(hyprctl activeworkspace)
  active_workspace=$(echo "$workspace" | grep "workspace ID" | awk '{print $3}')
  has_fullscreen=$(echo "$workspace" | grep "hasfullscreen" | awk '{print $2}')
  window_count=$(echo "$workspace" | grep "windows" | awk '{print $2}')

  if [ "$window_count" -ne "$last_count" ] && [ "$has_fullscreen" -eq 0 ]; then
    # If there is exactly one window in the workspace
    if [ "$window_count" -eq 1 ]; then
      hyprctl dispatch setfloating
      hyprctl dispatch resizeactive exact 80% 80%
      hyprctl dispatch centerwindow
    else
      for i in {1..$window_count}; do
        hyprctl dispatch cyclenext
        hyprctl dispatch settiled
      done
    fi
    last_count="$window_count"
  fi

  # Sleep to avoid busy-waiting (adjust as needed)
  sleep 0.5
done &
