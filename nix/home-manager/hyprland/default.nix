{ config, pkgs, hyprlandProfile, ... }:
{
  imports = [
    ./xdg.nix
    ./wlogout.nix
    ./swaylock.nix
    ./waybar.nix
    ./gtk.nix
  ];

  home.packages = with pkgs; [
    waybar
    swww
    copyq
    rofi-wayland
    networkmanagerapplet
    gnome-icon-theme
    pulseaudio
    fira-code-nerdfont
    grim
    slurp
    swappy
    swayidle
  ];

  home.file = {
    ".config/hypr/hyprland.conf".source = ./${hyprlandProfile}.conf;
  };
}
