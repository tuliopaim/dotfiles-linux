{ pkgs, pkgs-unstable, ... }:
{
  home.packages = [
    # langs
    (pkgs.lib.hiPrio pkgs.gcc)
    (pkgs.lib.lowPrio pkgs.clang)
    pkgs.cargo
    pkgs.nodejs
    pkgs.yarn
    pkgs.go
    pkgs.gopls
    pkgs.nixd

    # dev tools
    pkgs-unstable.lazygit
    pkgs.docker
    pkgs.docker-compose
    pkgs.lazydocker
    pkgs.awscli
    pkgs.aws-sam-cli
    pkgs.terraform
    pkgs.postman
    pkgs.postgresql
    pkgs.postgresql_jdbc
    pkgs.typescript
    pkgs.dbeaver-bin
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };
}
