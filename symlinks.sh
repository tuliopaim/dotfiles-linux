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
create_symlink ~/.dotfiles/nvim ~/.config/nvim
create_symlink ~/.dotfiles/ghostty ~/.config/ghostty
create_symlink ~/.dotfiles/aerospace ~/.config/aerospace
create_symlink ~/.dotfiles/ideavim/.ideavimrc ~/.ideavimrc

echo "Symlink creation completed!"
