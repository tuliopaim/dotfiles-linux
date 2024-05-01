export ZSH=$HOME/.oh-my-zsh

ZSH_THEME="amuse"
DOTFILES="/home/$USER/.dotfiles"
NVIM_FOLDER="/home/$USER/.config/nvim/"

plugins=(git zsh-autosuggestions vi-mode)

source $ZSH/oh-my-zsh.sh

# Enable vi mode
bindkey -v

# fzf
export FZF_DEFAULT_OPTS="--color=16 --color=fg+:#FF5E7D --color=bg+:#002B36 --color=hl:#B48EAD --color=fg:#839496"
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix'

export FZF_ALT_C_COMMAND="fd --type d . --strip-cwd-prefix"
export FZF_ALT_C_OPTS="--preview 'tree -C {}'"

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :50 {}'"

# Enable fzf widget
source /usr/share/fzf/key-bindings.zsh

#aliases
alias ls='ls -la'
alias ..='cd ..'
alias ....='cd ../..'
alias ......='cd ../../..'

alias nvimconfig='cd $NVIM_FOLDER'

alias subup='sshtb && git submodule update --init --recursive'
alias sshpersonal='eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_personal_gh'
alias sshtb='eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_tb_gh'
alias tm='tmux-sessionizer'

alias k='kubectl'

alias lg='lazygit'
alias lzd='lazydocker'
alias us='~/.dotfiles/scripts/usersecrets.sh'

export PATH="/home/tuliopaim/.local/bin:$PATH"

# dotnet 
export DOTNET_ROOT="/home/$USER/.dotnet"
export PATH=$PATH:/home/$USER/.dotnet:~/.dotnet/tools

# fnm
export PATH="/home/tuliopaim/.local/share/fnm:$PATH"
eval "`fnm env`"

eval "$(zoxide init zsh)"

alias cd='z'
