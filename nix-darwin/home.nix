{ username, ... }:

{
  home.username = username;
  home.homeDirectory = "/Users/" + username;
  home.stateVersion = "24.05";

  imports = [
    ./apps.nix
    ./dev.nix
    ../nix/home-manager/terminal/tmux.nix
    ../nix/home-manager/terminal/scripts.nix
    ../nix/home-manager/terminal/zsh.nix
  ];

  home.file = {
    ".config/aerospace/aerospace.toml".source = ./aerospace/aerospace.toml;
    ".config/alacritty.toml".source = ../alacritty/alacritty.toml;
    ".ideavimrc".source = ../ideavim/.ideavimrc;
  };

  programs = {
    home-manager = {
      enable = true;
    };
  };
}
