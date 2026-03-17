{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  # Nix settings
  nix.settings.experimental-features = "nix-command flakes";
  nix.settings.trusted-users = [ "root" "tuliopaim" ];

  # System defaults
  system.defaults = {
    dock = {
      autohide = true;
      mru-spaces = false;
      minimize-to-application = true;
      show-recents = false;
    };
    finder = {
      AppleShowAllExtensions = true;
      FHSEnabled = true;
      ShowPathbar = true;
    };
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      AppleInterfaceStyle = "Dark";
      "com.apple.swipescrolldirection" = false;
    };
    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = true;
    };
  };

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
  ];

  # Homebrew
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
    };
    casks = [
      "cursor"
      "orbstack"
      "google-drive"
      "the-unarchiver"
      "todoist"
      "slack"
      "microsoft-teams"
      "notion"
      "spotify"
      "obsidian"
      "alt-tab"
      "raycast"
      "zen"
      "whatsapp"
      "telegram"
      "google-chrome"
    ];
    taps = [];
    brews = [];
  };

  # Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    neovim
  ];

  # Enable zsh
  programs.zsh.enable = true;

  # Used for backwards compatibility
  system.stateVersion = 6;
}
