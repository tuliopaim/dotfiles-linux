{ config, ... }:
let
  dotfilesDir = "${config.home.homeDirectory}/dotfiles";
in
{
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/nvim";
  xdg.configFile."opencode".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/opencode";

  home.file.".pi/agent/extensions".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/pi/agent/extensions";
  home.file.".ideavimrc".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/ideavim/.ideavimrc";

  home.sessionVariables = {
    EDITOR = "nvim";
    DOTNET_ROOT = "$HOME/.dotnet";
  };

  home.sessionPath = [
    "$HOME/.dotnet"
    "$HOME/.dotnet/tools"
  ];

  programs.home-manager.enable = true;
  programs.direnv.enable = true;
}
