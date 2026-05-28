/**
 * Context Tokens Footer Extension
 *
 * Replicates the default footer but shows the absolute context token count
 * instead of just the percentage. Adds a compact Unicode bar for visual
 * context-at-a-glance.
 *
 * Default:  26.9%/272k (auto)
 * Custom:   ████░░░░░░ 26.9% 73k/272k (auto)
 */

import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, SessionEntry } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

// ── Helpers ────────────────────────────────────────────────────────────────

/** Compact number formatter: 999 -> "999", 1_234 -> "1.2k", etc. */
const fmt = (n: number): string => {
	if (n < 1000) return `${n}`;
	if (n < 10_000) return `${(n / 1000).toFixed(1)}k`;
	if (n < 1_000_000) return `${Math.round(n / 1000)}k`;
	if (n < 10_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
	return `${Math.round(n / 1_000_000)}M`;
};

/** Sum token usage from assistant messages in a branch. */
function summarizeUsage(branch: SessionEntry[]) {
	let input = 0, output = 0, cacheRead = 0, cacheWrite = 0, cost = 0;
	for (const e of branch) {
		if (e.type === "message" && e.message.role === "assistant") {
			const u = (e.message as AssistantMessage).usage;
			if (!u) continue;
			input += u.input;
			output += u.output;
			cacheRead += u.cacheRead;
			cacheWrite += u.cacheWrite;
			cost += u.cost.total;
		}
	}
	return { input, output, cacheRead, cacheWrite, cost };
}

/** Unicode block bar. width=10 default. */
function contextBar(percent: number, width = 8): string {
	const filled = Math.round((percent / 100) * width);
	return "█".repeat(filled) + "░".repeat(Math.max(0, width - filled));
}

/** Left/right align with truncation fallback. */
function alignLeftRight(
	left: string,
	right: string,
	width: number,
	minPad = 2,
): string {
	const lw = visibleWidth(left);
	const rw = visibleWidth(right);
	if (lw + minPad + rw <= width) {
		return left + " ".repeat(width - lw - rw) + right;
	}
	if (width > lw + minPad) {
		const truncated = truncateToWidth(right, width - lw - minPad, "");
		return left + " ".repeat(Math.max(0, width - lw - visibleWidth(truncated))) + truncated;
	}
	return left;
}

// ── Extension ──────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		ctx.ui.setFooter((tui, theme, footerData) => {
			const unsubBranch = footerData.onBranchChange(() => tui.requestRender());

			return {
				dispose: unsubBranch,
				invalidate() {},

				render(width: number): string[] {
					const lines: string[] = [];

					// --- Line 1: pwd + git branch + session name ---
					let pwd = ctx.sessionManager.getCwd();
					const home = process.env.HOME || process.env.USERPROFILE;
					if (home && pwd.startsWith(home)) pwd = `~${pwd.slice(home.length)}`;
					const branch = footerData.getGitBranch();
					if (branch) pwd = `${pwd} (${branch})`;
					const sessionName = ctx.sessionManager.getSessionName();
					if (sessionName) pwd = `${pwd} • ${sessionName}`;
					lines.push(truncateToWidth(theme.fg("dim", pwd), width, theme.fg("dim", "...")));

					// --- Line 2: stats ---
					const usage = summarizeUsage(ctx.sessionManager.getBranch());
					const isSub = ctx.model ? ctx.modelRegistry.isUsingOAuth(ctx.model) : false;

					// --- Left stats (tokens, cost) ---
					const leftParts: string[] = [];
					if (usage.input) leftParts.push(`↑${fmt(usage.input)}`);
					if (usage.output) leftParts.push(`↓${fmt(usage.output)}`);
					if (usage.cacheRead) leftParts.push(`R${fmt(usage.cacheRead)}`);
					if (usage.cacheWrite) leftParts.push(`W${fmt(usage.cacheWrite)}`);
					if (usage.cost || isSub) leftParts.push(`$${usage.cost.toFixed(3)}${isSub ? " (sub)" : ""}`);
					const leftRaw = leftParts.join(" ");

					// --- Context bar (middle, colored by severity) ---
					const contextUsage = ctx.getContextUsage();
					const contextWindow = contextUsage?.contextWindow ?? ctx.model?.contextWindow ?? 0;
					const percent = contextUsage?.percent ?? null;
					const tokens = contextUsage?.tokens ?? null;

					let contextRaw: string;
					if (percent === null) {
						contextRaw = contextWindow > 0 ? `?/${fmt(contextWindow)}` : "?";
					} else if (tokens !== null) {
						contextRaw = `${contextBar(percent)} ${percent.toFixed(0)}% ${fmt(tokens)}/${fmt(contextWindow)}`;
					} else {
						contextRaw = `${contextBar(percent)} ${percent.toFixed(0)}% /${fmt(contextWindow)}`;
					}

					let contextColored = theme.fg("dim", contextRaw);
					if (percent !== null && percent > 90) {
						contextColored = theme.fg("error", contextRaw);
					} else if (percent !== null && percent > 70) {
						contextColored = theme.fg("warning", contextRaw);
					}

					// --- Right side: model ---
					let modelRaw = ctx.model?.id || "no-model";
					if (ctx.model?.reasoning) {
						const level = pi.getThinkingLevel();
						modelRaw = level === "off" ? `${modelRaw} • thinking off` : `${modelRaw} • ${level}`;
					}
					if (footerData.getAvailableProviderCount() > 1 && ctx.model) {
						modelRaw = `(${ctx.model.provider}) ${modelRaw}`;
					}

					// --- Assemble: left ... context ... model ---
					const lw = visibleWidth(leftRaw);
					const cw = visibleWidth(contextRaw);
					const mw = visibleWidth(modelRaw);
					const minPad = 2;

					let statsLine: string;
					if (lw + minPad + cw + 1 + mw <= width) {
						// Everything fits
						const pad = " ".repeat(width - lw - cw - 1 - mw);
						statsLine = theme.fg("dim", leftRaw) + pad + contextColored + " " + theme.fg("dim", modelRaw);
					} else if (width > lw + minPad + cw + 1) {
						// Truncate model
						const avail = width - lw - minPad - cw - 1;
						const truncated = truncateToWidth(modelRaw, avail, "");
						const pad = " ".repeat(Math.max(0, width - lw - visibleWidth(truncated) - cw - 1));
						statsLine = theme.fg("dim", leftRaw) + pad + contextColored + " " + theme.fg("dim", truncated);
					} else if (width > lw + minPad + cw) {
						// Drop model, keep context
						const pad = " ".repeat(Math.max(0, width - lw - cw));
						statsLine = theme.fg("dim", leftRaw) + pad + contextColored;
					} else {
						// Only left stats fit
						statsLine = theme.fg("dim", leftRaw);
					}
					lines.push(statsLine);

					// --- Extension statuses (line 3+) ---
					for (const [, text] of Array.from(footerData.getExtensionStatuses().entries()).sort(([a], [b]) => a.localeCompare(b))) {
						const sanitized = text.replace(/[\r\n\t]/g, " ").replace(/ +/g, " ").trim();
						lines.push(truncateToWidth(sanitized, width, theme.fg("dim", "...")));
					}

					return lines;
				},
			};
		});
	});
}
