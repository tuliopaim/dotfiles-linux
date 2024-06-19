{ pkgs }:

pkgs.writeShellScriptBin "connect-vpn" ''
    cd ~/.dotfiles/tb/vpn

    nix-shell --command zsh
''

pkgs.writeShellScriptBin "disconnect-vpn" ''
    killall openfortivpn
''
