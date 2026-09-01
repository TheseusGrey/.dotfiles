
# Preflight to install package deps,
# This includes EVERYTHING for the dotfiles, not just programming stuffs
setup:
  echo 'setup'

# This will handle symlinking all the config to where it needs to be, basically what the 
# current setup.sh does
link:
  echo 'link'

# Eventually we might more complex stuff, such as pulling Nvidia drivers (if we still need it)
# Got a few other things I'd wanna set up as well, but one step at a time

# Run all neovim tests
nvim-test:
  nvim --headless -c "PlenaryBustedDirectory nvim/tests/ {minimal_init = 'nvim/init.lua'}"

# Run a specific neovim test file
nvim-test-file file:
  nvim --headless -c "PlenaryBustedFile {{file}}"

# ─── qsh (Quickshell TUI shell CLI) ────────────────────────────────────
# Build the qsh CLI into ~/.local/bin (replaces the old finder/socket recipes)
build-qsh:
  go build -trimpath -ldflags="-s -w" -o {{ home_directory() }}/.local/bin/qsh quickshell/scripts/qsh.go

# Open the app finder (mode: apps | screenshot | keybinds)
finder mode="apps":
  qsh finder {{mode}}

# Toggle the finder
finder-toggle:
  qsh finder toggle

# Pick a color
pick-color:
  qsh pick --items red,green,blue,yellow,purple,orange --prompt "pick a color"

# Pick a git branch to checkout
pick-branch:
  branch=$(git branch --format='%(refname:short)' | qsh pick --prompt "checkout branch") && git checkout "$branch"

# Pick a process to kill (by memory usage)
pick-kill:
  proc=$(ps -eo comm= --sort=-%mem | head -20 | qsh pick --prompt "kill process") && pkill -x "$proc" && echo "Killed: $proc"

# Pick a directory (prints path — use with: cd $(just pick-dir))
pick-dir:
  find . -maxdepth 2 -type d | head -30 | qsh pick --prompt "directory"

# Pick from a list on stdin
pick-stdin prompt="select":
  qsh pick --prompt "{{prompt}}"

# Regenerate the theme from a wallpaper image
wallpaper file:
  qsh wallpaper {{file}}

# Apply a fixed theme preset (default, catppuccin) — not tied to the wallpaper
theme name="default":
  qsh theme {{name}}
