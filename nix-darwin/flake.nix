{
  description = "My config";

  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nix-darwin
    , nixpkgs
    , home-manager
    , ...
    } @ inputs:
    let
      inherit (self) outputs;
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      pkgs-unstable = import inputs.nixpkgs-unstable { inherit system; config.allowUnfree = true; };
    in
    {
      darwinConfigurations."macos" = nix-darwin.lib.darwinSystem {
        inherit pkgs;
        system = "aarch64-darwin";
        specialArgs = {
          inherit outputs self;
        };
        modules = [
          ./configuration.nix

          home-manager.darwinModules.home-manager
          {
            home-manager.extraSpecialArgs = {
              inherit pkgs inputs system pkgs-unstable;
              username = "tuliopaim";
            };
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.tuliopaim = import ./home.nix;
          }
        ];
      };

      darwinPackages = self.darwinConfigurations."macos".pkgs;
    };
}
