import { spawnSync } from "child_process";
import { accessSync, constants, existsSync, statSync } from "fs";
import { homedir } from "os";
import { basename, join } from "path";

export type RunResult = {
  status: number | null;
  stdout: string;
  stderr: string;
  error?: Error;
};

export const HOME = homedir();

/**
 * Read the generic name first while accepting the old macOS-prefixed name.
 * This keeps existing hotkeys and launch agents working during the rename.
 */
export function setting(name: string): string | undefined {
  return process.env[`STT_${name}`] ?? process.env[`MACOS_STT_${name}`];
}

const user = process.env.USER || basename(HOME);
const fallbackLocale = process.platform === "darwin" ? "en_US.UTF-8" : "C.UTF-8";

export const CHILD_ENV = {
  ...process.env,
  LANG: process.env.LANG || fallbackLocale,
  LC_ALL: process.env.LC_ALL || fallbackLocale,
  LC_CTYPE: process.env.LC_CTYPE || fallbackLocale,
  PATH: [
    process.env.PATH ?? "",
    join(HOME, ".local/bin"),
    join(HOME, ".nix-profile/bin"),
    `/etc/profiles/per-user/${user}/bin`,
    "/run/current-system/sw/bin",
    "/opt/homebrew/bin",
    "/usr/local/bin",
    "/usr/bin",
    "/bin",
    "/usr/sbin",
    "/sbin",
  ].filter(Boolean).join(":"),
};

export function run(bin: string, args: string[], input?: string, timeoutMs = 120_000): RunResult {
  const result = spawnSync(bin, args, {
    input,
    encoding: "utf8",
    maxBuffer: 20 * 1024 * 1024,
    timeout: timeoutMs,
    env: CHILD_ENV,
  });
  return {
    status: result.status,
    stdout: result.stdout ?? "",
    stderr: result.stderr ?? "",
    error: result.error,
  };
}

export function existingFile(path: string | undefined): path is string {
  if (!path) return false;
  try {
    return existsSync(path) && statSync(path).isFile();
  } catch {
    return false;
  }
}

function executableFile(path: string): boolean {
  try {
    accessSync(path, constants.X_OK);
    return statSync(path).isFile();
  } catch {
    return false;
  }
}

/** Resolve absolute paths and bare command names against the child PATH. */
export function findExecutable(candidates: (string | undefined)[]): string | undefined {
  const pathDirs = (CHILD_ENV.PATH || "").split(":").filter(Boolean);
  for (const candidate of candidates) {
    if (!candidate) continue;
    if (candidate.includes("/")) {
      if (executableFile(candidate)) return candidate;
      continue;
    }
    for (const dir of pathDirs) {
      const path = join(dir, candidate);
      if (executableFile(path)) return path;
    }
  }
  return undefined;
}

export function findFile(candidates: (string | undefined)[]): string | undefined {
  return candidates.find(existingFile);
}

export function splitArgs(value: string): string[] {
  const matches = value.match(/(?:[^\s"']+|"[^"]*"|'[^']*')+/g) ?? [];
  return matches.map((part) => part.replace(/^(['"])(.*)\1$/, "$2"));
}
