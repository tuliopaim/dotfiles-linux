{ pkgs, ... }:
{
  imports = [
    ./git
    ./browser
    ./vpn
  ];

  home.packages = with pkgs; [
    cinnamon.nemo-with-extensions
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
    gnome.file-roller
    libreoffice
    gnome.gnome-disk-utility
    gnome.gnome-calculator
    mongodb-compass
    vesktop
    virtualbox
    woeusb
    blueman

    #qmk
    qmk
    via
    vial
    keymapviz
  ];
}
