{ pkgs, pkgs-unstable, ... }:
{
  home.packages = with pkgs; [
    fd
    bat
    ripgrep
    eza
    fzf
    zoxide
    lazygit
    lazydocker
    jq
    wget
    tree
    unzip
    zip
    age
    glow
    gnumake
    yazi
    gdu
    p7zip
    stow
    fastfetch
    htop
    cargo
    go
    gopls
    nixd
    git
    gh
    jujutsu
    jjui

    pkgs-unstable.pi-coding-agent
  ];
}
