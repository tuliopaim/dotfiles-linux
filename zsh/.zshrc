source $HOME/dotfiles/zsh/.zshrc.shared

if [[ "$(uname)" == "Darwin" ]]; then
    source $HOME/dotfiles/zsh/.zshrc.macos
fi
