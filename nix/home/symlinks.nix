{ config, ... }:
let
  dotfilesDir = "${config.home.homeDirectory}/dotfiles";
in
{
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/nvim";
  xdg.configFile."opencode/opencode.json".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/opencode/opencode.json";
  xdg.configFile."opencode/tui.json".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/opencode/tui.json";
  xdg.configFile."opencode/skills".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/skills";
  xdg.configFile."karabiner/karabiner.json".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/karabiner/karabiner.json";
  xdg.configFile."kanata/kanata.kbd".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/kanata/kanata.kbd";

  home.file.".pi/agent/extensions".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/pi/agent/extensions";
  home.file.".pi/agent/skills".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/skills";
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
