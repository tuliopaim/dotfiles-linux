{ pkgs, ... }:
{
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
      packageOverrides = pkgs: {
        dotnet-ef = pkgs.callPackage ./dotnet-ef/default.nix { inherit pkgs; };
      };
    };
  };

  home.packages = with pkgs; [
    (with dotnetCorePackages; combinePackages [
      sdk_6_0
      sdk_7_0
      sdk_8_0
    ])
    dotnet-ef
    jetbrains.rider
    netcoredbg
  ];

  home.file = {
    ".ideavimrc".source = ../../../../ideavim/.ideavimrc;
  };
}
