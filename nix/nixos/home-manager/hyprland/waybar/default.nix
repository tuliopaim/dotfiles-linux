{ pkgs, hyprlandProfile, ... }:
{

  home.packages = with pkgs; [
    waybar
  ];

  home.file = {
    ".config/waybar/config.jsonc".source = ./config-${hyprlandProfile}.jsonc;
    ".config/waybar/style.css".source = ./style-${hyprlandProfile}.css;
    ".config/waybar/mocha.css".source = ./mocha.css;
  };
}
