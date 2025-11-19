{ username, pkgs, ... }:

{
  home.username = username;
  home.homeDirectory = "/Users/" + username;
  home.stateVersion = "25.05";

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.packages = [
    # langs
    pkgs.cargo
    pkgs.yarn
    pkgs.go
    pkgs.gopls
    pkgs.nixd

    # dev tools
    pkgs.terraform
    pkgs.postgresql
    pkgs.postgresql_jdbc

    # dotnet stuff
    pkgs.netcoredbg

    # cli tools
    pkgs.jq
    pkgs.fd
    pkgs.bat
    pkgs.ripgrep
    pkgs.eza
    pkgs.fzf
    pkgs.zoxide
    pkgs.lazygit
    pkgs.lazydocker
    pkgs.glow
    pkgs.wget
    pkgs.unzip
    pkgs.zip
    pkgs.tree
    pkgs.stow
    pkgs.fastfetch
    pkgs.age
    pkgs.pngpaste
  ];
  programs = {
    home-manager = {
      enable = true;
    };
  };
}
