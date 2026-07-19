# macOS STT — Speech-to-Text Toggle

A hotkey-activated speech-to-text workflow for macOS. Press a key to start
recording, press again to stop, transcribe with a local whisper.cpp model,
optionally clean the transcript with pi, and auto-paste the result.

## How it works

1. **Press hotkey** → starts recording via `afrecord` or `ffmpeg` (16 kHz WAV).
2. **Press hotkey again** → stops recording, runs `whisper-cli` to transcribe.
3. **Cleanup** (optional) → pipes the raw transcript through `pi` for spelling
   correction, punctuation, Portuguese→English translation, and light Markdown
   formatting (bullet/numbered lists, paragraphs) inferred from the dictation.
4. **Paste** → copies the final text to the clipboard and simulates ⌘V.

A menu-bar indicator shows the current state: **●** recording, **⏳** processing,
**✓** idle (auto-dismisses after 1.5 s).

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
# Homebrew
brew install whisper-cpp

# or Nix
# nix profile install nixpkgs#whisper-cpp
```

### 2. Download a model

```bash
mkdir -p ~/.local/share/whisper-cpp

# Small model (~465 MB) — good accuracy/speed balance
curl -L -o ~/.local/share/whisper-cpp/ggml-small.bin \
  https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin

# or Base model (~142 MB) — faster, slightly less accurate
# curl -L -o ~/.local/share/whisper-cpp/ggml-base.bin \
#   https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin
```

The script auto-detects the model at `~/.local/share/whisper-cpp/ggml-small.bin`
(or `ggml-base.bin`, `ggml-base.en.bin` as fallbacks).

### 3. (Optional) Install pi for AI transcript cleanup

```bash
# Nix
nix profile install nixpkgs#pi

# or Homebrew
brew install pi
```

The script searches for pi in common Nix/Homebrew paths. If it's not found,
transcripts are copied raw (no cleanup).

## Usage

### Via skhd (recommended)

Add to your `skhdrc`:

```conf
# Toggle STT recording
cmd + shift + alt - v : /etc/profiles/per-user/tuliopaim/bin/bun /Users/tuliopaim/dotfiles/scripts/macos-stt/toggle.ts

# Toggle STT recording (raw mode, no AI cleanup)
cmd + shift + alt - r : /etc/profiles/per-user/tuliopaim/bin/bun /Users/tuliopaim/dotfiles/scripts/macos-stt/toggle.ts --raw

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
| `--raw` | Skip AI cleanup, paste raw whisper transcript |
| `--cancel` | Cancel an active recording, delete its partial audio, and do not transcribe or paste |
| `--correct-stdin` | Read text from stdin, clean with pi, copy & paste |

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MACOS_STT_WHISPER_BIN` | *(auto-search)* | Path to `whisper-cli` binary |
| `MACOS_STT_WHISPER_MODEL` | *(auto-search)* | Path to ggml model file |
| `MACOS_STT_WHISPER_ARGS` | `""` | Extra args passed to whisper-cli |
| `MACOS_STT_PI_BIN` | *(auto-search)* | Path to `pi` binary |
| `MACOS_STT_PI_MODEL` | `opencode-go/deepseek-v4-flash` | Model used by pi for cleanup |
| `MACOS_STT_PI_THINKING` | `low` | Pi thinking level |
| `MACOS_STT_RAW` | `false` | Default to raw mode |
| `MACOS_STT_RECORD_CMD` | *(auto)* | Full recorder command template (`{audio}` is replaced) |
| `MACOS_STT_AFRECORD_BIN` | `/usr/bin/afrecord` | afrecord binary path |
| `MACOS_STT_AFRECORD_ARGS` | `-f WAVE -c 1 -r 16000` | afrecord args before the audio path |
| `MACOS_STT_FFMPEG_BIN` | *(auto-search)* | ffmpeg binary path |
| `MACOS_STT_FFMPEG_INPUT` | `:0` | ffmpeg avfoundation input device |
| `MACOS_STT_STATE_DIR` | `$TMPDIR` or `/tmp` | Parent directory for state files |
| `MACOS_STT_AUDIO_DIR` | *(state dir)* | Directory for recording files |
| `MACOS_STT_KEEP_AUDIO` | `false` | Keep audio files after successful transcription |
| `MACOS_STT_PASTE_DELAY_MS` | `150` | Delay before simulating ⌘V |
| `MACOS_STT_STATUS_IDLE_GRACE_SECONDS` | `1.5` | Seconds before menu-bar indicator auto-dismisses |

## Troubleshooting

### "No speech detected" / whisper returns `[BLANK_AUDIO]`

The default ffmpeg avfoundation input (`:0`) is often a virtual/silent audio
device. List available devices and pick a real microphone:

```bash
ffmpeg -f avfoundation -list_devices true -i ""
```

Then set the correct input:

```bash
export MACOS_STT_FFMPEG_INPUT=:1   # or whichever index your mic is
```

### "Missing whisper-cpp binary"

Install `whisper-cpp` or set `MACOS_STT_WHISPER_BIN` to the correct path.

### "Missing whisper model"

Download a ggml model (see [Setup step 2](#2-download-a-model)) or set
`MACOS_STT_WHISPER_MODEL` to point to an existing model file.

### No menu-bar indicator

The indicator is a Swift status-bar app (`status.swift`). Make sure
`/usr/bin/swift` is available (it is on any standard macOS).
