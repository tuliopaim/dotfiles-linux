# macOS STT — Speech-to-Text Toggle

A hotkey-activated speech-to-text workflow for macOS. Press a key to start
recording, press again to stop, transcribe with a local whisper.cpp model,
optionally clean the transcript with pi, and auto-paste the result.

## How it works

1. **Press hotkey** → starts recording via `afrecord` or `ffmpeg` (16 kHz WAV).
2. **Press hotkey again** → stops recording and transcribes:
   - first against a warm `whisper-server` holding the model in memory,
   - falling back to spawning `whisper-cli` if the server is not running.
3. **Cleanup** (opt-in with `--clean`) → pipes the English transcript through `pi`
   for spelling correction, punctuation, and light Markdown formatting
   (bullet/numbered lists, paragraphs) inferred from the dictation.
4. **Paste** → copies the final text to the clipboard and simulates ⌘V.

A menu-bar indicator shows the current state: **●** recording, **⏳** processing,
**✓** idle (auto-dismisses after 1.5 s).

> **Leave a beat before you speak.** The recorder needs roughly 600 ms to open
> the microphone (measured: 3.00 s of wall clock yields 2.43 s of audio), so
> anything said in the moment right after the hotkey is lost. Pressing the key
> and then starting to talk naturally covers this. It is also why hold-to-talk
> was tried and abandoned — see [Why there is no hold-to-talk](#why-there-is-no-hold-to-talk).

## Dependencies

| Tool | Purpose | Install |
|------|---------|---------|
| [`whisper.cpp`](https://github.com/ggerganov/whisper.cpp) (`whisper-cli`) | Local speech-to-text | `brew install whisper-cpp` or Nix |
| ggml model file | Whisper model weights | Download from Hugging Face (see below) |
| [pi](https://github.com/earendil-works/pi) | Optional AI transcript cleanup | Via Nix or Homebrew |
| `afrecord` or `ffmpeg` | Audio recording | Built-in macOS (`afrecord`) or `brew install ffmpeg` |

## Setup

### 1. Install whisper-cli (if not already present)

```bash
brew install whisper-cpp
# or: nix profile install nixpkgs#whisper-cpp
```

### 2. Download a model

```bash
mkdir -p ~/.local/share/whisper-cpp

# large-v3-turbo (~574 MB) — the default. Noticeably better punctuation,
# casing and proper nouns than small, and still faster than realtime on Apple
# Silicon.
curl -L -o ~/.local/share/whisper-cpp/ggml-large-v3-turbo-q5_0.bin \
  https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin
```

Models are auto-detected in this order: `ggml-large-v3-turbo-q5_0.bin`,
`ggml-large-v3-turbo.bin`, `ggml-small.bin`, `ggml-base.bin`.

### 3. (Optional) Install pi for AI transcript cleanup

```bash
nix profile install nixpkgs#pi   # or: brew install pi
```

The script searches for pi in common Nix/Homebrew paths. If it's not found,
transcripts are copied raw (no cleanup).

### 4. (Optional) Install the warm whisper-server

```bash
./install.sh
```

Installs a launchd agent (`com.tuliopaim.macos-stt-server`) that keeps the model
resident, so dictations do not reload it from disk each time. Worth about 0.3 s
per dictation in steady state, and much more on the first run after a reboot
(~8.6 s cold versus ~0.8 s warm, because of Metal shader compilation). It costs
the RAM of the model, roughly 600 MB.

Everything works without it — `toggle.ts` falls back to `whisper-cli`
automatically. To remove it:

```bash
launchctl bootout gui/$(id -u)/com.tuliopaim.macos-stt-server
rm ~/Library/LaunchAgents/com.tuliopaim.macos-stt-server.plist
```

## Usage

### Via skhd (recommended)

Add to your `skhdrc`:

```conf
# English transcription with Pi cleanup
cmd + shift + alt - v : /etc/profiles/per-user/tuliopaim/bin/bun /Users/tuliopaim/dotfiles/scripts/macos-stt/toggle.ts --clean

# Fast English transcription without Pi
cmd + shift + alt - r : /etc/profiles/per-user/tuliopaim/bin/bun /Users/tuliopaim/dotfiles/scripts/macos-stt/toggle.ts

# Fast Portuguese transcription without Pi
cmd + shift + alt - p : /etc/profiles/per-user/tuliopaim/bin/bun /Users/tuliopaim/dotfiles/scripts/macos-stt/toggle.ts --portuguese

# Cancel an active recording without transcribing it
cmd + shift + alt - space : /etc/profiles/per-user/tuliopaim/bin/bun /Users/tuliopaim/dotfiles/scripts/macos-stt/toggle.ts --cancel
```

### Direct invocation

```bash
bun ~/dotfiles/scripts/macos-stt/toggle.ts
```

### Options

| Flag | Description |
|------|-------------|
| `--help` | Show usage |
| `--raw` | Auto-detect the spoken language; skip AI cleanup |
| `--clean` | Clean the English transcript with Pi |
| `--portuguese` | Transcribe in Portuguese; skip AI cleanup |
| `--cancel` | Cancel an active recording, delete its partial audio, and do not transcribe or paste |
| `--correct-stdin` | Read text from stdin, clean with pi, copy & paste |
| `--serve` | Run `whisper-server` in the foreground (used by the launchd agent) |

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MACOS_STT_WHISPER_BIN` | *(auto-search)* | Path to `whisper-cli` binary |
| `MACOS_STT_WHISPER_MODEL` | *(auto-search)* | Path to ggml model file |
| `MACOS_STT_WHISPER_PROMPT` | *(punctuated sample)* | Initial prompt priming punctuation and casing |
| `MACOS_STT_WHISPER_ARGS` | `-l en`; `-l pt` with `--portuguese`; `-l auto` with `--raw` | Extra args passed to whisper-cli |
| `MACOS_STT_USE_SERVER` | `1` | Set to `0` to always spawn `whisper-cli` |
| `MACOS_STT_SERVER_URL` | `http://127.0.0.1:8910` | whisper-server base URL |
| `MACOS_STT_SERVER_ARGS` | *(none)* | Extra args for `--serve` |
| `MACOS_STT_WHISPER_SERVER_BIN` | *(auto-search)* | Path to `whisper-server` |
| `MACOS_STT_PI_BIN` | *(auto-search)* | Path to `pi` binary |
| `MACOS_STT_PI_MODEL` | `openai-codex/gpt-5.6-luna` | Model used by pi for cleanup |
| `MACOS_STT_PI_THINKING` | `off` | Pi thinking level |
| `MACOS_STT_RAW` | `false` | Default to raw mode |
| `MACOS_STT_CLEAN` | `false` | Enable slower AI cleanup by default |
| `MACOS_STT_RECORD_CMD` | *(auto)* | Full recorder command template (`{audio}` is replaced) |
| `MACOS_STT_AFRECORD_BIN` | `/usr/bin/afrecord` | afrecord binary path |
| `MACOS_STT_AFRECORD_ARGS` | `-f WAVE -c 1 -r 16000` | afrecord args before the audio path |
| `MACOS_STT_FFMPEG_BIN` | *(auto-search)* | ffmpeg binary path |
| `MACOS_STT_FFMPEG_INPUT` | `:default` | ffmpeg avfoundation input device |
| `MACOS_STT_STATE_DIR` | `~/.local/state` | Parent directory for state files |
| `MACOS_STT_MAX_RECORDING_SECONDS` | `1800` | Hard cap after which the recorder stops itself |
| `MACOS_STT_AUDIO_DIR` | *(state dir)* | Directory for recording files |
| `MACOS_STT_KEEP_AUDIO` | `false` | Keep audio files after successful transcription |
| `MACOS_STT_PASTE_DELAY_MS` | `150` | Delay before simulating ⌘V |
| `MACOS_STT_STATUS_IDLE_GRACE_SECONDS` | `1.5` | Seconds before menu-bar indicator auto-dismisses |

## Notes on output quality

Punctuation and casing come from the model, helped by an initial prompt
(`--prompt`) written in correctly punctuated prose — priming the decoder that
way biases it toward producing the same. `-sns` suppresses non-speech tokens
like `[BLANK_AUDIO]`.

**Paragraph breaks are deliberately not inferred from pauses.** whisper.cpp
gives no usable silence signal: without VAD, segment boundaries are padded so
each segment begins exactly where the previous one ended (a 2.5 s pause shows up
as a 0 ms gap), and with VAD enabled the silence is cut before decoding and the
segments merge outright. Recovering real pauses would need a separate
`whisper-vad-speech-segments` pass aligned back onto the transcript. Structure
is left to the `--clean` pass, which infers it from the wording.

VAD is still worth enabling if you pause a lot mid-dictation, since it skips
silence during decoding:

```bash
export MACOS_STT_WHISPER_ARGS="-l en --vad -vm $HOME/.local/share/whisper-cpp/ggml-silero-v5.1.2.bin"
```

(Model: `https://huggingface.co/ggml-org/whisper-vad/resolve/main/ggml-silero-v5.1.2.bin`.)

## Why there is no hold-to-talk

A Wispr Flow-style "hold ctrl+shift to dictate" mode was built and removed. It
worked mechanically — a listen-only `CGEventTap` daemon saw the chord correctly
on both the built-in keyboard and the Corne — but the audio was unusable.

Spawning a recorder per dictation costs roughly 600 ms before the microphone
produces samples, plus the hold threshold and interpreter startup: close to a
second. The press-then-speak toggle hides that behind human reaction time.
Hold-to-talk does not, so the opening of every sentence was lost and Whisper
returned hallucinations like `"Thank you."` on what was effectively silence.

Doing it properly requires keeping the audio device open continuously in a
resident process and capturing into a ring buffer with pre-roll, so a keypress
only marks a position in already-flowing audio. That means the microphone stays
open for as long as the daemon runs. Not worth it here.

## Testing

```bash
sh test.sh
```

Stubs the recorder, whisper, clipboard and paste — no microphone, no model, and
nothing typed into the focused window.

## Troubleshooting

### The first word or two is missing

Expected — see the note at the top. Pause briefly after pressing the hotkey.

### "No speech detected" / whisper returns `[BLANK_AUDIO]`

The ffmpeg avfoundation input may be a virtual/silent device. List devices and
pick a real microphone:

```bash
ffmpeg -f avfoundation -list_devices true -i ""
export MACOS_STT_FFMPEG_INPUT=:1
```

### A recorder is stuck holding the microphone

Check and clear:

```bash
pgrep -fl "ffmpeg.*avfoundation"
pkill -f "ffmpeg.*avfoundation"
```

This used to happen for two compounding reasons, both fixed here.

**What created an orphan: a race on the start path.** `main()` locked the stop
path but not the start path. Two near-simultaneous invocations — a double tap,
or skhd firing twice — would both read "nothing is recording", both spawn a
recorder, and the second `writeState()` would overwrite the first's pid. The
first recorder was then unreachable by any later hotkey press and ran until
killed by hand, holding the microphone open. Capture devices are effectively
exclusive, so other apps (Teams, Zoom) misbehave while that is true. A double
tap is easy to provoke, because the recorder takes ~600 ms to open the mic and
the hotkey feels unresponsive until it does.

**What made it unrecoverable: `$TMPDIR`.** State used to live there, and macOS
runs `com.apple.bsd.dirhelper` nightly at 03:35, deleting anything under
`/var/folders/.../T` untouched for three days. `state.json` is written once and
never touched again, so it aged out — taking with it any record of a still
running recorder, and unlinking the `.wav` while ffmpeg held it open. Disk space
for an unlinked-but-open file is not reclaimed and `ls` cannot show it. One
instance was found alive for 9 days having written 702 MB.

Three changes prevent recurrence: the start/stop decision is taken under a lock
(`decision.lock`) so concurrent invocations cannot both start; state lives in
`~/.local/state/macos-stt`, which nothing garbage-collects; and the recorder gets
a `-t` hard stop (`MACOS_STT_MAX_RECORDING_SECONDS`, default 30 minutes). On
each start, any recorder writing into the audio directory that the state file
does not know about is also reaped. `test.sh` covers the double-press case.

To check for orphaned open-but-deleted recordings:

```bash
lsof -c ffmpeg | grep -i 'recording-.*\.wav'
```

### "osascript is not allowed to send keystrokes"

The auto-paste needs Accessibility permission for whatever launches the script
(skhd). Grant it in **System Settings → Privacy & Security → Accessibility**.
The transcript is still on the clipboard, so ⌘V works meanwhile.

### "Missing whisper-cpp binary" / "Missing whisper model"

Install `whisper-cpp`, or set `MACOS_STT_WHISPER_BIN` /
`MACOS_STT_WHISPER_MODEL` to the correct paths.

### No menu-bar indicator

The indicator is a Swift status-bar app (`status.swift`) run through
`/usr/bin/swift`, which ships with macOS.
