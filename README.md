# .dotfiles

My collection of `.dotfiles` I use when and where ever I'm doing stuff. The README is mostly a few of my ramblings and ideas that I wanted to keep track of. Such as the requirements to get things started:

- The [Nix package manager](https://nixos.org/download/)
- [Home Manager](https://nix-community.github.io/home-manager/index.xhtml#ch-installation), this is the tool we'll be using to build and apply our nix configs.

If anyone comes and wants to steal this stuff, I have a rough rule of using `env` files for machine/environment specific configs, for example:

- The `.zshrc` will look for a `~/.env.sh` file which gets loaded after all the other stuff, this is good for things like env variables and config for tools you only use that machine.
- You will need to put a `env.nix` file containing the config you want specifically for that machine, you can start with the basic stuff that comes from the default `home.nix` config file:

```nix
{
  home.username = "{username}";
  home.homeDirectory = "/home/{ashe}";
}


## Screenshot
![Desktop Screenshot](screenshot.png "Sample desktop screenshot :)")
```
