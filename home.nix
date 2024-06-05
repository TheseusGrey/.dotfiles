{ config, pkgs, ... }:

{
  imports = [ ./env.nix ];
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.11"; # Please read the comment before changing.

  # https://search.nixos.org/packages
  home.packages = with pkgs; [
    zsh-powerlevel10k
    nixd
    pyright
    fzf
    neovim
    tmuxifier
    cargo
    nodenv
    gcc
  ];

  home.file = {
  "${config.xdg.configHome}/alacritty/alacritty.toml".source = config.lib.file.mkOutOfStoreSymlink ~/.dotfiles/alacritty/alacritty.toml;
  # "${config.xdg.configHome}/kitty/kitty.conf".source = config.lib.file.mkOutOfStoreSymlink ~/.dotfiles/kitty/kitty.conf;
    "${config.xdg.configHome}/nvim".source = config.lib.file.mkOutOfStoreSymlink ~/.dotfiles/nvim;
  # "${config.xdg.configHome}/tmux".source = config.lib.file.mkOutOfStoreSymlink ~/.dotfiles/tmux;
    "${config.xdg.configHome}/zsh".source = config.lib.file.mkOutOfStoreSymlink ~/.dotfiles/zsh;
  # "${config.xdg.configHome}/polybar".source = config.lib.file.mkOutOfStoreSymlink ~/.dotfiles/polybar;
  # "${config.xdg.configHome}/i3".source = config.lib.file.mkOutOfStoreSymlink ~/.dotfiles/i3;
  # "${config.home.homeDirectory}/.zshrc".source = config.lib.file.mkOutOfStoreSymlink ~/.dotfiles/zsh/.zshrc;
  # "${config.home.homeDirectory}/.zshenv".source = config.lib.file.mkOutOfStoreSymlink ~/.dotfiles/zsh/.zshenv;
  };

  home.sessionVariables = {
    XDG_DATA_HOME = "${xdg.dataHome}";
    XDG_CONFIG_HOME = "${xdg.configHome}";
    XDG_STATE_HOME = "${xdg.stateHome}";
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

  programs.alacritty = {
    enable = true;
    settings = {
      env = {
	        TERM = "xterm-256color";
	    };
      font = {
        size = 14;
        family = "JetBrainsMono Nerd Font Mono";
      };
      window = {
        decoration = "none";
      };
    };
    };

  programs.git = {
    enable = true;
    userName = "TheseusGrey";
    userEmail = "TheseusGrey@proton.me";
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
        { name = "romkatv/powerlevel10k"; tags = [ as:theme depth:1 ]; } # Installations with additional options. For the list of options, please refer to Zplug README.
      ];
    };
  };

  programs.tmux = {
    enable = true;
    plugins = with pkgs; [
      tmuxPlugins.sensible
      tmuxPlugins.vim-tmux-navigator
      tmuxPlugins.catppuccin
    ]; 
    extraConfig = ''
      set -g @plugin 'jimeh/tmuxifier'
      set -g @catppuccin_flavour 'frappe' # or frappe, macchiato, latte
      set-option -g status-position top
      
      
      # Smart pane switching with awareness of Vim splits.
      # See: https://github.com/christoomey/vim-tmux-navigator
      
      # decide whether we're in a Vim process
      is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
          | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
      
      bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h' 'select-pane -L'
      bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j' 'select-pane -D'
      bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k' 'select-pane -U'
      bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l' 'select-pane -R'
      
      tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
      
      if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
          "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
      if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
          "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"
      
      bind-key -n 'C-Space' if-shell "$is_vim" 'send-keys C-Space' 'select-pane -t:.+'
      
      bind-key -T copy-mode-vi 'C-h' select-pane -L
      bind-key -T copy-mode-vi 'C-j' select-pane -D
      bind-key -T copy-mode-vi 'C-k' select-pane -U
      bind-key -T copy-mode-vi 'C-l' select-pane -R
      bind-key -T copy-mode-vi 'C-\' select-pane -l
      bind-key -T copy-mode-vi 'C-Space' select-pane -t:.+
    '';
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
