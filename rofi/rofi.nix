{ config, ... }: {

  home.file = {
    "${config.xdg.configHome}/rofi/search-icon.svg".source =  ./search-icon.svg;
  };

  programs.rofi = {
      enable = true;
      theme = ./theme.rasi;
  };
}
