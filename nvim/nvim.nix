{ config, pkgs, ... }: {

  home.file = {
    "${config.xdg.configHome}/nvim".source = ../nvim;
  };
  
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    extraPackages = with pkgs; [
      lua-language-server
      nixd
      nodePackages.typescript-language-server
    ];
  };
}

