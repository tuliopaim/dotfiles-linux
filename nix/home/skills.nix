{ config, lib, ... }:
let
  dotfilesDir = "${config.home.homeDirectory}/dotfiles";
  # One symlink per skill folder, not one for the whole directory. Claude Code
  # writes its own synced skills into <profile>/skills/synced, and a directory
  # symlink would put them in this repo.
  # readDir only sees files git tracks: `git add` a new skill before rebuilding.
  skillLinks = target: dir:
    lib.mapAttrs'
      (name: _: lib.nameValuePair "${target}/${name}" {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${dir}/${name}";
      })
      (lib.filterAttrs (name: type: type == "directory" && !lib.hasPrefix "." name)
        (builtins.readDir (../.. + "/${dir}")));
in
{
  home.file =
    skillLinks ".claude/skills" "skills"
    // skillLinks ".claude-personal/skills" "skills"
    // skillLinks ".claude-work/skills" "skills"
    // skillLinks ".agents/skills" "skills";
}
