# Tulio's dotfiles

A comprehensive macOS development environment configuration featuring modern CLI tools, customized terminal emulators, and productivity-focused keybindings.

## Overview

This repository contains my personal dotfiles for macOS, including configurations for:

- **Shell**: Zsh with Oh My Zsh, syntax highlighting, and autosuggestions
- **Terminal Emulators**: Ghostty and WezTerm
- **Editors**: Neovim (with custom config), IdeaVim (extensive JetBrains IDE keybindings), VS Code/Cursor
- **Window Management**: AeroSpace (tiling window manager for macOS)
- **Terminal Multiplexer**: Tmux with custom keybindings and plugins
- **Custom Scripts**: Productivity scripts for tmux sessions, git worktrees, and automation
- **Keyboard**: QMK firmware configuration for Lily58 split keyboard

## Quick Start

### Using nix-darwin (Recommended)

1. **Install Homebrew**
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Install Nix**

   Follow the instructions at https://lix.systems/install/#on-any-other-linuxmacos-system

3. **Initialize nix-darwin**
   ```bash
   nix run nix-darwin -- init --flake ~/dotfiles/nix-darwin
   ```

4. **Configure the SSH keys**

5. **Clone the repository**
   ```bash
   git clone ssh@github.com-personal:tuliopaim/dotfiles-linux.git ~/dotfiles
   cd ~/dotfiles
   ```

6. **Initialize submodules** (for nvim and private configs)
   ```bash
   git submodule update --init --recursive
   ```

7. **Apply nix-darwin configuration**
   ```bash
   nix run nix-darwin -- switch --flake ~/dotfiles/nix-darwin
   ```

    This will:
    - Install all system packages (development tools, CLI utilities, databases)
    - Configure Homebrew and install/manage casks
    - Apply macOS system settings (dock, finder, dark mode, TouchID for sudo)
    - Create symlinks for Neovim, AeroSpace, and Ghostty configs
    - Set up Zsh with completions, autosuggestions, and syntax highlighting
    - Configure Tmux with custom keybindings

8. **Rebuild after configuration changes**
   ```bash
   darwin-rebuild switch --flake ~/dotfiles/nix-darwin
   ```

9. **Install Oh My Zsh and TPM**
   - https://github.com/ohmyzsh/ohmyzsh
   - https://github.com/tmux-plugins/tpm


## Nix-Darwin Configuration

This setup uses **nix-darwin** with **home-manager** to declaratively manage your entire macOS environment. All packages, symlinks, and system settings are defined in the `nix-darwin/` directory.

### Architecture

- **flake.nix**: Flake configuration that imports both nix-darwin and home-manager
- **configuration.nix**: System-level configuration (packages, homebrew, macOS defaults, fonts)
- **home.nix**: User-level configuration (home-manager packages, programs, symlinks)

### System Configuration (configuration.nix)

- **System Packages**: vim, neovim, ansible (installed globally)
- **Homebrew Integration**: Taps, brews, and casks are managed declaratively
- **macOS Defaults**:
  - Dock autohide enabled
  - Finder shows all file extensions
  - Dark mode enabled
  - TouchID authentication for sudo
  - Guest login disabled
- **Fonts**: Fira Code Nerd Font, Droid Sans Mono, Liberation
- **Nix Settings**: Flakes enabled, garbage collection every Sunday at 2 AM (keeping 30 days of history)

### Home-Manager Configuration (home.nix)

- **CLI Tools**: fzf, ripgrep, fd, bat, eza, zoxide, lazygit, and more
- **Development Tools**: Go, Rust (cargo), Yarn, Node.js tooling
- **Language Servers**: gopls, nixd, netcoredbg
- **Cloud Tools**: Terraform, AWS CLI v2
- **Zsh Integration**: Enabled with completions, autosuggestions, and syntax highlighting
- **Symlinks**: Automatically links config directories (nvim, ghostty, aerospace) and dotfiles

### Updating the Configuration

To apply changes after editing `nix-darwin/` files:

```bash
# First apply with nix run (if nix-darwin isn't initialized)
nix run nix-darwin -- switch --flake ~/dotfiles/nix-darwin

# Or use darwin-rebuild for subsequent rebuilds
darwin-rebuild switch --flake ~/dotfiles/nix-darwin

# Dry-run to see what would change
darwin-rebuild build --flake ~/dotfiles/nix-darwin
```

## What's Included

### Shell Configuration
- **Zsh** with completions, autosuggestions, and syntax highlighting (managed by home-manager)
- Plugins: git, fzf integration, vi-mode
- Fast Node Manager (fnm) for Node.js version management
- Zoxide for smart directory jumping
- Custom aliases and PATH configurations

### Terminal Emulators
- **Ghostty**: Modern GPU-accelerated terminal
- **WezTerm**: Lua-configured terminal with advanced features

### Editor Configurations

#### Neovim
Complete custom Neovim configuration (separate submodule with its own README)

#### IdeaVim (JetBrains IDEs)
Comprehensive 258-line configuration featuring:
- Custom leader key mappings (Space as leader)
- Harpoon integration for quick file navigation
- NERDTree file explorer
- Which-key for discoverable keybindings
- EasyMotion for fast cursor movement
- Multiple-cursors support
- Git integration
- Extensive refactoring shortcuts

#### VS Code/Cursor
Settings and keybindings for VS Code and Cursor editor

### Window Management
**AeroSpace**: i3-inspired tiling window manager for macOS with:
- Vim-style navigation (hjkl)
- Multiple workspace support
- Custom workspace assignments (N for Notes, S for Slack, T for Teams)
- Smart window resizing
- Fullscreen and native macOS integration

### Custom Scripts

Located in `scripts/`:

| Script | Description |
|--------|-------------|
| `tmux-sessionizer` | FZF-based tmux session manager for quick project switching |
| `tmux-windownizer` | Intelligent tmux window management |
| `tmux-dotfiles` | Quick access to dotfiles in tmux session |
| `tmux-vault` | Obsidian's vault access helper for tmux |
| `clone-wt` | Git worktree creation helper |
| `usersecrets` | .NET user secrets management |

## Tools & Applications

All tools and applications are installed and managed via nix-darwin's integrated Homebrew configuration. Edit `nix-darwin/configuration.nix` (for brews) or `nix-darwin/home.nix` (for packages and languages) to customize.

### Languages & Development

| Tool | Source | Description |
|------|--------|-------------|
| **Go** | home.nix | Go programming language |
| **Rust (cargo)** | home.nix | Rust and Cargo package manager |
| **Yarn** | home.nix | JavaScript package manager |
| **TypeScript** | home.nix | TypeScript compiler |
| **gopls** | home.nix | Go language server |
| **nixd** | home.nix | Nix language server |

### CLI Productivity Tools

| Tool | Source | Description |
|------|--------|-------------|
| **fzf** | home.nix | Fuzzy finder for command line |
| **ripgrep** | home.nix | Fast recursive grep alternative |
| **fd** | home.nix | Fast find alternative |
| **bat** | home.nix | Cat with syntax highlighting |
| **eza** | home.nix | Modern ls replacement |
| **yazi** | home.nix | Terminal file manager |
| **zoxide** | home.nix | Smart directory jumper |
| **glow** | home.nix | Markdown renderer |
| **fastfetch** | home.nix | System information tool |
| **jq** | home.nix | JSON processor |
| **tree** | home.nix | Directory structure viewer |
| **gdu** | home.nix | Disk usage analyzer |

### Database Tools

| Tool | Source | Description |
|------|--------|-------------|
| **mongosh** | Homebrew | MongoDB shell |
| **mongodb-compass** | Homebrew (cask) | MongoDB GUI |
| **libpq** | Homebrew | PostgreSQL client library |
| **redis** | Homebrew | Redis server |
| **postgresql** | home.nix | PostgreSQL server |
| **dbeaver-community** | Homebrew (cask) | Universal database tool |
| **pgadmin4** | Homebrew (cask) | PostgreSQL admin tool |

### Development Applications

| Application | Type | Description |
|-------------|------|-------------|
| **Rider** | Cask | JetBrains .NET IDE |
| **Visual Studio Code** | Cask | Microsoft code editor |
| **Cursor** | Cask | AI-powered code editor |
| **Postman** | Cask | API development platform |

### Browsers

- Google Chrome
- Firefox
- Microsoft Edge
- Brave Browser

### Communication

- Slack
- Discord
- Microsoft Teams

### Productivity & Utilities

| Application | Description |
|-------------|-------------|
| **Obsidian** | Knowledge management |
| **Raycast** | macOS launcher and productivity tool |
| **Bitwarden** | Password manager |
| **LocalSend** | Local file sharing |
| **Shottr** | Screenshot tool |
| **DrawIO** | Diagramming tool |
| **PDF Expert** | PDF reader and editor |

### System Utilities

| Application | Description |
|-------------|-------------|
| **AeroSpace** | Tiling window manager |
| **Karabiner Elements** | Keyboard customization |
| **iStat Menus** | System monitor |
| **Scroll Reverser** | Mouse scroll direction control |
| **VIA** | Keyboard configuration |
| **QMK Toolbox** | Keyboard firmware flashing |

### Media

- Spotify
- OBS Studio
- SoundSource

### Fonts

- Fira Code Nerd Font
- JetBrains Mono Nerd Font

## Keybinding Reference

### Tmux

**Prefix**: `Ctrl+s` (instead of default `Ctrl+b`)

#### Window & Pane Management

| Keybinding | Action |
|------------|--------|
| `prefix v` | Split window vertically |
| `prefix b` | Split window horizontally |
| `Ctrl+h/j/k/l` | Navigate panes (vim-aware) |
| `prefix h/j/k/l` | Navigate panes (repeatable) |
| `Alt+Ctrl+h/j/k/l` | Resize panes |

#### Copy Mode

| Keybinding | Action |
|------------|--------|
| `v` | Begin selection (in copy mode) |
| `Ctrl+v` | Rectangle toggle (in copy mode) |
| `y` | Yank selection (in copy mode) |

#### Custom Scripts

| Keybinding | Action |
|------------|--------|
| `prefix Shift+F` | Open tmux-sessionizer (project switcher) |
| `prefix f` | Open tmux-windownizer |
| `prefix Shift+H` | Open dotfiles |
| `prefix Shift+J` | Open vault |

#### Plugins

- tmux-sensible: Sensible defaults
- tmux-yank: System clipboard integration
- tmux-resurrect: Session persistence
- vim-tmux-navigator: Seamless vim/tmux navigation
- catppuccin-tmux: Mocha theme

### IdeaVim (JetBrains IDEs)

**Leader Key**: `Space`

#### File Navigation

| Keybinding | Action |
|------------|--------|
| `<leader>ff` | Go to file |
| `<leader>fa` | Search everywhere |
| `<leader>fg` | Find in path (grep) |
| `<leader>fn` | New scratch file |
| `<leader><leader>` | Recent files |
| `<leader>.` | Focus file explorer |
| `<leader>es` | Toggle NERDTree |

#### Harpoon (Quick File Navigation)

| Keybinding | Action |
|------------|--------|
| `<leader>1/2/3/4` | Jump to harpoon file 1/2/3/4 |
| `<leader>hh` | Harpoon quick menu |
| `<leader>hi` | Add file to harpoon |

#### Window Management

| Keybinding | Action |
|------------|--------|
| `<leader>v` | Split vertically |
| `<leader>b` | Split horizontally |
| `<leader>w=` | Unsplit window |
| `<leader>wl` | Move editor to opposite group |
| `Ctrl+h/j/k/l` | Navigate between splits |
| `<leader>rh/rl/rk/rj` | Resize splits |

#### Tab Management

| Keybinding | Action |
|------------|--------|
| `<leader>x` | Close tab |
| `<leader>ax` | Close all tabs |
| `<leader>tp` | Pin/unpin tab |
| `gk` | Next tab |
| `gj` | Previous tab |

#### LSP & Navigation

| Keybinding | Action |
|------------|--------|
| `gd` | Go to declaration |
| `gi` | Go to implementation |
| `gr` | Find usages |
| `gt` | Go to test |
| `[[` / `]]` | Jump between methods |
| `<leader>ds` | File structure popup |
| `<leader>k` | Show error description |
| `<leader>ca` | Show code actions |
| `]e` / `ge` | Next error |
| `gE` | Previous error |

#### Refactoring

| Keybinding | Action |
|------------|--------|
| `<leader>rn` | Rename element |
| `<leader>rm` | Extract method |
| `<leader>rv` | Introduce variable |
| `<leader>rf` | Introduce field |
| `<leader>rs` | Change signature |
| `<leader>rr` | Refactorings menu |
| `<leader>gf` | Auto indent lines |

#### Git

| Keybinding | Action |
|------------|--------|
| `<leader>gm` | Git menu |
| `<leader>gs` | Git status window |
| `<leader>gc` | Git commit window |
| `<leader>gb` | Git branches |
| `<leader>gpl` | Git pull |
| `<leader>gps` | Git push |

#### Testing & Building

| Keybinding | Action |
|------------|--------|
| `<leader>tt` | Open tests window |
| `<leader>rt` | Run test at cursor |
| `<leader>rd` | Debug test at cursor |
| `<leader>rs` | Rebuild solution |
| `<leader>rc` | Clean solution |
| `<leader>rp` | Recent projects |

#### Display & UI

| Keybinding | Action |
|------------|--------|
| `<leader>dd` | Toggle distraction-free mode |
| `<leader>dz` | Toggle zen mode |
| `<leader>df` | Toggle fullscreen |
| `<leader>ha` | Hide all windows |
| `<leader>tr` | Open terminal |

#### Editing

| Keybinding | Action |
|------------|--------|
| `<leader>j` | Jump with EasyMotion |
| `<leader>gc` | Comment line |
| `<leader>no` | Clear search highlight |
| `<leader>lc` | Clean line (delete to end) |
| `<leader>p` | Paste last yanked |
| `<leader>y` | Yank to system clipboard |
| `Ctrl+d` | Half page down (centered) |
| `Ctrl+u` | Half page up (centered) |

#### Code Folding

| Keybinding | Action |
|------------|--------|
| `zc` | Collapse region |
| `zo` | Expand region |
| `<leader>zc` | Collapse all regions |
| `<leader>zo` | Expand all regions |

### AeroSpace (Window Manager)

**Modifier**: `Alt` (Option key)

#### Focus Windows

| Keybinding | Action |
|------------|--------|
| `Alt+h/j/k/l` | Focus left/down/up/right window |
| `Alt+Tab` | Switch to last workspace |

#### Move Windows

| Keybinding | Action |
|------------|--------|
| `Alt+Shift+h/j/k/l` | Move window left/down/up/right |

#### Workspaces

| Keybinding | Action |
|------------|--------|
| `Alt+1` through `Alt+9` | Switch to workspace 1-9 |
| `Alt+n` | Switch to Notes workspace |
| `Alt+s` | Switch to Slack workspace |
| `Alt+Shift+1` through `9` | Move window to workspace (and follow) |
| `Alt+Shift+n/s/t` | Move window to named workspace (and follow) |
| `Alt+Shift+Tab` | Move workspace to next monitor |

#### Layout

| Keybinding | Action |
|------------|--------|
| `Alt+/` | Toggle between tiles layout (h/v) |
| `Alt+.` | Toggle between accordion layout (h/v) |
| `Alt+f` | Toggle fullscreen |
| `Alt+Shift+f` | Toggle native macOS fullscreen |
| `Alt+m` | Minimize window |

#### Resize

| Keybinding | Action |
|------------|--------|
| `Alt+Shift+-` | Decrease window size |
| `Alt+Shift+=` | Increase window size |

#### Service Mode

| Keybinding | Action |
|------------|--------|
| `Alt+Shift+;` | Enter service mode |
| `Esc` (in service mode) | Reload config and exit |
| `r` (in service mode) | Reset layout |
| `f` (in service mode) | Toggle floating/tiling |
| `Backspace` (in service mode) | Close all windows but current |
| `Alt+Shift+h/j/k/l` (in service mode) | Join with adjacent window |

#### Shortcuts

| Keybinding | Action |
|------------|--------|
| `Alt+Enter` | Open Ghostty terminal |

## Configuration Details

### Directory Structure

```
dotfiles/
├── aerospace/          # AeroSpace window manager config
├── brew/              # Homebrew bundle file
├── cs2/               # Counter-Strike 2 configs
├── ghostty/           # Ghostty terminal config
├── ideavim/           # JetBrains IdeaVim config
├── nix/               # NixOS configuration (legacy)
├── nix-darwin/        # Nix-darwin configuration 
├── nvim/              # Neovim config (git submodule)
├── private/           # Private configs (git submodule)
├── qmk/              # QMK keyboard firmware
├── scripts/           # Custom productivity scripts
├── sway/             # Sway window manager (Linux, legacy)
├── tmux/             # Tmux configuration
├── vscode/           # VS Code/Cursor settings
├── wallpapers/        # Custom wallpapers
├── wezterm/          # WezTerm terminal config
├── zsh/              # Zsh configuration
├── ansible/          # Ansible playbooks (legacy setup)
└── symlinks.sh       # Symlink creation script
```

### Symlinks Script

The `symlinks.sh` script automatically creates symlinks for all configurations to their appropriate locations:
- Checks for existing files/symlinks
- Creates necessary parent directories
- Links configs to standard locations (~/.config, ~/, etc.)
- Safe operation with conflict detection

## Notes

### Git Submodules

This repository uses git submodules for:
- `nvim/`: Neovim configuration (separate repository)
- `private/`: Private configurations (git config, etc.)

Remember to initialize submodules after cloning:
```bash
git submodule update --init --recursive
```

### Updating Nix-Darwin Configuration

When you make changes to `nix-darwin/configuration.nix` or `nix-darwin/home.nix`:

```bash
darwin-rebuild switch --flake ~/dotfiles/nix-darwin
```

This automatically handles:
- Installing/updating Homebrew packages
- Rebuilding system configuration
- Applying all symlinks and user-level settings

### Legacy Configurations

The repository contains some legacy configuration directories preserved for reference:
- **brew/Brewfile**: Manual Homebrew configuration (superseded by nix-darwin)
- **nix/**: NixOS configuration for Linux systems
- **sway/**: Sway window manager configuration for Linux
- **ansible/**: Ansible playbooks for automated installation

The primary setup now uses **nix-darwin** with home-manager for declarative macOS configuration. See the [Nix-Darwin Configuration](#nix-darwin-configuration) section above.

## License

Personal configuration files - feel free to use and modify as needed.
