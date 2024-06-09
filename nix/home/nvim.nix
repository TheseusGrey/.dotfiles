{ config, pkgs, ... }: {

  home.packages = with pkgs; [
    neovim
  ];

  home.file = {
    "${config.xdg.configHome}/nvim".source = ../../nvim;
  };
}

