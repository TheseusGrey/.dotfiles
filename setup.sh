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

configs=(
  zsh
  nvim
  rofi
  hypr
  kitty
  waybar
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
