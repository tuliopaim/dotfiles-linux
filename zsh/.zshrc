# Source shared configuration
if [[ -r "$HOME/dotfiles/zsh/.zshrc.shared" ]]; then
    source "$HOME/dotfiles/zsh/.zshrc.shared"
fi

# Platform-specific config
if [[ "$(uname)" == "Darwin" ]]; then
    [[ -r "$HOME/dotfiles/zsh/.zshrc.macos" ]] && source "$HOME/dotfiles/zsh/.zshrc.macos"
else
    [[ -r "$HOME/dotfiles/zsh/.zshrc.linux" ]] && source "$HOME/dotfiles/zsh/.zshrc.linux"
fi
