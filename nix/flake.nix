{
  description = "Unified Nix flake — Darwin, Ubuntu server, NixOS legacy";

  inputs = {
    # Darwin (25.05-darwin, must match nix-darwin branch)
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";

    # Server + default (unstable)
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # NixOS legacy (stable)
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";

    # nix-darwin
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # Home Manager (unstable, for server)
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager (25.05, for darwin)
    home-manager-darwin = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # Home Manager (stable, for NixOS)
    home-manager-stable = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    zen-browser.url = "github:tuliopaim/zen-browser-flake";
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-darwin
    , nixpkgs-stable
    , nix-darwin
    , home-manager
    , home-manager-darwin
    , home-manager-stable
    , ...
    } @ inputs:
    let
      # NixOS legacy
      nixosSystem = "x86_64-linux";
      pkgs-stable = import nixpkgs-stable { system = nixosSystem; config.allowUnfree = true; };
      pkgs-unstable-linux = import nixpkgs { system = nixosSystem; config.allowUnfree = true; };
    in
    {
      # ── MacOS (aarch64-darwin) ──────────────────────────────────
      darwinConfigurations."macos" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit inputs; };
        modules = [
          ./macos/configuration.nix
          home-manager-darwin.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.tuliopaim = import ./macos/home.nix;
          }
        ];
      };

      # ── Ubuntu server (standalone Home Manager) ────────────────────
      homeConfigurations."tuliopaim@server" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };
        modules = [
          ./linux/home.nix
        ];
      };

      # ── NixOS legacy desktop ───────────────────────────────────────
      nixosConfigurations."nixos" = nixpkgs-stable.lib.nixosSystem {
        system = nixosSystem;
        specialArgs = {
          inherit inputs;
          pkgs = pkgs-stable;
          pkgs-unstable = pkgs-unstable-linux;
          username = "tuliopaim";
          hostname = "nixos";
          outputs = self;
        };
        modules = [
          ./nixos/hosts/desktop/configuration.nix
        ];
      };

      # ── NixOS legacy Home Manager (standalone) ─────────────────────
      homeConfigurations."tuliopaim" = home-manager-stable.lib.homeManagerConfiguration {
        pkgs = pkgs-stable;
        extraSpecialArgs = {
          inherit inputs;
          system = nixosSystem;
          pkgs-unstable = pkgs-unstable-linux;
          username = "tuliopaim";
          hyprlandProfile = "desktop";
        };
        modules = [
          ./nixos/hosts/desktop/home.nix
        ];
      };

      # ── NixOS ISO builder ──────────────────────────────────────────
      nixosConfigurations."iso" = nixpkgs-stable.lib.nixosSystem {
        system = nixosSystem;
        modules = [
          "${nixpkgs-stable}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
          "${nixpkgs-stable}/nixos/modules/installer/cd-dvd/channel.nix"
          ./nixos/hosts/iso/configuration.nix
        ];
        specialArgs = {
          inherit inputs;
        };
      };

      # ── Dev shells ─────────────────────────────────────────────────
      devShells.${nixosSystem}.dotnet = (pkgs-stable.buildFHSUserEnv {
        name = "dotnet-env";
        targetPkgs = pkgs: (with pkgs; [
          icu
          zlib
          (with dotnetCorePackages; combinePackages [
            sdk_8_0
          ])
        ]);
        runScript = "zsh";
      }).env;
    };
}
