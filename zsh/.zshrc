# Initialize Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Initialize zoxide (if its init script adds to PATH)
if [ -z "$DISABLE_ZOXIDE" ] && command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi

# Initialize fnm
eval "$(fnm env --use-on-cd --shell zsh --log-level=quiet)"

# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="amuse"

if [[ "$TERM_PROGRAM" == "ghostty" ]]; then
    export TERM=xterm-256color
fi

if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then
  source "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration
fi

plugins=(git)

source $ZSH/oh-my-zsh.sh

# Enable vi mode
bindkey -v


# FZF configuration

export FZF_DEFAULT_OPTS=" \
  --ansi --extended \
  --height 40% --layout=reverse --border \
  --info=inline \
  --bind=ctrl-u:half-page-up,ctrl-d:half-page-down \
  --color=bg+:#002B36,fg:#839496,hl:#B48EAD,fg+:#FF5E7D,pointer:#FF5E7D,header:#B48EAD,border:#B48EAD"

export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix -H --no-ignore'

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --theme=OneHalfDark --line-range :50 {}'"

bindkey '^F' fzf-cd-widget

source <(fzf --zsh)

# Aliases
alias ls="eza -la"
alias ..="cd .."
alias ....="cd ../.."
alias ......="cd ../../.."
alias ssh1='eval "$(ssh-agent -s)" && ssh-add ~/.ssh/git_1'
alias ssh2='eval "$(ssh-agent -s)" && ssh-add ~/.ssh/git_2'
alias sshpersonal='eval "$(ssh-agent -s)" && ssh-add ~/.ssh/git_0'
alias lg="lazygit"
alias lz="lazydocker"
alias cd="z"
alias db="dotnet build"
alias dt="dotnet test"
alias tm="tmux-windownizer"
alias fupdate="nix flake update --flake ~/dotfiles/nix-darwin/";
alias fswitch="sudo darwin-rebuild switch --flake ~/dotfiles/nix-darwin/.#macos";

# Open buffer line in editor
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^e' edit-command-line

# History configuration
HISTSIZE=100000
HISTFILE="$HOME/.zsh_history"
SAVEHIST=100000

# Exports
export QMK_HOME='~/qmk_firmware'
export EDITOR=nvim

# PATH additions (consolidated)
export PATH="$HOME/.local/bin:$HOME/.docker/bin:$HOME/dotfiles/scripts:/usr/local/share/dotnet:$HOME/.dotnet/tools:$BUN_INSTALL/bin:$HOME/.opencode/bin:/opt/homebrew/bin:$PATH"
# Private 
source $HOME/dotfiles/private/private.sh

# bun completions
[ -s "/Users/tuliopaim/.bun/_bun" ] && source "/Users/tuliopaim/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# SSH
# Check if ssh-agent is running, if not, start it.
if ! pgrep -q ssh-agent; then
  eval "$(ssh-agent -s)" > /dev/null
fi

# Add your SSH keys to the agent
# Use 'ssh-add -K' on macOS to store the key in the Keychain,
# even if it's passwordless, for better integration.
# Make sure these paths are correct for your system.
ssh-add -K ~/.ssh/git_0 &>/dev/null
ssh-add -K ~/.ssh/git_1 &>/dev/null
ssh-add -K ~/.ssh/git_2 &>/dev/null

# Yazi
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

# Git cherry-pick merge commit
function gcpm() {
  git cherry-pick "$1" -m 1
}
