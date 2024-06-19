{ pkgs }:
{
  connect = pkgs.writeShellScriptBin "connect-vpn" ''
    cd /home/tuliopaim/.dotfiles/tb/vpn
    nix-shell --command zsh
  '';

  disconnect = pkgs.writeShellScriptBin "disconnect-vpn" ''
    sudo killall openfortivpn
  '';
}
