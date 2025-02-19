{ hostname, ... }:
{
  # Nix flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Networking
  networking = {
    hostName = hostname;
    networkmanager.enable = true;
  };
  security.polkit.enable = true;
}
