{ config, pkgs, ... }:
{
  imports = [
    ../home
  ];

  home.username = "tuliopaim";
  home.homeDirectory = "/home/tuliopaim";
  home.stateVersion = "25.05";

  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    kubectl
    kubernetes-helm
    k9s
    kubeseal
  ];
}
