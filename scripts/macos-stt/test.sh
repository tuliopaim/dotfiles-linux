#!/bin/sh
# Smoke tests for toggle.ts. Everything external is stubbed: no microphone, no
# Parakeet model, no clipboard, and no simulated paste. Run with: sh test.sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT INT TERM

cat >"$TMP/recorder" <<'EOF'
#!/bin/sh
touch "$1"
[ -z "${STT_TEST_RECORDER_PIDS:-}" ] || printf '%s\n' "$$" >>"$STT_TEST_RECORDER_PIDS"
trap 'exit 0' INT TERM
while :; do sleep 1; done
EOF

# Mimics parakeet-cli: record its arguments, then emit a transcript.
cat >"$TMP/parakeet-cli" <<'EOF'
#!/bin/sh
printf '%s\n' "$@" >"$STT_TEST_ARGS"
echo "First sentence. Second sentence."
EOF

chmod +x "$TMP/recorder" "$TMP/parakeet-cli"
touch "$TMP/model"

export STT_STATE_DIR="$TMP/state"
export STT_AUDIO_DIR="$TMP/audio"
export STT_RECORD_CMD="$TMP/recorder {audio}"
export STT_PARAKEET_BIN="$TMP/parakeet-cli"
export STT_PARAKEET_MODEL="$TMP/model"
export STT_TEST_ARGS="$TMP/parakeet-args"
export STT_TEST_RECORDER_PIDS="$TMP/recorder-pids"
export STT_STATUS_SCRIPT=/nonexistent
# Never reach for a real parakeet-server during tests.
export STT_USE_SERVER=0

# Stub the clipboard and paste so tests cannot type into the focused window.
mkdir -p "$TMP/bin"
printf '#!/bin/sh\ncat > %s/pasted.txt\n' "$TMP" >"$TMP/bin/pbcopy"
printf '#!/bin/sh\nexit 0\n' >"$TMP/bin/osascript"
chmod +x "$TMP/bin/pbcopy" "$TMP/bin/osascript"
export STT_COPY_CMD="$TMP/bin/pbcopy"
export STT_PASTE_CMD="$TMP/bin/osascript"

toggle() { bun "$ROOT/toggle.ts" "$@"; }

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

# --- generic settings win, while the former macOS prefix still works --------
export MACOS_STT_COPY_CMD=/nonexistent
printf 'Generic setting' | toggle --correct-stdin --raw >/dev/null 2>&1
grep -qx 'Generic setting' "$TMP/pasted.txt" || fail "STT_COPY_CMD did not beat its legacy alias"
unset STT_COPY_CMD
export MACOS_STT_COPY_CMD="$TMP/bin/pbcopy"
printf 'Legacy setting' | toggle --correct-stdin --raw >/dev/null 2>&1
grep -qx 'Legacy setting' "$TMP/pasted.txt" || fail "legacy MACOS_STT_COPY_CMD was not accepted"
unset MACOS_STT_COPY_CMD
export STT_COPY_CMD="$TMP/bin/pbcopy"

# --- toggle mode: press to start, press again to stop -----------------------
toggle >/dev/null 2>&1
sleep 0.1
output=$(toggle 2>&1 || true)
elapsed=$(printf '%s\n' "$output" | sed -n 's/.*\[timing\] stop recorder: \([0-9][0-9]*\)ms.*/\1/p')
[ -n "$elapsed" ] || fail "no stop-recorder timing reported"
[ "$elapsed" -lt 300 ] || fail "stop took ${elapsed}ms, expected < 300ms"

# Parakeet receives its model and audio input.
grep -qx -- '--model' "$STT_TEST_ARGS" || fail "missing parakeet --model"
grep -qx -- '--input' "$STT_TEST_ARGS" || fail "missing parakeet --input"

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
: >"$STT_TEST_RECORDER_PIDS"
toggle >/dev/null 2>&1 &
toggle >/dev/null 2>&1 &
wait
sleep 0.3
running=0
while IFS= read -r pid; do
  if kill -0 "$pid" 2>/dev/null; then running=$((running + 1)); fi
done <"$STT_TEST_RECORDER_PIDS"
[ "$running" -le 1 ] || fail "a double press started $running recorders"
toggle --cancel >/dev/null 2>&1 || true

# --- default ffmpeg input follows the current platform -----------------------
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
unset STT_RECORD_CMD
export STT_FFMPEG_BIN="$TMP/ffmpeg"
export STT_AFRECORD_BIN="$TMP/recorder"
output=$(toggle 2>&1)
case $(uname -s) in
  Darwin) expected='ffmpeg avfoundation input=:default' ;;
  Linux) expected='ffmpeg pulse input=default' ;;
  *) expected='recording' ;;
esac
printf '%s\n' "$output" | grep -q "$expected" \
  || fail "did not select the platform default input: $output"
toggle --cancel >/dev/null 2>&1 || true
unset STT_AFRECORD_BIN

printf 'ok — stop recorder: %sms\n' "$elapsed"
