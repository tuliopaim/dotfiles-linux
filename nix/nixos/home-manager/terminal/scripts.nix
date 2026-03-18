{ pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellScriptBin "clone-wt" (builtins.readFile ../../../scripts/clone-wt))
    (pkgs.writeShellScriptBin "prune-wt" (builtins.readFile ../../../scripts/prune-wt))
    (pkgs.writeShellScriptBin "tmux-worktree" (builtins.readFile ../../../scripts/tmux-worktree))
    (pkgs.writeShellScriptBin "tmux-dotfiles" (builtins.readFile ../../../scripts/tmux-dotfiles))
    (pkgs.writeShellScriptBin "tmux-vault" (builtins.readFile ../../../scripts/tmux-vault))
    (pkgs.writeShellScriptBin "usersecrets" (builtins.readFile ../../../scripts/usersecrets))
    (pkgs.writeShellScriptBin "hyprshot" (builtins.readFile ../../../scripts/hyprshot))
  ];
}
