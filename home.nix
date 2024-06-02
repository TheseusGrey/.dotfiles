{ config, pkgs, ... }:

{
  # Need to find a way to put this information somewhere else
  home.username = "ashe";
  home.homeDirectory = "/home/ashe";

  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # https://search.nixos.org/packages
  home.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    fzf
    git
    tmux
    neovim
    ansible
    tmuxifier
    alacritty
    cargo
    sdkmanager
    nodenv
  ];

  home.file = {
    "${config.xdg.configHome}/alacritty/alacritty.toml".source = config.lib.file.mkOutOfStoreSymlink ~/.dotfiles/alacritty/alacritty.toml;
    "${config.xdg.configHome}/kitty/kitty.conf".source = config.lib.file.mkOutOfStoreSymlink ~/.dotfiles/kitty/kitty.conf;
    "${config.xdg.configHome}/nvim".source = config.lib.file.mkOutOfStoreSymlink ~/.dotfiles/nvim;
    "${config.xdg.configHome}/tmux".source = config.lib.file.mkOutOfStoreSymlink ~/.dotfiles/tmux;
    "${config.xdg.configHome}/zsh".source = config.lib.file.mkOutOfStoreSymlink ~/.dotfiles/zsh;
    "${config.home.homeDirectory}/.zshrc".source = config.lib.file.mkOutOfStoreSymlink ~/.dotfiles/zsh/.zshrc;
    "${config.home.homeDirectory}/.zshenv".source = config.lib.file.mkOutOfStoreSymlink ~/.dotfiles/zsh/.zshenv;
  };

  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
