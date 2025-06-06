#!/usr/bin/env bash

create_symlink() {
    local source="$1"
    local target="$2"
    
    if [ -e "$target" ] || [ -L "$target" ]; then
        echo "Warning: $target already exists, skipping..."
    else
        echo "Creating symlink: $target -> $source"
        ln -s "$source" "$target"
    fi
}

# Create config directory if it doesn't exist
mkdir -p ~/.config

# Create symlinks
create_symlink ~/dotfiles/zsh/.zshrc ~/.zshrc
create_symlink ~/dotfiles/tmux/.tmux.conf ~/.tmux.conf
create_symlink ~/dotfiles/nvim ~/.config/nvim
create_symlink ~/dotfiles/ghostty ~/.config/ghostty
create_symlink ~/dotfiles/aerospace ~/.config/aerospace
create_symlink ~/dotfiles/ideavim/.ideavimrc ~/.ideavimrc
create_symlink ~/dotfiles/private/.config/git ~/.config/git
create_symlink ~/dotfiles/vscode/Code/User/settings.json ~/Library/Application\ Support/Cursor/User/settings.json
create_symlink ~/dotfiles/vscode/Code/User/keybindings.json ~/Library/Application\ Support/Cursor/User/keybindings.json
create_symlink ~/dotfiles/vscode/Code/User/settings.json ~/Library/Application\ Support/Code/User/settings.json
create_symlink ~/dotfiles/vscode/Code/User/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json

echo "Symlink creation completed!"
