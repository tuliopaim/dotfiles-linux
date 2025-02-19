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
      configuration = { pkgs, ... }: {

        environment.systemPackages =
          [
            pkgs.vim
            pkgs.neovim
            pkgs.ansible
          ];

        fonts.packages = with pkgs; [
          (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
          liberation_ttf
        ];

        services.nix-daemon.enable = true;

        nix.settings.experimental-features = "nix-command flakes";

        system.configurationRevision = self.rev or self.dirtyRev or null;

        system.stateVersion = 5;

        nixpkgs.hostPlatform = "aarch64-darwin";

        users.users.tuliopaim.home = "/Users/tuliopaim";
        security.pam.enableSudoTouchIdAuth = false;
        home-manager.backupFileExtension = "backup";
        nix.configureBuildUsers = true;
        nix.useDaemon = true;

        system.defaults = {
          dock.autohide = true;
          dock.mru-spaces = false;
          finder.AppleShowAllExtensions = true;
          finder.FXPreferredViewStyle = "clmv";
          loginwindow.LoginwindowText = "tuliopaim";
          screencapture.location = "~/Pictures/screenshots";
          screensaver.askForPasswordDelay = 10;
        };


        homebrew = {
          enable = true;
          casks = [
            "nikitabobko/tap/aerospace"
            "shottr"
          ];
        };

      };
    in
    {
      darwinConfigurations."macos" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          configuration
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
