{ pkgs, ... }:
{
  imports = [
    ./git
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
    gnome.file-roller
    gnome.gnome-disk-utility
    gnome.gnome-calculator
    cinnamon.nemo-with-extensions
    mongodb-compass
    vesktop
    woeusb
    blueman
    baobab
    shotcut
    ventoy-full
    mpv
    gimp-with-plugins

    #qmk
    qmk
    via
    keymapviz
  ];
}
