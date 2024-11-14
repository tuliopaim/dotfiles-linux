{ outputs, config, pkgs, pkgs-unstable, username, ... }:

{
  home.username = username;
  home.homeDirectory = "/Users/" + username;
  home.stateVersion = "24.05";

  imports = [
    ./apps.nix
    ./dev.nix
    ../nix/home-manager/dev/dotnet.nix
    ../nix/home-manager/terminal/alacritty.nix
    ../nix/home-manager/terminal/tmux.nix
    ../nix/home-manager/terminal/scripts.nix
    ../nix/home-manager/terminal/zsh.nix
  ];

  home.file = {
    ".config/aerospace/aerospace.toml".source = ./aerospace/aerospace.toml;
  };

  programs = {
    home-manager = {
      enable = true;
    };
  };
}
