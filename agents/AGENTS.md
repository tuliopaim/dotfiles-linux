# Global Agent Instructions

## Memory

Use OptMem for persistent memory across sessions:
- The CLI is `~/.optmem/memo`.
- The shared memory store is `~/.optmem/memory`, unless `MEMORY_DIR` overrides it.

### Pi sessions

The installed OptMem extension handles startup and supplies the `optmem` tool.
Use that tool for notes, requested compression, recall, and zoom. Do not run
the CLI startup instructions below in Pi.

### Non-Pi sessions

At startup, run `~/.optmem/memo wake` before any other tool call. Follow its
continuation and compression instructions until it says "You are awake."

Run `~/.optmem/memo note "<one line, at most 280 bytes>"` when you learn a
durable fact, user preference or correction, finish substantial work, or make
a lasting decision. Do not save redundant notes.

If any OptMem output requests compression, submit the requested summary with
`~/.optmem/memo nap <a-b> "<summary>"` before your next non-memory action.
Continue until no compression remains.

Use `~/.optmem/memo recall "<regex>"` to search original notes.
Use `~/.optmem/memo zoom <a-b>` to open a summary into its children.
Never directly edit or delete files under the memory store; the tool manages them.

### Subagents

Subagents must skip all memory instructions, ignore injected OptMem memory,
and never run `memo` or call `optmem`. Only parent agents maintain memory;
parallel parent sessions may all write to the shared store.

When spawning a subagent, include: "You are a subagent. Don't run memo or use optmem."

## Plain-English Writing Style

Lead with the answer. Write plain, concise English using concrete words and active voice. Cut repetition, filler, and unnecessary jargon. Apply these rules to prose, not code or identifiers. Clarity matters more than rigid style rules.

## Implementation Philosophy

Make the smallest change that fully solves the problem. Follow existing patterns, reuse existing code, and avoid unrequested abstractions or broad refactors. Verify that the change fixes the underlying problem.

## Commits and pull requests

- Never commit or push unless the user asks.
- In Claude Code and Codex, delegate requested commits to the configured `commit`
  subagent when available. Pass the checkout, scope, user authorization, and
  validation results. Keep its configured model; do not edit the checkout while
  it runs. Otherwise follow the harness's delegation rules and report model fallbacks.
- Never add AI attribution to commits or pull requests, including AI co-author trailers or generated-by footers.

## T3 Code

Only when running inside T3 Code with its orchestration tools available, read
`~/dotfiles/agents/T3.md` for delegation rules. Other agents should skip it.

## Git repositories and worktrees under `~/dev/`

Use a bare-repository layout for new clones. Keep Git administration files in
`.bare` and working trees as siblings of it. Preserve existing repository layouts.

For a new repository, use the helper instead of `git clone`:

```sh
~/dotfiles/scripts/clone-wt <repository-url> [repository-directory]
cd <repository-directory>
git worktree add -b main main origin/main
```

Adjust `main` if the repository uses a different default branch. The resulting
layout should look like this:

```text
repository-directory/
├── .bare/             # Git administration data; do not edit or remove
├── .git               # File pointing to ./.bare
├── main/              # A working tree
└── feature-name/      # Another working tree
```

When creating another working tree, place it alongside the current one (under
the same repository directory), not in `/tmp`, the home directory, or an
unrelated checkout:

```sh
git worktree add -b feature-name ../feature-name origin/main
```

If the branch already exists, omit `-b` and use the existing branch name. Do
not run `git clone`, `git init`, or manually move `.git` directories to create
additional worktrees. Do not place a worktree inside `.bare`.
