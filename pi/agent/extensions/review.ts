import { truncateHead, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { renderDelegationCall, renderDelegationResult } from "./shared/delegation-render.ts";
import { REVIEW, runDelegatedPi, type DelegationDetails } from "./shared/delegation.ts";

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "review",
    label: "Review",
    description: `${REVIEW.description} Hard timeout: ${REVIEW.timeoutMs / 1000}s.`,
    promptSnippet: REVIEW.snippet,
    promptGuidelines: [...REVIEW.guidelines],
    parameters: Type.Object({ task: Type.String({ description: REVIEW.parameter }) }),

    async execute(_toolCallId, params, signal, onUpdate, ctx) {
      const details = await runDelegatedPi(REVIEW, params.task, ctx.cwd, signal, (details) => {
        onUpdate?.({
          content: [{ type: "text", text: details.output || details.activities.at(-1) || "(running…)" }],
          details,
        });
      });
      const output = details.output || "(review returned no output)";
      const truncated = truncateHead(output, { maxLines: 250, maxBytes: 32 * 1024 });
      details.output = truncated.truncated
        ? `${truncated.content}\n\n[Review output truncated to 250 lines / 32KB]`
        : truncated.content;
      details.truncated = truncated.truncated;

      return { content: [{ type: "text", text: details.output }], details };
    },

    renderCall(args, theme, context) {
      return renderDelegationCall(REVIEW, args.task, context.expanded, theme);
    },

    renderResult(result, { expanded }, theme) {
      return renderDelegationResult(result.details as DelegationDetails | undefined, expanded, theme);
    },
  });
}
