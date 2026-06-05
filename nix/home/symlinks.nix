{ config, ... }:
let
  dotfilesDir = "${config.home.homeDirectory}/dotfiles";
in
{
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/nvim";
  # opencode: individual file symlinks, not xdg.configFile (which reifies the whole dir)
  home.file.".config/opencode/opencode.json".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/opencode/opencode.json";
  home.file.".config/opencode/tui.json".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/opencode/tui.json";
  home.file.".config/opencode/oh-my-opencode-slim.json".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/opencode/oh-my-opencode-slim.json";
  home.file.".config/opencode/skills".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/skills";
  xdg.configFile."kanata/kanata.kbd".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/kanata/kanata.kbd";
  # herdr: only the config file; the rest of ~/.config/herdr is runtime state (sockets, logs, session)
  home.file.".config/herdr/config.toml".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/herdr/config.toml";

  home.file.".pi/agent/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/pi/agent/settings.json";
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
