{ pkgs, ... }:
{
  home.packages = with pkgs; [
    (pkgs.writeShellScriptBin "clone-wt" (builtins.readFile ../../../scripts/clone-wt))
    (pkgs.writeShellScriptBin "prune-wt" (builtins.readFile ../../../scripts/prune-wt))
    (pkgs.writeShellScriptBin "tmux-sessionizer" (builtins.readFile ../../../scripts/tmux-sessionizer))
    (pkgs.writeShellScriptBin "tmux-dotfiles" (builtins.readFile ../../../scripts/tmux-dotfiles))
    (pkgs.writeShellScriptBin "usersecrets" (builtins.readFile ../../../scripts/usersecrets))
  ];
}
