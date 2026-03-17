{ username, pkgs, config, ... }:
let
  dotfilesDir = "${config.home.homeDirectory}/dotfiles";
in
{
  imports = [
    ../home
  ];

  home.username = username;
  home.homeDirectory = "/Users/" + username;
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    # darwin-only packages
    pngpaste
    clipboard-jh
    sesh
    imagemagick
    mercurial
    nmap
    bun
    yarn
    terraform
    postgresql
    postgresql_jdbc
    typescript
    nodePackages."@angular/cli"
    awscli2
  ];

  # darwin-only symlinks
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
