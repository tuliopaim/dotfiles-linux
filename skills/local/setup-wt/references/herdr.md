# Herdr workspace

Use `herdr --help` and the `workspace`, `pane`, and `tab` command-group help to confirm the installed CLI. Do not run bare `herdr` for discovery; it opens the TUI.

## Select the session

Inside Herdr, use the inherited session and socket context. Outside Herdr, including T3 Code, this setup workflow targets the local `default` session explicitly with `herdr --session default ...`. Honor a session supplied by the user instead. Use that same prefix for every API command; do not control whichever workspace happens to have UI focus. This workflow authorizes creating a workspace for the selected worktree, not modifying another workspace.

If the requested session is unavailable, keep the worktree and report the app step as incomplete. Do not start, stop, or upgrade Herdr servers as a retry.

## Create or reuse

Use `<repo>-<worktree-directory>` as the label, for example `my-api-add-search`. Derive the repo name from its repository container or primary checkout, not from an arbitrary current worktree's directory.

List workspaces first:

```sh
herdr workspace list
```

Apply the selected session prefix to these examples when outside Herdr. Reuse a workspace for the exact worktree path. Check its details and panes before using a matching label; a label alone does not establish its directory. If that label belongs to another path, choose a distinct label without renaming the unrelated workspace.

For a new workspace:

```sh
herdr workspace create --cwd "$task_worktree" --label "$task_label" --no-focus
```

Read the workspace ID from `.result.workspace.workspace_id` and the initial pane ID from `.result.root_pane.pane_id`. Keep those IDs. After a failed or ambiguous creation response, inspect the inventory before retrying.

## Set up the tabs

`hsw` requires the target pane's `HERDR_PANE_ID`. Run it through that pane's shell, not through the agent's own execution environment:

Read `~/dotfiles/scripts/hsw` to inspect its behavior. Do not execute it in the caller's shell for discovery. Never assume a helper supports `--help`; an unsupported flag can run its normal actions. The caller's inherited `HERDR_PANE_ID` targets the caller's workspace, not the new task workspace.

```sh
herdr pane run "$task_pane_id" '"$HOME/dotfiles/scripts/hsw"'
```

Confirm the pane is an available shell before sending input. Never send the command into an existing editor, agent, or other foreground process. `pane run` confirms submission, so inspect the target pane's output and verify the tabs:

```sh
herdr tab list --workspace "$task_workspace_id"
herdr pane read "$task_pane_id" --source recent-unwrapped --lines 40
```

Allow a short bounded wait for setup to finish. Expect `ai`, `nvim`, and `terminal` tabs, with the new panes in the selected worktree. These are tab labels; `hsw` does not launch an agent or Neovim.

`hsw` creates additional tabs on every run. Skip it when the layout already exists. On a partial failure, inspect the existing tabs and add only missing tabs with explicit workspace and cwd arguments instead of rerunning the entire script. Leave unrelated tabs and running processes alone.

Focus the verified workspace when setup finishes, unless the user requested no focus:

```sh
herdr workspace focus "$task_workspace_id"
```
