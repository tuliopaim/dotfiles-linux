{ pkgs, ... }:
{
  networking.firewall.enable = true;
  services.fail2ban = {
    enable = true;
    ignoreIP = [
        "192.168.100.12"
    ];
  };
}
