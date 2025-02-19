{ username, ... }:

{
  home.username = username;
  home.homeDirectory = "/Users/" + username;
  home.stateVersion = "24.05";

  imports = [
    ./apps.nix
    ./dev.nix
    ../nix/home-manager/terminal/tmux.nix
    ../nix/home-manager/terminal/zsh.nix
  ];

  programs = {
    home-manager = {
      enable = true;
    };
  };
}
