{ pkgs, inputs, ... }:
{
  system = {
    stateVersion = 6;
    primaryUser = "tuliopaim";

    defaults = {
      dock = {
        autohide = true;
        mru-spaces = false;
        minimize-to-application = true;
        show-recents = false;
      };

      finder = {
        AppleShowAllExtensions = true;
        FXPreferredViewStyle = "clmv";
        ShowPathbar = true;
      };

      loginwindow = {
        LoginwindowText = "tuliopaim";
        GuestEnabled = false;
      };

      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark";
        AppleShowAllExtensions = true;
        "com.apple.swipescrolldirection" = false;
      };

      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = true;
      };
    };
  };

  nix = {
    enable = true;
    optimise.automatic = true;

    settings = {
      experimental-features = "nix-command flakes";
      extra-platforms = [ "x86_64-darwin" "aarch64-darwin" ];
      trusted-users = [ "root" "tuliopaim" ];
      max-jobs = 8;
      cores = 0;
    };

    gc = {
      automatic = true;
      interval = { Weekday = 0; Hour = 2; Minute = 0; };
      options = "--delete-older-than 30d";
    };
  };

  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config.allowUnfree = true;
  };

  users.users.tuliopaim.home = "/Users/tuliopaim";
  home-manager.backupFileExtension = "backup";

  security.pam.services.sudo_local.touchIdAuth = true;

  environment.systemPackages = with pkgs; [
    vim
    neovim
    ansible
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
      cleanup = "zap";
    };

    taps = [
      "mongodb/brew"
      "nikitabobko/tap"
      "anomalyco/tap"
    ];

    brews = [
      # Shell
      "mas"

      # Development tools
      "direnv"
      "fnm"
      "poetry"
      "python@3.13"
      "anomalyco/tap/opencode"

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
      "codex"

      # Database Tools
      "mongodb-compass"
      "beekeeper-studio"

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
      "tailscale-app"
      "nikitabobko/tap/aerospace"
      "drawio"
      "istat-menus"
      "karabiner-elements"
      "localsend"
      "microsoft-auto-update"
      "obs"
      "qmk-toolbox"
      "scroll-reverser"
      "shottr"
      "via"
      "google-drive"

      # Browsers (cont.)
      "zen"

      # Entertainment
      "spotify"
    ];
  };
}
