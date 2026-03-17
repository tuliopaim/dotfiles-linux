{
  description = "Unified Nix configuration — Darwin, Ubuntu server, NixOS";

  inputs = {
    # Darwin + server (unstable)
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # NixOS legacy (stable)
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";

    # nix-darwin
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Home Manager (unstable, for darwin + server)
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Home Manager (stable, for NixOS)
    home-manager-stable.url = "github:nix-community/home-manager/release-25.05";
    home-manager-stable.inputs.nixpkgs.follows = "nixpkgs-stable";

    # NixOS extras
    zen-browser.url = "github:tuliopaim/zen-browser-flake";
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-stable
    , nix-darwin
    , home-manager
    , home-manager-stable
    , ...
    } @ inputs:
    let
      inherit (self) outputs;
    in
    {
      # ── Mac Mini (aarch64-darwin) ──────────────────────────────────────
      darwinConfigurations."macos" =
        let
          system = "aarch64-darwin";
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              permittedInsecurePackages = [ "dotnet-sdk-6.0.428" ];
            };
          };
        in
        nix-darwin.lib.darwinSystem {
          inherit pkgs system;
          specialArgs = {
            inherit outputs self;
          };
          modules = [
            ./macos/configuration.nix

            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit pkgs inputs system;
                username = "tuliopaim";
              };
              home-manager.users.tuliopaim = import ./macos/home.nix;
            }
          ];
        };

      # ── Ubuntu server (standalone Home Manager) ────────────────────────
      homeConfigurations."tuliopaim@server" =
        let
          system = "x86_64-linux";
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit inputs system;
            username = "tuliopaim";
          };
          modules = [
            ./linux/home.nix
          ];
        };

      # ── NixOS desktop (legacy) ─────────────────────────────────────────
      nixosConfigurations."nixos" =
        let
          system = "x86_64-linux";
          pkgs = import nixpkgs-stable {
            inherit system;
            config.allowUnfree = true;
          };
          pkgs-unstable = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        nixpkgs-stable.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit pkgs inputs outputs;
            username = "tuliopaim";
            hostname = "nixos";
          };
          modules = [
            ./nixos/hosts/desktop/configuration.nix
          ];
        };

      # ── NixOS ISO builder ──────────────────────────────────────────────
      nixosConfigurations."iso" =
        let
          system = "x86_64-linux";
        in
        nixpkgs-stable.lib.nixosSystem {
          inherit system;
          modules = [
            "${nixpkgs-stable}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
            "${nixpkgs-stable}/nixos/modules/installer/cd-dvd/channel.nix"
            ./nixos/hosts/iso/configuration.nix
          ];
          specialArgs = {
            inherit inputs;
          };
        };

      # ── NixOS home-manager (standalone) ────────────────────────────────
      homeConfigurations."tuliopaim" =
        let
          system = "x86_64-linux";
          pkgs = import nixpkgs-stable {
            inherit system;
            config.allowUnfree = true;
          };
          pkgs-unstable = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        home-manager-stable.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit inputs system pkgs-unstable;
            username = "tuliopaim";
            hyprlandProfile = "desktop";
          };
          modules = [
            ./nixos/hosts/desktop/home.nix
          ];
        };

      # ── Dev shells ─────────────────────────────────────────────────────
      devShells.x86_64-linux.dotnet =
        let
          system = "x86_64-linux";
          pkgs = import nixpkgs-stable {
            inherit system;
            config.allowUnfree = true;
          };
        in
        (pkgs.buildFHSUserEnv {
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
