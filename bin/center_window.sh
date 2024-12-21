#!/bin/bash

# Infinite loop to check the current workspace
while true; do
  # Workspace info
  workspace=$(hyprctl activeworkspace)
  active_workspace=$($workspace | grep "workspace ID" | awk '{print $3}')
  window_count=$($workspace | grep "windows" | awk '{print $2}')

  # If there is exactly one window in the workspace
  if [ "$window_count" -eq 1 ]; then
    hyprctl dispatch setfloating
    hyprctl dispatch resizeactive exact 80% 80%
    hyprctl dispatch centerwindow
  else
    # Make sure that there are no floating windows, currently focus shifts to the new window, need it to not
    hyprctl dispatch settiled
  fi

  # Sleep to avoid busy-waiting (adjust as needed)
  sleep 0.5
done
