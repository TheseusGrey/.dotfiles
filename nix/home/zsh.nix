{ pkgs, config, ... }: {

  home.packages = with pkgs; [
    zsh-powerlevel10k
  ];

  home.file = {
    "${config.xdg.configHome}/zsh".source =  ../../zsh;
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    TERMINAL = "alacritty";
    FZF_DEFAULT_OPTS='' 
      --height 62% --layout=reverse \
      --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
      --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
      --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
      --prompt='❯ ' \
      --pointer='󰅂' '';
    TMUXIFIER_LAYOUT_PATH="$HOME/.dotfiles/tmux/layouts";
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
    initExtraFirst = ''
      source ~/.p10k.zsh # This should always be a the top
      . "$HOME/.nix-profile/home-path/etc/profile.d/hm-session-vars.sh"
    '';
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
        { name = "romkatv/powerlevel10k"; tags = [ "as:theme" "depth:1" ]; } # Installations with additional options. For the list of options, please refer to Zplug README.
      ];
    };
  };
}