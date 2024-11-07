. "$HOME/.cargo/env"

export DOTFILES=~/.dotfiles
export EDITOR=nvim
export TERMINAL=kitty

export GEM_HOME="$(gem env user_gemhome)"
export PATH="$PATH:$GEM_HOME/bin:$DOTFILES/bin:$M2_HOME/bin:$HOME/.cargo/bin"

export FZF_DEFAULT_OPTS=" \
--height 62% --layout=reverse \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--prompt='❯ ' \
--pointer='󰅂'"
