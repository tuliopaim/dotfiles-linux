---
name: auto-commit
description: >
  Check uncommitted files, understand the changes at a high level, and create
  commits. Split into multiple commits only when strictly necessary. If the
  current branch name contains a ticket number (e.g., ABC-123), prepend the
  commit message with "TICKET-123: message". Trigger when user says
  "commit changes", "auto-commit", "prepare commit", or similar.
---

Review working tree and index, summarize changes, decide commit strategy, then execute.

## Workflow

1. **Inspect state**
   ```bash
   git status --short
   git diff --cached --stat
   git diff --stat
   ```

2. **Read diffs** to understand intent.
   - For small / single-concern changes: one commit.
   - For unrelated changes across domains (e.g., docs + refactor + feature): split.

3. **Decide commit split**
   - **Single commit** if all changes serve one purpose.
   - **Multiple commits** only if mixing orthogonal concerns. In that case group files logically and commit in dependency order (infra → lib → feature → tests → docs).

4. **Build commit message**
   - Determine current branch: `git branch --show-current`
   - Extract ticket number if present (pattern like `\b[A-Z]+-\d+\b`).
   - Prefix: `TICKET-123: {summary}`
   - If no ticket number, just `{summary}`.
   - Use imperative mood, lowercase after prefix, no period at end.
   - Examples:
     - `PROJ-42: add user authentication middleware`
     - `OPS-7: fix memory leak in worker pool`
     - `update readme with install instructions` (no ticket)

5. **Execute**
   - Stage selected files: `git add <files>`
   - Commit: `git commit -m "<message>"`
   - Repeat for each logical group if split.

## Constraints

- Do NOT commit if there are no changes.
- Do NOT commit untracked files unless explicitly included in the requested changes.
- Ask user before committing if changes include destructive operations, large binary files, or credential leaks.
- Prefer concise summary (≤72 chars for subject line).
