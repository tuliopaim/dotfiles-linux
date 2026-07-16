import { readFileSync, realpathSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { truncateHead, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { renderDelegationCall, renderDelegationResult } from "./shared/delegation-render.ts";
import {
  COMMIT,
  getDelegationConfig,
  runDelegatedPi,
  type DelegationConfig,
  type DelegationDetails,
} from "./shared/delegation.ts";

const workflow = readFileSync(
  resolve(dirname(realpathSync(fileURLToPath(import.meta.url))), "../../../skills/commit-work/SKILL.md"),
  "utf8",
);
function commitConfig(): DelegationConfig {
  const config = getDelegationConfig("commit", COMMIT);
  return { ...config, prompt: `${config.prompt}\n\n${workflow}` };
}

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "commit",
    label: "Commit",
    description: `${COMMIT.description} Hard timeout: ${COMMIT.timeoutMs / 1000}s.`,
    promptSnippet: COMMIT.snippet,
    promptGuidelines: [...COMMIT.guidelines],
    parameters: Type.Object({ task: Type.String({ description: COMMIT.parameter }) }),

    async execute(_toolCallId, params, signal, onUpdate, ctx) {
      const config = commitConfig();
      const details = await runDelegatedPi(config, params.task, ctx.cwd, signal, (details) => {
        onUpdate?.({
          content: [{ type: "text", text: details.output || details.activities.at(-1) || "(running…)" }],
          details,
        });
      });
      const output = details.output || "(commit agent returned no output)";
      const truncated = truncateHead(output, { maxLines: 200, maxBytes: 24 * 1024 });
      details.output = truncated.truncated
        ? `${truncated.content}\n\n[Commit output truncated to 200 lines / 24KB]`
        : truncated.content;
      details.truncated = truncated.truncated;

      return { content: [{ type: "text", text: details.output }], details };
    },

    renderCall(args, theme, context) {
      const config = (context.state.config as DelegationConfig | undefined) ?? commitConfig();
      context.state.config = config;
      return renderDelegationCall(config, args.task, context.expanded, theme);
    },

    renderResult(result, { expanded }, theme) {
      return renderDelegationResult(result.details as DelegationDetails | undefined, expanded, theme);
    },
  });

  pi.registerCommand("commit", {
    description: "Create intentional commits with the isolated commit tool",
    handler: async (args, ctx) => {
      if (!ctx.isIdle()) {
        ctx.ui.notify("Agent is busy", "warning");
        return;
      }
      const task = args.trim() || "Analyze all completed work and create the appropriate commit or commits.";
      pi.sendUserMessage(`Use the commit tool once with this task: ${task}`);
    },
  });
}
