{ hostname, ...}:
{
  # Nix flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Networking
  networking = {
    hostName = hostname;
    networkmanager.enable = true;
  };
  security.polkit.enable = true;

  services.gvfs.enable = true;
  services.devmon.enable = true;
  services.udisks2.enable = true;
}
