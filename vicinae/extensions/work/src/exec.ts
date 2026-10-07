import { spawn } from "child_process";
import { existsSync } from "fs";
import { homedir } from "os";
import { join } from "path";

const TIMEOUT_MS = 90_000;

const SEARCH_PATHS = [
  "/opt/homebrew/bin",
  "/usr/local/bin",
  join(homedir(), ".nix-profile/bin"),
  `/etc/profiles/per-user/${process.env.USER ?? ""}/bin`,
  "/run/current-system/sw/bin",
  "/usr/bin",
  "/bin",
];

export function expandHome(path: string): string {
  return path.trim().replace(/^~(?=$|\/)/, homedir());
}

export function resolveBin(name: string, override?: string): string {
  if (override?.trim()) {
    return expandHome(override);
  }
  const found = SEARCH_PATHS.map((dir) => join(dir, name)).find((path) => existsSync(path));
  if (!found) {
    throw new Error(`Could not find ${name}. Set its path in the extension preferences.`);
  }
  return found;
}

export function run(
  bin: string,
  args: string[],
  env: NodeJS.ProcessEnv = process.env,
  timeoutMs = TIMEOUT_MS,
): Promise<string> {
  return new Promise((resolve, reject) => {
    const child = spawn(bin, args, { env });
    let stdout = "";
    let stderr = "";
    const timer = setTimeout(() => {
      child.kill();
      reject(new Error(`${bin} timed out`));
    }, timeoutMs);

    child.stdout.setEncoding("utf8");
    child.stderr.setEncoding("utf8");
    child.stdout.on("data", (chunk) => (stdout += chunk));
    child.stderr.on("data", (chunk) => (stderr += chunk));
    child.on("error", (error) => {
      clearTimeout(timer);
      reject(error);
    });
    child.on("close", (code) => {
      clearTimeout(timer);
      if (code === 0) {
        resolve(stdout);
      } else {
        const lastLine = stderr.trim().split("\n").pop();
        reject(new Error(lastLine || `${bin} exited with code ${code}`));
      }
    });
  });
}
