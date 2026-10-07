# Work

A [Vicinae](https://github.com/vicinaehq/vicinae) extension with quick links for EMS work: Jira boards, Grafana dashboards, your open tickets, your open PRs and the repos you use most.

It's for the work macbook only. Nothing in the dotfiles builds it, so it's only installed where you run `npm run build`.

## Commands

| Command             | Type it as                   | Enter does                                                  |
| ------------------- | ---------------------------- | ----------------------------------------------------------- |
| E2 Board            | `e2`, `board`, `am`          | Opens the EMSmart 2.0 Combined Board                        |
| Services Board      | `emsvc`, `board`, `services` | Opens the Services Board in EMSmart 2.0                     |
| EMServices Prod     | `grafana`, `prod`            | Opens the EMServices Grafana folder in production           |
| EMServices Non-prod | `grafana`, `stage`           | Opens the EMServices Grafana folder in staging              |
| My Tickets          | `tickets`, `jira`            | Lists your open Jira items, grouped by status               |
| My PRs              | `pr`, `pull`                 | Lists your open PRs in the EMS GitHub organization          |
| Work                | `work`, `jira`, `repo`       | Boards, Grafana, both lists and the main repos in one place |

Every link opens in Microsoft Edge, not the default browser. If Edge already has a tab on that page, it switches to that tab instead of opening a new one. A tab on a sub-page counts too, like a PR's Files tab. Boards and repos only match their own page, so your Backlog tab doesn't count as the board and a PR tab doesn't count as the repo. Query strings are ignored, so a board with an issue selected still counts. This lives in `src/edge.tsx`. The board and Grafana commands open Edge straight away and close Vicinae.

In **My Tickets**, typing a key that isn't in the list, like `EMSVC-540`, `am21234` or just `540` (EMSVC by default), adds a row that opens it. Only the projects in `PROJECTS` in `src/config.ts` are recognized. A bare number that matches one of your tickets in any project, like `21234` for AM-21234, doesn't add the row. `⌘⇧C` copies the key and `⌘⌥C` copies the link.

In **My PRs**, the icon shows CI status and the tag shows review status. `⌘J` opens the Jira ticket named in the PR title.

In **Work**, `⌘Enter` on a repo opens its pull requests.

In the lists, `⌘R` refreshes, including from an empty or error screen. Lists show the last results right away and refresh in the background. If a refresh fails, a toast says so and the old results stay. Elsewhere, `⌘⇧C` copies the link.

## Setup

1. `cd ~/dotfiles/vicinae/extensions/work && npm install`
2. `npm run build` builds the extension and installs it into Vicinae.

Data comes from CLIs that are already logged in, so the extension holds no tokens:

| Preference    | Default            | Used for                            |
| ------------- | ------------------ | ----------------------------------- |
| acli Path     | found on `PATH`    | `acli jira workitem search`         |
| gh Path       | found on `PATH`    | `gh api graphql`                    |
| gh Config Dir | `~/.config/gh-ems` | `GH_CONFIG_DIR` for the EMS account |

## Adding boards, dashboards and repos

Boards, dashboards and repos live in `src/config.ts`. A new repo is one line in `REPOS`. A new board needs an entry in `BOARDS`, a `no-view` command in `package.json` and a two-line command file like `src/e2-board.ts`. A new Grafana link works the same way, with an entry in `DASHBOARDS` and a command file like `src/emservices-grafana-prod.ts`.
