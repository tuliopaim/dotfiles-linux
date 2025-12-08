{ pkgs, outputs, ... }:
{
  system = {
    stateVersion = 5;
    configurationRevision = outputs.rev or outputs.dirtyRev or null;
    primaryUser = "tuliopaim";

    defaults = {
      dock = {
        autohide = true;
        mru-spaces = false;
      };

      finder = {
        AppleShowAllExtensions = true;
        FXPreferredViewStyle = "clmv";
      };

      loginwindow = {
        LoginwindowText = "tuliopaim";
        GuestEnabled = false;
      };

      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark";
      };
    };
  };

  nix = {
    enable = true;
    optimise.automatic = true;

    settings = {
      experimental-features = "nix-command flakes";
      extra-platforms = [ "x86_64-darwin" "aarch64-darwin" ];
      max-jobs = 8;
      cores = 0;
    };

    gc = {
      automatic = true;
      interval = { Weekday = 0; Hour = 2; Minute = 0; };
      options = "--delete-older-than 30d";
    };
  };

  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.tuliopaim.home = "/Users/tuliopaim";
  home-manager.backupFileExtension = "backup";

  security.pam.services.sudo_local.touchIdAuth = true;

  environment.systemPackages = [
    pkgs.vim
    pkgs.neovim
    pkgs.ansible
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    liberation_ttf
  ];

  programs.zsh.enable = true;

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap"; # Uninstalls all formulae and casks not listed here
    };

    taps = [
      "mongodb/brew"
      "nikitabobko/tap"
    ];

    brews = [
      # Shell
      "mas"

      # Development tools
      "direnv"
      "fnm"
      "poetry"
      "python@3.13"

      # Databases & Related
      { name = "libpq"; link = true; }
      "mongosh"
      "redis"

      # Cloud & DevOps
      "awscli-local"

      # Other
      "mono-libgdiplus"
      "cask"
      "zlib"
      "qmk/qmk/qmk"
    ];

    casks = [
      # Browsers
      "brave-browser"
      "firefox"
      "google-chrome"
      "microsoft-edge"

      # Development
      "cursor"
      "dbeaver-community"
      "ghostty"
      "postman"
      "rider"
      "visual-studio-code"
      "orbstack"
      "claude-code"

      # Database Tools
      "mongodb-compass"
      "pgadmin4"

      # Productivity
      "bitwarden"
      "obsidian"
      "pdf-expert"
      "raycast"

      # Communication
      "discord"
      "microsoft-teams"
      "slack"

      # Utilities
      "aerospace"
      "balenaetcher"
      "drawio"
      "istat-menus"
      "karabiner-elements"
      "localsend"
      "logi-options+"
      "microsoft-auto-update"
      "obs"
      "qmk-toolbox"
      "scroll-reverser"
      "shottr"
      "via"

      # Entertainment
      "spotify"
    ];
  };
}
