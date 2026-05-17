{ config, pkgs, pkgs-unstable, ... }:
{
  imports = [
    ../home
  ];

  home.username = "tuliopaim";
  home.homeDirectory = "/home/tuliopaim";
  home.stateVersion = "25.05";

  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    pkgs-unstable.neovim

    kubectl
    kubernetes-helm
    k9s
    kubeseal
  ];
}
