{ pkgs, hyprlandProfile, ... }:
{
  imports = [
    ./xdg.nix
    ./wlogout.nix
    ./waybar
    ./gtk.nix
    ./hypridle.nix
    ./hyprlock
    ./swaync
  ];

  home.packages = with pkgs; [
    waybar
    swww
    copyq
    rofi-wayland
    smile
    networkmanagerapplet
    gnome-icon-theme
    pulseaudio
    fira-code-nerdfont
    grim
    slurp
    swappy
    hyprcursor
    hyprpicker
    libnotify
  ];

  home.file = {
    ".config/hypr/hyprland.conf".source = ./${hyprlandProfile}.conf;
  };
}
