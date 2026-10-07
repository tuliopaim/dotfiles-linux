{ config, lib, ... }:
let
  dotfilesDir = "${config.home.homeDirectory}/dotfiles";
  # One symlink per skill folder, not one for the whole directory. Claude Code
  # writes its own synced skills into <profile>/skills/synced, and a directory
  # symlink would put them in this repo.
  # Git-based flakes include tracked files only. Use a path: flake before staging.
  skillFolders = dir:
    lib.filterAttrs
      (name: type:
        type == "directory"
        && !lib.hasPrefix "." name
        && builtins.pathExists (../.. + "/${dir}/${name}/SKILL.md"))
      (builtins.readDir (../.. + "/${dir}"));
  collectSkills = dirs:
    lib.foldl'
      (skills: dir:
        let
          names = builtins.attrNames (skillFolders dir);
          duplicates = lib.intersectLists (builtins.attrNames skills) names;
        in
        if duplicates != [] then
          throw "Duplicate skill folder names in ${dir}: ${lib.concatStringsSep ", " duplicates}"
        else
          skills // lib.genAttrs names (_: dir))
      {}
      dirs;
  commonDirs = [ "skills/upstream/.agents/skills" "skills/local" ];
  commonSkills = collectSkills commonDirs;
  sharedSkills = collectSkills
    (commonDirs ++ lib.optional config.dotfiles.workSkills.enable "skills/work");
  skillLinks = target: skills:
    lib.mapAttrs'
      (name: dir: lib.nameValuePair "${target}/${name}" {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${dir}/${name}";
      })
      skills;
in
{
  options.dotfiles.workSkills.enable = lib.mkEnableOption "the skills in skills/work";

  # Work skills appear only in claude-work and the shared discovery directory.
  config.home.file =
    skillLinks ".claude/skills" commonSkills
    // skillLinks ".claude-personal/skills" commonSkills
    // skillLinks ".claude-work/skills" sharedSkills
    // skillLinks ".agents/skills" sharedSkills;
}
