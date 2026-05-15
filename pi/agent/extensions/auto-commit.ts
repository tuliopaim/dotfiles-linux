/**
 * /auto-commit command — pi slash command
 *
 * Converts the auto-commit skill into an interactive slash command.
 * Checks uncommitted files, groups changes logically, detects ticket
 * numbers from branch names, and commits with user-provided messages.
 *
 * Usage: /auto-commit [message]
 *   With a message: commit all changes with that message
 *   Without a message: interactive mode with status preview
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// ── Helpers ────────────────────────────────────────────────────────

function makeGit(pi: ExtensionAPI) {
	return (args: string[], { cwd }: { cwd: string }) =>
		pi.exec("git", args, { cwd });
}

/** Extract ticket number from branch name (e.g. "ABC-123" from "feature/ABC-123-foo"). */
function extractTicket(branch: string): string | null {
	const m = branch.match(/\b[A-Z]+-\d+\b/);
	return m ? m[0] : null;
}

/** Guess a short summary from a list of changed file paths. */
function summarizePaths(paths: string[]): string {
	// Extract directories for a sense of what was touched
	const dirs = new Set<string>();
	for (const p of paths) {
		const parts = p.split("/");
		if (parts.length > 1) dirs.add(parts[0]);
	}
	const dirList = [...dirs].join(", ");
	const count = paths.length;
	if (count === 1) {
		const file = paths[0]!;
		return `update ${file}`;
	}
	if (dirList) {
		return `update ${count} files in ${dirList}`;
	}
	return `update ${count} files`;
}

/** Build a suggested commit message from diffs and branch ticket. */
function suggestMessage(
	filePaths: string[],
	branch: string,
): string {
	const ticket = extractTicket(branch);
	const summary = summarizePaths(filePaths);
	return ticket ? `${ticket}: ${summary}` : summary;
}

/** Format git status for display. */
function formatStatus(short: string): string {
	if (!short.trim()) return "(no changes)";
	return short
		.split("\n")
		.map((l) => l.trimEnd())
		.join("\n");
}

// ── Groups ─────────────────────────────────────────────────────────

type FileEntry = { path: string; status: string }; // status char like "M", "A", "??"

/** Classify a file path into a logical group. */
function classify(path: string): string {
	const lower = path.toLowerCase();
	if (
		lower.startsWith("docs/") ||
		lower.startsWith("doc/") ||
		lower.endsWith(".md") ||
		lower.endsWith(".txt") ||
		lower.endsWith(".rst")
	)
		return "docs";
	if (
		lower.startsWith("test") ||
		lower.startsWith("spec") ||
		lower.endsWith(".test.ts") ||
		lower.endsWith(".spec.ts") ||
		lower.endsWith(".test.js") ||
		lower.endsWith(".spec.js")
	)
		return "tests";
	if (
		lower.startsWith("ci/") ||
		lower.startsWith(".github/") ||
		lower.startsWith(".gitlab/") ||
		lower.endsWith("dockerfile") ||
		lower.endsWith(".yml") ||
		lower.endsWith(".yaml")
	)
		return "infra";
	if (
		lower.startsWith("package.json") ||
		lower.startsWith("package-lock") ||
		lower.startsWith("yarn.lock") ||
		lower.startsWith("pnpm-lock") ||
		lower.startsWith("go.mod") ||
		lower.startsWith("go.sum")
	)
		return "deps";
	return "code";
}

/** Group file entries by concern using the classify helper + file extension. */
function groupByConcern(entries: FileEntry[]): Map<string, FileEntry[]> {
	const groups = new Map<string, FileEntry[]>();

	for (const entry of entries) {
		const category = classify(entry.path);
		const existing = groups.get(category);
		if (existing) {
			existing.push(entry);
		} else {
			groups.set(category, [entry]);
		}
	}

	return groups;
}

/** Order groups by dependency (infra → deps → code → tests → docs). */
const GROUP_ORDER = ["infra", "deps", "code", "tests", "docs"];

function orderedGroups(
	groups: Map<string, FileEntry[]>,
): Array<{ category: string; entries: FileEntry[] }> {
	const result: Array<{ category: string; entries: FileEntry[] }> = [];
	const seen = new Set<string>();

	for (const cat of GROUP_ORDER) {
		const g = groups.get(cat);
		if (g) {
			result.push({ category: cat, entries: g });
			seen.add(cat);
		}
	}
	// Any remaining categories not in the predefined order
	for (const [cat, g] of groups) {
		if (!seen.has(cat)) {
			result.push({ category: cat, entries: g });
		}
	}
	return result;
}

// ── Extension ──────────────────────────────────────────────────────

export default function autoCommitExtension(pi: ExtensionAPI) {
	const git = makeGit(pi);

	pi.registerCommand("auto-commit", {
		description:
			"Stage and commit changes. Detects ticket numbers from branch, groups files logically. " +
			"Usage: /auto-commit [message] — with a message does a single commit; without, interactive.",
		handler: async (args: string, ctx) => {
			const cwd = ctx.cwd;

			// ── 1. Check git repo state ─────────────────────────────
			const { stdout: branchOut, code: branchCode } = await git(
				["branch", "--show-current"],
				{ cwd },
			);
			if (branchCode !== 0) {
				ctx.ui.notify("Not a git repository", "error");
				return;
			}
			const branch = branchOut.trim();

			const { stdout: statusOut } = await git(["status", "--short"], { cwd });
			if (!statusOut.trim()) {
				ctx.ui.notify("No changes to commit", "info");
				return;
			}

			// ── 2. Parse status ─────────────────────────────────────
			const lines = statusOut.split("\n").filter(Boolean);
			const entries: FileEntry[] = lines.map((l) => ({
				status: l.slice(0, 2).trim(),
				path: l.slice(3).trim(),
			}));

			ctx.ui.notify(
				`${entries.length} changed file(s) on ${branch}`,
				"info",
			);

			// ── 3. Single commit (args provided) ────────────────────
			if (args.trim()) {
				const ticket = extractTicket(branch);
				const message = ticket
					? `${ticket}: ${args.trim()}`
					: args.trim();
				await git(["add", "-A"], { cwd });
				const { code: commitCode } = await git(
					["commit", "-m", message],
					{ cwd },
				);
				if (commitCode === 0) {
					ctx.ui.notify(`Committed: ${message}`, "success");
				} else {
					ctx.ui.notify("Commit failed", "error");
				}
				return;
			}

			// ── 4. Interactive: show status first ───────────────────
			const formatted = formatStatus(statusOut);
			const proceed = await ctx.ui.confirm(
				`Changes on ${branch}`,
				formatted + "\n\nProceed with commit?",
			);
			if (!proceed) {
				ctx.ui.notify("Cancelled", "info");
				return;
			}

			// ── 5. Decide single vs split ───────────────────────────
			const groups = groupByConcern(entries);
			const sorted = orderedGroups(groups);

			// Only split into multiple commits if we have 2+ distinct categories
			// AND the user wants to split
			let doSplit = false;
			if (sorted.length > 1) {
				const groupPreview = sorted
					.map(
						(g) =>
							`  ${g.category}: ${g.entries.map((e) => e.path).join(", ")}`,
					)
					.join("\n");
				const splitChoice = await ctx.ui.confirm(
					"Multiple concern areas detected",
					`I can commit in ${sorted.length} logical groups:\n\n${groupPreview}\n\nSplit into separate commits?`,
				);
				doSplit = splitChoice;
			}

			if (!doSplit) {
				// ── Single commit ───────────────────────────────────
				const allPaths = entries.map((e) => e.path);
				const suggested = suggestMessage(allPaths, branch);
				const msg = await ctx.ui.input(
					"Commit message",
					suggested,
				);
				if (!msg) {
					ctx.ui.notify("Cancelled", "info");
					return;
				}
				const ticket = extractTicket(branch);
				const fullMessage = ticket
					? `${ticket}: ${msg.trim()}`
					: msg.trim();
				await git(["add", "-A"], { cwd });
				const { code: commitCode } = await git(
					["commit", "-m", fullMessage],
					{ cwd },
				);
				if (commitCode === 0) {
					ctx.ui.notify(`Committed: ${fullMessage}`, "success");
				} else {
					ctx.ui.notify("Commit failed", "error");
				}
				return;
			}

			// ── 6. Multiple commits (split) ────────────────────────
			for (const group of sorted) {
				const paths = group.entries.map((e) => e.path);
				const suggested = suggestMessage(paths, branch);
				const msg = await ctx.ui.input(
					`Commit message for ${group.category} (${paths.length} files)`,
					suggested,
				);
				if (!msg) {
					ctx.ui.notify(
						`Skipped ${group.category} — commit cancelled`,
						"warning",
					);
					continue;
				}
				const ticket = extractTicket(branch);
				const fullMessage = ticket
					? `${ticket}: ${msg.trim()}`
					: msg.trim();
				for (const p of paths) {
					await git(["add", p], { cwd });
				}
				const { code: commitCode } = await git(
					["commit", "-m", fullMessage],
					{ cwd },
				);
				if (commitCode === 0) {
					ctx.ui.notify(
						`${group.category}: committed "${fullMessage}"`,
						"success",
					);
				} else {
					ctx.ui.notify(
						`${group.category}: commit failed`,
						"error",
					);
				}
			}
		},
	});
}
