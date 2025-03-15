# .dotfiles

My collection of `.dotfiles` I use when and where ever I'm doing stuff. The README is mostly a few of my ramblings and ideas that I wanted to keep track of. Such as the requirements to get things started:

- [GNU stow](https://www.gnu.org/s/stow/manual/stow.html) for installing/managing the dotfiles
- Any of the programs/tools that these configs are for (I might make a script to go and grab them as well eventually).

If anyone comes and wants to steal this stuff, I have a rough rule of using `env` files for machine/environment specific configs, for example:

- The `.zshrc` will look for a `~/.env.sh` file which gets loaded after all the other stuff, this is good for things like env variables and config for tools you only use that machine.
- There's a `setup.sh` script that should auto link all the configs
  - It's set to auto install `stow` via `pacman` if it doesn't exist, just change this to the package manager for your system if you want it to work for you.
  - There's a `configs` array, you can edit this to add/remove parts of the configs you do or don't want, it's looking for folders in the root of the project.

## Screenshot
![Desktop Screenshot](screenshot.png "Sample desktop screenshot :)")
