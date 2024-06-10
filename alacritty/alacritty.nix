{ config, ... }: {


  programs.alacritty = {
    enable = true;
    settings.source = ../../alacritty/alacritty.toml;
  };
}

