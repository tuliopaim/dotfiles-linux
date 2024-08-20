{ pkgs, ... }:
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

  home.packages = with pkgs; [
    (with dotnetCorePackages; combinePackages [
      sdk_6_0
      sdk_7_0
      sdk_8_0
    ])
    jetbrains.rider
    netcoredbg
  ];

  home.file = {
    ".ideavimrc".source = ../../../ideavim/.ideavimrc;
  };
}
