{ config, ... }: {

  home.file = {
    "${config.xdg.configHome}/alacritty/theme.toml".source = ./theme.toml;
  };

  programs.alacritty = {
    enable = true;
    settings.source = ./alacritty.toml;
  };
}

