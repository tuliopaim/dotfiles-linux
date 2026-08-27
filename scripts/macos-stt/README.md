# STT: desktop speech-to-text toggle

A hotkey-activated speech-to-text workflow for macOS and Linux. Press once to
record, press again to stop, transcribe locally with parakeet.cpp, optionally
clean the text with pi, then copy and paste it into the focused application.

## How it works

1. The first invocation records a mono 16 kHz WAV file.
2. The second invocation stops the recorder and sends the audio to a warm
   `parakeet-server`.
3. If the server is unavailable, the tool falls back to `parakeet-cli`.
4. `--clean` sends the transcript through pi for light copy editing.
5. The desktop adapter copies the result and simulates paste when supported.

On macOS, a menu-bar item shows recording and processing state. Linux runs
without a status indicator.

## Code layout

- `toggle.ts` owns state, locking, transcription, and cleanup.
- `desktop.ts` owns recording, clipboard delivery, auto-paste, and the macOS
  status indicator.
- `runtime.ts` resolves configuration and executables, then runs child
  processes with a predictable locale and `PATH`.

## Dependencies

| Tool | Purpose |
|------|---------|
| Bun | Runs the TypeScript entry point |
| `parakeet-cli` and optionally `parakeet-server` | Local transcription |
| Parakeet gguf model | Model weights |
| pi | Optional transcript cleanup |
| `afrecord`, FFmpeg, or `arecord` | Audio recording |
| Platform clipboard tools | Copy and automatic paste |

Linux clipboard tools:

- Wayland: `wl-copy`; optionally `wtype` for automatic paste
- X11: `xclip` or `xsel`; optionally `xdotool` for automatic paste

## Parakeet setup

Install `parakeet-cli` and `parakeet-server`, then place a model under
`~/.local/share/parakeet-cpp/`:

```bash
mkdir -p ~/.local/share/parakeet-cpp
curl -L -o ~/.local/share/parakeet-cpp/tdt-0.6b-v3-q8_0.gguf \
  https://huggingface.co/mudler/parakeet-cpp-gguf/resolve/main/tdt-0.6b-v3-q8_0.gguf
```

The tool searches for these models in order:

1. `tdt-0.6b-v3-q8_0.gguf`
2. `tdt-0.6b-v3-f16.gguf`
3. `parakeet-tdt-0.6b-v3-q8_0.gguf`
4. `tdt-0.6b-v2-q8_0.gguf`
5. `tdt_ctc-110m-f16.gguf`

Use `STT_PARAKEET_MODEL` if the model lives elsewhere.

## Warm server

Keeping Parakeet resident avoids loading the model for every dictation.

On macOS:

```bash
./install.sh
```

On Linux with systemd:

```bash
./install-linux.sh
```

Both installers remove obsolete Whisper background units left by earlier
versions.

## Usage

Run directly or bind the same command through skhd, desktop keyboard settings,
your Wayland compositor, or `sxhkd`:

```bash
bun /absolute/path/to/toggle.ts
```

Options:

| Flag | Description |
|------|-------------|
| `--raw` | Skip pi cleanup |
| `--clean` | Clean and translate mixed Portuguese/English into US English with pi |
| `--portuguese` | Skip cleanup; Parakeet auto-detects Portuguese |
| `--cancel` | Cancel recording and delete the partial audio |
| `--correct-stdin` | Clean, copy, and paste text read from stdin |
| `--serve` | Run `parakeet-server` in the foreground |

## Linux recording

FFmpeg defaults to the PulseAudio-compatible `default` source, which works with
most PipeWire desktops. To use ALSA directly:

```bash
export STT_FFMPEG_FORMAT=alsa
export STT_FFMPEG_INPUT=default
```

To copy without simulated paste:

```bash
export STT_AUTO_PASTE=0
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `STT_PARAKEET_BIN` | searched on `PATH` | `parakeet-cli` path |
| `STT_PARAKEET_SERVER_BIN` | searched on `PATH` | `parakeet-server` path |
| `STT_PARAKEET_MODEL` | auto-detected | Parakeet gguf model path |
| `STT_PARAKEET_SERVER_URL` | `http://127.0.0.1:8911` | Warm server URL |
| `STT_PARAKEET_TIMEOUT_MS` | `300000` | CLI timeout |
| `STT_USE_SERVER` | `1` | Set to `0` to always use the CLI |
| `STT_SERVER_ARGS` | none | Extra `parakeet-server` arguments |
| `STT_SERVER_TIMEOUT_MS` | `300000` | Server request timeout |
| `STT_PI_BIN` | searched on `PATH` | pi path |
| `STT_PI_MODEL` | `openai-codex/gpt-5.6-luna` | pi cleanup model |
| `STT_PI_THINKING` | `off` | pi thinking level |
| `STT_RAW` | `false` | Skip cleanup by default |
| `STT_CLEAN` | `false` | Enable cleanup by default |
| `STT_RECORD_CMD` | platform default | Recorder command; `{audio}` is replaced |
| `STT_COPY_CMD` | platform default | Clipboard command; text arrives on stdin |
| `STT_PASTE_CMD` | platform default | Paste command; use `none` for copy only |
| `STT_AUTO_PASTE` | `true` | Enable simulated paste |
| `STT_FFMPEG_BIN` | searched on `PATH` | FFmpeg path |
| `STT_FFMPEG_FORMAT` | `pulse` on Linux | Linux FFmpeg input format |
| `STT_FFMPEG_INPUT` | platform-dependent | Audio input device |
| `STT_STATE_DIR` | `$XDG_STATE_HOME` or `~/.local/state` | State parent directory |
| `STT_AUDIO_DIR` | state directory | Recording directory |
| `STT_MAX_RECORDING_SECONDS` | `1800` | Recording limit |
| `STT_KEEP_AUDIO` | `false` | Keep audio after successful delivery |
| `STT_PASTE_DELAY_MS` | `150` | Delay before automatic paste |

Former `MACOS_STT_*` names remain accepted. `STT_*` takes precedence.

## Testing

```bash
sh test.sh
```

The tests stub the recorder, Parakeet, clipboard, and paste commands.

## Troubleshooting

### No speech detected

On macOS, list AVFoundation devices and set the desired audio input:

```bash
ffmpeg -f avfoundation -list_devices true -i ""
export STT_FFMPEG_INPUT=:1
```

On Linux, check `STT_FFMPEG_FORMAT` and `STT_FFMPEG_INPUT` against your
PulseAudio, PipeWire, or ALSA setup.

### Automatic paste fails

The transcript remains on the clipboard. On macOS, grant Accessibility
permission to the hotkey launcher. On Linux, install the matching Wayland or
X11 paste tool, or set `STT_AUTO_PASTE=0`.

### A recorder is stuck

Run `toggle.ts --cancel`. The tool also reaps orphaned recorder processes on
the next start and caps FFmpeg recordings at 30 minutes by default.
