#!/usr/bin/env bash

export DOTFILES=~/.dotfiles

# Install gnu-stow if not present
if ! stow_loc="$(type -p "stow")" || [[ -z $stow_loc ]]; then
  sudo pacman -S stow
fi

link() {
  s=$1 # Source dir
  t=$2 # Target dir

  # -v=verbose -R=recursive -t=target
  stow -v -R -t ${t} ${s}
}

# /usr/share/applications
# Want to create some desktop files for tools I use
# yazi
# wikiman
# tldr
#
# An example for yazi already exists, we just need to move it here and symlink it properly
# We'll create an applications folder and link it to the path above

# Also, I want to include package lists to install a baseline incase I need it in future.

configs=(
  zsh
  nvim
  rofi
  hypr
  kitty
  waybar
  quickshell
)

echo ""
echo "Stowing ~ configs."
link home ~ # Special case that won't go into the loop below

echo ""
echo "Stowing configs."

for config in ${configs[@]}; do
  mkdir -p "${HOME}/.config/${config}"     # Make dir if not present
  link $config "${HOME}/.config/${config}" # stow configs to dir
done
