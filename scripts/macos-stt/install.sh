#!/bin/sh
# Install the warm whisper-server launchd agent.
#
# Without it, every dictation reloads the model from disk, and the first run
# after a reboot also pays for Metal shader compilation (measured at ~8.6s
# versus ~0.8s warm). Keeping the model resident costs the RAM of the model
# file — roughly 600 MB for large-v3-turbo.
#
# To remove it again:
#   launchctl bootout gui/$(id -u)/com.tuliopaim.macos-stt-server
#   rm ~/Library/LaunchAgents/com.tuliopaim.macos-stt-server.plist
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
AGENT_DIR=$HOME/Library/LaunchAgents
LOG_DIR=${MACOS_STT_LOG_DIR:-$HOME/Library/Logs/macos-stt}
LABEL=com.tuliopaim.macos-stt-server

BUN=${MACOS_STT_BUN_BIN:-/etc/profiles/per-user/tuliopaim/bin/bun}
SERVER_URL=${MACOS_STT_SERVER_URL:-http://127.0.0.1:8910}

mkdir -p "$AGENT_DIR" "$LOG_DIR"

plist=$AGENT_DIR/$LABEL.plist
cat >"$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$BUN</string>
    <string>$ROOT/toggle.ts</string>
    <string>--serve</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>MACOS_STT_SERVER_URL</key><string>$SERVER_URL</string>
  </dict>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardErrorPath</key><string>$LOG_DIR/server.log</string>
  <key>StandardOutPath</key><string>$LOG_DIR/server.log</string>
</dict>
</plist>
EOF
echo "==> Wrote $plist"

# bootout is expected to fail the first time; the agent is not loaded yet.
launchctl bootout "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$plist"
echo "==> Loaded $LABEL"

cat <<EOF

Installed. Logs: $LOG_DIR/server.log

Check it is answering:
  curl -s -o /dev/null -w '%{http_code}\\n' $SERVER_URL/
EOF
