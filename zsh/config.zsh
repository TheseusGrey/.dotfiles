plugins=(ansible docker kubectl mix)

autoload -U zmv
autoload -U promptinit && promptinit
autoload -U colors && colors
autoload -Uz compinit && compinit

compinit 

zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes