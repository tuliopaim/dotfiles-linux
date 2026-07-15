import { homedir } from "node:os";
import { relative } from "node:path";
import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext, ReadonlyFooterDataProvider } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

function formatTokens(tokens: number) {
  if (tokens < 1_000) return `${tokens}`;
  if (tokens < 1_000_000) return `${Math.round(tokens / 1_000)}k`;
  return `${(tokens / 1_000_000).toFixed(1)}m`;
}

function formatDirectory(cwd: string) {
  const home = homedir();
  if (cwd === home) return "~";
  return cwd.startsWith(`${home}/`) ? `~/${relative(home, cwd)}` : cwd;
}

function columns(left: string, right: string, width: number) {
  const gap = width - visibleWidth(left) - visibleWidth(right);
  if (gap >= 1) return `${left}${" ".repeat(gap)}${right}`;

  const leftWidth = Math.max(1, Math.floor(width * 0.45));
  const fittedLeft = truncateToWidth(left, leftWidth);
  const fittedRight = truncateToWidth(right, Math.max(1, width - leftWidth - 1));
  return truncateToWidth(`${fittedLeft} ${fittedRight}`, width);
}

function sessionCost(ctx: ExtensionContext) {
  return ctx.sessionManager.getBranch().reduce((cost, entry) => {
    if (entry.type !== "message" || entry.message.role !== "assistant") return cost;
    return cost + ((entry.message as AssistantMessage).usage?.cost.total ?? 0);
  }, 0);
}

export default function dashboardFooter(pi: ExtensionAPI) {
  let changedFiles: number | null = null;
  let tokensPerSecond: number | null = null;
  let streamStartedAt = 0;
  let requestRender: (() => void) | undefined;
  let lastRenderAt = 0;
  let cwd = "";

  async function refreshGit() {
    if (!cwd) return;
    const targetCwd = cwd;
    const result = await pi.exec("git", ["status", "--porcelain", "--untracked-files=all"], { cwd: targetCwd, timeout: 2_000 });
    if (cwd !== targetCwd) return;
    changedFiles = result.code === 0 && !result.killed
      ? result.stdout.trim() ? result.stdout.trim().split("\n").length : 0
      : null;
    requestRender?.();
  }

  function install(ctx: ExtensionContext) {
    if (ctx.mode !== "tui") return;
    cwd = ctx.cwd;
    changedFiles = null;
    tokensPerSecond = null;

    ctx.ui.setFooter((tui, theme, footerData: ReadonlyFooterDataProvider) => {
      requestRender = () => tui.requestRender();
      const unsubscribe = footerData.onBranchChange(() => {
        void refreshGit();
        tui.requestRender();
      });

      return {
        dispose: unsubscribe,
        invalidate() {},
        render(width: number) {
          const usage = ctx.getContextUsage();
          const contextTokens = usage?.tokens;
          const contextWindow = usage?.contextWindow ?? ctx.model?.contextWindow ?? 0;
          const contextPercent = usage?.percent;
          const context = `${contextPercent === null || contextPercent === undefined ? "?" : Math.round(contextPercent)}% ${contextTokens === null || contextTokens === undefined ? "?" : formatTokens(contextTokens)}/${contextWindow ? formatTokens(contextWindow) : "?"}`;
          const speed = tokensPerSecond === null ? "— tok/s" : `${Math.round(tokensPerSecond)} tok/s`;
          const model = ctx.model
            ? `${ctx.model.provider}/${ctx.model.id}${ctx.model.reasoning ? ` · ${pi.getThinkingLevel()}` : ""}`
            : "no-model";
          const branch = footerData.getGitBranch();
          const git = branch
            ? `${branch}${changedFiles === null ? "" : ` · ${changedFiles} ${changedFiles === 1 ? "file" : "files"} changed`}`
            : "";

          const lines = [
            columns(theme.fg("text", formatDirectory(ctx.cwd)), theme.fg("muted", model), width),
            columns(theme.fg("muted", `${context} · $${sessionCost(ctx).toFixed(2)} · ${speed}`), theme.fg("muted", git), width),
          ];

          for (const [, text] of Array.from(footerData.getExtensionStatuses()).sort(([a], [b]) => a.localeCompare(b))) {
            for (const line of text.split("\n")) lines.push(truncateToWidth(line, width, theme.fg("dim", "...")));
          }
          return lines;
        },
      };
    });

    void refreshGit();
  }

  pi.on("session_start", (_event, ctx) => install(ctx));
  pi.on("message_start", (event) => {
    if (event.message.role !== "assistant") return;
    streamStartedAt = Date.now();
    tokensPerSecond = null;
  });
  pi.on("message_update", (event) => {
    if (event.message.role !== "assistant") return;
    const now = Date.now();
    if (now - lastRenderAt >= 200) {
      lastRenderAt = now;
      requestRender?.();
    }
  });
  pi.on("message_end", (event) => {
    if (event.message.role !== "assistant" || !streamStartedAt) return;
    const elapsedSeconds = (Date.now() - streamStartedAt) / 1_000;
    tokensPerSecond = elapsedSeconds >= 0.05 ? event.message.usage.output / elapsedSeconds : null;
    streamStartedAt = 0;
    requestRender?.();
  });
  pi.on("agent_settled", () => void refreshGit());
  pi.on("model_select", () => requestRender?.());
  pi.on("thinking_level_select", () => requestRender?.());
  pi.on("session_shutdown", (_event, ctx) => {
    requestRender = undefined;
    cwd = "";
    if (ctx.mode === "tui") ctx.ui.setFooter(undefined);
  });
}
