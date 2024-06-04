{ config, pkgs, ... }:

{
  imports = [ ./env.nix ];
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.11"; # Please read the comment before changing.

  # https://search.nixos.org/packages
  home.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    nixd
    fzf
    git
    tmux
    neovim
    ansible
    tmuxifier
    alacritty
    cargo
    polybar
    nodenv
    gcc
  ];

  home.file = {
    "${config.xdg.configHome}/alacritty/alacritty.toml".source = config.lib.file.mkOutOfStoreSymlink ~/.dotfiles/alacritty/alacritty.toml;
    "${config.xdg.configHome}/kitty/kitty.conf".source = config.lib.file.mkOutOfStoreSymlink ~/.dotfiles/kitty/kitty.conf;
    "${config.xdg.configHome}/nvim".source = config.lib.file.mkOutOfStoreSymlink ~/.dotfiles/nvim;
    "${config.xdg.configHome}/tmux".source = config.lib.file.mkOutOfStoreSymlink ~/.dotfiles/tmux;
    "${config.xdg.configHome}/zsh".source = config.lib.file.mkOutOfStoreSymlink ~/.dotfiles/zsh;
    "${config.xdg.configHome}/polybar".source = config.lib.file.mkOutOfStoreSymlink ~/.dotfiles/polybar;
  # "${config.xdg.configHome}/i3".source = config.lib.file.mkOutOfStoreSymlink ~/.dotfiles/i3;
  # "${config.home.homeDirectory}/.zshrc".source = config.lib.file.mkOutOfStoreSymlink ~/.dotfiles/zsh/.zshrc;
  # "${config.home.homeDirectory}/.zshenv".source = config.lib.file.mkOutOfStoreSymlink ~/.dotfiles/zsh/.zshenv;
  };

  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  programs.alacritty = {
    enable = true;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    completionInit = "autoload -Uz compinit && compinit";
    shellAliases = {
      # ALIASES ---------------------------------------------------------------------
      please="sudo";
      yeet="rm";
      "cd.."="cd ..";
      c="clear";
      s="source ~/.zshrc";
      ls="ls --color";
      hms="home-manager switch";

      # TMUX + NVIM ALIASES
      t="tmuxifier";

      # GIT ALIASES -----------------------------------------------------------------
      gs="git status";
      gc="git commit";
      gch="git checkout";
      ga="git add";
      gb="git checkout -b";
      gd="git diff";
      gp="git push";
    };
    initExtra = ''
      pl() {
      	local project_name=$(find ~/project_list -maxdepth 1 -exec basename {} \; | fzf)
      	if [ -n "$project_name" ]; then
      		local project_path=$(readlink -f ~/project_list/$project_name)
      		echo $project_path
      	fi
      }

      po() {
      	local project=$(pl)
      	if [ -n "$project" ]; then
      		local layout_type="w"
      		local window_name="''${2:-dev}"
      		DIR="$project" t "$layout_type" "$window_name"
      	fi
      }'';
    history = {
      size = 1000;
      save = 1000;
      path = "${config.xdg.dataHome}/zsh/history";
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
    };
    oh-my-zsh.extraConfig = ''
      # Completion styling
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*' menu no
      zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup

      # Shell integrations
      eval "$(fzf --zsh)"
    '';

    zplug = {
      enable = true;
      plugins = [
        { name = "zsh-users/zsh-syntax-highlighting"; }
        { name = "zsh-users/zsh-completions"; }
        { name = "Aloxaf/fzf-tab"; }
        { name = "zsh-users/zsh-autosuggestions"; } # Simple plugin installation
        { name = "romkatv/powerlevel10k"; tags = [ as:theme depth:1 ]; } # Installations with additional options. For the list of options, please refer to Zplug README.
      ];
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
