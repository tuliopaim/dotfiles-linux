{ pkgs, pkgs-unstable, ... }:
{
  home.packages = with pkgs; [
    # langs
    (lib.hiPrio gcc)
    (lib.lowPrio clang)
    cargo
    nodejs
    yarn

    # dev tools
    pkgs-unstable.neovim
    pkgs-unstable.lazygit
    docker
    docker-compose
    lazydocker
    awscli
    aws-sam-cli
    terraform
    postman
    postgresql
    postgresql_jdbc
    typescript
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };
}
