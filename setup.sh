#!/usr/bin/env bash

export DOTFILES="$HOME/.dotfiles"

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

# Generated theme outputs are gitignored. They must exist before stowing so
# their live symlinks can be created; `qsh bootstrap` fills them afterwards.
ensure_generated() {
  local files=(
    quickshell/services/Colors.qml
    hypr/themes/matugen_colors.lua
    hypr/hyprpaper.conf
    chrome/matugen-chrome.css
    chrome/matugen-content.css
    kitty/matugen.conf
  )
  for f in "${files[@]}"; do
    mkdir -p "$(dirname "$DOTFILES/$f")"
    [ -e "$DOTFILES/$f" ] || : > "$DOTFILES/$f"
  done
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
  hypr
  kitty
  waybar
  quickshell
  matugen
)

ensure_generated

echo ""
echo "Stowing ~ configs."
# Special cases that won't go into the loop below
link home ~
link chrome ~/.config/librewolf/librewolf/*.default-release/chrome

echo ""
echo "Stowing configs."

for config in ${configs[@]}; do
  mkdir -p "${HOME}/.config/${config}"     # Make dir if not present
  link $config "${HOME}/.config/${config}" # stow configs to dir
done

# Build qsh and generate a working default palette if this is a fresh checkout.
if command -v matugen >/dev/null 2>&1; then
  if command -v just >/dev/null 2>&1; then
    just build-qsh >/dev/null
  elif command -v go >/dev/null 2>&1; then
    go build -trimpath -ldflags="-s -w" \
      -o "${HOME}/.local/bin/qsh" "$DOTFILES/quickshell/scripts/qsh.go"
  fi

  if [ -x "${HOME}/.local/bin/qsh" ]; then
    "${HOME}/.local/bin/qsh" bootstrap || \
      echo "warning: qsh bootstrap failed; run 'qsh theme default' manually" >&2
  else
    echo "warning: qsh is not installed; run 'just build-qsh' and then 'qsh bootstrap'" >&2
  fi
else
  echo "warning: matugen is not installed; generated theme files will stay empty" >&2
fi
