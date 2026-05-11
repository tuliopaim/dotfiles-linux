#!/usr/bin/env bun
import { spawn, spawnSync } from "child_process";
import { existsSync, mkdirSync, readFileSync, rmSync, statSync, writeFileSync } from "fs";
import { homedir, tmpdir } from "os";
import { join } from "path";

/**
 * macOS speech-to-text toggle for skhd.
 *
 * Press once to start recording, press again to stop, transcribe with whisper-cpp,
 * optionally clean/translate with pi, copy with pbcopy, and paste with System Events.
 */

type State = {
  pid: number;
  audioPath: string;
  startedAt: string;
  logPath?: string;
};

type RunResult = {
  status: number | null;
  stdout: string;
  stderr: string;
  error?: Error;
};

const APP_TITLE = "macOS STT";
const HOME = homedir();
const BASE_ENV = {
  ...process.env,
  PATH: [
    "/opt/homebrew/bin",
    "/usr/local/bin",
    "/etc/profiles/per-user/tuliopaim/bin",
    join(HOME, ".nix-profile/bin"),
    "/run/current-system/sw/bin",
    "/usr/bin",
    "/bin",
    "/usr/sbin",
    "/sbin",
    process.env.PATH ?? "",
  ].filter(Boolean).join(":"),
};

const stateRoot = process.env.MACOS_STT_STATE_DIR || process.env.TMPDIR || tmpdir() || "/tmp";
const stateDir = join(stateRoot, "macos-stt-toggle");
const stateFile = join(stateDir, "state.json");
const lockDir = join(stateDir, "processing.lock");
const statusPidFile = join(stateDir, "status.pid");
const audioDir = process.env.MACOS_STT_AUDIO_DIR || stateDir;

function usage(): string {
  return `Usage: macos-stt/toggle.ts [--help] [--correct-stdin]

Toggle macOS speech-to-text recording. First invocation starts recording with
afrecord or ffmpeg/avfoundation; the next invocation stops recording, transcribes with
whisper-cpp, cleans/translates with pi in non-interactive print mode, copies the result to the clipboard, and pastes it.

Options:
  --help             Show this help.
  --correct-stdin    Read transcript text from stdin, clean it with pi if
                     available, copy it, and paste it. Does not record audio.

Environment:
  MACOS_STT_WHISPER_BIN     whisper-cpp binary path. Defaults search common
                            absolute paths such as /opt/homebrew/bin/whisper-cli.
  MACOS_STT_WHISPER_MODEL   ggml model path. Required unless a known local model
                            exists, e.g. ~/.local/share/whisper-cpp/ggml-small.bin.
  MACOS_STT_PI_BIN          pi binary path. Defaults search Nix/Homebrew paths.
  MACOS_STT_PI_MODEL        pi model (default: opencode-go/deepseek-v4-flash).
  MACOS_STT_PI_THINKING     pi thinking level (default: off).
  MACOS_STT_STATE_DIR       Parent for state files (default: TMPDIR or /tmp).
  MACOS_STT_AUDIO_DIR       Directory for recordings (default: state directory).
  MACOS_STT_KEEP_AUDIO      Set to 1/true/yes to keep audio after success.
  MACOS_STT_PASTE_DELAY_MS  Delay before Cmd+V (default: 150).
  MACOS_STT_RECORD_CMD      Full recorder command template. If it contains {audio},
                            that token is replaced; otherwise the audio path is appended.
  MACOS_STT_AFRECORD_BIN    afrecord path. Used when set or when /usr/bin/afrecord exists.
  MACOS_STT_AFRECORD_ARGS   afrecord args before the audio path
                            (default: -f WAVE -c 1 -r 16000).
  MACOS_STT_FFMPEG_BIN      ffmpeg path. Used as fallback recorder on macOS.
  MACOS_STT_FFMPEG_INPUT    ffmpeg avfoundation input (default: :0).

Model setup example (outside this repo):
  mkdir -p ~/.local/share/whisper-cpp
  curl -L -o ~/.local/share/whisper-cpp/ggml-small.bin \\
    https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin
  export MACOS_STT_WHISPER_MODEL=~/.local/share/whisper-cpp/ggml-small.bin

skhd should invoke Bun with absolute paths, for example:
  /etc/profiles/per-user/tuliopaim/bin/bun /Users/tuliopaim/dotfiles/scripts/macos-stt/toggle.ts
`;
}

function ensureDirs(): void {
  mkdirSync(stateDir, { recursive: true });
  mkdirSync(audioDir, { recursive: true });
}

function shellQuote(value: string): string {
  return `'${value.replace(/'/g, `'\\''`)}'`;
}

function appleString(value: string): string {
  return `"${value.replace(/\\/g, "\\\\").replace(/"/g, '\\"')}"`;
}

function notify(title: string, message: string): void {
  // Intentionally avoid macOS notification banners; the menu bar indicator shows state.
  console.error(`${title}: ${message}`);
}

function run(bin: string, args: string[], input?: string, timeoutMs = 120_000): RunResult {
  const result = spawnSync(bin, args, {
    input,
    encoding: "utf8",
    maxBuffer: 20 * 1024 * 1024,
    timeout: timeoutMs,
    env: BASE_ENV,
  });
  return {
    status: result.status,
    stdout: result.stdout ?? "",
    stderr: result.stderr ?? "",
    error: result.error,
  };
}

function executable(path: string | undefined): path is string {
  if (!path) return false;
  try {
    return existsSync(path) && statSync(path).isFile();
  } catch {
    return false;
  }
}

function firstExisting(paths: string[]): string | undefined {
  return paths.find(executable);
}

function resolveWhisperBin(): string | undefined {
  return firstExisting([
    process.env.MACOS_STT_WHISPER_BIN ?? "",
    "/opt/homebrew/bin/whisper-cli",
    "/opt/homebrew/bin/whisper-cpp",
    "/usr/local/bin/whisper-cli",
    "/usr/local/bin/whisper-cpp",
    "/etc/profiles/per-user/tuliopaim/bin/whisper-cli",
    "/etc/profiles/per-user/tuliopaim/bin/whisper-cpp",
    join(HOME, ".nix-profile/bin/whisper-cli"),
    join(HOME, ".nix-profile/bin/whisper-cpp"),
    "/run/current-system/sw/bin/whisper-cli",
    "/run/current-system/sw/bin/whisper-cpp",
  ]);
}

function resolveWhisperModel(): string | undefined {
  return firstExisting([
    process.env.MACOS_STT_WHISPER_MODEL ?? "",
    join(HOME, ".local/share/whisper-cpp/ggml-small.bin"),
    join(HOME, ".local/share/whisper-cpp/ggml-base.bin"),
    join(HOME, ".local/share/whisper-cpp/ggml-base.en.bin"),
    join(HOME, ".cache/whisper/ggml-small.bin"),
    join(HOME, ".cache/whisper/ggml-base.bin"),
    join(HOME, ".cache/whisper/ggml-base.en.bin"),
    join(HOME, ".cache/whisper-cpp/ggml-small.bin"),
    join(HOME, ".cache/whisper-cpp/ggml-base.bin"),
    join(HOME, ".cache/whisper-cpp/ggml-base.en.bin"),
  ]);
}

function resolvePiBin(): string | undefined {
  return firstExisting([
    process.env.MACOS_STT_PI_BIN ?? "",
    "/etc/profiles/per-user/tuliopaim/bin/pi",
    join(HOME, ".nix-profile/bin/pi"),
    "/run/current-system/sw/bin/pi",
    "/opt/homebrew/bin/pi",
    "/usr/local/bin/pi",
  ]);
}

function resolveFfmpegBin(): string | undefined {
  return firstExisting([
    process.env.MACOS_STT_FFMPEG_BIN ?? "",
    "/etc/profiles/per-user/tuliopaim/bin/ffmpeg",
    join(HOME, ".nix-profile/bin/ffmpeg"),
    "/run/current-system/sw/bin/ffmpeg",
    "/opt/homebrew/bin/ffmpeg",
    "/usr/local/bin/ffmpeg",
  ]);
}

function isPidAlive(pid: number): boolean {
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}

function signalProcessTree(pid: number, signal: NodeJS.Signals): void {
  for (const target of [-pid, pid]) {
    try {
      process.kill(target, signal);
    } catch {
      // Ignore already-exited processes and platforms that do not support groups.
    }
  }
}

function readState(): State | undefined {
  if (!existsSync(stateFile)) return undefined;
  try {
    const parsed = JSON.parse(readFileSync(stateFile, "utf8")) as State;
    if (typeof parsed.pid === "number" && parsed.audioPath && parsed.startedAt) return parsed;
  } catch (error) {
    console.error(`Invalid state file ${stateFile}: ${String(error)}`);
  }
  rmSync(stateFile, { force: true });
  return undefined;
}

function writeState(state: State): void {
  writeFileSync(stateFile, JSON.stringify(state, null, 2), { mode: 0o600 });
}

function removeState(): void {
  rmSync(stateFile, { force: true });
}

function processing(): boolean {
  return existsSync(lockDir);
}

function ensureStatusIndicator(): void {
  try {
    const existingPid = existsSync(statusPidFile) ? Number(readFileSync(statusPidFile, "utf8")) : NaN;
    if (Number.isFinite(existingPid) && isPidAlive(existingPid)) return;

    const script = process.env.MACOS_STT_STATUS_SCRIPT || join(import.meta.dir, "status.swift");
    if (!executable(script)) return;

    const child = spawn("/usr/bin/swift", [script, stateFile, lockDir], {
      detached: true,
      stdio: ["ignore", "ignore", "ignore"],
      env: BASE_ENV,
    });
    child.unref();
    if (child.pid) writeFileSync(statusPidFile, String(child.pid), { mode: 0o600 });
  } catch (error) {
    console.error(`Failed to start status indicator: ${String(error)}`);
  }
}

async function withLock<T>(fn: () => Promise<T>): Promise<T | undefined> {
  ensureDirs();
  try {
    mkdirSync(lockDir);
  } catch {
    notify(APP_TITLE, "Already processing a recording; please wait.");
    console.error(`Lock exists: ${lockDir}`);
    return undefined;
  }
  try {
    return await fn();
  } finally {
    rmSync(lockDir, { recursive: true, force: true });
  }
}

function timestamp(): string {
  return new Date().toISOString().replace(/[:.]/g, "-");
}

function formatDuration(ms: number): string {
  if (!Number.isFinite(ms)) return "unknown";
  if (ms < 1000) return `${Math.round(ms)}ms`;
  return `${(ms / 1000).toFixed(2)}s`;
}

function logTiming(label: string, startedAtMs: number): void {
  console.error(`[timing] ${label}: ${formatDuration(Date.now() - startedAtMs)}`);
}

function splitArgs(value: string): string[] {
  const matches = value.match(/(?:[^\s"']+|"[^"]*"|'[^']*')+/g) ?? [];
  return matches.map((part) => part.replace(/^(['"])(.*)\1$/, "$2"));
}

function startRecording(): void {
  ensureDirs();
  const audioPath = join(audioDir, `recording-${timestamp()}.wav`);
  const logPath = join(stateDir, `recording-${timestamp()}.log`);

  let command: string;
  let args: string[];
  if (process.env.MACOS_STT_RECORD_CMD) {
    const template = process.env.MACOS_STT_RECORD_CMD.includes("{audio}")
      ? process.env.MACOS_STT_RECORD_CMD.replaceAll("{audio}", shellQuote(audioPath))
      : `${process.env.MACOS_STT_RECORD_CMD} ${shellQuote(audioPath)}`;
    command = "/bin/sh";
    args = ["-lc", template];
  } else if (process.env.MACOS_STT_AFRECORD_BIN || executable("/usr/bin/afrecord")) {
    command = process.env.MACOS_STT_AFRECORD_BIN || "/usr/bin/afrecord";
    args = [...splitArgs(process.env.MACOS_STT_AFRECORD_ARGS || "-f WAVE -c 1 -r 16000"), audioPath];
  } else {
    const ffmpeg = resolveFfmpegBin();
    command = ffmpeg || "/usr/bin/afrecord";
    args = ffmpeg
      ? ["-hide_banner", "-loglevel", "error", "-f", "avfoundation", "-i", process.env.MACOS_STT_FFMPEG_INPUT || ":0", "-ac", "1", "-ar", "16000", "-y", audioPath]
      : [...splitArgs(process.env.MACOS_STT_AFRECORD_ARGS || "-f WAVE -c 1 -r 16000"), audioPath];
  }

  if (command !== "/bin/sh" && !executable(command)) {
    notify(APP_TITLE, `Recorder not found: ${command}`);
    process.exitCode = 1;
    return;
  }

  const child = spawn(command, args, {
    detached: true,
    stdio: ["ignore", "ignore", "ignore"],
    env: BASE_ENV,
  });
  child.unref();
  writeState({ pid: child.pid ?? -1, audioPath, startedAt: new Date().toISOString(), logPath });
  ensureStatusIndicator();
  notify(APP_TITLE, "Recording started. Press the hotkey again to transcribe.");
  console.error(`Recording started: pid=${child.pid} audio=${audioPath}`);
}

async function stopRecording(state: State): Promise<void> {
  const stopStartedAtMs = Date.now();
  const recordingStartedAtMs = Date.parse(state.startedAt);
  removeState();
  if (isPidAlive(state.pid)) {
    signalProcessTree(state.pid, "SIGINT");
  }
  await sleep(700);
  if (isPidAlive(state.pid)) {
    signalProcessTree(state.pid, "SIGTERM");
    await sleep(500);
  }
  if (isPidAlive(state.pid)) {
    signalProcessTree(state.pid, "SIGKILL");
    await sleep(200);
  }
  logTiming("stop recorder", stopStartedAtMs);
  if (Number.isFinite(recordingStartedAtMs)) {
    console.error(`[timing] recorded audio: ${formatDuration(Date.now() - recordingStartedAtMs)}`);
  }
  ensureStatusIndicator();
  notify(APP_TITLE, "Processing recording…");
  console.error(`Processing audio: ${state.audioPath}`);
  await processAudio(state.audioPath);
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function transcribe(audioPath: string): string | undefined {
  const startedAtMs = Date.now();
  const whisper = resolveWhisperBin();
  const model = resolveWhisperModel();
  if (!whisper || !model) {
    const missing = !whisper ? "whisper-cpp binary" : "whisper model";
    notify(APP_TITLE, `Missing ${missing}; audio left at ${audioPath}`);
    console.error(`Missing ${missing}. Install/rebuild whisper-cpp and set/download MACOS_STT_WHISPER_MODEL. Audio: ${audioPath}`);
    return undefined;
  }

  const outputBase = join(stateDir, `whisper-${timestamp()}`);
  const extraArgs = splitArgs(process.env.MACOS_STT_WHISPER_ARGS || "");
  const args = ["-m", model, "-f", audioPath, "-nt", "-otxt", "-of", outputBase, ...extraArgs];
  const result = run(whisper, args, undefined, Number(process.env.MACOS_STT_WHISPER_TIMEOUT_MS || 300_000));
  logTiming("whisper transcription", startedAtMs);
  const outputTextPath = `${outputBase}.txt`;
  const fileText = existsSync(outputTextPath) ? readFileSync(outputTextPath, "utf8") : "";
  const transcript = normalizeTranscript(fileText || result.stdout);

  if (result.status !== 0 || !transcript) {
    notify(APP_TITLE, `Transcription failed; audio left at ${audioPath}`);
    console.error(`whisper failed with status ${result.status}`);
    if (result.stderr.trim()) console.error(result.stderr.trim());
    if (result.stdout.trim()) console.error(result.stdout.trim());
    return undefined;
  }

  rmSync(outputTextPath, { force: true });
  return transcript;
}

function normalizeTranscript(text: string): string {
  return text
    .split(/\r?\n/)
    .map((line) => line.replace(/^\s*\[[^\]]+\]\s*/g, "").trim())
    .filter(Boolean)
    .join(" ")
    .replace(/\s+/g, " ")
    .trim();
}

function correctionPrompt(raw: string): string {
  return `You are cleaning a speech-to-text transcript. Translate Portuguese or mixed Portuguese/English into natural US English. Fix speech recognition mistakes, spelling, punctuation, capitalization, and grammar. Preserve code, commands, URLs, product names, file paths, and proper names exactly when possible. Return only the final cleaned text, with no markdown, labels, explanations, or quotes.\n\nTranscript:\n${raw}\n`;
}

function previewText(text: string, maxLength = 1000): string {
  const normalized = text.replace(/\s+/g, " ").trim();
  return normalized.length > maxLength ? `${normalized.slice(0, maxLength)}…` : normalized;
}

function cleanWithPi(raw: string): string {
  const startedAtMs = Date.now();
  const pi = resolvePiBin();
  if (!pi) {
    notify(APP_TITLE, "pi not found; using raw transcript.");
    console.error("pi not found; set MACOS_STT_PI_BIN to enable cleanup.");
    return raw;
  }

  const model = process.env.MACOS_STT_PI_MODEL || "opencode-go/deepseek-v4-flash";
  const thinking = process.env.MACOS_STT_PI_THINKING || "off";
  console.error(`[pi] before cleanup: model=${model} thinking=${thinking} chars=${raw.length}`);
  console.error(`[pi] raw transcript: ${previewText(raw)}`);
  const result = run(pi, ["--model", model, "--thinking", thinking, "--no-tools", "--no-session", "--print"], correctionPrompt(raw), Number(process.env.MACOS_STT_PI_TIMEOUT_MS || 120_000));
  logTiming("pi cleanup", startedAtMs);
  const cleaned = result.stdout.trim();
  console.error(`[pi] after cleanup: status=${result.status} chars=${cleaned.length}`);
  if (cleaned) console.error(`[pi] cleaned transcript: ${previewText(cleaned)}`);
  if (result.status !== 0 || !cleaned) {
    notify(APP_TITLE, "pi cleanup failed; using raw transcript.");
    console.error(`pi failed with status ${result.status}`);
    if (result.stderr.trim()) console.error(result.stderr.trim());
    return raw;
  }
  return cleaned;
}

function copyAndPaste(text: string): void {
  const copyStartedAtMs = Date.now();
  const copy = run("/usr/bin/pbcopy", [], text, 10_000);
  logTiming("clipboard copy", copyStartedAtMs);
  if (copy.status !== 0) {
    notify(APP_TITLE, "Failed to copy transcript to clipboard.");
    console.error(copy.stderr.trim() || copy.error?.message || "pbcopy failed");
    process.exitCode = 1;
    return;
  }

  const delay = Number(process.env.MACOS_STT_PASTE_DELAY_MS || 150);
  const pasteScript = 'tell application "System Events" to keystroke "v" using command down';
  setTimeout(() => {
    const pasteStartedAtMs = Date.now();
    const paste = run("/usr/bin/osascript", ["-e", pasteScript], undefined, 10_000);
    logTiming("paste", pasteStartedAtMs);
    if (paste.status !== 0) {
      notify(APP_TITLE, "Transcript copied. Automatic paste failed; paste manually with Cmd+V.");
      console.error(paste.stderr.trim() || paste.error?.message || "osascript paste failed");
      return;
    }
    notify(APP_TITLE, "Transcript pasted.");
  }, Number.isFinite(delay) ? delay : 150);
}

async function processAudio(audioPath: string): Promise<void> {
  const totalStartedAtMs = Date.now();
  if (!existsSync(audioPath)) {
    notify(APP_TITLE, `Audio file not found: ${audioPath}`);
    process.exitCode = 1;
    return;
  }

  const transcript = transcribe(audioPath);
  if (!transcript) {
    process.exitCode = 1;
    return;
  }

  const finalText = cleanWithPi(transcript);
  copyAndPaste(finalText);

  if (!/^(1|true|yes)$/i.test(process.env.MACOS_STT_KEEP_AUDIO || "")) {
    rmSync(audioPath, { force: true });
  }

  logTiming("total processing", totalStartedAtMs);
}

async function correctStdin(): Promise<void> {
  const input = readFileSync(0, "utf8").trim();
  if (!input) {
    console.error("No stdin transcript provided.");
    process.exitCode = 1;
    return;
  }
  const finalText = cleanWithPi(input);
  copyAndPaste(finalText);
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  if (args.includes("--help") || args.includes("-h")) {
    process.stdout.write(usage());
    return;
  }
  if (args.includes("--correct-stdin")) {
    await correctStdin();
    return;
  }

  ensureDirs();
  const state = readState();
  if (!state) {
    if (processing()) {
      notify(APP_TITLE, "Already processing a recording; please wait.");
      console.error(`Lock exists: ${lockDir}`);
      return;
    }
    startRecording();
    return;
  }
  if (!isPidAlive(state.pid)) {
    console.error(`Removing stale state for dead pid ${state.pid}`);
    removeState();
    startRecording();
    return;
  }
  await withLock(() => stopRecording(state));
}

main().catch((error) => {
  notify(APP_TITLE, `Unexpected error: ${error instanceof Error ? error.message : String(error)}`);
  console.error(error);
  process.exitCode = 1;
});
