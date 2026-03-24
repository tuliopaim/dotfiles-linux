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
  ];

  # Mac-only symlinks
  xdg.configFile = {
    "ghostty".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/ghostty";
    "aerospace".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/aerospace";
  };

  home.file = {
    "Library/Application Support/Cursor/User/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/vscode/Code/User/settings.json";
    "Library/Application Support/Cursor/User/keybindings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/vscode/Code/User/keybindings.json";
  };
}
