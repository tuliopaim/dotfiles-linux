{ outputs, config, pkgs, ... }:

{
  nixpkgs = {
    overlays = [
      outputs.overlays.unstable-packages
    ];
  };

  home.username = "tuliopaim";
  home.homeDirectory = "/home/tuliopaim";

  home.stateVersion = "24.05";

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = (_: true);
  };

  programs.home-manager.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome.gnome-themes-extra;
    };
    cursorTheme.name = "Bibata-Modern-Ice";
  };

  home.packages = with pkgs; [

    # langs
    (lib.hiPrio gcc)
    (lib.lowPrio clang)
    cargo
    nodejs
    (with dotnetCorePackages; combinePackages [
      sdk_6_0
      sdk_7_0
      sdk_8_0
    ])

    # dev tools
    unstable.neovim
    docker
    docker-compose
    awscli
    terraform
    jetbrains.rider
    postman
    netcoredbg

    # terminal tools
    wget
    jq
    fd
    fzf
    htop
    ripgrep
    tree
    unzip
    zip
    zoxide
    wl-clipboard
    grim
    slurp
    swappy
    copyq
    ansible
    stow
    lazygit
    lazydocker
    killall
    postgresql
    inotify-info

    #hyprland
    swww
    waybar
    rofi-wayland
    gnome-icon-theme
    pulseaudio
    fira-code-nerdfont
    swaylock
    wlogout

    # desktop
    cinnamon.nemo-with-extensions
    brave
    microsoft-edge
    spotify
    slack
    obsidian
    pavucontrol
    vlc
    discord
    networkmanagerapplet
    os-prober
    obs-studio
    stremio
    evince
    sxiv

    # scripts 
    (import ./vpn.nix { inherit pkgs; }).connect
    (import ./vpn.nix { inherit pkgs; }).disconnect
  ];

  imports = [
    ./apps/zsh.nix
    ./apps/tmux.nix
    ./apps/firefox.nix
  ];

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  xdg.mimeApps.defaultApplications = {
    "application/pdf" = [ "firefox.desktop" ];
    "image/*" = [ "sxiv.desktop" ];
    "video/*" = [ "vlc.desktop" ];
  };
}
