{ config, pkgs, ... }:
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

  xdg.configFile."ghostty".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/ghostty";
  xdg.configFile."aerospace".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/aerospace";
}
