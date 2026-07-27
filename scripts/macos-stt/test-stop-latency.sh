#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT INT TERM

cat >"$TMP/recorder" <<'EOF'
#!/bin/sh
touch "$1"
trap 'exit 0' INT TERM
while :; do sleep 1; done
EOF

cat >"$TMP/whisper" <<'EOF'
#!/bin/sh
printf '%s\n' "$@" >"$MACOS_STT_TEST_ARGS"
while [ "$#" -gt 0 ]; do
  [ "$1" = -of ] && { shift; output=$1; }
  shift
done
printf '[BLANK_AUDIO]\n' >"$output.txt"
EOF

chmod +x "$TMP/recorder" "$TMP/whisper"
touch "$TMP/model"

export MACOS_STT_STATE_DIR="$TMP/state"
export MACOS_STT_AUDIO_DIR="$TMP/audio"
export MACOS_STT_RECORD_CMD="$TMP/recorder {audio}"
export MACOS_STT_WHISPER_BIN="$TMP/whisper"
export MACOS_STT_WHISPER_MODEL="$TMP/model"
export MACOS_STT_TEST_ARGS="$TMP/whisper-args"

bun "$ROOT/toggle.ts" >/dev/null 2>&1
sleep 0.1
output=$(bun "$ROOT/toggle.ts" 2>&1 || true)
elapsed=$(printf '%s\n' "$output" | sed -n 's/.*\[timing\] stop recorder: \([0-9][0-9]*\)ms.*/\1/p')

[ -n "$elapsed" ]
[ "$elapsed" -lt 300 ]
grep -qx -- '-l' "$MACOS_STT_TEST_ARGS"
grep -qx -- 'en' "$MACOS_STT_TEST_ARGS"

bun "$ROOT/toggle.ts" --portuguese >/dev/null 2>&1
sleep 0.1
bun "$ROOT/toggle.ts" --portuguese >/dev/null 2>&1 || true
grep -qx -- 'pt' "$MACOS_STT_TEST_ARGS"
printf 'stop recorder: %sms\n' "$elapsed"
