{ config, ... }: {

  home.file = {
    "${config.xdg.configHome}/alacritty/theme.toml".source = ./theme.toml;
  };

  programs.alacritty = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ./alacritty.toml);
  };
}

