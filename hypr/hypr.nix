{ config, ... }: {

home.file = {
  "${config.xdg.configHome}/hypr".source = config.lib.file.mkOutOfStoreSymlink ../hypr;
  };
}

