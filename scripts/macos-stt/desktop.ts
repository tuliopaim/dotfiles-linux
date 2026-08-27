import { spawn } from "child_process";
import { readFileSync, writeFileSync } from "fs";
import { join } from "path";
import { CHILD_ENV, existingFile, findExecutable, run, setting, splitArgs } from "./runtime";

type Command = {
  bin: string;
  args: string[];
  input?: string;
};

export type RecorderStart =
  | { pid: number; description: string }
  | { error: string };

export type DeliveryResult = {
  copied: boolean;
  pasted: boolean;
  pasteAttempted: boolean;
  error?: string;
};

export class DesktopIntegration {
  constructor(
    private readonly stateFile: string,
    private readonly lockDir: string,
    private readonly statusPidFile: string,
  ) {}

  startRecorder(audioPath: string, maxSeconds: number): RecorderStart {
    const command = this.recorderCommand(audioPath, maxSeconds);
    if (!command) {
      return {
        error: process.platform === "linux"
          ? "No recorder found. Install ffmpeg or arecord, or set STT_RECORD_CMD."
          : "No recorder found. Install ffmpeg or set STT_RECORD_CMD.",
      };
    }

    const child = spawn(command.bin, command.args, {
      detached: true,
      stdio: ["ignore", "ignore", "ignore"],
      env: CHILD_ENV,
    });
    child.unref();
    child.on("error", (error) => console.error(`Recorder failed to start: ${error.message}`));
    if (!child.pid) return { error: `Recorder failed to start: ${command.bin}` };
    return { pid: child.pid, description: `${command.bin} ${command.args.join(" ")}` };
  }

  showStatus(): void {
    if (process.platform !== "darwin") return;

    try {
      const existingPid = this.readPid(this.statusPidFile);
      if (existingPid !== undefined && this.isPidAlive(existingPid)) return;

      const script = setting("STATUS_SCRIPT") || join(import.meta.dir, "status.swift");
      if (!existingFile(script)) return;
      const swift = findExecutable([setting("SWIFT_BIN"), "swift", "/usr/bin/swift"]);
      if (!swift) return;

      const child = spawn(swift, [script, this.stateFile, this.lockDir], {
        detached: true,
        stdio: ["ignore", "ignore", "ignore"],
        env: CHILD_ENV,
      });
      child.unref();
      child.on("error", (error) => console.error(`Status indicator failed to start: ${error.message}`));
      if (child.pid) writeFileSync(this.statusPidFile, String(child.pid), { mode: 0o600 });
    } catch (error) {
      console.error(`Failed to start status indicator: ${String(error)}`);
    }
  }

  async deliverText(text: string): Promise<DeliveryResult> {
    const copy = this.copyCommand(text);
    if (!copy) {
      return { copied: false, pasted: false, pasteAttempted: false, error: this.clipboardHelp() };
    }

    const copyStartedAt = Date.now();
    const copyResult = run(copy.bin, copy.args, copy.input, 10_000);
    this.logTiming("clipboard copy", copyStartedAt);
    if (copyResult.status !== 0) {
      return {
        copied: false,
        pasted: false,
        pasteAttempted: false,
        error: copyResult.stderr.trim() || copyResult.error?.message || "clipboard command failed",
      };
    }

    if (/^(0|false|no)$/i.test(setting("AUTO_PASTE") || "1") || setting("PASTE_CMD") === "none") {
      return { copied: true, pasted: false, pasteAttempted: false };
    }

    const paste = this.pasteCommand();
    if (!paste) return { copied: true, pasted: false, pasteAttempted: false };

    const delay = Number(setting("PASTE_DELAY_MS") || 150);
    await this.sleep(Number.isFinite(delay) ? Math.max(0, delay) : 150);
    const pasteStartedAt = Date.now();
    const pasteResult = run(paste.bin, paste.args, paste.input, 10_000);
    this.logTiming("paste", pasteStartedAt);
    if (pasteResult.status !== 0) {
      return {
        copied: true,
        pasted: false,
        pasteAttempted: true,
        error: pasteResult.stderr.trim() || pasteResult.error?.message || "paste command failed",
      };
    }
    return { copied: true, pasted: true, pasteAttempted: true };
  }

  private recorderCommand(audioPath: string, maxSeconds: number): Command | undefined {
    const custom = setting("RECORD_CMD");
    if (custom) {
      const template = custom.includes("{audio}")
        ? custom.replaceAll("{audio}", this.shellQuote(audioPath))
        : `${custom} ${this.shellQuote(audioPath)}`;
      const shell = findExecutable(["sh", "/bin/sh"]);
      return shell ? { bin: shell, args: ["-lc", template] } : undefined;
    }

    if (process.platform === "darwin") return this.macRecorder(audioPath, maxSeconds);
    if (process.platform === "linux") return this.linuxRecorder(audioPath, maxSeconds);
    return undefined;
  }

  private macRecorder(audioPath: string, maxSeconds: number): Command | undefined {
    // An explicit FFmpeg setting must beat auto-detected afrecord so callers can
    // select an AVFoundation device. Without an override, retain the existing
    // preference for macOS's built-in recorder.
    const configuredFfmpeg = setting("FFMPEG_BIN");
    if (configuredFfmpeg) {
      const ffmpeg = findExecutable([configuredFfmpeg]);
      if (ffmpeg) return this.ffmpegRecorder(ffmpeg, "avfoundation", setting("FFMPEG_INPUT") || ":default", audioPath, maxSeconds);
    }

    const afrecord = findExecutable([setting("AFRECORD_BIN"), "afrecord", "/usr/bin/afrecord"]);
    if (afrecord) {
      return {
        bin: afrecord,
        args: [...splitArgs(setting("AFRECORD_ARGS") || "-f WAVE -c 1 -r 16000"), audioPath],
      };
    }

    const ffmpeg = findExecutable([setting("FFMPEG_BIN"), "ffmpeg"]);
    if (!ffmpeg) return undefined;
    const input = setting("FFMPEG_INPUT") || ":default";
    return this.ffmpegRecorder(ffmpeg, "avfoundation", input, audioPath, maxSeconds);
  }

  private linuxRecorder(audioPath: string, maxSeconds: number): Command | undefined {
    const ffmpeg = findExecutable([setting("FFMPEG_BIN"), "ffmpeg"]);
    if (ffmpeg) {
      const format = setting("FFMPEG_FORMAT") || "pulse";
      const input = setting("FFMPEG_INPUT") || "default";
      return this.ffmpegRecorder(ffmpeg, format, input, audioPath, maxSeconds);
    }

    const arecord = findExecutable([setting("ARECORD_BIN"), "arecord"]);
    if (!arecord) return undefined;
    return {
      bin: arecord,
      args: ["-q", "-f", "S16_LE", "-c", "1", "-r", "16000", "-d", String(Math.ceil(maxSeconds)), audioPath],
    };
  }

  private ffmpegRecorder(ffmpeg: string, format: string, input: string, audioPath: string, maxSeconds: number): Command {
    console.error(`[recording] ffmpeg ${format} input=${input}`);
    return {
      bin: ffmpeg,
      args: ["-hide_banner", "-loglevel", "error", "-f", format, "-i", input,
        "-ac", "1", "-ar", "16000", "-t", String(maxSeconds), "-y", audioPath],
    };
  }

  private copyCommand(text: string): Command | undefined {
    const custom = setting("COPY_CMD");
    if (custom) return this.shellCommand(custom, text);

    if (process.platform === "darwin") {
      const pbcopy = findExecutable(["pbcopy", "/usr/bin/pbcopy"]);
      return pbcopy ? { bin: pbcopy, args: [], input: text } : undefined;
    }

    if (process.platform === "linux") {
      if (process.env.WAYLAND_DISPLAY) {
        const wlCopy = findExecutable(["wl-copy"]);
        if (wlCopy) return { bin: wlCopy, args: [], input: text };
      }
      const xclip = findExecutable(["xclip"]);
      if (xclip) return { bin: xclip, args: ["-selection", "clipboard"], input: text };
      const xsel = findExecutable(["xsel"]);
      if (xsel) return { bin: xsel, args: ["--clipboard", "--input"], input: text };
      const wlCopy = findExecutable(["wl-copy"]);
      if (wlCopy) return { bin: wlCopy, args: [], input: text };
    }
    return undefined;
  }

  private pasteCommand(): Command | undefined {
    const custom = setting("PASTE_CMD");
    if (custom) return this.shellCommand(custom);

    if (process.platform === "darwin") {
      const osascript = findExecutable(["osascript", "/usr/bin/osascript"]);
      return osascript
        ? { bin: osascript, args: ["-e", 'tell application "System Events" to keystroke "v" using command down'] }
        : undefined;
    }

    if (process.platform === "linux") {
      if (process.env.WAYLAND_DISPLAY) {
        const wtype = findExecutable(["wtype"]);
        if (wtype) return { bin: wtype, args: ["-M", "ctrl", "-P", "v", "-p", "v", "-m", "ctrl"] };
      }
      const xdotool = findExecutable(["xdotool"]);
      if (xdotool) return { bin: xdotool, args: ["key", "--clearmodifiers", "ctrl+v"] };
    }
    return undefined;
  }

  private shellCommand(command: string, input?: string): Command | undefined {
    const shell = findExecutable(["sh", "/bin/sh"]);
    return shell ? { bin: shell, args: ["-lc", command], input } : undefined;
  }

  private clipboardHelp(): string {
    if (process.platform === "linux") {
      return "No clipboard tool found. Install wl-clipboard, xclip, or xsel, or set STT_COPY_CMD.";
    }
    return "No clipboard command found. Set STT_COPY_CMD.";
  }

  private shellQuote(value: string): string {
    return `'${value.replace(/'/g, `'\\''`)}'`;
  }

  private readPid(path: string): number | undefined {
    try {
      const pid = Number(readFileSync(path, "utf8"));
      return Number.isFinite(pid) ? pid : undefined;
    } catch {
      return undefined;
    }
  }

  private isPidAlive(pid: number): boolean {
    try {
      process.kill(pid, 0);
      return true;
    } catch {
      return false;
    }
  }

  private logTiming(label: string, startedAt: number): void {
    const ms = Date.now() - startedAt;
    console.error(`[timing] ${label}: ${ms < 1000 ? `${ms}ms` : `${(ms / 1000).toFixed(2)}s`}`);
  }

  private sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
}
