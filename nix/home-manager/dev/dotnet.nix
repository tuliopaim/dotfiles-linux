{ pkgs, pkgs-unstable, ... }:
{
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };

  home.sessionVariables = {
    DOTNET_ROOT = "${pkgs.dotnet-sdk}";
  };

  home.packages = [
    pkgs-unstable.roslyn-ls
    (with pkgs.dotnetCorePackages; combinePackages [
      sdk_6_0
      sdk_7_0
      sdk_8_0
    ])
    pkgs.jetbrains.rider
    pkgs.netcoredbg
  ];

  home.file = {
    ".ideavimrc".source = ../../../ideavim/.ideavimrc;
  };
}
