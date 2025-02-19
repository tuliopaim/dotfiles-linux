{ pkgs,  ...  }:

let
  lib = pkgs.lib;
  mkNugetDeps = pkgs.mkNugetDeps;
in
pkgs.buildDotnetGlobalTool rec {
  pname = "dotnet-ef";
  version = "8.0.6";

  dotnet-sdk = pkgs.dotnetCorePackages.sdk_8_0;

  nugetSha256 = "sha256-OAerJg3CZRg7xxRB8AKzgPsPY2ubPQ5MjMEmGb2mlQE";

  meta = {
    homepage = "https://docs.microsoft.com/ef/core/";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
