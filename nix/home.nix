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
    teams-for-linux

    # scripts 
    (pkgs.writeShellScriptBin "clone-wt" (builtins.readFile ../scripts/clone-wt))
    (pkgs.writeShellScriptBin "prune-wt" (builtins.readFile ../scripts/prune-wt))
    (pkgs.writeShellScriptBin "lockscreentime" (builtins.readFile ../scripts/lockscreentime))
    (pkgs.writeShellScriptBin "tmux-sessionizer" (builtins.readFile ../scripts/tmux-sessionizer))
    (pkgs.writeShellScriptBin "usersecrets" (builtins.readFile ../scripts/usersecrets))
    (pkgs.writeShellScriptBin "connect-vpn" (builtins.readFile ../scripts/connect-vpn))
    (pkgs.writeShellScriptBin "disconnect-vpn" (builtins.readFile ../scripts/disconnect-vpn))
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

  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    "application/pdf" = [ "firefox.desktop" ];
    "image/*" = [ "sxiv.desktop" ];
    "video/*" = [ "vlc.desktop" ];
  };
}
