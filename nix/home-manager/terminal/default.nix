{ pkgs, pkgs-unstable, ... }:
{
  imports = [
    ./alacritty.nix
    ./tmux.nix
    ./kitty.nix
    ./zsh.nix
    ./scripts.nix
    ./yazi.nix
  ];

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.direnv = {
    enable = true;
  };

  home.packages = with pkgs; [
    wget
    jq
    fd
    fzf
    htop
    ripgrep
    tree
    unzip
    zip
    zoxide
    wl-clipboard
    ansible
    stow
    killall
    inotify-info
    neofetch
    gcalcli
    playerctl
    mono
    exfat
    zlib
    age
    lm_sensors
  ];
}
