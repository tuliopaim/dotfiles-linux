{ pkgs, ... }:
{
  imports = [
    ./browser
    ./vpn
  ];

  home.packages = with pkgs; [
    spotify
    slack
    obsidian
    pavucontrol
    vlc
    os-prober
    obs-studio
    stremio
    evince
    sxiv
    teams-for-linux
    libreoffice
    file-roller
    gnome-disk-utility
    gnome-calculator
    nemo-with-extensions
    mongodb-compass
    vesktop
    woeusb
    blueman
    baobab
    shotcut
    ventoy-full
    mpv
    gimp-with-plugins
    todoist-electron

    #qmk
    qmk
    via
    keymapviz
  ];
}
