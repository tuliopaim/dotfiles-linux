# Pi local workflows

## Multi-agent workflows

Use the `workflow` tool for substantial tasks that benefit from parallel research, phased implementation, or independent synthesis. Keep focused one-off work in the existing tools:

- `scout` — locate and understand code
- `review` — independently review completed changes
- `commit` — create requested commits
- `workflow` — coordinate several isolated agents

Workflow children cannot invoke those delegation tools or recursively start workflows. Every `agent()` call must explicitly select a `provider/model-id` and reasoning `effort`; missing either fails before contacting a provider.

### Model routing

| Role | Model | Effort | Benefit | Trade-off |
|---|---|---|---|---|
| Reconnaissance, code tracing, test discovery | `opencode-go/deepseek-v4-flash` | `medium` | Large context for cheap bulk reading | Not the default for delicate edits |
| Implementation and integration | `opencode-go/kimi-k2.7-code` | `high` | Code-focused without OpenAI quota usage | Smaller 262K context |
| Planning and synthesis | `openai-codex/gpt-5.6-sol` | `high` | Strong judgment over compact findings | Scarce weekly quota |
| Consequential adversarial/final review | `openai-codex/gpt-5.6-sol` | `high` | Best reserved for correctness decisions | Scarce weekly quota |
| Routine verification and report formatting | `opencode-go/deepseek-v4-flash` | `medium` or `low` | Cheap and sufficient | Less useful for ambiguous design decisions |

Other enabled alternatives are `opencode-go/minimax-m3` for experiments and `openai-codex/gpt-5.6-terra` for strong implementation when OpenAI quota is intentionally available. Do not use Sol for reconnaissance or routine implementation. Keep reconnaissance outputs bounded so premium agents consume findings rather than raw transcripts.

When a schema-bound agent returns prose without `structured_output`, the runner asks it once, in the same session, to submit its existing findings correctly. Agents are required by default: one failure mechanically blocks all later agents and fails the workflow. The parent orchestrator then inspects the error and decides whether to retry, narrow/split the assignment, or change models; workflows do not blindly retry failures or unchanged timeouts. Use `optional: true` only for planned best-effort read-only work whose absence cannot affect later phases.

```js
const scan = await agent(prompt, {
  label: 'event-flow',
  phase: 'Reconnaissance',
  model: 'opencode-go/deepseek-v4-flash',
  effort: 'medium',
  schema: TRACE,
})
```

### Orchestrated task with plan approval

Start the reusable recipe with:

```text
/orchestrate Add organization-level API tokens
```

The planning workflow runs parallel reconnaissance, creates a plan, reviews it adversarially, and then stops without editing. Review or refine the returned plan in the parent conversation:

```text
Keep the migration backward-compatible and put the API tests in the existing token suite.
```

When satisfied, explicitly approve it:

```text
Approved, continue.
```

A new workflow implements the approved plan, integrates the agents' changes, and verifies the result. This is intentionally two workflow runs: the parent conversation is the human checkpoint, so no paused child or resume protocol is required.

Use `/skill:orchestrated-task <task>` as the direct alternative to `/orchestrate`, and `/workflows` to inspect active and completed runs. Nothing commits automatically.

For other large tasks, ask Pi to “use a workflow” or “orchestrate this.” Pi generates a task-specific script rather than selecting a fixed pipeline. Parallel implementation is allowed only when agents own disjoint files.

### Setup and checks

After cloning the dotfiles, install the workflow dependencies:

```sh
npm install --prefix ~/dotfiles/pi/agent
```

Apply the Home Manager configuration and run `/reload` in Pi after configuration changes.

Run the workflow checks with:

```sh
npm run --prefix ~/dotfiles/pi/agent test:workflows
```

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
