#!/usr/bin/env bash
# Install Karabiner-DriverKit-VirtualHIDDevice standalone.
# kanata needs this driver but NOT the full Karabiner-Elements app.
# Bump VERSION to upgrade — check kanata's release notes for min version.
set -euo pipefail

VERSION="6.14.0"
URL="https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases/download/v${VERSION}/Karabiner-DriverKit-VirtualHIDDevice-${VERSION}.pkg"
MANAGER="/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager"

installed=$(/usr/sbin/pkgutil --pkg-info org.pqrs.Karabiner-DriverKit-VirtualHIDDevice 2>/dev/null | awk '/^version:/ {print $2}')
if [ "$installed" = "$VERSION" ]; then
  echo "[kanata-driver] v${VERSION} already installed"
else
  echo "[kanata-driver] installing v${VERSION} (was: ${installed:-none})"
  PKG=$(mktemp -t vhid).pkg
  trap 'rm -f "$PKG"' EXIT
  curl -fsSL "$URL" -o "$PKG"
  sudo /usr/sbin/installer -pkg "$PKG" -target /
fi

if [ -x "$MANAGER" ]; then
  echo "[kanata-driver] activating system extension"
  "$MANAGER" activate || true
else
  echo "[kanata-driver] WARNING: manager app not found at $MANAGER" >&2
fi

echo "[kanata-driver] done. If extension prompt appears, approve in System Settings → Login Items & Extensions → Driver Extensions."
