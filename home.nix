{ config, pkgs, ... }:

{
  # Need to find a way to put this information somewhere else
  home.username = "ashe";
  home.homeDirectory = "/home/ashe";

  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

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
    "${config.xdg.configHome}/alacritty/alacritty.toml".source =  ~/.dotfiles/alacritty/alacritty.toml;
    "${config.xdg.configHome}/kitty/kitty.conf".source =  ~/.dotfiles/kitty/kitty.conf;
    "${config.xdg.configHome}/nvim".source =  ~/.dotfiles/nvim;
    "${config.xdg.configHome}/tmux".source =  ~/.dotfiles/tmux;
    "${config.xdg.configHome}/zsh".source =  ~/.dotfiles/zsh;
    "${config.home.homeDirectory}/.zshrc".source =  ~/.dotfiles/zsh/.zshrc;
    "${config.home.homeDirectory}/.zshenv".source =  ~/.dotfiles/zsh/.zshenv;
  };

  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
