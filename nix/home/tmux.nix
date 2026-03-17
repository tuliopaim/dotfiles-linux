{ config, ... }:
let
  dotfilesDir = "${config.home.homeDirectory}/dotfiles";
in
{
  programs.tmux = {
    enable = true;
    mouse = true;
    extraConfig = ''
      source-file ${dotfilesDir}/tmux/.tmux.conf
    '';
  };
}
