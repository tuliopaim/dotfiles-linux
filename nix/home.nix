{ outputs, config, pkgs, pkgs-unstable, ... }:

{
  home.username = "tuliopaim";
  home.homeDirectory = "/home/tuliopaim";

  home.stateVersion = "24.05";

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
      packageOverrides = pkgs: {
         dotnet-ef = pkgs.callPackage ./apps/dotnet-ef/default.nix { inherit pkgs; };
      };
    };
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  qt = {
    enable = true;
    platformTheme = {
      name = "gtk";
    };
    style = {
      name = "adwaita-dark";
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome.gnome-themes-extra;
    };
    cursorTheme = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
    };
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
    dotnet-ef

    # dev tools
    pkgs-unstable.neovim
    docker
    docker-compose
    awscli
    aws-sam-cli
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
    neofetch
    gcalcli
    playerctl
    mono

    #hyprland
    swww
    waybar
    rofi-wayland
    gnome-icon-theme
    pulseaudio
    fira-code-nerdfont
    swayidle

    # desktop
    cinnamon.nemo-with-extensions
    brave
    microsoft-edge
    firefox
    spotify
    slack
    obsidian
    pavucontrol
    vlc
    networkmanagerapplet
    os-prober
    obs-studio
    stremio
    evince
    sxiv
    teams-for-linux
    gnome.file-roller
    libreoffice
    exfat
    zlib
    gnome.gnome-calculator
    mongodb-compass
    vesktop

    # scripts 
    (pkgs.writeShellScriptBin "clone-wt" (builtins.readFile ../scripts/clone-wt))
    (pkgs.writeShellScriptBin "prune-wt" (builtins.readFile ../scripts/prune-wt))
    (pkgs.writeShellScriptBin "tmux-sessionizer" (builtins.readFile ../scripts/tmux-sessionizer))
    (pkgs.writeShellScriptBin "lockscreentime" (builtins.readFile ../scripts/lockscreentime))
    (pkgs.writeShellScriptBin "usersecrets" (builtins.readFile ../scripts/usersecrets))
    (pkgs.writeShellScriptBin "connect-vpn" (builtins.readFile ../scripts/connect-vpn))
    (pkgs.writeShellScriptBin "disconnect-vpn" (builtins.readFile ../scripts/disconnect-vpn))
  ];

  home.file = {
    ".config/hypr/hyprland.conf".source = ../hypr/.config/hypr/hyprland.conf;
    ".config/hypr/start.sh".source = ../hypr/.config/hypr/start.sh;
    ".config/alacritty.toml".source = ../alacritty/.config/alacritty.toml;
    ".config/waybar/config.jsonc".source = ../waybar/.config/waybar/config.jsonc;
    ".config/waybar/style.css".source = ../waybar/.config/waybar/style.css;
    ".ideavimrc".source = ../ideavim/.ideavimrc;
  };

  imports = [
    ./apps/zsh.nix
    ./apps/tmux.nix
    ./apps/git.nix
    ./apps/wlogout.nix
    ./apps/swaylock.nix
  ];

  programs = {
    home-manager = {
      enable = true;
    };
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
    direnv = {
      enable = true;
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "microsoft-edge.desktop";
      "x-scheme-handler/http" = "microsoft-edge.desktop";
      "x-scheme-handler/https" = "microsoft-edge.desktop";
      "x-scheme-handler/about" = "microsoft-edge.desktop";
      "x-scheme-handler/unknown" = "microsoft-edge.desktop";
      "application/pdf" = "org.gnome.Evince.desktop";
      "image/png" = "sxiv.desktop";
      "image/jpg" = "sxiv.desktop";
      "image/gif" = "sxiv.desktop";
      "image/webp" = "sxiv.desktop";
      "video/mp4" = "vlc.desktop";
      "video/mkv" = "vlc.desktop";
      "video/mpeg" = "vlc.desktop";
      "audio/mpeg" = "vlc.desktop";
      "application/x-tar" = "org.gnome.FileRoller.desktop";
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "writer.desktop";
      "application/msword" = "writer.desktop";
    };
  };
}
