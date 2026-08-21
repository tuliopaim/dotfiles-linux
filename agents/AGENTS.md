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
