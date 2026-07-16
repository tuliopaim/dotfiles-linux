import { spawn, spawnSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

let sessionPreset: string | undefined;

function subagentSettings(): any {
  try {
    const agentDir = process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent");
    return JSON.parse(readFileSync(join(agentDir, "settings.json"), "utf8"))?.subagents;
  } catch {
    return undefined;
  }
}

export function getSubagentPresetNames(): string[] {
  const presets = subagentSettings()?.presets;
  return presets && typeof presets === "object" ? Object.keys(presets) : [];
}

export function getActiveSubagentPresetName(): string | undefined {
  const configured = subagentSettings()?.preset;
  return sessionPreset
    ?? (process.env.PI_SUBAGENT_PRESET?.trim() || undefined)
    ?? (typeof configured === "string" ? configured : undefined);
}

export function setSubagentPreset(name: string | undefined) {
  sessionPreset = name;
}

export function getDelegationConfig(name: string, defaults: DelegationConfig): DelegationConfig {
  const presetName = getActiveSubagentPresetName();
  if (!presetName) return defaults;

  const override = subagentSettings()?.presets?.[presetName]?.[name];
  if (!override || typeof override.model !== "string" || typeof override.thinking !== "string") {
    throw new Error(`Subagent preset "${presetName}" has no valid "${name}" configuration`);
  }

  return { ...defaults, model: override.model, thinking: override.thinking };
}

export const SCOUT = {
  name: "Scout",
  model: "opencode-go/deepseek-v4-flash",
  thinking: "medium",
  timeoutMs: 5 * 60_000,
  tools: "read,grep,find,ls",
  description: "Delegate focused, read-only codebase reconnaissance to a cheaper model.",
  snippet: "Delegate focused codebase reconnaissance to a cheaper read-only model",
  guidelines: [
    "Use scout before broad exploration when locating the answer likely requires more than 2-3 files.",
    "Do not use scout for work answerable with one or two direct reads, after equivalent reconnaissance is already done, for implementation, or for decisions requiring your own judgment.",
    "Give scout one narrow, self-contained question and use it at most once per task unless the user explicitly requests broader investigation.",
    "After scout returns, read only its recommended targets and verify only claims that affect edits or important decisions.",
  ],
  parameter: "One narrow, self-contained reconnaissance question, including the evidence the parent needs",
  prompt: `You are a read-only codebase scout. Your job is to reduce the parent agent's context usage. Investigate one delegated question; do not implement, edit files, run builds, or run tests.

Return only this compact handoff:
## Answer
Direct answer in at most 3 bullets.

## Relevant flow
- symbol — path:line
- → caller or consumer — path:line
- → test, when relevant — path:line

## Parent should read
- At most 3 exact files or line ranges required for the next decision.

## Unknowns
- Only uncertainties that could change the implementation, or "None".

Rules:
- Stop when the delegated question is answered.
- Include at most 8 evidence references and 500 words.
- Prefer exact symbols, paths, and line numbers over prose.
- Trace definitions and callers when relevant.
- Do not include large code excerpts or general architecture commentary unless requested.`,
} as const;

export const COMMIT = {
  name: "Commit",
  model: "opencode-go/deepseek-v4-flash",
  thinking: "medium",
  timeoutMs: 15 * 60_000,
  tools: "read,grep,find,ls,bash",
  description: "Delegate completed-work analysis and intentional git commits to a specialized model.",
  snippet: "Delegate git commit creation to an isolated specialized child",
  guidelines: [
    "Use commit only when the user explicitly asks to commit completed work.",
    "Pass any requested scope or commit-splitting instructions in the task.",
    "Do not inspect, stage, or commit in the parent; the isolated commit agent owns the complete workflow.",
  ],
  parameter: "Optional commit scope, ticket context, or commit-splitting instructions",
  prompt: `You are an isolated git commit agent. Follow the injected commit-work workflow exactly. Inspect all changes before staging, keep unrelated work uncommitted, never expose secrets, never amend or force push, and report each created commit's SHA and message.`,
} as const;

export const REVIEW = {
  name: "Review",
  model: "openai-codex/gpt-5.6-sol",
  thinking: "high",
  timeoutMs: 15 * 60_000,
  tools: "read,grep,find,ls,bash",
  description: "Delegate focused, read-only code review to a high-reasoning model.",
  snippet: "Delegate focused code review to a high-reasoning model",
  guidelines: [
    "Use review only when the user explicitly requests it, or after a high-risk change where an independent fresh-context review is materially useful; do not invoke it automatically.",
    "Give review the exact scope: working tree, commit/range, or named files, plus intended behavior.",
    "Use review at most once per change unless new code is added after the review.",
    "Treat review findings as leads; verify each finding yourself before changing code or reporting it as fact.",
  ],
  parameter: "Review scope and intended behavior, including commit/range or files when known",
  prompt: `You are a read-only code reviewer. Review the delegated change or scope; do not edit files.

Return only this compact handoff:
## Findings
For each real issue, ordered by severity:
### [P0-P3] Short title
- Evidence: path:line
- Impact: what breaks and under which conditions
- Fix: smallest correct change

If there are no findings, write "No findings."

## Validation gaps
- Important behavior you could not verify, or "None".

## Verdict
One sentence stating whether the change is safe to merge.

Rules:
- Prioritize correctness, security, data loss, regressions, and missing validation.
- Review the actual diff and trace affected callers when relevant.
- Do not report style preferences, speculative concerns, or pre-existing issues unrelated to the change.
- Use shell only for read-only inspection such as git diff/status/show/log and rg/find.
- Do not run builds or tests unless the delegated task explicitly asks.
- Prefer exact file paths and line numbers over prose.
- Stay under 1,200 words.`,
} as const;

export interface DelegationConfig {
  readonly name: string;
  readonly model: string;
  readonly thinking: string;
  readonly timeoutMs: number;
  readonly tools: string;
  readonly description: string;
  readonly snippet: string;
  readonly guidelines: readonly string[];
  readonly parameter: string;
  readonly prompt: string;
}

export interface DelegationDetails {
  task: string;
  model: string;
  thinking: string;
  prompt: string;
  status: "running" | "done";
  activities: string[];
  output: string;
  elapsedMs: number;
  usage: {
    turns: number;
    input: number;
    output: number;
    cacheRead: number;
    cacheWrite: number;
    cost: number;
    contextTokens: number;
  };
  truncated?: boolean;
  lastStopReason?: string;
}

function textFromMessage(message: any) {
  return Array.isArray(message?.content)
    ? message.content.filter((part: any) => part.type === "text").map((part: any) => part.text).join("\n")
    : "";
}

function formatTool(toolName: string, args: Record<string, unknown>) {
  const path = String(args.path ?? args.file_path ?? ".");
  switch (toolName) {
    case "read": return `read ${path}${args.offset ? `:${args.offset}` : ""}`;
    case "grep": return `grep /${String(args.pattern ?? "")}/ in ${path}`;
    case "find": return `find ${String(args.pattern ?? "*")} in ${path}`;
    case "ls": return `ls ${path}`;
    case "bash": {
      const command = String(args.command ?? "");
      return `$ ${command.length > 100 ? `${command.slice(0, 100)}…` : command}`;
    }
    default: return `${toolName} ${JSON.stringify(args)}`;
  }
}

export function createDelegationDetails(config: DelegationConfig, task: string): DelegationDetails {
  return {
    task,
    model: config.model,
    thinking: config.thinking,
    prompt: config.prompt,
    status: "running",
    activities: [],
    output: "",
    elapsedMs: 0,
    usage: { turns: 0, input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0 },
  };
}

/** Apply one event from `pi --mode json`; returns whether the visible state changed. */
export function applyDelegationEvent(details: DelegationDetails, event: any) {
  if (event.type === "message_start" && event.message?.role === "assistant") {
    details.output = "";
    return true;
  }

  if (event.type === "message_update") {
    const update = event.assistantMessageEvent;
    if (update?.type === "text_delta" && typeof update.delta === "string") {
      details.output += update.delta;
      return true;
    }
  }

  if (event.type === "tool_execution_start") {
    details.activities.push(formatTool(event.toolName, event.args ?? {}));
    if (details.activities.length > 100) details.activities.shift();
    return true;
  }

  if (event.type === "tool_execution_end" && event.isError) {
    details.activities.push(`✗ ${event.toolName}`);
    if (details.activities.length > 100) details.activities.shift();
    return true;
  }

  if (event.type === "message_end" && event.message?.role === "assistant") {
    const text = textFromMessage(event.message);
    if (text) details.output = text;
    if (event.message.stopReason) details.lastStopReason = event.message.stopReason;
    const usage = event.message.usage;
    if (usage) {
      details.usage.turns++;
      details.usage.input += usage.input ?? 0;
      details.usage.output += usage.output ?? 0;
      details.usage.cacheRead += usage.cacheRead ?? 0;
      details.usage.cacheWrite += usage.cacheWrite ?? 0;
      details.usage.cost += usage.cost?.total ?? 0;
      details.usage.contextTokens = usage.totalTokens ?? details.usage.contextTokens;
    }
    return true;
  }

  if (event.type === "agent_end" && !event.willRetry) {
    return true;
  }

  if (event.type === "agent_settled") {
    details.status = "done";
    return true;
  }

  return false;
}

export function runProcess(
  command: string,
  args: string[],
  options: {
    cwd: string;
    timeoutMs: number;
    signal?: AbortSignal;
    onStdout?: (chunk: string) => void;
    captureStdout?: boolean;
  },
) {
  return new Promise<{ stdout: string; stderr: string; code: number }>((resolve, reject) => {
    const proc = spawn(command, args, {
      cwd: options.cwd,
      detached: process.platform !== "win32",
      shell: false,
      stdio: ["ignore", "pipe", "pipe"],
    });
    let stdout = "";
    let stderr = "";
    let stopped: "timeout" | "aborted" | undefined;
    let forceKillTimer: ReturnType<typeof setTimeout> | undefined;

    proc.stdout.setEncoding("utf8");
    proc.stderr.setEncoding("utf8");

    const killTree = (signal: NodeJS.Signals) => {
      try {
        if (process.platform === "win32" && proc.pid) {
          spawnSync("taskkill", ["/PID", String(proc.pid), "/T", ...(signal === "SIGKILL" ? ["/F"] : [])], {
            stdio: "ignore",
            windowsHide: true,
          });
        } else if (proc.pid) process.kill(-proc.pid, signal);
        else proc.kill(signal);
      } catch {
        proc.kill(signal);
      }
    };
    const stop = (reason: "timeout" | "aborted") => {
      if (stopped) return;
      stopped = reason;
      killTree("SIGTERM");
      forceKillTimer = setTimeout(() => killTree("SIGKILL"), 5_000);
    };
    const onAbort = () => stop("aborted");
    const timeout = setTimeout(() => stop("timeout"), options.timeoutMs);

    proc.stdout.on("data", (data) => {
      const chunk = data.toString();
      if (options.captureStdout !== false) stdout += chunk;
      options.onStdout?.(chunk);
    });
    proc.stderr.on("data", (data) => { stderr += data.toString(); });
    if (options.signal?.aborted) onAbort();
    else options.signal?.addEventListener("abort", onAbort, { once: true });

    proc.on("error", (error) => reject(error));
    proc.on("close", (code) => {
      clearTimeout(timeout);
      if (stopped) killTree("SIGKILL");
      if (forceKillTimer) clearTimeout(forceKillTimer);
      options.signal?.removeEventListener("abort", onAbort);
      if (stopped === "timeout") reject(new Error(`Timed out after ${options.timeoutMs / 60_000} minutes`));
      else if (stopped === "aborted") reject(new Error("Delegated task aborted"));
      else resolve({ stdout, stderr, code: code ?? 1 });
    });
  });
}

export async function runDelegatedPi(
  config: DelegationConfig,
  task: string,
  cwd: string,
  signal?: AbortSignal,
  onUpdate?: (details: DelegationDetails) => void,
) {
  const details = createDelegationDetails(config, task);
  const startedAt = Date.now();
  let buffer = "";
  let lastUpdate = 0;

  const emit = (force = false) => {
    details.elapsedMs = Date.now() - startedAt;
    if (force || Date.now() - lastUpdate >= 100) {
      lastUpdate = Date.now();
      onUpdate?.({ ...details, activities: [...details.activities], usage: { ...details.usage } });
    }
  };
  const processLine = (line: string) => {
    if (!line.trim()) return;
    try {
      if (applyDelegationEvent(details, JSON.parse(line))) emit();
    } catch {
      // Ignore non-JSON stdout; stderr and exit status still report child failures.
    }
  };

  emit(true);
  const result = await runProcess(
    "pi",
    [
      "--mode", "json",
      "-p",
      "--no-session",
      "--no-extensions",
      "--no-skills",
      "--no-prompt-templates",
      "--model", config.model,
      "--thinking", config.thinking,
      "--tools", config.tools,
      "--append-system-prompt", config.prompt,
      `${config.name} task: ${task}`,
    ],
    {
      cwd,
      timeoutMs: config.timeoutMs,
      signal,
      captureStdout: false,
      onStdout(chunk) {
        buffer += chunk;
        const lines = buffer.split("\n");
        buffer = lines.pop() ?? "";
        for (const line of lines) processLine(line);
      },
    },
  );

  processLine(buffer);
  details.status = "done";
  emit(true);
  if (result.code !== 0) throw new Error(result.stderr.trim() || `Delegated task exited with code ${result.code}`);
  if (details.lastStopReason && details.lastStopReason !== "stop" && details.lastStopReason !== "toolUse") {
    throw new Error(`Delegated task ended with stopReason: ${details.lastStopReason}`);
  }
  return details;
}

