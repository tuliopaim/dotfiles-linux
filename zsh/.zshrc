# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH_DISABLE_COMPFIX=true
export ZSH="/usr/local/share/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

# Enable vi mode
bindkey -v

# fzf
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix'

export FZF_ALT_C_COMMAND="fd --type d . --strip-cwd-prefix"
export FZF_ALT_C_OPTS="--preview 'tree -C {}'"

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :50 {}'"
export FZF_TMUX_OPTS='-p80%,60%'

# Enable fzf widget
source /usr/share/doc/fzf/examples/key-bindings.zsh
source /usr/share/doc/fzf/examples/completion.zsh

#aliases
alias ls='ls -la'
alias ..='cd ..'
alias ....='cd ../..'
alias ......='cd ../../..'
alias dev='cd ~/dev/'
alias dotfiles='cd /usr/local/share/.dotfiles'

alias sshpersonal='eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_personal_gh'
alias sshtb='eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_tb_gh'

alias gp='git pull'
alias gps='git push'
alias gs='git status'

bindkey '^ ' autosuggest-accept

alias fh='history | fzf --tac | awk '\''{$1=""; print $0}'\'' | xargs -r -I{} fc -s {}'

# No error beep
setopt no_beep

export PATH="/usr/local/bin/nvim:$PATH"

# dotnet 
export DOTNET_ROOT=/usr/local/share/.dotnet
export PATH=$PATH:/usr/local/share/.dotnet:/usr/local/share/.dotnet/tools

# fnm
# export PATH="/usr/local/share/.fnm:$PATH"
# eval "`fnm env`"

export FZF_DEFAULT_OPTS="--color=16 --color=fg+:#FF5E7D --color=bg+:#002B36 --color=hl:#B48EAD --color=fg:#839496"
