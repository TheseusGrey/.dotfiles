{ config, ... }: {

  home.file = {
    "${config.xdg.configHome}/rofi/theme.rasi".source = config.lib.file.mkOutOfStoreSymlink ./theme.rasi;
    "${config.xdg.configHome}/rofi/search-icon.svg".source = config.lib.file.mkOutOfStoreSymlink ./search-icon.svg;
  };

  programs.rofi = {
      enable = true;
      theme = ./theme.rasi;
  };
}
