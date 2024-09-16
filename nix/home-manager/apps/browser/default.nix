{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    brave
    microsoft-edge
    firefox
    inputs.zen-browser.packages."${system}".specific
  ];
}
