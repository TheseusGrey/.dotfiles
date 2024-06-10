{ config, ... }: {

  home.file = {
    "${config.xdg.configHome}/rofi/theme.rasi".source = config.lib.file.mkOutOfStoreSymlink ./rofi/theme.rasi;
    "${config.xdg.configHome}/rofi/search-icon.svg".source = config.lib.file.mkOutOfStoreSymlink ./rofi/search-icon.svg;
  };

  programs.rofi = {
      enable = true;
      theme = ../../rofi/theme.rasi;
  };
}
