{ config, ... }:
let
  dotfilesDir = "${config.home.homeDirectory}/dotfiles";
in
{
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/nvim";
  # opencode: individual file symlinks, not xdg.configFile (which reifies the whole dir)
  home.file.".config/opencode/opencode.json".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/opencode/opencode.json";
  home.file.".config/opencode/tui.json".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/opencode/tui.json";
  home.file.".config/opencode/cli.json".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/opencode/cli.json";
  home.file.".config/opencode/commands".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/opencode/commands";
  xdg.configFile."kanata/kanata.kbd".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/kanata/kanata.kbd";
  # herdr: only the config file; the rest of ~/.config/herdr is runtime state (sockets, logs, session)
  home.file.".config/herdr/config.toml".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/herdr/config.toml";

  home.file.".pi/agent/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/pi/agent/settings.json";
  home.file.".ideavimrc".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/ideavim/.ideavimrc";

  home.file.".claude/skills".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/skills";
  # settings.json stays a real per-machine file: Claude Code rewrites it itself
  # (/model, /config, /statusline), and an atomic write would replace a symlink.
  home.file.".claude/statusline.sh".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/claude/statusline.sh";

  home.sessionVariables = {
    EDITOR = "nvim";
    DOTNET_ROOT = "$HOME/.dotnet";
    OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS = "true";
  };

  home.sessionPath = [
    "$HOME/.dotnet"
    "$HOME/.dotnet/tools"
  ];

  programs.home-manager.enable = true;
  programs.direnv.enable = true;
}
