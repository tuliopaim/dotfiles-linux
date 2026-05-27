{ pkgs, config, ... }:
let
  dotfilesDir = "${config.home.homeDirectory}/dotfiles";
in
{
  imports = [
    ../home
  ];

  home.username = "tuliopaim";
  home.homeDirectory = "/Users/tuliopaim";
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    # langs
    yarn

    # dev tools
    terraform
    postgresql
    postgresql_jdbc
    bun
    devenv

    # speech-to-text
    whisper-cpp

    # cli tools
    pngpaste
    clipboard-jh
    sesh
    imagemagick
    mercurial
    nmap
    typescript
    nodePackages."@angular/cli"
    awscli2
    bitwarden-cli
  ];

  # Mac-only symlinks
  xdg.configFile = {
    "ghostty".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/ghostty";
  };

  home.file = {
    ".config/yabai/yabairc".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/yabai/.yabairc";
    ".config/yabai/labels.sh".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/yabai/labels.sh";
    ".config/yabai/distribute.sh".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/yabai/distribute.sh";
    ".config/skhd/skhdrc".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/skhd/.skhdrc";
    "Library/Application Support/Cursor/User/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/vscode/Code/User/settings.json";
    "Library/Application Support/Cursor/User/keybindings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/vscode/Code/User/keybindings.json";
  };
}
