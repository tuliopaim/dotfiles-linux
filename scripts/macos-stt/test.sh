#!/bin/sh
# Smoke tests for toggle.ts. Everything external is stubbed: no microphone, no
# whisper model, no clipboard, and no simulated Cmd+V. Run with: sh test.sh
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

# Mimics whisper-cli: record the args it was given, then emit the -of JSON.
cat >"$TMP/whisper" <<'EOF'
#!/bin/sh
printf '%s\n' "$@" >"$MACOS_STT_TEST_ARGS"
while [ "$#" -gt 0 ]; do
  [ "$1" = -of ] && { shift; output=$1; }
  shift
done
cat >"$output.json" <<'JSON'
{"transcription":[
  {"offsets":{"from":0,"to":1000},"text":" First sentence."},
  {"offsets":{"from":3000,"to":4000},"text":" Second sentence."}
]}
JSON
EOF

chmod +x "$TMP/recorder" "$TMP/whisper"
touch "$TMP/model"

export MACOS_STT_STATE_DIR="$TMP/state"
export MACOS_STT_AUDIO_DIR="$TMP/audio"
export MACOS_STT_RECORD_CMD="$TMP/recorder {audio}"
export MACOS_STT_WHISPER_BIN="$TMP/whisper"
export MACOS_STT_WHISPER_MODEL="$TMP/model"
export MACOS_STT_TEST_ARGS="$TMP/whisper-args"
export MACOS_STT_STATUS_SCRIPT=/nonexistent
# Never reach for a real whisper-server during tests.
export MACOS_STT_USE_SERVER=0

# Stub the clipboard and paste so tests cannot type into the focused window.
mkdir -p "$TMP/bin"
printf '#!/bin/sh\ncat > %s/pasted.txt\n' "$TMP" >"$TMP/bin/pbcopy"
printf '#!/bin/sh\nexit 0\n' >"$TMP/bin/osascript"
chmod +x "$TMP/bin/pbcopy" "$TMP/bin/osascript"
sed -e "s#/usr/bin/pbcopy#$TMP/bin/pbcopy#" -e "s#/usr/bin/osascript#$TMP/bin/osascript#" \
  "$ROOT/toggle.ts" >"$TMP/toggle.ts"

toggle() { bun "$TMP/toggle.ts" "$@"; }

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

# --- toggle mode: press to start, press again to stop -----------------------
toggle >/dev/null 2>&1
sleep 0.1
output=$(toggle 2>&1 || true)
elapsed=$(printf '%s\n' "$output" | sed -n 's/.*\[timing\] stop recorder: \([0-9][0-9]*\)ms.*/\1/p')
[ -n "$elapsed" ] || fail "no stop-recorder timing reported"
[ "$elapsed" -lt 300 ] || fail "stop took ${elapsed}ms, expected < 300ms"

# Default language is English, and the punctuation-priming prompt is passed.
grep -qx -- '-l' "$MACOS_STT_TEST_ARGS" || fail "missing -l flag"
grep -qx -- 'en' "$MACOS_STT_TEST_ARGS" || fail "missing en language"
grep -qx -- '--prompt' "$MACOS_STT_TEST_ARGS" || fail "missing --prompt"
grep -qx -- '-sns' "$MACOS_STT_TEST_ARGS" || fail "missing -sns"

# Segments are joined into one block of text.
grep -qx 'First sentence. Second sentence.' "$TMP/pasted.txt" \
  || fail "unexpected transcript: $(cat "$TMP/pasted.txt")"

# --- state is cleaned up after a stop ---------------------------------------
[ ! -f "$TMP/state/macos-stt/state.json" ] || fail "stop left state behind"

# --- --cancel discards the audio without transcribing -----------------------
rm -f "$TMP/pasted.txt"
toggle >/dev/null 2>&1
[ -f "$TMP/state/macos-stt/state.json" ] || fail "start did not record state"
sleep 0.1
toggle --cancel >/dev/null 2>&1
[ ! -f "$TMP/pasted.txt" ] || fail "--cancel still pasted a transcript"
[ ! -f "$TMP/state/macos-stt/state.json" ] || fail "--cancel left state behind"

# --- a double press must never start two recorders --------------------------
# Two near-simultaneous invocations used to both see "nothing recording", both
# spawn a recorder, and the second overwrite the first's pid in state.json —
# orphaning that recorder, which then held the microphone until killed by hand.
toggle >/dev/null 2>&1 &
toggle >/dev/null 2>&1 &
wait
sleep 0.3
running=$(pgrep -f "$TMP/recorder" | wc -l | tr -d ' ')
[ "$running" -le 1 ] || fail "a double press started $running recorders"
toggle --cancel >/dev/null 2>&1 || true
pkill -f "$TMP/recorder" 2>/dev/null || true

# --- default input follows macOS instead of guessing from device names ------
cat >"$TMP/ffmpeg" <<'EOF'
#!/bin/sh
case " $* " in
  *" -list_devices "*)
    cat >&2 <<'DEVICES'
[AVFoundation indev @ 0x1] AVFoundation video devices:
[AVFoundation indev @ 0x1] [0] Capture screen 0
[AVFoundation indev @ 0x1] AVFoundation audio devices:
[AVFoundation indev @ 0x1] [0] G435 Wireless Gaming Headset
[AVFoundation indev @ 0x1] [1] Microsoft Teams Audio
DEVICES
    exit 1
    ;;
esac
trap 'exit 0' INT TERM
while :; do sleep 1; done
EOF
chmod +x "$TMP/ffmpeg"
unset MACOS_STT_RECORD_CMD
export MACOS_STT_FFMPEG_BIN="$TMP/ffmpeg"
output=$(toggle 2>&1)
printf '%s\n' "$output" | grep -q 'input=:default' \
  || fail "did not select the macOS default input: $output"
toggle --cancel >/dev/null 2>&1 || true
pkill -f "$TMP/ffmpeg" 2>/dev/null || true

# --- Portuguese selects the pt model language -------------------------------
export MACOS_STT_RECORD_CMD="$TMP/recorder {audio}"
toggle --portuguese >/dev/null 2>&1
sleep 0.1
toggle --portuguese >/dev/null 2>&1 || true
grep -qx -- 'pt' "$MACOS_STT_TEST_ARGS" || fail "missing pt language"

printf 'ok — stop recorder: %sms\n' "$elapsed"
