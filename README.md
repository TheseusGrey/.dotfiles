# .dotfiles

My collection of `.dotfiles` I use when and where ever I'm doing stuff. The README is mostly a few of my ramblings and ideas that I wanted to keep track of. Such as the requirements to get things started:

- A working [Python](https://www.python.org/) version, ideally an up-to-date version of `Python3`.
  - You'll also need [pip]() if you're missing that
- `Ansible`, you can find install instructions [here](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#).
- There are a bunch of packages that you'd need to go grab as dependencies, but `ansible` has made finding a platform agnostic way of doing that without writing endless near duplicate `.yml` files quite a challenge, and it's not worth creating some fancy templating to make it work.

In future I might move to a tool like [Home Manger](https://github.com/nix-community/home-manager). Since it does alot to make itself platform agnostic (I've run into a couple hurdles getting packages & dependencies installed in a platform agnostic way when using ansible).

If anyone does see this and wants to try it out or steal stuff, the `.zshrc` includes a source to a `.env.sh` file. The file isn't part of the repo, it's there if you need to do anything specific to the environment you're working on you wouldn't want saved, like env variables etc.
