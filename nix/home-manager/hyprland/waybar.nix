{ pkgs, ... }:
{

  home.packages = with pkgs; [
    waybar
  ];

  home.file = {
    ".config/waybar/config.jsonc".source = ../../../waybar/.config/waybar/config.jsonc;
    ".config/waybar/style.css".source = ../../../waybar/.config/waybar/style.css;
  };
}
