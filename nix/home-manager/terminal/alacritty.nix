{ pkgs, ... }:
{
  programs.alacritty = {
    enable = true;
  };

  home.file = {
    ".config/alacritty.toml".source = ../../../alacritty/alacritty.toml;
  };
}
