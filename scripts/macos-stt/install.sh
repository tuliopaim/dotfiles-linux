#!/bin/sh
# Install the warm Parakeet transcription server as a launchd agent.
#
# Without it, every dictation reloads the model from disk.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
AGENT_DIR=$HOME/Library/LaunchAgents
LOG_DIR=${STT_LOG_DIR:-${MACOS_STT_LOG_DIR:-$HOME/Library/Logs/macos-stt}}
BUN=${STT_BUN_BIN:-${MACOS_STT_BUN_BIN:-$(command -v bun || true)}}
[ -n "$BUN" ] || { echo "bun not found; set STT_BUN_BIN" >&2; exit 1; }

LABEL=com.tuliopaim.macos-stt-parakeet-server
SERVER_URL=${STT_PARAKEET_SERVER_URL:-${MACOS_STT_PARAKEET_SERVER_URL:-http://127.0.0.1:8911}}

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
    <key>STT_PARAKEET_SERVER_URL</key><string>$SERVER_URL</string>
  </dict>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardErrorPath</key><string>$LOG_DIR/parakeet.log</string>
  <key>StandardOutPath</key><string>$LOG_DIR/parakeet.log</string>
</dict>
</plist>
EOF
echo "==> Wrote $plist"

# Remove the obsolete Whisper agent left by older installations.
launchctl bootout "gui/$(id -u)/com.tuliopaim.macos-stt-server" >/dev/null 2>&1 || true
rm -f "$AGENT_DIR/com.tuliopaim.macos-stt-server.plist"

# bootout is expected to fail the first time; the Parakeet agent is not loaded yet.
launchctl bootout "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$plist"
echo "==> Loaded $LABEL"

cat <<EOF

Installed Parakeet agent ($LABEL). Logs: $LOG_DIR/parakeet.log

Check it is answering:
  curl -s -o /dev/null -w '%{http_code}\\n' $SERVER_URL/
EOF
