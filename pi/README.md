# Pi local workflows

## `/review` Neovim diff review

The `pi/agent/extensions/review.ts` extension adds a `/review` slash command for reviewing the current git diff in Neovim.

What it does:

- detects the current git repo
- generates a git diff for the selected scope (default: `git diff HEAD --no-ext-diff --unified=80 -- .`)
- writes the diff to `.pi/reviews/latest.diff`
- opens `nvim -R` with a local Lua review module
- saves comments to:
  - `.pi/reviews/latest.md`
  - `.pi/reviews/latest.json`
- does **not** submit anything to the agent automatically

After Neovim exits, Pi asks whether to prefill the editor with:

```text
Please address my review comments.

@.pi/reviews/latest.md
```

You can edit or discard that prompt before sending it.

### Neovim keymaps

Inside review mode:

- `<leader>rc` — add/edit a multiline comment on the current diff body line. In your setup `<leader>` is usually `\\`, so try `\\rc` if unsure. Save the comment editor with `<C-s>` or cancel with `q` in normal mode. Saving a comment immediately updates Markdown/JSON.
- `<leader>rd` — delete the comment on the current line and immediately update Markdown/JSON.
- `<leader>rx` — toggle the comment resolved/unresolved and immediately update Markdown/JSON
- `<leader>rR` — restart the review by clearing all saved comments after confirmation
- `<leader>rs` — save Markdown and JSON review files
- `<leader>rq` — save and quit
- `<leader>rn` — next comment
- `<leader>rp` — previous comment
- `]f` — next changed file
- `[f` — previous changed file

Comments can be attached to added, removed, and context diff lines. Diff headers and metadata lines are not commentable.

### Diff scopes

`/review` accepts common git-diff options:

- `/review` — tracked staged + unstaged changes relative to `HEAD` in Diffview mode
- `/review --staged` — staged changes only
- `/review --unstaged` — unstaged changes relative to the index
- `/review --base <rev>` — diff against a base revision instead of `HEAD`
- `/review --merge-base <rev>` — triple-dot range, e.g. `origin/main...HEAD`
- `/review --untracked` — append untracked files as new-file diffs
- `/review --unified <n>` — set context lines
- `/review --reset` — restart the review by deleting saved comments before opening
- `/review -- path/to/file ...` — restrict to paths
- `/review --raw` — use the old unified-diff buffer mode
- `/review --diffview` — explicitly use Diffview side-by-side mode, now the default

### Notes

- Existing unresolved comments are preserved and remapped when possible using semantic anchors (`file`, `side`, `line`) instead of only raw diff line numbers.
- Comments include `resolved: false` in JSON and `[ ]` checkboxes in Markdown; resolved comments are hidden from future review sessions.
- Markdown checkboxes are synced back into JSON on review load/save, so changing `### [ ] Line N` to `### [x] Line N` marks that comment resolved without manually editing JSON.
- Saved Markdown includes scope, grouped files, side/line metadata, quoted code, and nearby context.
- Diffview mode uses real file buffers/windows and preserves the same comment/save keymaps where possible.
- Review files are repo-local under `.pi/reviews/` so they can be referenced from Pi prompts with `@.pi/reviews/latest.md`.
- `/review` best-effort appends `.pi/reviews/` to `.git/info/exclude` to avoid untracked review artifacts.
