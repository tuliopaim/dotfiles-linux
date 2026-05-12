{ ... }:
{
  # Userland daemon for the Karabiner VirtualHIDDevice driver.
  # The standalone .pkg installs the binary but no launchd plist for it
  # (Karabiner-Elements normally starts it). Without this, kanata can't
  # talk to the driver and fails with `connect_failed asio.system:61`.
  launchd.daemons.karabiner-vhid-daemon = {
    serviceConfig = {
      ProgramArguments = [
        "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/var/log/karabiner-vhid-daemon.log";
      StandardErrorPath = "/var/log/karabiner-vhid-daemon.err.log";
      ProcessType = "Interactive";
    };
  };

  launchd.daemons.kanata = {
    serviceConfig = {
      ProgramArguments = [
        "/opt/homebrew/bin/kanata"
        "--cfg"
        "/Users/tuliopaim/dotfiles/kanata/kanata.kbd"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/var/log/kanata.log";
      StandardErrorPath = "/var/log/kanata.err.log";
      ProcessType = "Interactive";
    };
  };

  homebrew.brews = [ "kanata" ];
}
