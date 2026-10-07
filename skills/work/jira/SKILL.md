---
name: jira
description: Read and update EMS Jira work items with the Atlassian CLI (acli). Use when a request mentions Jira, a ticket or work item key like AM-21312 or EMSVC-123, a sprint, or JQL.
---

# Jira via acli

`acli` is already logged in to `emsmc1.atlassian.net` as `tulio.paim@emsmc.com`. Check with `acli jira auth status` if a command fails with an auth error. Do not log in again or handle tokens yourself; ask the user instead.

## Projects

- `AM` — EMSmart 2.0. **Create Tulio's new work here.** The services team's work moved from EMSVC to AM in September 2026 and is identified by the `services-team` label. It still appears on the EMServices board (board 913) and in its sprints.
- `EMSVC` — EMServices. Legacy: read existing EMSVC-* tickets, but do not create new ones here.
- `SOL` — EMSolutions
- `DE` — Data Engineering Team
- `DEVOPS2` — DevOps

## Reading

Add `--json` when you need to parse output. The default table output wraps long text.

```sh
acli jira workitem search --jql "assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC" --limit 20
acli jira workitem search --jql "project = AM AND labels = services-team AND sprint in openSprints()" --fields key,summary,status,assignee
acli jira workitem view AM-123
acli jira workitem view AM-123 --fields '*all' --json
acli jira workitem comment list --key AM-123
acli jira sprint --help   # boards and sprints
```

## Writing

These change shared data that teammates see. Confirm with the user before running them, unless they asked for that exact change. Pass `--yes` to skip acli's own prompt, since agents can't answer it.

```sh
acli jira workitem create --project AM --type Task --label services-team --summary "..." --description-file desc.md --assignee @me
acli jira workitem comment create --key AM-123 --body "..."
acli jira workitem transition --key AM-123 --status "Code Review" --yes
acli jira workitem assign --key AM-123 --assignee @me --yes
acli jira workitem edit --key AM-123 --summary "..." --yes
```

Transitions use the target status name. Statuses include `In Progress`, `Code Review`, `Dev: Testing` and `Approved for Release`. If a transition fails, view the item to see its current status and try a status the workflow allows from there.

For long descriptions or comments, write the text to a temp file and use `--description-file` or `--body-file` so shell quoting doesn't mangle it.

New tickets go to the backlog. `acli jira workitem create` cannot set a sprint, so tell the user to add it to one if they need that.

Run `acli jira workitem <command> --help` for flags not listed here.
