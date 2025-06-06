{
  description = "A simple NixOS flake";

  inputs = {
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser.url = "github:tuliopaim/zen-browser-flake";
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , ...
    } @ inputs:
    let
      inherit (self) outputs;
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      pkgs-unstable = import inputs.nixpkgs-unstable { inherit system; config.allowUnfree = true; };
    in
    {
      nixosConfigurations.iso = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
          "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
          ./hosts/iso/configuration.nix
        ];
        specialArgs = {
          inherit inputs;
        };
      };

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit pkgs inputs outputs;
          username = "tuliopaim";
          hostname = "nixos";
        };
        modules = [
          ./hosts/desktop/configuration.nix
        ];
      };

      homeConfigurations."tuliopaim" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs system pkgs-unstable;
          username = "tuliopaim";
          hyprlandProfile = "desktop";
        };
        modules = [
          ./hosts/desktop/home.nix
        ];
      };

      devShells.${system}.dotnet = (pkgs.buildFHSUserEnv {
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
      }).env;
    };
}
