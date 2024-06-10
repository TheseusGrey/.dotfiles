{ config, ... }: {

  home.file = {
    "${config.xdg.configHome}/waybar".source =  ../waybar;
  };
}

