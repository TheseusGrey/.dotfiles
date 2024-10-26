{ config, ... }: {

  home.file = {
    "${config.xdg.configHome}/kitty".source = config.lib.file.mkOutOfStoreSymlink ../kitty;
  };
}

