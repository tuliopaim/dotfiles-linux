{ pkgs, modulesPath, lib, ... }:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-graphical-gnome.nix"
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  programs = {
    hyprland.enable = true;
    zsh.enable = true;
  };

  # Nix flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # inotify
  boot.kernel.sysctl."fs.inotify.max_user_instances" = 524288;

  users.defaultUserShell = pkgs.zsh;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
    variables = {
      EDITOR = "nvim";
      NIXOS_OZONE_WL = "1";
    };
    systemPackages = with pkgs; [
      vim
      neovim
      git
      alacritty
      home-manager
    ];
  };
}
