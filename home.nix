{ config, pkgs, lib, ... }:

{
  imports = [
    ./env.nix
    ./hypr/hypr.nix
    ./waybar/waybar.nix
    ./rofi/rofi.nix
    ./alacritty/alacritty.nix
    ./tmux/tmux.nix
    ./zsh/zsh.nix
    ./nvim/nvim.nix
  ];

  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.

  # https://search.nixos.org/packages

  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    jq
    nixd
    pyright
    fzf
    tmuxifier
    cargo
    nodenv
    gcc
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
