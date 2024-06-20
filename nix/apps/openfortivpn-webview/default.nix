{ pkgs ? import <nixpkgs> { } }:

let
  appimage = pkgs.fetchurl {
    url = "https://github.com/gm-vm/openfortivpn-webview/releases/download/v1.2.0-electron/openfortivpn-webview-1.2.0.AppImage";
    sha256 = "1j6yf3gjh9hqw2j6q1il165jyyn0aylfjya2i2a3ln1y98bs7832";
  };
in
pkgs.mkShell {
  buildInputs = [
    pkgs.appimage-run
    pkgs.openfortivpn
    (pkgs.writeShellScriptBin "run-openfortivpn" ''
      #!/usr/bin/env bash

      echo "Using AppImage at: ${appimage}"
      
      appimage-run "${appimage}" vpn.emsbilling.com \
        | grep SVPNCOOKIE \
        | sudo openfortivpnv vpn.emsbilling.com \
          --trusted-cert=0a8e5703f0283e9d60ed495fe78eb221eef36841ca83046acf52586d73c54b7c \
          --cookie-on-stdin &
    '')
  ];
}

