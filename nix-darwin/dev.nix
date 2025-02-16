{ pkgs, pkgs-unstable, ... }:
{
  home.packages = [
    # langs
    (pkgs.lib.hiPrio pkgs.gcc)
    (pkgs.lib.lowPrio pkgs.clang)
    pkgs.cargo
    pkgs.yarn
    pkgs.go
    pkgs.gopls
    pkgs.nixd

    # dev tools
    pkgs-unstable.lazygit
    pkgs.lazydocker
    pkgs.awscli
    pkgs.aws-sam-cli
    pkgs.terraform
    pkgs.postgresql
    pkgs.postgresql_jdbc
    pkgs.typescript

    #dotnet stuff
    pkgs.netcoredbg
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };
}
