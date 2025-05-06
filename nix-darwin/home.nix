{ username, pkgs, ... }:

{
  home.username = username;
  home.homeDirectory = "/Users/" + username;
  home.stateVersion = "24.05";

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.packages = [
    pkgs.exfat

    # langs
    (pkgs.lib.hiPrio pkgs.gcc)
    (pkgs.lib.lowPrio pkgs.clang)
    pkgs.cargo
    pkgs.yarn
    pkgs.go
    pkgs.gopls
    pkgs.nixd

    # dev tools
    pkgs.terraform
    pkgs.postgresql
    pkgs.postgresql_jdbc

    #dotnet stuff
    pkgs.netcoredbg
  ];
  programs = {
    home-manager = {
      enable = true;
    };
  };
}
