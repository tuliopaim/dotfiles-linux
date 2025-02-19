# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Created by newuser for 5.8.1
source ~/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Fix Interop Error that randomly occurs in vscode terminal when using WSL2
fix_wsl2_interop() {
    for i in $(pstree -np -s $$ | grep -o -E '[0-9]+'); do
        if [[ -e "/run/WSL/${i}_interop" ]]; then
            export WSL_INTEROP=/run/WSL/${i}_interop
        fi
    done
}

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"


# fzf
export FZF_DEFAULT_OPTS='--no-height --color=bg+:#343d46,gutter:-1,pointer:#ff3c3c,info:#0dbc79,hl:#0dbc79,hl+:#23d18b'

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :50 {}'"

export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND --type d . --color=never --hidden"
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -50'"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

#aliases

alias ls='/bin/ls -a'
alias ..='cd ..'
alias ....='cd ../..'
alias ......='cd ../../..'
alias dev='cd /mnt/c/dev/'
alias c='cd /mnt/c/'
alias tutpa='cd /mnt/c/Users/tutpa'
alias dotfiles='cd ~/.dotfiles'

#dotnet

export PATH=$HOME/dotnet:$PATH
export PATH=$HOME/dotnet/tools:$PATH
export DOTNET_ROOT=$HOME/dotnet


