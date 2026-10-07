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
create_symlink ~/dotfiles/ideavim/.ideavimrc ~/.ideavimrc
create_symlink ~/dotfiles/private/.config/git ~/.config/git
create_symlink ~/dotfiles/opencode/opencode.json ~/.config/opencode/opencode.json
create_symlink ~/dotfiles/opencode/cli.json ~/.config/opencode/cli.json
create_symlink ~/dotfiles/opencode/tui.json ~/.config/opencode/tui.json
create_symlink ~/dotfiles/opencode/commands/commit.md ~/.config/opencode/commands/commit.md
create_symlink ~/dotfiles/opencode/commands/setup-wt.md ~/.config/opencode/commands/setup-wt.md
create_symlink ~/dotfiles/opencode/commands/review-comments.md ~/.config/opencode/commands/review-comments.md
create_symlink ~/dotfiles/opencode/commands/review.md ~/.config/opencode/commands/review.md
create_symlink ~/dotfiles/kanata/kanata.kbd ~/.config/kanata/kanata.kbd
create_symlink ~/dotfiles/herdr/config.toml ~/.config/herdr/config.toml
create_symlink ~/dotfiles/pi/agent/settings.json ~/.pi/agent/settings.json
create_symlink ~/dotfiles/agents/AGENTS.md ~/.codex/AGENTS.md
link_skills() {
    local root="$HOME/dotfiles/skills"
    local source skill_dir name previous target link
    local roots=("$root/upstream/.agents/skills" "$root/local")
    local sources=() names=()
    local targets=("$HOME/.claude/skills" "$HOME/.claude-personal/skills"
                   "$HOME/.claude-work/skills" "$HOME/.agents/skills")
    [ "${DOTFILES_WORK_SKILLS:-false}" != true ] || roots+=("$root/work")

    # Check names before changing any skill links. Compatible with macOS Bash 3.
    for source in "${roots[@]}"; do
        for skill_dir in "$source"/*; do
            [ -f "$skill_dir/SKILL.md" ] || continue
            name="$(basename "$skill_dir")"
            for previous in "${names[@]}"; do
                if [ "$name" = "$previous" ]; then
                    echo "Error: duplicate skill folder name: $name" >&2
                    return 1
                fi
            done
            names+=("$name")
            sources+=("$skill_dir")
        done
    done

    for target in "${targets[@]}"; do
        if [ -L "$target" ]; then
            # Replace only the whole-directory links this script used to create.
            if [ "$(readlink "$target")" = "$root" ]; then
                rm "$target"
            else
                echo "Preserving externally managed skills directory: $target"
                continue
            fi
        fi
        for link in "$target"/*; do
            [ -L "$link" ] || continue
            source="$(readlink "$link")"
            case "$source" in
                "$root"/*|"$HOME/dotfiles/skills-work"/*)
                    if [ ! -f "$source/SKILL.md" ]; then
                        rm "$link"
                        continue
                    fi
                    ;;
            esac
            case "$source" in
                "$root/work"/*|"$HOME/dotfiles/skills-work"/*)
                    if [ "${DOTFILES_WORK_SKILLS:-false}" != true ] ||
                       { [ "$target" != "$HOME/.claude-work/skills" ] &&
                         [ "$target" != "$HOME/.agents/skills" ]; }; then
                        rm "$link"
                    fi
                    ;;
            esac
        done
        for skill_dir in "${sources[@]}"; do
            case "$skill_dir" in
                "$root/work"/*)
                    [ "$target" = "$HOME/.claude-work/skills" ] ||
                    [ "$target" = "$HOME/.agents/skills" ] || continue
                    ;;
            esac
            link="$target/$(basename "$skill_dir")"
            if [ -L "$link" ]; then
                case "$(readlink "$link")" in
                    "$root"/*|"$HOME/dotfiles/skills-work"/*) ;;
                    *)
                        echo "Preserving externally managed skill: $link"
                        continue
                        ;;
                esac
            elif [ -e "$link" ]; then
                echo "Preserving independently installed skill: $link"
                continue
            fi
            create_symlink "$skill_dir" "$link"
        done
    done
}

link_skills || exit 1

create_symlink ~/dotfiles/claude/statusline.sh ~/.claude/statusline.sh

if [ "$(uname)" = "Darwin" ]; then
    create_symlink ~/dotfiles/yabai/.yabairc ~/.config/yabai/yabairc
    create_symlink ~/dotfiles/skhd/.skhdrc ~/.config/skhd/skhdrc
    create_symlink ~/dotfiles/vscode/Code/User/settings.json ~/Library/Application\ Support/Cursor/User/settings.json
    create_symlink ~/dotfiles/vscode/Code/User/keybindings.json ~/Library/Application\ Support/Cursor/User/keybindings.json
    create_symlink ~/dotfiles/vscode/Code/User/settings.json ~/Library/Application\ Support/Code/User/settings.json
    create_symlink ~/dotfiles/vscode/Code/User/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json
fi

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
