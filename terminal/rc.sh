#!/usr/bin/env bash
source_if_exists () {
    if test -r "$1"; then
        source "$1"
    fi
}

source_if_exists "$HOME"/.env.sh
source_if_exists "$HOME"/config.sh
source_if_exists "$DOTFILES"/terminal/zsh/history.zsh
source_if_exists "$DOTFILES"/terminal/git.zsh
source_if_exists ~/.fzf.zsh
source_if_exists "$DOTFILES"/terminal/aliases.zsh
source_if_exists /usr/local/etc/profile.d/z.sh
source_if_exists /opt/homebrew/etc/profile.d/z.sh

export VISUAL=neovide
export EDITOR=neovide
