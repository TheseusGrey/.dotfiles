{ config, pkgs, ... }: {

  home.packages = with pkgs; [
    tmuxifier
  ];

  home.file = {
    "${config.xdg.configHome}/tmux".source = ../tmux;
  };
}

