{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "p.goldmansmith1";
  home.homeDirectory = "/Users/p.goldmansmith1";

  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  home.packages = with pkgs; [
    nerdfonts
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
    "~/.config/alacritty".source = ~/.dotfiles/alacritty;
    "~/.config/kitty".source = ~/.dotfiles/kitty;
    "~/.config/nvim".source = ~/.dotfiles/nvim;
    "~/.config/tmux".source = ~/.dotfiles/tmux;
    "~/.config/zsh".source = ~/.dotfiles/zsh;
    "~/.zshrc".source = ~/.dotfiles/zsh/.zshrc;
    "~/.zshenv".source = ~/.dotfiles/zsh/.zshenv;
  };

  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
