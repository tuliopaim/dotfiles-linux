# Initialize Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Initialize zoxide (if its init script adds to PATH)
if [ -z "$DISABLE_ZOXIDE" ]; then
    eval "$(zoxide init zsh)"
fi

# Initialize fnm
eval "$(fnm env --use-on-cd --shell zsh)"

# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="amuse"

if [[ "$TERM_PROGRAM" == "ghostty" ]]; then
    export TERM=xterm-256color
fi

if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then
  source "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration
fi

plugins=(git fzf-zsh-plugin)

source $ZSH/oh-my-zsh.sh

source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

# Enable vi mode
bindkey -v

# Append a command directly (after zsh-vi-mode is loaded and bindkey -v is set)
zvm_after_init_commands+=('bindkey "^F" fzf-cd-widget')
zvm_after_init_commands+=('bindkey "^R" fzf-history-widget')

# FZF configuration
export FZF_DEFAULT_OPTS=" \
  --ansi --extended \
  --height 40% --layout=reverse --border \
  --info=inline \
  --bind=ctrl-u:half-page-up,ctrl-d:half-page-down \
  --color=bg+:#002B36,fg:#839496,hl:#B48EAD,fg+:#FF5E7D,pointer:#FF5E7D,header:#B48EAD,border:#B48EAD"

export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix -H --no-ignore'

export FZF_ALT_C_COMMAND="fd --type d . -H --strip-cwd-prefix"
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --theme=OneHalfDark --line-range :50 {}'"

# Aliases
alias ls="eza -la"
alias ..="cd .."
alias ....="cd ../.."
alias ......="cd ../../.."
alias ssh1='eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_1_gh'
alias ssh2='eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_2'
alias sshpersonal='eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_personal_gh'
alias lg="lazygit"
alias lz="lazydocker"
alias cd="z"
alias db="dotnet build"
alias dt="dotnet test"
alias tm="tmux-windownizer"
alias claude="$HOME/.claude/local/claude"

# History configuration
HISTSIZE=100000
HISTFILE="$HOME/.zsh_history"
SAVEHIST=100000

# Exports
export QMK_HOME='~/qmk_firmware'
export EDITOR=nvim

# PATH additions
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/.docker/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="/usr/local/share/dotnet:/Users/tuliopaim/.dotnet/tools:$PATH"
export PATH="$HOME/dotfiles/scripts:$PATH"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH=/Users/tuliopaim/.opencode/bin:$PATH

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

# Private 
source $HOME/dotfiles/private/private.sh

# bun completions
[ -s "/Users/tuliopaim/.bun/_bun" ] && source "/Users/tuliopaim/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
