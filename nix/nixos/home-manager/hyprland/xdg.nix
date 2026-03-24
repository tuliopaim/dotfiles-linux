{ config, ... }:
let
  browser = [ "microsoft-edge.desktop" ];

  # XDG MIME types
  associations = {
    "application/x-extension-htm" = browser;
    "application/x-extension-html" = browser;
    "application/x-extension-shtml" = browser;
    "application/x-extension-xht" = browser;
    "application/x-extension-xhtml" = browser;
    "application/xhtml+xml" = browser;
    "text/html" = browser;
    "x-scheme-handler/about" = browser;
    "x-scheme-handler/ftp" = browser;
    "x-scheme-handler/http" = browser;
    "x-scheme-handler/https" = browser;
    "x-scheme-handler/unknown" = browser;
    "image/png" = "sxiv.desktop";
    "image/jpg" = "sxiv.desktop";
    "image/gif" = "sxiv.desktop";
    "image/webp" = "sxiv.desktop";
    "video/mp4" = "vlc.desktop";
    "video/mkv" = "vlc.desktop";
    "video/mpeg" = "vlc.desktop";
    "audio/mpeg" = "vlc.desktop";
    "application/json" = browser;
    "application/pdf" = "org.gnome.Evince.desktop";
    "application/x-tar" = "org.gnome.FileRoller.desktop";
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "writer.desktop";
    "application/msword" = "writer.desktop";
    "x-scheme-handler/discord" = [ "discord.desktop" ];
    "x-scheme-handler/spotify" = [ "spotify.desktop" ];
    "x-scheme-handler/tg" = [ "telegramdesktop.desktop" ];
  };
in
{
  xdg = {
    enable = true;
    cacheHome = config.home.homeDirectory + "/.local/cache";

    mimeApps = {
      enable = true;
      defaultApplications = associations;
    };

    userDirs = {
      enable = true;
      createDirectories = true;
      extraConfig = {
        XDG_SCREENSHOTS_DIR = "${config.xdg.userDirs.pictures}/Screenshots";
      };
    };
  };
}


