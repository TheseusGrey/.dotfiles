#!/usr/bin/env bash

# - replace with other path for the Neovim server pipe
server_path="$HOME/.cache/nvim/godot-server.pipe"
nvim_exec="nvim --listen $server_path $1"

godot_window=$(tmux list-windows | grep 'godot' | awk 'BEGIN{FS=":|-"} {print$1}')

if [ -n "$godot_window" ]; then
	tmux send-keys -t 0:$godot_window.0 C-z ":e $1" Enter
else
	tmux new-window -n godot -d "$nvim_exec"
fi
