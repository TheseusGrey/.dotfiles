{ config, pkgs, ... }: {

  home.packages = with pkgs; [
    tmuxifier
  ];

  home.file = {
    # "${config.xdg.configHome}/tmux".source = config.lib.file.mkOutOfStoreSymlink ../tmux;
  };

  programs.tmux = {
    enable = true;
    plugins = with pkgs; [
      tmuxPlugins.nord
      tmuxPlugins.sensible
      tmuxPlugins.vim-tmux-navigator
    ];
    extraConfig = ''
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
}

