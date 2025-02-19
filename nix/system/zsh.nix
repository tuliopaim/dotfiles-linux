{ pkgs, ...}:
{
  # zsh for the system
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
}
