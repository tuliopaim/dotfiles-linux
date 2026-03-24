{ hostname, lib, ... }:
{
  # Nix flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Networking
  networking = {
    hostName = hostname;
    networkmanager.enable = true;
  };
  security.polkit.enable = true;

  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;
}
