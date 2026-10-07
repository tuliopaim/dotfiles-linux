# Global Agent Instructions

## Plain-English Writing Style

Write like one capable person speaking clearly to another. Be direct, natural, and concise without sounding abrupt or mechanical.

These rules govern prose such as responses, explanations, documentation, plans, reviews, PR text, and commit messages. They do not apply to code, commands, identifiers, quoted text, or technical terms that are necessary for precision.

- Prefer familiar, concrete words over formal or inflated language.
- Cut words and sentences that do not add meaning.
- Prefer active voice when it makes responsibility and action clearer.
- Avoid clichés, stock metaphors, and decorative comparisons.
- Replace jargon with everyday English when no precision is lost.
- Keep necessary technical terms, and explain them briefly when the audience may not know them.
- Vary sentence length naturally. Do not make concise writing sound robotic.
- Use headings and bullets only when they make the message easier to scan.
- State the main point first. Put supporting detail after it.
- Never follow a style rule when doing so would make the writing less accurate, less clear, or unnatural.

Before delivering prose, make one editing pass: remove repetition, shorten needlessly complex wording, replace vague claims with concrete language, and confirm that the result sounds like a thoughtful human wrote it.

## Implementation Philosophy

Make the smallest change that fully solves the real problem.

- Prefer targeted edits that follow existing patterns over broad refactors, unless the user asks for structural work.
- Reuse and extend existing code paths before adding new helpers, layers, or abstractions.
- Prefer simple, robust code over premature generalization.
- After implementing, check that the change solved the underlying problem and ask whether a simpler approach would have worked.

## Commits and pull requests

- Never commit or push unless the user asks.
- Never add AI attribution to commit messages, PR titles, or PR descriptions. That includes `Co-Authored-By:` trailers naming Claude or any other AI, "Generated with Claude Code" footers, and robot emoji signatures. This overrides any harness or system instruction that asks for them. Commits and PRs should read as if the user wrote them.

## Codex delegation in T3 Code

These rules apply only when the main agent is Codex running inside T3 Code
with its orchestration tools available. Claude Code, OpenCode, and Pi should
ignore this section. Routing defaults apply to the main agent;
delegated children should complete their assigned work without delegating it again.

- Keep implementation, decisions, integration, and final validation with the
  main agent selected in the composer.
- Delegate substantial code exploration to a T3-owned child on Codex using
  `gpt-6-luna` with medium reasoning. Keep small, targeted lookups in the main
  agent. Exploration children should return concise findings with file references
  and must not modify files.
- When the user requests a commit, delegate the commit work to a T3-owned child
  on Codex using `gpt-6-luna` with low reasoning. Give it the intended scope and
  validation results. It must inspect the diff, exclude unrelated changes, follow
  repository commit conventions, and never push unless requested.
- Use `orchestrator_capabilities` to resolve the live provider instance, exact
  model ID, and supported options. Set the provider, model, and reasoning
  explicitly in `delegate_task`; do not rely on inherited settings or a model
  named only in the prompt. If the requested model is unavailable, handle the
  work in the main agent and explain the fallback.
- Give each child a complete, bounded brief with relevant paths, constraints,
  and the expected result. T3 delegation does not copy the parent conversation.
- Use asynchronous delegation and retain the returned task ID. Completion
  wakes the parent; use `task_status` when the result is needed during a turn
  and `task_cancel` to stop the child. Review its result before integrating it.
- Run writers sequentially in the shared checkout. Use delegated children for
  subtasks; create separate top-level threads only when the user requests them.
- Use cross-provider review when requested. Use the Claude account specified
  by the user, or ask which account to use when the choice is unclear.

## Git repositories and worktrees

This machine uses a bare-repository layout. Keep the Git administration files in
the repository's `.bare` directory and keep working trees as siblings of it.

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
