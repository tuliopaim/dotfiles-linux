import { truncateHead, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { renderDelegationCall, renderDelegationResult } from "./shared/delegation-render.ts";
import { runDelegatedPi, SCOUT, type DelegationDetails } from "./shared/delegation.ts";

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "scout",
    label: "Scout",
    description: `${SCOUT.description} Hard timeout: ${SCOUT.timeoutMs / 1000}s.`,
    promptSnippet: SCOUT.snippet,
    promptGuidelines: [...SCOUT.guidelines],
    parameters: Type.Object({ task: Type.String({ description: SCOUT.parameter }) }),

    async execute(_toolCallId, params, signal, onUpdate, ctx) {
      const details = await runDelegatedPi(SCOUT, params.task, ctx.cwd, signal, (details) => {
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
      return renderDelegationCall(SCOUT, args.task, context.expanded, theme);
    },

    renderResult(result, { expanded }, theme) {
      return renderDelegationResult(result.details as DelegationDetails | undefined, expanded, theme);
    },
  });
}
