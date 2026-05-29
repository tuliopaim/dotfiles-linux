# Pi local workflows

## `/review` Neovim diff review

The `pi/agent/extensions/review.ts` extension adds a `/review` slash command for reviewing the current git diff in Neovim.

What it does:

- detects the current git repo
- generates `git diff HEAD --no-ext-diff --unified=80 -- .`
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

- `<leader>rc` — add/edit a comment on the current diff body line. In your setup `<leader>` is usually `\\`, so try `\\rc` if unsure.
- `<leader>rd` — delete the comment on the current line
- `<leader>rs` — save Markdown and JSON review files
- `<leader>rq` — save and quit
- `<leader>rn` — next comment
- `<leader>rp` — previous comment
- `]f` — next changed file
- `[f` — previous changed file

Comments can be attached to added, removed, and context diff lines. Diff headers and metadata lines are not commentable.

### Notes and limitations

- The diff is tracked staged + unstaged changes relative to `HEAD`.
- Untracked files are not included in the MVP.
- Review files are repo-local under `.pi/reviews/` so they can be referenced from Pi prompts with `@.pi/reviews/latest.md`.
- `/review` best-effort appends `.pi/reviews/` to `.git/info/exclude` to avoid untracked review artifacts.
