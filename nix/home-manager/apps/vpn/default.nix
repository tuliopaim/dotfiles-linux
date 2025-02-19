{ pkgs, ...}:
{
  home.packages = with pkgs; [
    (pkgs.writeShellScriptBin "connect-vpn" (builtins.readFile ./scripts/connect-vpn))
    (pkgs.writeShellScriptBin "disconnect-vpn" (builtins.readFile ./scripts/disconnect-vpn))
  ];
}
