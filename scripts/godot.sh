#!/usr/bin/env bash

# - replace with other path for the Neovim server pipe
server_path="$HOME/.cache/nvim/godot-server.pipe"
nvim_exec="nvim --listen $server_path $1"

tmux new-window -d "$nvim_exec"
