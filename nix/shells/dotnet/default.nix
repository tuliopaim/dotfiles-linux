{ pkgs ? (import <nixpkgs> { 
    config.allowUnfree = true;
}), ... }:

let fhs = pkgs.buildFHSUserEnv {
  name = "dotnet-env";
  targetPkgs = pkgs: (with pkgs; [
    icu
    zlib
    (with dotnetCorePackages; combinePackages [
      sdk_6_0
      sdk_7_0
      sdk_8_0
    ])
  ]);
  runScript = "zsh";
};
in pkgs.stdenv.mkDerivation {
  name = "dotnet-env";
  buildInputs = [ fhs ];
  shellHook = "exec dotnet-env";
}
