# Machine sync audit, October 5, 2026

The common starting point was `e4f64cd`, the published `main` tip. The MacBook
was at `7673f7e`; the Mac Mini was at `f586282`. Both had uncommitted changes.

`main` holds shared behavior, including platform-specific modules when they are
wanted on every machine of that platform. The `macbook` and `macmini` branches
hold the changes kept on those machines. This audit deliberately keeps AeroSpace
on the MacBook and the EF skill and Teams presence automation on the Mac Mini,
as requested. Neither machine branch should be merged wholesale into `main`.

## MacBook commits after main

| Commit | Change | Destination | Reason |
| --- | --- | --- | --- |
| `3e4025a` | Atlassian MCP configuration | MacBook | Work integration, even though currently disabled. |
| `da12342` | GitHub CLI account switching under `~/dev/ems` | MacBook | EMS account and workspace. |
| `54b3df0` | AeroSpace migration | MacBook | Explicit choice for this sync. Includes install/config and optional skhd STT config. |
| `44ed65a` | Jira skill, acli, work-skill option | MacBook | Job tooling, enabled in the MacBook host module. |
| `54c8776` | Work Vicinae extension and favorite | MacBook | EMS links, Jira, work PRs. |
| `315f320` | EMS skill | MacBook | Work repositories and workflow. |
| `7673f7e` | Nix input lock update | Main | General package inputs; shared copy is `cef06a4`. |

## Mac Mini commits after main

| Commit | Change | Destination | Reason |
| --- | --- | --- | --- |
| `ee2225c` | Entity Framework Core skill | Mac Mini | Explicit choice for this sync. |
| `081ebeb` | Teams presence automation, private pin, shell helpers | Mac Mini | Explicit choice; includes a private-repository dependency. |
| `8c8dea3` | Private repository pin | Mac Mini | Retain its machine-specific private revision. |
| `f586282` | Pi pin to `71c9395` | Superseded by shared Pi pin | Old local fork that added Copilot models. Preserve its history and local model choices during deployment. |

The Mac Mini's private revision `bff4413` is available on that machine but was
not downloadable from the published private remote during the audit. Keep the
existing checkout and backup branch. A fresh clone of that branch would need
that private commit published separately.

## Shared changes prepared from the working tree

| Shared commit | Change | Scope |
| --- | --- | --- |
| `4091a37` | Link shared skills individually into `~/.agents/skills`, in Nix and symlinks.sh | All machines. Work skill activation stays on the MacBook branch. |
| `4331ec8` | Herdr document review shortcuts and disabled sounds | Shared terminal behavior. |
| `1978774` | Pin Pi to published `76574bc` | All machines. Extension dependencies must be installed after updating. |

These copies were made in a separate checkout. The MacBook's original working
files were left in place, including the shared edits copied into these commits.

## Pi repository changes

The previous main pin was `dcb7e1b`. The new pin `76574bc` is already on Pi's
published main branch. The commits between them are:

| Commit | Change | Scope |
| --- | --- | --- |
| `cdb6d43` | Named agents and live job workflows | Shared Pi behavior. |
| `041c29a` | Wait ownership and usage reporting | Shared Pi behavior. |
| `a0b4857` | Remove the subagents command alias | Shared Pi behavior. |
| `5918ce5` | Default and enabled gpt-6.1-sol settings | Shared Pi behavior. |
| `76574bc` | Settings/changelog version update | Shared Pi behavior. |

Pi CLI is installed outside Nix. Match the MacBook's installed version `1.0.3`
on the Mac Mini, and run `npm ci --prefix ~/dotfiles/pi/agent`. The local dirty
MacBook change only updates `lastChangelogVersion` from `1.0.2` to `1.0.3` and was
left uncommitted. Preserve the Mac Mini's Copilot entries as local settings.

## Changes left local

On the MacBook: the newer uncommitted Nix lock refresh, T3 nightly cask choice,
unfinished Work extension/Grafana changes, Neovim changes, private-repository
edits and untracked work data, and Pi's runtime-written changelog version.

On the Mac Mini: its newer uncommitted Nix lock refresh, removal of the Homebrew
OpenCode package, deleted camera launcher, Neovim lock update, and local Pi model
choices. Preserve these before integrating main and restore them afterwards.

## Verification and future updates

Pi's agent and web-tools type checks pass on the MacBook. The full Pi test suite
passes with `TZ=UTC`. A dashboard test hard-codes midnight for epoch timestamps;
it fails in the Sao Paulo timezone because the rendered local time is 21:00.
This is an existing test assumption, not a deployment failure.

For future syncs, inspect each machine's commits beyond `origin/main`, update
only the shared commits, and merge main into the machine branch with local work
saved. Use `git fetch --no-recurse-submodules` first: a machine branch can point
to unpublished private or Pi commits. Update Pi explicitly to the shared pin,
install its dependencies, and check both `pi --version` and extension loading.

A full Mac Mini system activation requires its sudo password:

```sh
sudo darwin-rebuild switch --flake ~/dotfiles/nix#macmini
```

Do not run the generic symlinks script just to update Pi: it touches unrelated
configurations too. Link the shared skill folders and check the existing Pi
settings and AGENTS.md links directly when a full Nix switch is unavailable.
