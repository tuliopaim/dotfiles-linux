{ pkgs ? (import <nixpkgs> { 
    config.allowUnfree = true;
}), ... }:

let fhs = pkgs.buildFHSUserEnv {
  name = "dotnet-full-env";
  targetPkgs = pkgs: (with pkgs; [
    icu
    zlib
    (with dotnetCorePackages; combinePackages [
      sdk_6_0
      sdk_7_0
      sdk_8_0
    ])
    jetbrains.rider
    docker
    docker-compose
    awscli
    terraform
    postman
    netcoredbg
    lazygit
    lazydocker
  ]);
  runScript = "zsh";
};
in pkgs.stdenv.mkDerivation {
  name = "dotnet-full-env";
  buildInputs = [ fhs ];
  shellHook = "exec dotnet-full-env";
}
