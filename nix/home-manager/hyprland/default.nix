{ config, pkgs, ... }:
{
  imports = [
    ./xdg.nix
    ./wlogout.nix
    ./swaylock.nix
    ./waybar.nix
  ];

  home.packages = with pkgs; [
    waybar
    swww
    copyq
    rofi-wayland
    gnome-icon-theme
    pulseaudio
    fira-code-nerdfont
    grim
    slurp
    swappy
  ];

  home.file = {
    ".config/hypr/hyprland.conf".source = ../../../hypr/.config/hypr/hyprland.conf;
  };

}
