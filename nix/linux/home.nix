{ username, pkgs, config, ... }:
{
  imports = [
    ../home
  ];

  home.username = username;
  home.homeDirectory = "/home/" + username;
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    # server-specific packages
    kubectl
    kubernetes-helm
    k9s
  ];
}
