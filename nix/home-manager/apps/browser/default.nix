{ pkgs, ... }:
{
  home.packages = with pkgs; [
    brave
    microsoft-edge
    firefox
  ];
}
