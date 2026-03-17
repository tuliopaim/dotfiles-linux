{ config, ... }:
let
  dotfilesDir = "${config.home.homeDirectory}/dotfiles";
in
{
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  xdg.configFile = {
    "nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/nvim";
    "opencode".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/opencode";
  };

  home.file = {
    ".ideavimrc".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/ideavim/.ideavimrc";
  };

  programs.home-manager.enable = true;
}
