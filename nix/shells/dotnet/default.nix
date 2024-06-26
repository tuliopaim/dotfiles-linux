with import <nixpkgs> {};

buildFHSUserEnv {
  name = "dotnet-env";
  targetPkgs = pkgs: (with pkgs; [
    zlib
    dotnetCorePackages.sdk_6_0
    icu
  ]);
}
