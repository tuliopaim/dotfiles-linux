# Enable the subsequent settings only in interactive sessions
case $- in
  *i*) ;;
    *) return;;
esac

# Path to your oh-my-bash installation.
export OSH='/home/tuliopaim/.oh-my-bash'

export QT_QPA_PLATFORM=wayland

set -o vi

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-bash is loaded.
OSH_THEME="minimal-gh"

NVIM_FOLDER="~/.dotfiles/nvim/.config/nvim/"

# No error beep
set opt no_beep

# dotnet 
export DOTNET_ROOT="/home/$USER/.dotnet"

export PATH=$PATH:/home/$USER/.dotnet:~/.dotnet/tools

# fzf
source /usr/share/fzf/shell/key-bindings.bash

export FZF_DEFAULT_OPTS="--color=16 --color=fg+:#FF5E7D --color=bg+:#002B36 --color=hl:#B48EAD --color=fg:#839496"
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix'
export FZF_ALT_C_COMMAND="fd --type d . --strip-cwd-prefix"
export FZF_ALT_C_OPTS="--preview 'tree -C {}'"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :50 {}'"
export FZF_TMUX_OPTS='-p80%,60%'

alias fh='history | fzf --tac | awk '\''{$1=""; print $0}'\'' | xargs -r -I{} fc -s {}'

OMB_USE_SUDO=true

completions=(
  git
  composer
  ssh
)

aliases=(
  general
)

#aliases
alias ls='ls -la'
alias ..='cd ..'
alias ....='cd ../..'
alias ......='cd ../../..'
alias dev='cd ~/dev/'
alias dotfiles='cd ~/.dotfiles'
alias nvimconfig='cd $NVIM_FOLDER'
alias sshpersonal='eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_personal_gh'

alias lg='lazygit'
alias lzd='lazydocker'
alias us='~/.dotfiles/scripts/usersecrets.sh'

plugins=(
  git
  bashmarks
)

source /etc/profile.d/bash_completion.sh

source "$OSH"/oh-my-bash.sh

export EDITOR='nvim'
