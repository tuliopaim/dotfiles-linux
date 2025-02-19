{ pkgs, ... }:
{

  home.packages = with pkgs; [
    hyprpaper
  ];

  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "off";
      splash = true;
      splash_offset = 2.0;
      preload =
        [ "~/.dotfiles/wallpapers/nasa-89125.jpg" ];

      wallpaper = [
        ",~/.dotfiles/wallpapers/nasa-89125.jpg"
      ];
    };
  };
}
