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

  # Work skills appear in claude-work, claude-personal and the shared discovery directory.
  config.home.file =
    skillLinks ".claude/skills" commonSkills
    // skillLinks ".claude-personal/skills" sharedSkills
    // skillLinks ".claude-work/skills" sharedSkills
    // skillLinks ".agents/skills" sharedSkills
    # Claude work only: it depends on tools that exist only in that profile.
    # Lives in the private submodule; Nix links the path without reading it.
    // lib.optionalAttrs config.dotfiles.workSkills.enable {
      ".claude-work/skills/work-services".source =
        config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/private/skills/work-services";
      ".claude-work/skills/health-scout".source =
        config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/private/skills/health-scout";
    };
}
