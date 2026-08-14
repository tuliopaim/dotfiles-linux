#!/usr/bin/env bash

create_symlink() {
    local source="$1"
    local target="$2"
    local backup

    mkdir -p "$(dirname "$target")"

    if [ ! -e "$source" ]; then
        echo "Warning: source $source does not exist, skipping $target"
        return 0
    fi

    if [ -L "$target" ]; then
        if [ "$(readlink "$target")" = "$source" ]; then
            echo "Symlink already correct: $target -> $source"
            return 0
        fi

        echo "Replacing stale symlink: $target -> $(readlink "$target")"
        rm "$target"
    elif [ -e "$target" ]; then
        backup="$target.backup.$(date +%Y%m%d%H%M%S)"
        echo "Backing up existing file/directory: $target -> $backup"
        mv "$target" "$backup"
    fi

    echo "Creating symlink: $target -> $source"
    ln -s "$source" "$target"
}

# Create config directory if it doesn't exist
mkdir -p ~/.config
mkdir -p ~/.config/opencode
mkdir -p ~/.pi/agent

# Create symlinks
create_symlink ~/dotfiles/zsh/.zshrc ~/.zshrc
create_symlink ~/dotfiles/tmux/.tmux.conf ~/.tmux.conf
create_symlink ~/dotfiles/nvim ~/.config/nvim
create_symlink ~/dotfiles/ghostty ~/.config/ghostty
mkdir -p ~/.config/yabai ~/.config/skhd
create_symlink ~/dotfiles/yabai/.yabairc ~/.config/yabai/yabairc
create_symlink ~/dotfiles/skhd/.skhdrc ~/.config/skhd/skhdrc
create_symlink ~/dotfiles/ideavim/.ideavimrc ~/.ideavimrc
create_symlink ~/dotfiles/private/.config/git ~/.config/git
create_symlink ~/dotfiles/opencode/opencode.json ~/.config/opencode/opencode.json
create_symlink ~/dotfiles/opencode/tui.json ~/.config/opencode/tui.json
create_symlink ~/dotfiles/opencode/oh-my-opencode-slim.json ~/.config/opencode/oh-my-opencode-slim.json
create_symlink ~/dotfiles/opencode/commands ~/.config/opencode/commands
create_symlink ~/dotfiles/pi/agent/settings.json ~/.pi/agent/settings.json
create_symlink ~/dotfiles/vscode/Code/User/settings.json ~/Library/Application\ Support/Cursor/User/settings.json
create_symlink ~/dotfiles/vscode/Code/User/keybindings.json ~/Library/Application\ Support/Cursor/User/keybindings.json
create_symlink ~/dotfiles/vscode/Code/User/settings.json ~/Library/Application\ Support/Code/User/settings.json
create_symlink ~/dotfiles/vscode/Code/User/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json

# Hyprland configs (protect from Omarchy updates overwriting customizations)
mkdir -p ~/.config/hypr
create_symlink ~/dotfiles/omarchy/hypr/hyprland.lua ~/.config/hypr/hyprland.lua
create_symlink ~/dotfiles/omarchy/hypr/bindings.lua ~/.config/hypr/bindings.lua
create_symlink ~/dotfiles/omarchy/hypr/input.lua ~/.config/hypr/input.lua
create_symlink ~/dotfiles/omarchy/hypr/looknfeel.lua ~/.config/hypr/looknfeel.lua
create_symlink ~/dotfiles/omarchy/hypr/autostart.lua ~/.config/hypr/autostart.lua
create_symlink ~/dotfiles/omarchy/hypr/monitors.lua ~/.config/hypr/monitors.lua

# Waybar configs (protect from Omarchy updates overwriting customizations)
create_symlink ~/dotfiles/omarchy/waybar/config.jsonc ~/.config/waybar/config.jsonc
create_symlink ~/dotfiles/omarchy/waybar/style.css ~/.config/waybar/style.css

echo "Symlink creation completed!"
