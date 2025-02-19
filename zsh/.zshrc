export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh

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
export FZF_DEFAULT_OPTS="--color=16 --color=fg+:#FF5E7D --color=bg+:#002B36 --color=hl:#B48EAD --color=fg:#839496"

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :50 {}'"

export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND --type d . --color=never --hidden"
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -50'"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

#aliases

alias ..='cd ..'
alias ....='cd ../..'
alias ......='cd ../../..'
alias dev='cd /mnt/c/dev/'
alias c='cd /mnt/c/'
alias tutpa='cd /mnt/c/Users/tutpa'
alias dotfiles='cd ~/.dotfiles'
alias sshconfig='eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_tuliopaim_github'

export GIT_CONFIG=~/.gitconfig

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(zsh-autosuggestions)

