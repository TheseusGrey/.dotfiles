#!/bin/bash

# Infinite loop to check the current workspace
while true; do
  # Get the focused workspace
  focused_workspace=$(hyprctl workspaces | grep "focused" | awk '{print $1}')

  # Get the number of windows in the focused workspace
  window_count=$(hyprctl clients | grep "workspace: $focused_workspace" | wc -l)

  # If there is exactly one window in the workspace
  if [ "$window_count" -eq 1 ]; then
    # Center the window on this workspace
    hyprctl dispatch windowrule center
  fi

  # Sleep to avoid busy-waiting (adjust as needed)
  sleep 0.5
done
