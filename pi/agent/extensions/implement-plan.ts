import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { access, readFile } from "node:fs/promises";
import path from "node:path";

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

async function resolvePlanPath(cwd: string, rawPath: string): Promise<{ displayPath: string; absolutePath: string }> {
  const displayPath = cleanArgPath(rawPath);
  const candidates = [displayPath];

  // Allow pi-style file mentions like @plans/foo.md by falling back to plans/foo.md.
  if (displayPath.startsWith("@")) candidates.push(displayPath.slice(1));
  candidates.push(displayPath.replaceAll("/@", "/"));

  for (const candidate of [...new Set(candidates)]) {
    const absolutePath = path.isAbsolute(candidate) ? candidate : path.resolve(cwd, candidate);
    if (await exists(absolutePath)) return { displayPath: candidate, absolutePath };
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

export default function (pi: ExtensionAPI) {
  pi.registerCommand("implement-plan", {
    description: "Start a fresh session and implement a plan file",
    handler: async (args, ctx) => {
      await ctx.waitForIdle();

      const rawPlanPath = cleanArgPath(args);
      if (!rawPlanPath) {
        ctx.ui.notify("Usage: /implement-plan <path-to-plan-file>", "error");
        return;
      }

      const { displayPath, absolutePath } = await resolvePlanPath(ctx.cwd, rawPlanPath);

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

      const parentSession = ctx.sessionManager.getSessionFile();
      const prompt = buildPrompt(displayPath, plan);

      const result = await ctx.newSession({
        parentSession,
        withSession: async (newCtx) => {
          await newCtx.sendUserMessage(prompt);
        },
      });

      if (result.cancelled) {
        ctx.ui.notify("New session was cancelled.", "warning");
      }
    },
  });
}
