{
  description = "A simple NixOS flake";

  inputs = {
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , nixpkgs-unstable
    , ...
    } @ inputs:
    let
      inherit (self) outputs;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
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
          inherit inputs outputs;
        };
      };

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
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
          inherit inputs outputs;
          inherit pkgs-unstable;
          username = "tuliopaim";
          hyprlandProfile = "desktop";
        };
        modules = [
          ./hosts/desktop/home.nix
        ];
      };
    };
}
