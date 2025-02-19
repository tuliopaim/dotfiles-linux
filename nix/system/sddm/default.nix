{ pkgs, ... }:
{
  services.displayManager = {
    sddm = {
      enable = true;
      theme = "${import ./sddm-sugar-dark.nix {inherit pkgs;}}";
      wayland.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    libsForQt5.qt5.qtquickcontrols2
    libsForQt5.qt5.qtgraphicaleffects
  ];
}
