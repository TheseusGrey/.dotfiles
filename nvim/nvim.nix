{ config, pkgs, ... }: {

  home.file = {
    "${config.xdg.configHome}/nvim".source = config.lib.file.mkOutOfStoreSymlink ../nvim;
  };
  
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    defaultEditor = true;
    extraPackages = with pkgs; [
      pyright
      stylua
      nil
      typescript
      lua-language-server
      black
      vscode-extensions.rust-lang.rust-analyzer
    ];
  };
}

