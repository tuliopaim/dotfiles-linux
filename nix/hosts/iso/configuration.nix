{ pkgs, lib, ... }:
{
  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
    config.allowUnfree = true;
  };

  imports = [
    ../../system/hyprland.nix
    ../../system/locale.nix
    ../../system/zsh.nix
    ../../system/bluetooth.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking = {
    hostName = "iso";
  };

  environment.systemPackages = with pkgs; [
    git
    neovim
    ansible
    brave
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
  ];
}
