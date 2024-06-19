{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.appimage-run
    pkgs.openfortivpn
  ];

  shellHook = ''
      appimage-run openfortivpn-webview-1.2.0.AppImage vpn.emsbilling.com \
      | grep SVPNCOOKIE \
      | sudo openfortivpn vpn.emsbilling.com \
        --trusted-cert=0a8e5703f0283e9d60ed495fe78eb221eef36841ca83046acf52586d73c54b7c \
        --cookie-on-stdin &
  '';
}
