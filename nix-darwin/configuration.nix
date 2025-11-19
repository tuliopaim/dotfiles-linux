{ pkgs, outputs, ... }:
{
  environment.systemPackages =
    [
      pkgs.vim
      pkgs.neovim
      pkgs.ansible
      pkgs.mkalias
    ];

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    liberation_ttf
  ];

  nix.settings.experimental-features = "nix-command flakes";

  system.configurationRevision = outputs.rev or outputs.dirtyRev or null;

  system.stateVersion = 5;

  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.tuliopaim.home = "/Users/tuliopaim";
  home-manager.backupFileExtension = "backup";

  nix.enable = true;
  security.pam.services.sudo_local.touchIdAuth = false;

  system.primaryUser = "tuliopaim";
  system.defaults = {
    dock.autohide = true;
    dock.mru-spaces = false;
    finder.AppleShowAllExtensions = true;
    finder.FXPreferredViewStyle = "clmv";
    loginwindow.LoginwindowText = "tuliopaim";
    loginwindow.GuestEnabled = false;
    NSGlobalDomain.AppleInterfaceStyle = "Dark";
  };

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # 'zap': Uninstalls all formulae(and casks) not listed here.
      cleanup = "zap";
    };

    taps = [
      "mongodb/brew"
      "nikitabobko/tap"
    ];

    brews = [
      "mas"
      "zsh"
      "zsh-autosuggestions"
      "zsh-vi-mode"
      "zsh-syntax-highlighting"
      "tmux"
      "mono-libgdiplus"
      "python@3.13"
      "cask"
      "fnm"
      { name = "libpq"; link = true; }
      "mongosh"
      "sevenzip"
      "yazi"
      "poetry"
      "typescript"
      "clipboard"
      "ansible"
      "zlib"
      "make"
      "direnv"
      "awscli"
      "awscli-local"
      "hg"
      "imagemagick"
      "qmk/qmk/qmk"
      "angular-cli"
      "redis"
      "gdu"
    ];

    # GUI Apps
    casks = [
      "aerospace"
      "balenaetcher"
      "bitwarden"
      "brave-browser"
      "cursor"
      "dbeaver-community"
      "discord"
      "drawio"
      "firefox"
      "font-fira-code-nerd-font"
      "font-jetbrains-mono-nerd-font"
      "ghostty"
      "google-chrome"
      "istat-menus"
      "karabiner-elements"
      "localsend"
      "logi-options+"
      "microsoft-auto-update"
      "microsoft-edge"
      "microsoft-teams"
      "mongodb-compass"
      "obs"
      "obsidian"
      "pdf-expert"
      "pgadmin4"
      "postman"
      "qmk-toolbox"
      "raycast"
      "rider"
      "scroll-reverser"
      "shottr"
      "slack"
      "soundsource"
      "spotify"
      "via"
      "visual-studio-code"
      "wezterm"
    ];

    # Mac App Store Apps (requires 'mas' in brews)
    masApps = {
      # "Xcode" = 497799835;
    };
  };
}
