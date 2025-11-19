{ pkgs, outputs, ... }:
{
  environment.systemPackages =
    [
      pkgs.vim
      pkgs.neovim
      pkgs.ansible
      pkgs.mkalias
    ];

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    liberation_ttf
  ];

  nix.settings.experimental-features = "nix-command flakes";

  system.configurationRevision = outputs.rev or outputs.dirtyRev or null;

  system.stateVersion = 5;

  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.tuliopaim.home = "/Users/tuliopaim";
  home-manager.backupFileExtension = "backup";

  nix.enable = true;
  security.pam.services.sudo_local.touchIdAuth = false;

  system.primaryUser = "tuliopaim";
  system.defaults = {
    dock.autohide = true;
    dock.mru-spaces = false;
    finder.AppleShowAllExtensions = true;
    finder.FXPreferredViewStyle = "clmv";
    loginwindow.LoginwindowText = "tuliopaim";
    loginwindow.GuestEnabled = false;
    NSGlobalDomain.AppleInterfaceStyle = "Dark";
  };
}
