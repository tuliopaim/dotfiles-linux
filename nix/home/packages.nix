{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # cli tools
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
    gdu
    p7zip
    stow
    fastfetch
    htop

    # dev tools
    cargo
    go
    gopls
    nixd
    git
    gh
    jujutsu
    jjui

    # file manager
    yazi
  ];
}
