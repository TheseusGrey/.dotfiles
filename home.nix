{ config, pkgs, lib, ... }:

{
  imports = [
    ./env.nix
    ./nix/home/hypr.nix
    ./nix/home/waybar.nix
    ./nix/home/rofi.nix
    ./nix/home/alacritty.nix
    ./nix/home/tmux.nix
    ./nix/home/zsh.nix
    ./nix/home/nvim.nix
  ];

  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.11"; # Please read the comment before changing.

  # https://search.nixos.org/packages
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "obsidian"
  ];

  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    nixd
    pyright
    fzf
    tmuxifier
    cargo
    nodenv
    gcc
    obsidian
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
