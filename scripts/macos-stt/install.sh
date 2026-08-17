#!/bin/sh
# Install a warm transcription-server launchd agent — whisper or parakeet per
# MACOS_STT_BACKEND. Each backend gets its own agent, so both can run at once.
#
# Without it, every dictation reloads the model from disk, and the first run
# after a reboot also pays for Metal shader compilation (measured at ~8.6s
# versus ~0.8s warm for whisper). Keeping the model resident costs the RAM of
# the model file — roughly 600 MB for whisper large-v3-turbo.
#
# To remove an agent again:
#   launchctl bootout gui/$(id -u)/com.tuliopaim.macos-stt-server          # whisper
#   launchctl bootout gui/$(id -u)/com.tuliopaim.macos-stt-parakeet-server # parakeet
#   rm ~/Library/LaunchAgents/com.tuliopaim.macos-stt-*.plist
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
AGENT_DIR=$HOME/Library/LaunchAgents
LOG_DIR=${MACOS_STT_LOG_DIR:-$HOME/Library/Logs/macos-stt}
BUN=${MACOS_STT_BUN_BIN:-/etc/profiles/per-user/tuliopaim/bin/bun}

BACKEND=${MACOS_STT_BACKEND:-whisper}
if [ "$BACKEND" = parakeet ]; then
  LABEL=com.tuliopaim.macos-stt-parakeet-server
  SERVER_URL=${MACOS_STT_PARAKEET_SERVER_URL:-http://127.0.0.1:8911}
  LOG_SUFFIX=parakeet
else
  LABEL=com.tuliopaim.macos-stt-server
  SERVER_URL=${MACOS_STT_SERVER_URL:-http://127.0.0.1:8910}
  LOG_SUFFIX=server
fi
BACKEND_ENV="<key>MACOS_STT_BACKEND</key><string>$BACKEND</string>"

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
    $BACKEND_ENV
  </dict>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardErrorPath</key><string>$LOG_DIR/$LOG_SUFFIX.log</string>
  <key>StandardOutPath</key><string>$LOG_DIR/$LOG_SUFFIX.log</string>
</dict>
</plist>
EOF
echo "==> Wrote $plist"

# bootout is expected to fail the first time; the agent is not loaded yet.
launchctl bootout "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$plist"
echo "==> Loaded $LABEL"

cat <<EOF

Installed $BACKEND agent ($LABEL). Logs: $LOG_DIR/$LOG_SUFFIX.log

Check it is answering:
  curl -s -o /dev/null -w '%{http_code}\\n' $SERVER_URL/
EOF
