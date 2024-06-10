{ config, ... }: {

  programs.waybar = {
    enable = true;
    settings.source = builtins.fromJSON (builtins.readFile ./config.json);
    style = ./style.css;
  };
}

