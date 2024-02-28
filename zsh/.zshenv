PRIMARY_CLR=$(tput setaf 121)
SECONDARY_CLR=$(tput setaf 63)
RESET_PRMPT=$(tput sgr0)

current_dir=${PWD##*/}
current_dir=${current_dir:-/}

. "$HOME/.cargo/env"

export PATH=~/.local/bin:~/.cargo/bin:~/tools/nvim/bin:/usr/local/go/bin:${M2_HOME}/bin:$PATH
export EDITOR=nvim
export TERMINAL=alacritty
export PROMPT="%{$PRIMARY_CLR%}%n%{$RESET_PRMPT%}@%{$PRIMARY_CLR%}%m%{$RESET_PRMPT%}: "
export RPROMPT="%{$PRIMARY_CLR%}%1d%{$RESET_PRMPT%} |%{$SECONDARY_CLR%}%t%{$RESET_PRMPT%}"

