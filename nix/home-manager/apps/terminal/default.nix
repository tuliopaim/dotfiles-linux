{ pkgs, pkgs-unstable, ... }:
{
  imports = [
    #./alacritty.nix
    ./tmux.nix
    ./kitty.nix
    ./zsh.nix
    ./scripts.nix
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
    pkgs-unstable.lazygit
    lazydocker
    killall
    postgresql
    postgresql_jdbc
    inotify-info
    neofetch
    gcalcli
    playerctl
    mono
    exfat
    zlib
    yazi
  ];

}
