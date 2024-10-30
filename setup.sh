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
  rofi
  hypr
  kitty
  # waybar
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

# Check stow exists, if not install it (assume arch/pacman for now)
# stow each of the configs (we can remove stuff we don't use anymore)

# stow usage example in this blog: https://dev.to/spacerockmedia/how-i-manage-my-dotfiles-using-gnu-stow-4l59

# Side note is I should go through the stuff in .config for hyprdots to see if there's anything
# I wanna grab and add to my own stuff
