# Source shared configuration
source $HOME/dotfiles/zsh/.zshrc.shared

# Platform-specific config
if [[ "$(uname)" == "Darwin" ]]; then
    source $HOME/dotfiles/zsh/.zshrc.macos
else
    source $HOME/dotfiles/zsh/.zshrc.linux
fi
