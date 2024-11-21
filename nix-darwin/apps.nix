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
    qmk
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
    stow
  ];
}
