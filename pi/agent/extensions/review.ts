import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { spawn, execFile as execFileCb } from "node:child_process";
import { promises as fs } from "node:fs";
import path from "node:path";
import { promisify } from "node:util";

const execFile = promisify(execFileCb);

async function git(args: string[], cwd: string): Promise<string> {
	const { stdout } = await execFile("git", ["-C", cwd, ...args], { maxBuffer: 50 * 1024 * 1024 });
	return stdout;
}

async function addToGitInfoExclude(repoRoot: string) {
	const excludePath = path.join(repoRoot, ".git", "info", "exclude");
	try {
		let content = "";
		try {
			content = await fs.readFile(excludePath, "utf8");
		} catch {
			// Ignore; writeFile below will create it if possible.
		}
		if (!content.split(/\r?\n/).includes(".pi/reviews/")) {
			const prefix = content.length > 0 && !content.endsWith("\n") ? "\n" : "";
			await fs.appendFile(excludePath, `${prefix}.pi/reviews/\n`, "utf8");
		}
	} catch {
		// Best effort only. Review files are still useful even if exclude cannot be updated.
	}
}

function runNvim(repoRoot: string, diffPath: string, jsonPath: string, mdPath: string): Promise<number | null> {
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
			},
		});
		child.on("error", reject);
		child.on("exit", (code) => resolve(code));
	});
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand("review", {
		description: "Open Neovim diff review UI for the current git diff",
		handler: async (_args, ctx) => {
			await ctx.waitForIdle();

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
				diff = await git(["diff", "HEAD", "--no-ext-diff", "--unified=80", "--", "."], repoRoot);
			} catch (error) {
				ctx.ui.notify(`/review: failed to generate git diff: ${error instanceof Error ? error.message : String(error)}`, "error");
				return;
			}

			if (diff.trim().length === 0) {
				ctx.ui.notify("/review: no tracked staged or unstaged changes to review", "info");
				return;
			}

			const reviewDir = path.join(repoRoot, ".pi", "reviews");
			const diffPath = path.join(reviewDir, "latest.diff");
			const jsonPath = path.join(reviewDir, "latest.json");
			const mdPath = path.join(reviewDir, "latest.md");

			await fs.mkdir(reviewDir, { recursive: true });
			await fs.writeFile(diffPath, diff, "utf8");
			await fs.writeFile(mdPath, "# Code Review Comments\n\nNo comments yet. Opened review but nothing saved from Neovim yet.\n", "utf8");
			await fs.writeFile(jsonPath, JSON.stringify({ version: 1, repo: repoRoot, diff: diffPath, base: "HEAD", comments: [] }, null, 2), "utf8");
			await addToGitInfoExclude(repoRoot);

			ctx.ui.notify("/review: opening Neovim. Use <leader>rc to comment and <leader>rq to save/quit.", "info");

			try {
				const code = await runNvim(repoRoot, diffPath, jsonPath, mdPath);
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
				ctx.ui.setEditorText("Please address my review comments.\n\n@.pi/reviews/latest.md");
			}
		},
	});
}
