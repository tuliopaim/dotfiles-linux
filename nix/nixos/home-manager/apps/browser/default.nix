{ pkgs, inputs, system, ... }:
{
  home.packages = [
    pkgs.brave
    pkgs.microsoft-edge
    pkgs.firefox
    inputs.zen-browser.packages."${system}".specific
  ];
}
