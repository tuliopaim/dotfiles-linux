# Initialize Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="amuse"

if [[ "$TERM_PROGRAM" == "ghostty" ]]; then
    export TERM=xterm-256color
fi

# Oh My Zsh plugins
plugins=(git fzf-zsh-plugin)

source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

source $ZSH/oh-my-zsh.sh

# Append a command directly
zvm_after_init_commands+=('[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh && bindkey "^F" fzf-cd-widget')

# Enable vi mode
bindkey -v

# FZF configuration
export FZF_DEFAULT_OPTS="--color=16 --color=fg+:#FF5E7D --color=bg+:#002B36 --color=hl:#B48EAD --color=fg:#839496"
export FZF_DE AULT_COMMAND='fd --type f --strip-cwd-prefix -H'

export FZF_ALT_C_COMMAND="fd --type d . -H --strip-cwd-prefix"
export FZF_ALT_C_OPTS="--preview 'tree -C {}'"

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :50 {}'"

# Aliases
alias ls="eza -la"
alias ..="cd .."
alias ....="cd ../.."
alias ......="cd ../../.."
alias ssh1='eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_1_gh'
alias ssh2='eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_2_gh'
alias sshpersonal='eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_personal_gh'
alias lg="lazygit"
alias lz="lazydocker"
alias cd="z"
alias db="dotnet build"
alias dt="dotnet test"
alias tm="tmux-windownizer"

# History configuration
HISTSIZE=10000
HISTFILE="$HOME/.zsh_history"
SAVEHIST=10000

# PATH additions
export PATH="$PATH:/opt/homebrew/bin:$PATH"
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:/usr/local/share/dotnet:/Users/tuliopaim/.dotnet/tools"
export PATH="$PATH:$HOME/dotfiles/scripts"

# Yazi function
function yy() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# Kill process function
function killp(){
    ps aux | fzf --height 40% --layout=reverse --prompt="Select a process to kill: " | awk '{print $2}' | xargs -r sudo kill
}

# Initialize zoxide
eval "$(zoxide init zsh)"

# Initialize fnm
eval "$(fnm env --use-on-cd --shell zsh)"

# Private 
source $HOME/dotfiles/private/private.sh

# Exports
export QMK_HOME='~/qmk_firmware'
export EDITOR=nvim

