{ outputs, config, pkgs, pkgs-unstable, username, ... }:

{
  home.username = username;
  home.homeDirectory = "/home/" + username;
  home.stateVersion = "24.05";

  imports = [
    ../../home-manager/hyprland
    ../../home-manager/apps
    ../../home-manager/apps/brightness.nix
    ../../home-manager/terminal
    ../../home-manager/dev
    ../../home-manager/dev/dotnet.nix
    ../../home-manager/dev/neovim.nix
    ../../home-manager/dev/vscode
  ];

  programs = {
    home-manager = {
      enable = true;
    };
  };
}
