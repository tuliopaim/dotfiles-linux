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
mkdir -p ~/.pi/agent

# Create symlinks
create_symlink ~/dotfiles/zsh/.zshrc ~/.zshrc
create_symlink ~/dotfiles/tmux/.tmux.conf ~/.tmux.conf
create_symlink ~/dotfiles/nvim ~/.config/nvim
create_symlink ~/dotfiles/ghostty ~/.config/ghostty
create_symlink ~/dotfiles/aerospace ~/.config/aerospace
create_symlink ~/dotfiles/ideavim/.ideavimrc ~/.ideavimrc
create_symlink ~/dotfiles/private/.config/git ~/.config/git
create_symlink ~/dotfiles/opencode/opencode.json ~/.config/opencode/opencode.json
create_symlink ~/dotfiles/opencode/tui.json ~/.config/opencode/tui.json
create_symlink ~/dotfiles/opencode/skills ~/.config/opencode/skills
create_symlink ~/dotfiles/pi/agent/extensions ~/.pi/agent/extensions
create_symlink ~/dotfiles/vscode/Code/User/settings.json ~/Library/Application\ Support/Cursor/User/settings.json
create_symlink ~/dotfiles/vscode/Code/User/keybindings.json ~/Library/Application\ Support/Cursor/User/keybindings.json
create_symlink ~/dotfiles/vscode/Code/User/settings.json ~/Library/Application\ Support/Code/User/settings.json
create_symlink ~/dotfiles/vscode/Code/User/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json

# Hyprland configs (protect from Omarchy updates overwriting customizations)
mkdir -p ~/.config/hypr
create_symlink ~/dotfiles/omarchy/hypr/hyprland.conf ~/.config/hypr/hyprland.conf
create_symlink ~/dotfiles/omarchy/hypr/bindings.conf ~/.config/hypr/bindings.conf
create_symlink ~/dotfiles/omarchy/hypr/input.conf ~/.config/hypr/input.conf
create_symlink ~/dotfiles/omarchy/hypr/looknfeel.conf ~/.config/hypr/looknfeel.conf
create_symlink ~/dotfiles/omarchy/hypr/autostart.conf ~/.config/hypr/autostart.conf
create_symlink ~/dotfiles/omarchy/hypr/envs.conf ~/.config/hypr/envs.conf
# monitors.conf is already symlinked

# Waybar configs (protect from Omarchy updates overwriting customizations)
create_symlink ~/dotfiles/omarchy/waybar/config.jsonc ~/.config/waybar/config.jsonc
create_symlink ~/dotfiles/omarchy/waybar/style.css ~/.config/waybar/style.css

echo "Symlink creation completed!"
