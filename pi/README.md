# Pi local workflows

## Code review

Code review of agent-produced changes lives outside Pi now. See:

- Neovim plugin: `agent-review.nvim` (`~/dev/personal/agent-review.nvim`, wired in via `nvim/lua/plugins/agent-review.lua`)
- Agent skill: `skills/review-comments/SKILL.md`

Workflow:

1. In any git repo, open Neovim. Two entry points:
   - `:ReviewStart` (or `<leader>rR`) — opens Diffview for the working tree. Accepts Diffview args, e.g. `:ReviewStart origin/main...HEAD`.
   - `<leader>rc` in any normal buffer under the repo — bootstraps a review session and opens the comment dialog on the current line, no Diffview needed.
2. Leave inline comments with `<leader>rc`. Save/quit with `<leader>rq`. Comments are written to `<repo>/.review/comments.json` (auto-added to `.git/info/exclude`).
3. Back in any agent (Pi, Claude Code, Codex), say "process my review comments" — the `review-comments` skill walks through each unresolved entry.

### Neovim keymaps

`<leader>rc` works globally in any buffer whose file lives under the repo root, and inside Diffview review buffers. The rest become available once a buffer is attached (Diffview opens, or `<leader>rc` is pressed in a regular buffer):

- `<leader>rc` — add/edit a multiline comment on the current line. `<C-s>` saves, `q` cancels.
- `<leader>rd` — delete the comment on the current line.
- `<leader>rx` — toggle resolved/unresolved.
- `<leader>rs` — save now.
- `<leader>rq` — save and quit.
- `<leader>rn` / `<leader>rp` — next / previous comment in this buffer.
- `<leader>rr` — refresh (close + reopen Diffview, reload comments from disk).
- `<leader>rR` — start (or restart) the Diffview review. Prompts before clearing if a session is active.

Caveats for commenting from a plain buffer (not Diffview): comments always anchor to `side: "new"`, so you can't comment on a deleted line that way; and the line number you pick reflects the buffer's current state, so if you have unsaved edits, the agent may see a slightly different line by the time it reads `comments.json`. Use Diffview when either matters.
