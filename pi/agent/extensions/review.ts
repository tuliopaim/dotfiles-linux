import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { spawn, execFile as execFileCb } from "node:child_process";
import { promises as fs } from "node:fs";
import path from "node:path";
import { promisify } from "node:util";

const execFile = promisify(execFileCb);

type ReviewBackend = "raw" | "diffview";
type ReviewTarget = "auto" | "herdr" | "tmux" | "inline" | "file";

interface ReviewOptions {
	backend: ReviewBackend;
	target: ReviewTarget;
	wait: boolean;
	staged: boolean;
	unstaged: boolean;
	base?: string;
	mergeBase?: string;
	untracked: boolean;
	unified: number;
	reset: boolean;
	paths: string[];
}

interface ReviewFiles {
	reviewDir: string;
	diffPath: string;
	jsonPath: string;
	statePath: string;
	openScriptPath: string;
	scope: string;
}

async function git(args: string[], cwd: string): Promise<string> {
	const { stdout } = await execFile("git", ["-C", cwd, ...args], { maxBuffer: 50 * 1024 * 1024 });
	return stdout;
}

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
	const opts: ReviewOptions = { backend: "diffview", target: "auto", wait: false, staged: false, unstaged: false, untracked: true, unified: 5, reset: false, paths: [] };
	const args = shellSplit(rawArgs || "");
	let pathMode = false;
	for (let i = 0; i < args.length; i++) {
		const arg = args[i];
		if (pathMode) opts.paths.push(arg);
		else if (arg === "--") pathMode = true;
		else if (arg === "--raw") opts.backend = "raw";
		else if (arg === "--diffview") opts.backend = "diffview";
		else if (arg === "--target") {
			const target = args[++i] as ReviewTarget;
			if (["auto", "herdr", "tmux", "inline", "file"].includes(target)) opts.target = target;
		} else if (arg.startsWith("--target=")) {
			const target = arg.slice("--target=".length) as ReviewTarget;
			if (["auto", "herdr", "tmux", "inline", "file"].includes(target)) opts.target = target;
		} else if (arg === "--herdr") opts.target = "herdr";
		else if (arg === "--tmux") opts.target = "tmux";
		else if (arg === "--inline") opts.target = "inline";
		else if (arg === "--file") opts.target = "file";
		else if (arg === "--wait") opts.wait = true;
		else if (arg === "--staged" || arg === "--cached") opts.staged = true;
		else if (arg === "--unstaged") opts.unstaged = true;
		else if (arg === "--untracked") opts.untracked = true;
		else if (arg === "--reset") opts.reset = true;
		else if (arg === "--base") opts.base = args[++i];
		else if (arg === "--merge-base") opts.mergeBase = args[++i];
		else if (arg === "--unified" || arg === "-U") {
			const parsed = Number(args[++i]);
			if (Number.isFinite(parsed) && parsed >= 0) opts.unified = parsed;
		} else if (arg.startsWith("--unified=")) {
			const parsed = Number(arg.slice("--unified=".length));
			if (Number.isFinite(parsed) && parsed >= 0) opts.unified = parsed;
		} else opts.paths.push(arg);
	}
	return opts;
}

function buildDiffArgs(opts: ReviewOptions): string[] {
	const paths = opts.paths.length ? opts.paths : ["."];
	let range: string[];
	if (opts.staged && !opts.unstaged) range = ["--cached"];
	else if (opts.unstaged && !opts.staged) range = [];
	else if (opts.mergeBase) range = [`${opts.mergeBase}...HEAD`];
	else range = [opts.base || "HEAD"];
	return ["diff", ...range, "--no-ext-diff", "--submodule=diff", `--unified=${opts.unified}`, "--", ...paths];
}

async function untrackedDiff(repoRoot: string, paths: string[], unified: number): Promise<string> {
	void unified;
	const files = (await git(["ls-files", "--others", "--exclude-standard", "--", ...(paths.length ? paths : ["."])], repoRoot)).split(/\r?\n/).filter(Boolean);
	const chunks: string[] = [];
	for (const file of files) {
		const content = await fs.readFile(path.join(repoRoot, file), "utf8").catch(() => "");
		const lines = content.endsWith("\n") ? content.slice(0, -1).split("\n") : content.split("\n");
		chunks.push([`diff --git a/${file} b/${file}`, "new file mode 100644", "--- /dev/null", `+++ b/${file}`, `@@ -0,0 +1,${lines.length} @@`, ...lines.map((line) => `+${line}`)].join("\n"));
	}
	return chunks.length ? chunks.join("\n") + "\n" : "";
}

function buildDiffviewArgs(opts: ReviewOptions): string[] {
	const args: string[] = [];
	if (opts.staged && !opts.unstaged) args.push("--staged");
	else if (opts.mergeBase) args.push(`${opts.mergeBase}...HEAD`);
	else if (!opts.unstaged || opts.staged) {
		// Diffview.nvim only shows untracked files when comparing against the
		// index (STAGE vs LOCAL). When comparing against a commit like HEAD,
		// it silently ignores --untracked-files. Omit the revision when
		// untracked files are requested so Diffview uses index comparison.
		if (!opts.untracked || opts.base) {
			args.push(opts.base || "HEAD");
		}
		// else: DiffviewOpen (no revision) → index-based, supports untracked
	}
	args.push("--submodule=diff");
	if (opts.untracked) args.push("--untracked-files=true");
	if (opts.paths.length) args.push("--", ...opts.paths);
	return args;
}

function scopeLabel(opts: ReviewOptions): string {
	const scope = opts.staged && !opts.unstaged ? "staged"
		: opts.unstaged && !opts.staged ? "unstaged"
		: opts.mergeBase ? `${opts.mergeBase}...HEAD`
		: opts.base || (opts.untracked ? "index" : "HEAD");
	const parts = [scope];
	if (opts.untracked) parts.push("untracked");
	if (opts.paths.length) parts.push(`paths: ${opts.paths.join(" ")}`);
	parts.push(`unified=${opts.unified}`);
	return parts.join(", ");
}

async function addToGitInfoExclude(repoRoot: string): Promise<boolean> {
	const excludePath = path.join(repoRoot, ".git", "info", "exclude");
	try {
		let content = "";
		try { content = await fs.readFile(excludePath, "utf8"); } catch {}
		if (content.split(/\r?\n/).includes(".pi/reviews/")) return false;
		await fs.appendFile(excludePath, `${content.length > 0 && !content.endsWith("\n") ? "\n" : ""}.pi/reviews/\n`, "utf8");
		return true;
	} catch { return false; }
}

function restoreTerminalCursor(): void {
	if (process.stdout.isTTY) process.stdout.write("\x1b[?25h\x1b[0m");
}

function buildNvimArgs(files: ReviewFiles): string[] {
	return ["-R", files.diffPath, "-c", "lua require('tuliopaim.pi_review').start()"];
}

function buildNvimEnv(repoRoot: string, files: ReviewFiles, opts: ReviewOptions): Record<string, string | undefined> {
	return { ...process.env, PI_REVIEW_ROOT: repoRoot, PI_REVIEW_DIFF: files.diffPath, PI_REVIEW_JSON: files.jsonPath, PI_REVIEW_BACKEND: opts.backend, PI_REVIEW_SCOPE: files.scope, PI_REVIEW_DIFFVIEW_ARGS: JSON.stringify(buildDiffviewArgs(opts)) };
}

function shQuote(value: string): string {
	return `'${value.replace(/'/g, `'"'"'`)}'`;
}

function buildShellCommand(repoRoot: string, files: ReviewFiles, opts: ReviewOptions): string {
	const env = buildNvimEnv(repoRoot, files, opts);
	const keys = ["PI_REVIEW_ROOT", "PI_REVIEW_DIFF", "PI_REVIEW_JSON", "PI_REVIEW_BACKEND", "PI_REVIEW_SCOPE", "PI_REVIEW_DIFFVIEW_ARGS"];
	return `${keys.map((k) => `${k}=${shQuote(String(env[k] ?? ""))}`).join(" ")} nvim ${buildNvimArgs(files).map(shQuote).join(" ")}`;
}

async function writeOpenScript(repoRoot: string, files: ReviewFiles, opts: ReviewOptions): Promise<void> {
	const env = buildNvimEnv(repoRoot, files, opts);
	await fs.writeFile(files.openScriptPath, `#!/usr/bin/env bash
set -euo pipefail
cd ${shQuote(repoRoot)}
export PI_REVIEW_ROOT=${shQuote(String(env.PI_REVIEW_ROOT ?? ""))}
export PI_REVIEW_DIFF=${shQuote(String(env.PI_REVIEW_DIFF ?? ""))}
export PI_REVIEW_JSON=${shQuote(String(env.PI_REVIEW_JSON ?? ""))}
export PI_REVIEW_BACKEND=${shQuote(String(env.PI_REVIEW_BACKEND ?? ""))}
export PI_REVIEW_SCOPE=${shQuote(String(env.PI_REVIEW_SCOPE ?? ""))}
export PI_REVIEW_DIFFVIEW_ARGS=${shQuote(String(env.PI_REVIEW_DIFFVIEW_ARGS ?? ""))}
exec nvim ${buildNvimArgs(files).map(shQuote).join(" ")}
`, "utf8");
	await fs.chmod(files.openScriptPath, 0o755);
}

function runNvim(repoRoot: string, files: ReviewFiles, opts: ReviewOptions): Promise<number | null> {
	return new Promise((resolve, reject) => {
		const child = spawn("nvim", buildNvimArgs(files), { cwd: repoRoot, stdio: "inherit", env: buildNvimEnv(repoRoot, files, opts) });
		child.on("error", (error) => { restoreTerminalCursor(); reject(error); });
		child.on("exit", (code) => { restoreTerminalCursor(); resolve(code); });
	});
}

async function commandExists(command: string): Promise<boolean> {
	try { await execFile(command, ["--version"], { timeout: 1500 }); return true; } catch { return false; }
}

async function prepareReviewFiles(repoRoot: string, opts: ReviewOptions): Promise<ReviewFiles | null> {
	let diff = await git(buildDiffArgs(opts), repoRoot);
	if (opts.untracked) diff += (diff.endsWith("\n") || diff.length === 0 ? "" : "\n") + await untrackedDiff(repoRoot, opts.paths, opts.unified);
	if (diff.trim().length === 0) return null;
	const reviewDir = path.join(repoRoot, ".pi", "reviews");
	const files = { reviewDir, diffPath: path.join(reviewDir, "latest.diff"), jsonPath: path.join(reviewDir, "latest.json"), statePath: path.join(reviewDir, "latest.state.json"), openScriptPath: path.join(reviewDir, "latest.open.sh"), scope: scopeLabel(opts) };
	await fs.mkdir(reviewDir, { recursive: true });
	if (opts.reset) await fs.rm(files.jsonPath, { force: true });
	await fs.writeFile(files.diffPath, diff, "utf8");
	try { await fs.access(files.jsonPath); } catch { await fs.writeFile(files.jsonPath, JSON.stringify({ version: 2, repo: repoRoot, diff: files.diffPath, scope: files.scope, comments: [] }, null, 2), "utf8"); }
	await writeOpenScript(repoRoot, files, opts);
	return files;
}

async function writeState(repoRoot: string, files: ReviewFiles, opts: ReviewOptions, target: ReviewTarget, status: string, extra: Record<string, unknown> = {}) {
	await fs.writeFile(files.statePath, JSON.stringify({ version: 1, repoRoot, paths: { diff: files.diffPath, json: files.jsonPath }, backend: opts.backend, scope: files.scope, requestedTarget: opts.target, target, status, command: buildShellCommand(repoRoot, files, opts), updatedAt: new Date().toISOString(), options: opts, ...extra }, null, 2), "utf8");
}

async function launchTmux(repoRoot: string, files: ReviewFiles, opts: ReviewOptions): Promise<string> {
	if (!process.env.TMUX) throw new Error("not inside tmux ($TMUX is unset)");
	if (!(await commandExists("tmux"))) throw new Error("tmux executable not found");
	const { stdout } = await execFile("tmux", ["new-window", "-P", "-F", "#{window_id}", "-c", repoRoot, "-n", "pi-review", files.openScriptPath]);
	return stdout.trim();
}

async function launchHerdr(repoRoot: string, files: ReviewFiles, opts: ReviewOptions): Promise<string> {
	if (process.env.HERDR_ENV !== "1" || !process.env.HERDR_PANE_ID) throw new Error("not inside Herdr (HERDR_ENV/HERDR_PANE_ID unset)");
	if (!(await commandExists("herdr"))) throw new Error("herdr executable not found");
	const paneInfo = JSON.parse((await execFile("herdr", ["pane", "get", process.env.HERDR_PANE_ID])).stdout);
	const workspaceId = paneInfo?.result?.pane?.workspace_id;
	if (!workspaceId) throw new Error("could not resolve Herdr workspace");
	const tabInfo = JSON.parse((await execFile("herdr", ["tab", "create", "--workspace", workspaceId, "--cwd", repoRoot, "--label", "review", "--focus"])).stdout);
	const tabId = tabInfo?.result?.tab?.tab_id;
	const paneId = tabInfo?.result?.root_pane?.pane_id;
	if (!paneId) throw new Error("could not find Herdr root pane for new review tab");
	// Use a tiny generated script rather than a long env-prefixed shell command:
	// Herdr's pane runner is reliable with executable paths, while complex quoted
	// command strings can be dropped or interpreted differently across versions.
	await execFile("herdr", ["pane", "run", paneId, files.openScriptPath]);
	return String(tabId ?? paneId);
}

const finishPrompt = `Please address my review comments.

@.pi/reviews/latest.json

Instructions:
- Read the \`comments\` array in the JSON file. Each comment object has a \`resolved\` boolean field.
- For each comment where \`resolved\` is \`false\`, implement the requested change or explain why not.
- After addressing a comment, set its \`resolved\` field to \`true\` in the JSON file.
- If a comment is obsolete rather than addressed, remove it from the array entirely; do not delete unresolved comments silently.
- Preserve file/line metadata for unresolved comments.
- When finished, summarize which comments were resolved and which remain.`;

export default function (pi: ExtensionAPI) {
	pi.registerCommand("review", {
		description: "Generate Pi review files and open external Neovim review UI when possible",
		handler: async (args, ctx) => {
			await ctx.waitForIdle();
			const opts = parseReviewOptions(args);
			const cwd = ctx.sessionManager.getCwd();
			let repoRoot: string;
			try { repoRoot = (await git(["rev-parse", "--show-toplevel"], cwd)).trim(); } catch { ctx.ui.notify("/review: current directory is not inside a git repo", "warning"); return; }
			let files: ReviewFiles | null;
			try { files = await prepareReviewFiles(repoRoot, opts); } catch (error) { ctx.ui.notify(`/review: failed to generate git diff: ${error instanceof Error ? error.message : String(error)}`, "error"); return; }
			if (!files) { ctx.ui.notify(`/review: no changes to review for selected scope (cwd: ${cwd})`, "info"); return; }
			if (await addToGitInfoExclude(repoRoot)) ctx.ui.notify("/review: added .pi/reviews/ to .git/info/exclude", "info");

			const targets: ReviewTarget[] = opts.target === "auto" ? ["herdr", "tmux", "file"] : [opts.target];
			for (const target of targets) {
				try {
					if (target === "file") {
						await writeState(repoRoot, files, opts, "file", "ready");
						ctx.ui.notify(`/review: wrote ${path.relative(repoRoot, files.jsonPath)}. Open with: ${buildShellCommand(repoRoot, files, opts)}. Run /review-finish when done.`, "info");
						return;
					}
					if (target === "inline") {
						ctx.ui.notify("/review: opening inline Neovim (legacy opt-in).", "warning");
						const code = await runNvim(repoRoot, files, opts);
						await writeState(repoRoot, files, opts, "inline", code && code !== 0 ? `exited:${code}` : "complete");
						ctx.ui.notify(`/review: review saved to ${files.jsonPath}. Run /review-finish to insert the prompt.`, "info");
						return;
					}
					const launched = target === "tmux" ? await launchTmux(repoRoot, files, opts) : await launchHerdr(repoRoot, files, opts);
					await writeState(repoRoot, files, opts, target, "launched", { launchId: launched });
					ctx.ui.notify(`/review: opened ${target} review (${files.scope}). Use <leader>rc to comment, <leader>rq to save/quit, then run /review-finish.`, "info");
					return;
				} catch (error) {
					if (opts.target !== "auto") { ctx.ui.notify(`/review: failed to launch ${target}: ${error instanceof Error ? error.message : String(error)}`, "error"); await writeState(repoRoot, files, opts, target, "failed", { error: String(error) }); return; }
				}
			}
		},
	});

	pi.registerCommand("review-finish", {
		description: "Prefill prompt from latest Pi review comments",
		handler: async (args, ctx) => {
			const opts = shellSplit(args || "");
			const cwd = ctx.sessionManager.getCwd();
			let repoRoot: string;
			try { repoRoot = (await git(["rev-parse", "--show-toplevel"], cwd)).trim(); } catch { ctx.ui.notify("/review-finish: current directory is not inside a git repo", "warning"); return; }
			const explicit = opts.find((a) => !a.startsWith("--"));
			const jsonPath = explicit ? path.resolve(cwd, explicit) : path.join(repoRoot, ".pi", "reviews", "latest.json");
			ctx.ui.setEditorText(finishPrompt.replace("@.pi/reviews/latest.json", `@${path.relative(repoRoot, jsonPath)}`));
			ctx.ui.notify(`/review-finish: inserted prompt for ${path.relative(repoRoot, jsonPath)}`, "info");
		},
	});
}
