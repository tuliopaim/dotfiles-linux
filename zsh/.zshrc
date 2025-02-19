# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH_DISABLE_COMPFIX=true
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(zsh-autosuggestions)

DOTFILES="/usr/local/share/.dotfiles"
NVIM_FOLDER="/usr/local/share/.dotfiles/nvim/.config/nvim"

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
alias nvimconfig='cd /usr/local/share/.dotfiles/nvim/.config/nvim'
alias via='/usr/local/bin/via.AppImage'

alias sshpersonal='eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_personal_gh'

alias gp='git pull'
alias gps='git push'
alias gs='git status'
alias gc='git commit'
alias gl='git log'
alias lg='lazygit'
alias lzd='lazydocker'
alias us='/usr/local/share/.dotfiles/scripts/usersecrets.sh'

bindkey '^ ' autosuggest-accept

alias fh='history | fzf --tac | awk '\''{$1=""; print $0}'\'' | xargs -r -I{} fc -s {}'

# No error beep
setopt no_beep

export PATH="/usr/local/bin/nvim:$PATH"

# dotnet 
export DOTNET_ROOT="/home/$USER/.dotnet"
export PATH=$PATH:/home/$USER/.dotnet:~/.dotnet/tools

export FZF_DEFAULT_OPTS="--color=16 --color=fg+:#FF5E7D --color=bg+:#002B36 --color=hl:#B48EAD --color=fg:#839496"

# fnm
export PATH="/home/$USER/.local/share/fnm:$PATH"
eval "`fnm env`"

export PATH="/home/$USER/.local/bin:$PATH"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

