PRIMARY_CLR=$(tput setaf 121)
SECONDARY_CLR=$(tput setaf 63)
RESET_PRMPT=$(tput sgr0)

current_dir=${PWD##*/}
current_dir=${current_dir:-/}

. "$HOME/.cargo/env"

export PATH=$HOME/.tmux/plugins/tmuxifier/bin:~/.local/bin:~/.cargo/bin:~/tools/nvim/bin:/usr/local/go/bin:${M2_HOME}/bin:$PATH
export EDITOR=nvim
export TERMINAL=alacritty

export FZF_DEFAULT_OPTS=" \
--height 62% --layout=reverse \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
export TMUXIFIER_LAYOUT_PATH="$HOME/.dotfiles/tmux/layouts"

