
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
