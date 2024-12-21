#!/bin/bash

last_count=-1

while true; do
  # Workspace info
  workspace=$(hyprctl activeworkspace)
  active_workspace=$(echo "$workspace" | grep "workspace ID" | awk '{print $3}')
  has_fullscreen=$(echo "$workspace" | grep "hasfullscreen" | awk '{print $2}')
  window_count=$(echo "$workspace" | grep "windows" | awk '{print $2}')

  # Only run if number of windows has changes, the workspace doesn't contain a fullspace window, and ignore
  # worspace 3 since that's where Steam runs and it doesn't play nice
  if [ "$window_count" -ne "$last_count" ] && [ "$has_fullscreen" -eq 0 ] && [ "$active_workspace" -ne 3 ]; then
    if [ "$window_count" -eq 1 ]; then # Single windows are focused to center of screen
      hyprctl dispatch setfloating
      hyprctl dispatch resizeactive exact 80% 80%
      hyprctl dispatch centerwindow
    else # If there are multiple windows we reset to the default tiled layout
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
