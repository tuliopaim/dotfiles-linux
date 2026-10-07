---
name: ems
description: Navigate the local EMS repositories, their responsibilities and integrations, and the E2/frontend Aspire worktrees. Use when locating EMS code or working across projects under ~/dev/ems.
---

# EMS workspace

All paths below are relative to `~/dev/ems/`. E2 means EMSmart 2.0; the main pair is `ems2` (backend) and `front` (frontend).

## Repositories

| Directory | Responsibility and relationship |
| --- | --- |
| `ems2/` | Main .NET backend: API, domain/application logic, persistence, and workers. Billing Rules V2 lives here under `src/BillingRules/`. |
| `front/` | Main Angular frontend for E2, plus its shared UI component library. Calls the E2 API. |
| `identity-verification/` | Identity verification/TLO service integrated with E2 through worker messaging. |
| `emsservices-billing-rules/` | Standalone legacy Billing Rules (V1). Still used while clients migrate to V2 in E2; intended for retirement. Check which version the task concerns. |
| `importer/` | Imports data from external formats for E2. |
| `exporter/` | Exports E2 data into external formats. |
| `scheduled/` | Scheduled Batcher: scheduled/background batch jobs supporting E2. |
| `audit/` | Audit-log service supporting E2. |
| `common/` | Shared EMSmart code, also consumed through repositories' `integration/` submodules. |
| `emstatus/` | Claim submission/status processing and downstream EOB workflows. |
| `eob_835_converter/` | EOB-to-835 conversion integration. |

`ems2-client/` is another clone of the same frontend repository; use `front/` unless the task points to that clone.

## Local layout

These repositories use `.bare/` plus sibling worktrees: `~/dev/ems/<repo>/<worktree>/`. The repo directory itself is not a source checkout. Locate the relevant worktree with `git -C ~/dev/ems/<repo> worktree list`; directory names can differ from branch names. Read that checkout's `AGENTS.md` for project-specific guidance.

Use the machine's existing `~/dotfiles/scripts/clone-wt` helper for new clones and keep new worktrees under the repo directory. E2 and several support repos have submodules; initialize the selected checkout's pinned versions with `git submodule update --init --recursive` when needed.

## Aspire across feature branches

The reusable local tooling lives on branch `aspire-local` in both repos:

- Backend: `~/dev/ems/ems2/aspire-local/`
- Frontend: `~/dev/ems/front/aspire-local/`

Tulio cherry-picks the tooling commits from each branch into the corresponding feature branch to run the pair together. Inspect each branch's current history to identify those commits and their dependencies; do not assume the backend tip alone contains all setup.

For setup/run details, read the backend's `development/aspire-prototype/README.md` and `development/aspire-prototype/AppHost/README.md`. Point Aspire at the selected frontend worktree; that frontend needs the companion `local-full-stack` configuration. Keep this skill as the workspace map and use those repo docs for evolving launch instructions.
