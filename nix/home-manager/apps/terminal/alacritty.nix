{ pkgs, ... }:
{
  programs.alacritty = {
    enable = true;
  };

  home.file = {
    ".config/alacritty.toml".source = ../../../../alacritty/.config/alacritty.toml;
  };
}
