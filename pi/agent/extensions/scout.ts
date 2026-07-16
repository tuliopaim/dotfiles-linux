import { truncateHead, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { renderDelegationCall, renderDelegationResult } from "./shared/delegation-render.ts";
import {
  getActiveSubagentPresetName,
  getDelegationConfig,
  getSubagentPresetNames,
  runDelegatedPi,
  SCOUT,
  setSubagentPreset,
  type DelegationConfig,
  type DelegationDetails,
} from "./shared/delegation.ts";

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "scout",
    label: "Scout",
    description: `${SCOUT.description} Hard timeout: ${SCOUT.timeoutMs / 1000}s.`,
    promptSnippet: SCOUT.snippet,
    promptGuidelines: [...SCOUT.guidelines],
    parameters: Type.Object({ task: Type.String({ description: SCOUT.parameter }) }),

    async execute(_toolCallId, params, signal, onUpdate, ctx) {
      const config = getDelegationConfig("scout", SCOUT);
      const details = await runDelegatedPi(config, params.task, ctx.cwd, signal, (details) => {
        onUpdate?.({
          content: [{ type: "text", text: details.output || details.activities.at(-1) || "(running…)" }],
          details,
        });
      });
      const output = details.output || "(scout returned no output)";
      const truncated = truncateHead(output, { maxLines: 200, maxBytes: 24 * 1024 });
      details.output = truncated.truncated
        ? `${truncated.content}\n\n[Scout output truncated to 200 lines / 24KB]`
        : truncated.content;
      details.truncated = truncated.truncated;

      return { content: [{ type: "text", text: details.output }], details };
    },

    renderCall(args, theme, context) {
      const config = (context.state.config as DelegationConfig | undefined) ?? getDelegationConfig("scout", SCOUT);
      context.state.config = config;
      return renderDelegationCall(config, args.task, context.expanded, theme);
    },

    renderResult(result, { expanded }, theme) {
      return renderDelegationResult(result.details as DelegationDetails | undefined, expanded, theme);
    },
  });

  pi.registerCommand("subagent-preset", {
    description: "Switch the model preset used by scout, review, and commit",
    handler: async (args, ctx) => {
      const names = getSubagentPresetNames();
      if (names.length === 0) {
        ctx.ui.notify("No subagent presets configured", "warning");
        return;
      }

      const requested = args.trim();
      const name = requested || await ctx.ui.select(
        `Subagent preset (current: ${getActiveSubagentPresetName() ?? "none"})`,
        names,
      );
      if (!name) return;
      if (!names.includes(name)) {
        ctx.ui.notify(`Unknown subagent preset "${name}". Available: ${names.join(", ")}`, "error");
        return;
      }

      setSubagentPreset(name);
      ctx.ui.notify(`Subagent preset "${name}" activated`, "info");
    },
  });

  pi.on("session_start", (_event, ctx) => {
    const active = getActiveSubagentPresetName();
    if (active && !getSubagentPresetNames().includes(active)) {
      ctx.ui.notify(`Unknown subagent preset "${active}"`, "warning");
    }
  });
}
