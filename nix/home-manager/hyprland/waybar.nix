{ pkgs, ... }:
{

  home.packages = with pkgs; [
    waybar
  ];

  home.file = {
    ".config/waybar/config.jsonc".source = ../../../waybar/config.jsonc;
    ".config/waybar/style.css".source = ../../../waybar/style.css;
  };
}
