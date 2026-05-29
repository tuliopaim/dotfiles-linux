import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { spawn, execFile as execFileCb } from "node:child_process";
import { promises as fs } from "node:fs";
import path from "node:path";
import { promisify } from "node:util";

const execFile = promisify(execFileCb);

type ReviewBackend = "raw" | "diffview";

interface ReviewOptions {
	backend: ReviewBackend;
	staged: boolean;
	unstaged: boolean;
	base?: string;
	mergeBase?: string;
	untracked: boolean;
	unified: number;
	reset: boolean;
	paths: string[];
}

async function git(args: string[], cwd: string): Promise<string> {
	const { stdout } = await execFile("git", ["-C", cwd, ...args], { maxBuffer: 50 * 1024 * 1024 });
	return stdout;
}

// Minimal shell-like splitter: supports single/double quotes and backslash escape of
// one character. Does NOT expand $VAR or interpret \n / \t as control chars.
function shellSplit(input: string): string[] {
	const out: string[] = [];
	let current = "";
	let quote: string | null = null;
	let escaped = false;
	for (const ch of input) {
		if (escaped) {
			current += ch;
			escaped = false;
		} else if (ch === "\\") {
			escaped = true;
		} else if (quote) {
			if (ch === quote) quote = null;
			else current += ch;
		} else if (ch === "'" || ch === '"') {
			quote = ch;
		} else if (/\s/.test(ch)) {
			if (current) out.push(current);
			current = "";
		} else {
			current += ch;
		}
	}
	if (current) out.push(current);
	return out;
}

function parseReviewOptions(rawArgs: string): ReviewOptions {
	const opts: ReviewOptions = { backend: "diffview", staged: false, unstaged: false, untracked: true, unified: 5, reset: false, paths: [] };
	const args = shellSplit(rawArgs || "");
	let pathMode = false;
	for (let i = 0; i < args.length; i++) {
		const arg = args[i];
		if (pathMode) {
			opts.paths.push(arg);
		} else if (arg === "--") {
			pathMode = true;
		} else if (arg === "--raw") {
			opts.backend = "raw";
		} else if (arg === "--diffview") {
			opts.backend = "diffview";
		} else if (arg === "--staged" || arg === "--cached") {
			opts.staged = true;
		} else if (arg === "--unstaged") {
			opts.unstaged = true;
		} else if (arg === "--untracked") {
			opts.untracked = true;
		} else if (arg === "--reset") {
			opts.reset = true;
		} else if (arg === "--base") {
			opts.base = args[++i];
		} else if (arg === "--merge-base") {
			opts.mergeBase = args[++i];
		} else if (arg === "--unified" || arg === "-U") {
			const parsed = Number(args[++i]);
			if (Number.isFinite(parsed) && parsed >= 0) opts.unified = parsed;
		} else if (arg.startsWith("--unified=")) {
			const parsed = Number(arg.slice("--unified=".length));
			if (Number.isFinite(parsed) && parsed >= 0) opts.unified = parsed;
		} else {
			opts.paths.push(arg);
		}
	}
	return opts;
}

function buildDiffArgs(opts: ReviewOptions): string[] {
	const paths = opts.paths.length ? opts.paths : ["."];
	let range: string[];
	if (opts.staged && !opts.unstaged) {
		range = ["--cached"];
	} else if (opts.unstaged && !opts.staged) {
		range = [];
	} else if (opts.mergeBase) {
		range = [`${opts.mergeBase}...HEAD`];
	} else {
		range = [opts.base || "HEAD"];
	}
	return ["diff", ...range, "--no-ext-diff", "--submodule=diff", `--unified=${opts.unified}`, "--", ...paths];
}

async function untrackedDiff(repoRoot: string, paths: string[], unified: number): Promise<string> {
	void unified;
	const lsArgs = ["ls-files", "--others", "--exclude-standard", "--", ...(paths.length ? paths : ["."])];
	const files = (await git(lsArgs, repoRoot)).split(/\r?\n/).filter(Boolean);
	const chunks: string[] = [];
	for (const file of files) {
		const content = await fs.readFile(path.join(repoRoot, file), "utf8").catch(() => "");
		const lines = content.endsWith("\n") ? content.slice(0, -1).split("\n") : content.split("\n");
		chunks.push([
			`diff --git a/${file} b/${file}`,
			"new file mode 100644",
			"--- /dev/null",
			`+++ b/${file}`,
			`@@ -0,0 +1,${lines.length} @@`,
			...lines.map((line) => `+${line}`),
		].join("\n"));
	}
	return chunks.length ? chunks.join("\n") + "\n" : "";
}

function buildDiffviewArgs(opts: ReviewOptions): string[] {
	const args: string[] = [];
	if (opts.staged && !opts.unstaged) {
		args.push("--staged");
	} else if (opts.mergeBase) {
		args.push(`${opts.mergeBase}...HEAD`);
	} else if (!opts.unstaged || opts.staged) {
		args.push(opts.base || "HEAD");
	}
	args.push("--submodule=diff");
	if (opts.untracked) args.push("--untracked-files=true");
	if (opts.paths.length) args.push("--", ...opts.paths);
	return args;
}

function scopeLabel(opts: ReviewOptions): string {
	const parts = [opts.staged && !opts.unstaged ? "staged" : opts.unstaged && !opts.staged ? "unstaged" : opts.mergeBase ? `${opts.mergeBase}...HEAD` : opts.base || "HEAD"];
	if (opts.untracked) parts.push("untracked");
	if (opts.paths.length) parts.push(`paths: ${opts.paths.join(" ")}`);
	parts.push(`unified=${opts.unified}`);
	return parts.join(", ");
}

async function addToGitInfoExclude(repoRoot: string): Promise<boolean> {
	const excludePath = path.join(repoRoot, ".git", "info", "exclude");
	try {
		let content = "";
		try {
			content = await fs.readFile(excludePath, "utf8");
		} catch {
			// Ignore; writeFile below will create it if possible.
		}
		if (content.split(/\r?\n/).includes(".pi/reviews/")) return false;
		const prefix = content.length > 0 && !content.endsWith("\n") ? "\n" : "";
		await fs.appendFile(excludePath, `${prefix}.pi/reviews/\n`, "utf8");
		return true;
	} catch {
		// Best effort only. Review files are still useful even if exclude cannot be updated.
		return false;
	}
}

function runNvim(repoRoot: string, diffPath: string, jsonPath: string, mdPath: string, opts: ReviewOptions): Promise<number | null> {
	return new Promise((resolve, reject) => {
		const child = spawn("nvim", ["-R", diffPath, "-c", "lua require('tuliopaim.pi_review').start()"], {
			cwd: repoRoot,
			stdio: "inherit",
			env: {
				...process.env,
				PI_REVIEW_ROOT: repoRoot,
				PI_REVIEW_DIFF: diffPath,
				PI_REVIEW_JSON: jsonPath,
				PI_REVIEW_MD: mdPath,
				PI_REVIEW_BACKEND: opts.backend,
				PI_REVIEW_SCOPE: scopeLabel(opts),
				PI_REVIEW_DIFFVIEW_ARGS: JSON.stringify(buildDiffviewArgs(opts)),
			},
		});
		child.on("error", reject);
		child.on("exit", (code) => resolve(code));
	});
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand("review", {
		description: "Open Neovim diff review UI for git changes",
		handler: async (args, ctx) => {
			await ctx.waitForIdle();

			const opts = parseReviewOptions(args);
			const cwd = ctx.sessionManager.getCwd();
			let repoRoot: string;
			try {
				repoRoot = (await git(["rev-parse", "--show-toplevel"], cwd)).trim();
			} catch {
				ctx.ui.notify("/review: current directory is not inside a git repo", "warning");
				return;
			}

			let diff: string;
			try {
				diff = await git(buildDiffArgs(opts), repoRoot);
				if (opts.untracked) diff += (diff.endsWith("\n") || diff.length === 0 ? "" : "\n") + await untrackedDiff(repoRoot, opts.paths, opts.unified);
			} catch (error) {
				ctx.ui.notify(`/review: failed to generate git diff: ${error instanceof Error ? error.message : String(error)}`, "error");
				return;
			}

			if (diff.trim().length === 0) {
				ctx.ui.notify("/review: no changes to review for selected scope", "info");
				return;
			}

			const reviewDir = path.join(repoRoot, ".pi", "reviews");
			const diffPath = path.join(reviewDir, "latest.diff");
			const jsonPath = path.join(reviewDir, "latest.json");
			const mdPath = path.join(reviewDir, "latest.md");

			await fs.mkdir(reviewDir, { recursive: true });
			if (opts.reset) {
				await Promise.all([fs.rm(jsonPath, { force: true }), fs.rm(mdPath, { force: true })]);
			}
			await fs.writeFile(diffPath, diff, "utf8");
			try {
				await fs.access(mdPath);
			} catch {
				await fs.writeFile(mdPath, "# Code Review Comments\n\nNo comments yet. Opened review but nothing saved from Neovim yet.\n", "utf8");
			}
			try {
				await fs.access(jsonPath);
			} catch {
				await fs.writeFile(jsonPath, JSON.stringify({ version: 2, repo: repoRoot, diff: diffPath, scope: scopeLabel(opts), comments: [] }, null, 2), "utf8");
			}
			const addedExclude = await addToGitInfoExclude(repoRoot);
			if (addedExclude) {
				ctx.ui.notify("/review: added .pi/reviews/ to .git/info/exclude", "info");
			}

			ctx.ui.notify(`/review: opening Neovim (${scopeLabel(opts)}). Use <leader>rc to comment and <leader>rq to save/quit.`, "info");

			try {
				const code = await runNvim(repoRoot, diffPath, jsonPath, mdPath, opts);
				if (code && code !== 0) {
					ctx.ui.notify(`/review: Neovim exited with code ${code}`, "warning");
				}
			} catch (error) {
				ctx.ui.notify(`/review: failed to launch nvim: ${error instanceof Error ? error.message : String(error)}`, "error");
				return;
			}

			ctx.ui.notify(`/review: review saved to ${mdPath}`, "info");
			const insert = await ctx.ui.confirm("Insert review prompt?", `Prefill the editor with a prompt referencing ${path.relative(repoRoot, mdPath)}?`);
			if (insert) {
				ctx.ui.setEditorText(`Please address my review comments.

@.pi/reviews/latest.md

Instructions:
- Treat each unchecked review comment as a checklist item.
- For each comment, either implement the requested change or explain why not.
- After addressing a comment, mark it resolved by changing its Markdown heading from [ ] to [x]. Neovim review mode will sync Markdown checkbox state back to JSON on the next save.
- If a comment is obsolete rather than addressed, delete it explicitly; do not delete unresolved comments silently.
- Preserve file/line metadata for unresolved comments.
- When finished, summarize which comments were resolved and which remain.`);
			}
		},
	});
}
