{ pkgs, ... }:
{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.direnv = {
    enable = true;
  };

  home.packages = with pkgs; [
    spotify
    slack
    obsidian
    discord
    qmk
    zoxide
    teams
    raycast

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
    neofetch
    exfat
    zlib
    age
    glow
    gnumake
    eza
  ];
}
