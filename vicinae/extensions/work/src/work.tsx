import { Action, ActionPanel, Icon, List } from "@vicinae/api";
import { OpenInEdge } from "./edge";
import { BOARDS, boardUrl, DASHBOARDS, GITHUB_ORG, REPOS, repoUrl } from "./config";
import { PullRequestsList } from "./my-prs";
import { TicketsList } from "./my-tickets";

export default function Command() {
  return (
    <List searchBarPlaceholder="Boards, dashboards, tickets, PRs and repos">
      <List.Section title="Boards">
        {BOARDS.map((board) => (
          <List.Item
            key={board.command}
            title={board.title}
            subtitle={board.subtitle}
            keywords={["board", ...board.keywords]}
            icon={Icon.Jira}
            actions={
              <ActionPanel>
                <OpenInEdge title="Open Board" url={boardUrl(board)} exact />
                <Action.CopyToClipboard
                  title="Copy Link"
                  content={boardUrl(board)}
                  shortcut={{ modifiers: ["cmd", "shift"], key: "c" }}
                />
              </ActionPanel>
            }
          />
        ))}
      </List.Section>
      <List.Section title="Grafana">
        {DASHBOARDS.map((dashboard) => (
          <List.Item
            key={dashboard.command}
            title={dashboard.title}
            subtitle={new URL(dashboard.url).host}
            keywords={["grafana", "dashboard", "dashboards", "metrics", ...dashboard.keywords]}
            icon={Icon.Grafana}
            actions={
              <ActionPanel>
                <OpenInEdge title="Open Dashboards" url={dashboard.url} />
                <Action.CopyToClipboard
                  title="Copy Link"
                  content={dashboard.url}
                  shortcut={{ modifiers: ["cmd", "shift"], key: "c" }}
                />
              </ActionPanel>
            }
          />
        ))}
      </List.Section>
      <List.Section title="Lists">
        <List.Item
          title="My Tickets"
          subtitle="Open Jira work items assigned to you"
          keywords={["tickets", "issues", "jira"]}
          icon={Icon.Jira}
          actions={
            <ActionPanel>
              <Action.Push title="Show My Tickets" target={<TicketsList />} />
            </ActionPanel>
          }
        />
        <List.Item
          title="My PRs"
          subtitle={`Open pull requests in ${GITHUB_ORG}`}
          keywords={["pr", "prs", "pull", "github"]}
          icon={Icon.Github}
          actions={
            <ActionPanel>
              <Action.Push title="Show My PRs" target={<PullRequestsList />} />
            </ActionPanel>
          }
        />
      </List.Section>
      <List.Section title="Repos">
        {REPOS.map((repo) => (
          <List.Item
            key={repo.name}
            title={repo.title}
            subtitle={repo.name}
            keywords={["repo", "github", ...repo.keywords]}
            icon={Icon.Github}
            actions={
              <ActionPanel>
                <OpenInEdge title="Open Repo" url={repoUrl(repo.name)} exact />
                <OpenInEdge
                  title="Open Pull Requests"
                  url={`${repoUrl(repo.name)}/pulls`}
                  shortcut={{ modifiers: ["cmd"], key: "return" }}
                />
                <Action.CopyToClipboard
                  title="Copy Link"
                  content={repoUrl(repo.name)}
                  shortcut={{ modifiers: ["cmd", "shift"], key: "c" }}
                />
              </ActionPanel>
            }
          />
        ))}
      </List.Section>
    </List>
  );
}
