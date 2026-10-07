# T3 Code

Use the live T3 MCP tool descriptions for supported arguments. Bind T3 to the exact sibling worktree path instead of using its default worktree location or waiting for UI discovery.

If the request only selects T3 Code, clarify whether to move the current conversation or open a new one. Continue repository discovery while waiting. Create a thread only for an explicit request such as "create a new T3 thread."

## Move the current conversation

Use this path when explicitly requested and the new worktree has not already been created:

1. Call `t3_worktree_status`. Confirm the thread is not already attached to a worktree and its project's Git common directory matches the selected repository.
2. Choose and validate the branch, sibling path, and base as described in `SKILL.md`, including fetching a remote base. The handoff creates the checkout, so do not first create it through Git.
3. Call `t3_worktree_handoff` as the last action of the turn. Pass the selected branch, absolute sibling `path`, and the exact verified ref as `baseRef`. Set `startFromOrigin: false` because the selected ref already identifies the local or fetched remote base. Set `runSetupScript: false` to let the continuation read repo instructions before running setup.
4. Supply `continuationPrompt` with the task context, chosen path/base, and remaining setup. Tell it to read the new checkout's `AGENTS.md`, initialize pinned submodules, run required repository and configured T3 worktree setup, verify the binding, and report readiness. It must not create another checkout, invoke Herdr, or implement the task unless requested.

This preserves the conversation and uses the specified path. The current turn ends after handoff. If the thread is already attached, the target is another repository, or the branch/worktree already exists, this handoff is unavailable. Prepare or reuse the checkout normally and offer the new-thread route below; launch it only when requested.

## Open a requested new thread

1. List registered projects with `t3_project_list`, following pagination if needed. Find the selected repository by checking that the project's workspace and the new checkout share the same Git common directory. Do not inherit the caller's project when setting up another repository.
2. If no project exists and the user requested a new T3 thread, register the already-created checkout with `t3_project_create`, supplying its absolute path as `workspaceRoot`. Do not omit the path or create a new repository. Preserve existing project settings.
3. Inspect `t3_thread_list` for the selected project before launching, especially on a retry. Reuse a thread for the same setup when appropriate; use `t3_thread_read` to confirm its checkout rather than matching its title alone.
4. Call `t3_thread_launch` with the selected `projectId`, a title based on the task description or issue title and its identifier when supplied, and:

   ```json
   {
     "workspaceStrategy": {
       "type": "existing_worktree",
       "worktreePath": "/absolute/path/to/the/prepared/worktree",
       "branch": "add-search"
     }
   }
   ```

   Leave `message` omitted for setup alone. Pass an implementation task only if the user explicitly requested starting that work. Honor a requested provider/model. When opening a different project, pass its configured `defaultModelSelection` as `modelSelection` if present; omitting it inside T3 inherits the caller's selection.
5. Retain the returned `threadId` and `link`. Preparation may still be running after acceptance; read the thread to verify its worktree binding and status before reporting it ready. After a failed call or lost response, inspect the thread inventory before retrying because launch has no idempotency key.

Use this existing-worktree strategy to preserve the user's sibling-directory layout. Do not ask a new thread's agent to create its own worktree, since that would leave T3's binding unchanged. Do not use delegated tasks as substitutes for the user's workspace, or hand off an unrelated setup conversation into another repository.

If T3 tools are not exposed and `T3_ACP_MCP_NODE` is set, use the supported ACP MCP transport, for example:

```sh
ELECTRON_RUN_AS_NODE=1 "$T3_ACP_MCP_NODE" ${T3_ACP_MCP_ENTRYPOINT:+"$T3_ACP_MCP_ENTRYPOINT"} acp-mcp-call t3_project_list '{}'
```

Pass other tool names and properly quoted JSON arguments through the same transport. Otherwise finish the Git setup and report that app binding remains incomplete; do not invent a T3 CLI or edit its storage.
