let
  nix-rice = builtins.fetchGit {
    url = "https://github.com/bertof/nix-rice.git";
    ref = "refs/tags/v0.3.0";  
  };
  nix-rice-overlay = import (nix-rice + "/overlay.nix");
  pkgs = import <nixpkgs> { overlays = [ nix-rice-overlay ];};
in
{
  blend = {color1, color2, alpha, }: let
    rgb1 = pkgs.nix-rice.hexToRbga color1;
    rgb2 = pkgs.nix-rice.hexToRbga color2;
    new_r = builtins.round (rgb1.r * (1 - alpha) + rgb2.r * alpha);
    new_g = builtins.round (rgb1.g * (1 - alpha) + rgb2.g * alpha);
    new_b = builtins.round (rgb1.b * (1 - alpha) + rgb2.b * alpha);
    in builtins.format "#%02x%02x%02x" new_r new_g new_b;
}
