{ config, ... }: {

  home.file = {
    "${config.xdg.configHome}/alacritty".source = ../../alacritty;
  };

  programs.alacritty = {
    enable = true;
  };
}

