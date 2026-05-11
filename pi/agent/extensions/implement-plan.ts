import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { access, readFile, writeFile, unlink } from "node:fs/promises";
import path from "node:path";
import os from "node:os";

// ── Token file: bridges old → new extension instance across session reload ──
// When the extension reloads in the new session (after ctx.newSession()),
// the session_start handler picks up the pending plan and executes it.
const tokenPath = () => path.join(os.tmpdir(), `pi-implement-plan-${process.pid}.json`);

interface PendingPlan {
  planPath: string;
  planContent: string;
  modelProvider: string;
  modelId: string;
  parentSessionFile: string;
}

async function writeToken(plan: PendingPlan): Promise<void> {
  await writeFile(tokenPath(), JSON.stringify(plan), "utf8");
}

async function readToken(): Promise<PendingPlan | null> {
  try {
    const raw = await readFile(tokenPath(), "utf8");
    return JSON.parse(raw) as PendingPlan;
  } catch {
    return null;
  }
}

async function clearToken(): Promise<void> {
  try {
    await unlink(tokenPath());
  } catch {
    // ignore
  }
}

// ── Helpers ──

function cleanArgPath(input: string): string {
  return input.trim().replace(/^['\"]|['\"]$/g, "");
}

async function exists(filePath: string): Promise<boolean> {
  try {
    await access(filePath);
    return true;
  } catch {
    return false;
  }
}

async function resolvePlanPath(
  cwd: string,
  rawPath: string,
): Promise<{ displayPath: string; absolutePath: string }> {
  const displayPath = cleanArgPath(rawPath);
  const candidates = [displayPath];

  // Allow pi-style file mentions like @plans/foo.md by falling back to plans/foo.md.
  if (displayPath.startsWith("@")) candidates.push(displayPath.slice(1));
  candidates.push(displayPath.replaceAll("/@", "/"));

  for (const candidate of [...new Set(candidates)]) {
    const absolutePath = path.isAbsolute(candidate)
      ? candidate
      : path.resolve(cwd, candidate);
    if (await exists(absolutePath))
      return { displayPath: candidate, absolutePath };
  }

  const first = candidates[0];
  return {
    displayPath: first,
    absolutePath: path.isAbsolute(first) ? first : path.resolve(cwd, first),
  };
}

function buildPrompt(planPath: string, plan: string): string {
  return `We are starting from a fresh context.

Implement the plan below.

Rules:
- Do not rely on any previous conversation; use only this handoff and repository files.
- Before editing, inspect the files relevant to the plan.
- Keep changes focused on the plan.
- Preserve existing project style and conventions.
- Run relevant tests/checks when practical, or explain why they were not run.
- If the plan is ambiguous or unsafe, ask for clarification before broad changes.

Plan file: ${planPath}

<plan>
${plan.trim()}
</plan>`;
}

// ── Extension ──

export default function (pi: ExtensionAPI) {
  // ── New-session auto-execution ──
  // When the extension reloads after a ctx.newSession(), check for a pending plan.
  pi.on("session_start", async (event, ctx) => {
    if (event.reason !== "new") return;

    const plan = await readToken();
    if (!plan) return;

    // Only execute if the token matches this specific parent session.
    if (event.previousSessionFile !== plan.parentSessionFile) return;

    // Consume the token immediately to prevent double-execution.
    await clearToken();

    // Restore the model from the parent session.
    if (plan.modelProvider && plan.modelId) {
      const model = ctx.modelRegistry.find(plan.modelProvider, plan.modelId);
      if (model) {
        try {
          await pi.setModel(model);
        } catch {
          ctx.ui.notify(
            `Could not switch to ${plan.modelProvider}/${plan.modelId}, using default model.`,
            "warning",
          );
        }
      }
    }

    // Fire the plan prompt.
    const prompt = buildPrompt(plan.planPath, plan.planContent);
    await pi.sendUserMessage(prompt);
  });

  // ── /implement-plan command ──
  pi.registerCommand("implement-plan", {
    description: "Start a fresh session and implement a plan file",
    handler: async (args, ctx) => {
      await ctx.waitForIdle();

      let rawPlanPath = cleanArgPath(args);

      if (!rawPlanPath) {
        for (const defaultPath of ["plans/PLAN.md", "PLAN.md"]) {
          const absolutePath = path.resolve(ctx.cwd, defaultPath);
          if (await exists(absolutePath)) {
            rawPlanPath = defaultPath;
            break;
          }
        }
      }

      if (!rawPlanPath) {
        ctx.ui.notify(
          "Usage: /implement-plan <path-to-plan-file> (or ensure plans/PLAN.md or ./PLAN.md exists)",
          "error",
        );
        return;
      }

      const { displayPath, absolutePath } = await resolvePlanPath(
        ctx.cwd,
        rawPlanPath,
      );

      let plan: string;
      try {
        plan = await readFile(absolutePath, "utf8");
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        ctx.ui.notify(`Could not read plan file: ${message}`, "error");
        return;
      }

      if (!plan.trim()) {
        ctx.ui.notify(`Plan file is empty: ${displayPath}`, "error");
        return;
      }

      const confirmed = await ctx.ui.confirm(
        "Implement plan in fresh context?",
        `Start a new session and implement ${displayPath}?`,
      );
      if (!confirmed) return;

      // Save plan + model info so the reloaded extension can pick it up.
      const model = ctx.model;
      const parentSessionFile =
        ctx.sessionManager.getSessionFile() ?? "";

      await writeToken({
        planPath: displayPath,
        planContent: plan,
        modelProvider: model?.provider ?? "",
        modelId: model?.id ?? "",
        parentSessionFile,
      });

      // Create a fresh session. The session_start handler above will
      // restore the model and fire the plan prompt automatically.
      await ctx.newSession({ parentSession: parentSessionFile });
    },
  });
}
