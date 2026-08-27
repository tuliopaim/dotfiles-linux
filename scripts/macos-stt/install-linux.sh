#!/bin/sh
# Install the warm Parakeet server as a systemd user unit.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BUN=${STT_BUN_BIN:-${MACOS_STT_BUN_BIN:-$(command -v bun || true)}}
[ -n "$BUN" ] || { echo "bun not found; set STT_BUN_BIN" >&2; exit 1; }

UNIT=stt-parakeet-server

UNIT_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user
mkdir -p "$UNIT_DIR"
UNIT_PATH=$UNIT_DIR/$UNIT.service
ENV_PATH=$UNIT_DIR/$UNIT.env

cat >"$UNIT_PATH" <<EOF
[Unit]
Description=STT Parakeet transcription server
After=network.target

[Service]
Type=simple
EnvironmentFile=-$ENV_PATH
ExecStart="$BUN" "$ROOT/toggle.ts" --serve
Restart=on-failure
RestartSec=2

[Install]
WantedBy=default.target
EOF

# Keep model, binary, URL, and extra arguments across login sessions. Generic
# names win, but legacy names are imported too.
: >"$ENV_PATH"

append_setting() {
  name=$1
  legacy=MACOS_$name
  value=$(printenv "$name" 2>/dev/null || true)
  [ -n "$value" ] || value=$(printenv "$legacy" 2>/dev/null || true)
  [ -n "$value" ] || return 0
  escaped=$(printf '%s' "$value" | sed 's/\\/\\\\/g; s/"/\\"/g')
  printf '%s="%s"\n' "$name" "$escaped" >>"$ENV_PATH"
}

append_setting STT_SERVER_ARGS
append_setting STT_PARAKEET_SERVER_BIN
append_setting STT_PARAKEET_MODEL
append_setting STT_PARAKEET_SERVER_URL

# Remove the obsolete Whisper unit left by older installations.
systemctl --user disable --now stt-whisper-server.service >/dev/null 2>&1 || true
rm -f "$UNIT_DIR/stt-whisper-server.service" "$UNIT_DIR/stt-whisper-server.env"
systemctl --user daemon-reload
systemctl --user enable --now "$UNIT.service"
echo "Installed $UNIT. Server settings: $ENV_PATH"
echo "Check it with: systemctl --user status $UNIT"
