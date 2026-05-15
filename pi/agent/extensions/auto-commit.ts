/**
 * /auto-commit command — pi slash command
 *
 * Converts the auto-commit skill into an interactive slash command.
 * Checks uncommitted files, detects ticket numbers from branch names,
 * and asks the agent to generate commit message(s) from the actual diff.
 *
 * Usage: /auto-commit [message]
 *   With a message: commit all changes with that message
 *   Without a message: let the agent inspect the diff, generate message(s), and commit
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
			"Stage and commit changes. Detects ticket numbers from branch. " +
			"Usage: /auto-commit [message] — with a message does a single commit; without, AI generates commit message(s) from the diff.",
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

			// ── 4. Let the agent inspect diffs and commit ───────────
			const formatted = formatStatus(statusOut);
			const ticket = extractTicket(branch);
			const groups = orderedGroups(groupByConcern(entries));
			const groupPreview = groups
				.map(
					(g) =>
						`  ${g.category}: ${g.entries.map((e) => e.path).join(", ")}`,
				)
				.join("\n");

			ctx.ui.notify("Handing off to agent to generate commit message(s)", "info");
			pi.sendUserMessage(
				`Auto-commit the current git changes in ${cwd}.

Branch: ${branch}${ticket ? `\nTicket prefix to use if appropriate: ${ticket}` : ""}

Changed files:\n${formatted}

Logical grouping suggestion:\n${groupPreview}

Instructions:
- Inspect the actual diff before committing (use git diff and git diff --cached as needed).
- Generate concise, conventional commit message(s) from the diff. Do not ask me for the message.
- Prefer a single commit unless the diff clearly contains unrelated concerns; if splitting, stage and commit each group separately.
${ticket ? `- Include the ticket prefix (${ticket}) at the start of each subject if it fits the repository's style.\n` : ""}- Run git status afterward and report the commit hash(es).`,
			);
		},
	});
}
