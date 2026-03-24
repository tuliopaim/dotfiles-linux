{ pkgs ? import <nixpkgs> { } }:

let
  openfortivpn-webview = pkgs.fetchurl {
    url = "https://github.com/gm-vm/openfortivpn-webview/releases/download/v1.2.0-electron/openfortivpn-webview-1.2.0.AppImage";
    sha256 = "1j6yf3gjh9hqw2j6q1il165jyyn0aylfjya2i2a3ln1y98bs7832";
  };
in
pkgs.mkShell {
  buildInputs = [
    pkgs.appimage-run
    pkgs.openfortivpn
  ];

  shellHook = ''
    appimage-run ${openfortivpn-webview} vpn.emsbilling.com \
        | grep SVPNCOOKIE \
        | sudo openfortivpn vpn.emsbilling.com \
        --trusted-cert=6fa8089ba148f8dd65720bdaa62dc7a52e6ab9b135661fddfe6dbacd7f294ddb \
        --cookie-on-stdin &
  '';
}
