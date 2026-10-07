import { Action, ActionPanel, Color, Icon, List } from "@vicinae/api";
import { useState } from "react";
import { useCachedLoad } from "./cached";
import { issueUrl } from "./config";
import { loadPullRequests, PullRequest } from "./github";
import { OpenInEdge } from "./edge";
import { findKey } from "./tickets";

function ago(iso: string): string {
  const minutes = Math.round((Date.now() - Date.parse(iso)) / 60_000);
  if (minutes < 60) return `${minutes}m`;
  if (minutes < 60 * 24) return `${Math.round(minutes / 60)}h`;
  return `${Math.round(minutes / (60 * 24))}d`;
}

function reviewTag(pr: PullRequest): List.Item.Accessory {
  if (pr.isDraft) return { tag: { value: "Draft", color: Color.SecondaryText } };
  switch (pr.review) {
    case "APPROVED":
      return { tag: { value: "Approved", color: Color.Green } };
    case "CHANGES_REQUESTED":
      return { tag: { value: "Changes requested", color: Color.Red } };
    case "REVIEW_REQUIRED":
      return { tag: { value: "Review required", color: Color.Orange } };
    default:
      // GitHub only reports a decision when the repo requires reviews.
      return { tag: { value: "No review required", color: Color.SecondaryText } };
  }
}

function checksIcon(pr: PullRequest) {
  switch (pr.checks) {
    case "SUCCESS":
      return { value: { source: Icon.CheckCircle, tintColor: Color.Green }, tooltip: "Checks passed" };
    case "FAILURE":
    case "ERROR":
      return { value: { source: Icon.XMarkCircle, tintColor: Color.Red }, tooltip: "Checks failed" };
    case "PENDING":
    case "EXPECTED":
      return { value: { source: Icon.Clock, tintColor: Color.Yellow }, tooltip: "Checks running" };
    default:
      return { value: { source: Icon.Circle, tintColor: Color.SecondaryText }, tooltip: "No checks" };
  }
}

export function PullRequestsList() {
  const [reloads, setReloads] = useState(0);
  const { data, error, isLoading } = useCachedLoad("pull-requests", loadPullRequests, reloads);
  const refresh = () => setReloads((count) => count + 1);
  const refreshAction = (
    <Action title="Refresh" icon={Icon.ArrowClockwise} shortcut={{ modifiers: ["cmd"], key: "r" }} onAction={refresh} />
  );

  return (
    <List navigationTitle="My PRs" isLoading={isLoading} searchBarPlaceholder="Filter your open PRs">
      {error && !data && (
        <List.EmptyView
          icon={Icon.Warning}
          title="Could not load PRs"
          description={error}
          actions={<ActionPanel>{refreshAction}</ActionPanel>}
        />
      )}
      {data?.length === 0 && (
        <List.EmptyView icon={Icon.Github} title="No open PRs" actions={<ActionPanel>{refreshAction}</ActionPanel>} />
      )}
      {data?.map((pr) => {
        const key = findKey(pr.title);
        return (
          <List.Item
            key={pr.url}
            title={pr.title}
            subtitle={`${pr.repo} #${pr.number}`}
            keywords={[pr.repo, String(pr.number)]}
            icon={checksIcon(pr)}
            accessories={[reviewTag(pr), { text: ago(pr.updatedAt), tooltip: `Updated ${pr.updatedAt}` }]}
            actions={
              <ActionPanel>
                <OpenInEdge title="Open PR" url={pr.url} />
                {key && (
                  <OpenInEdge
                    title={`Open ${key} in Jira`}
                    icon={Icon.Jira}
                    url={issueUrl(key)}
                    shortcut={{ modifiers: ["cmd"], key: "j" }}
                  />
                )}
                <Action.CopyToClipboard
                  title="Copy PR Link"
                  content={pr.url}
                  shortcut={{ modifiers: ["cmd", "shift"], key: "c" }}
                />
                {refreshAction}
              </ActionPanel>
            }
          />
        );
      })}
    </List>
  );
}

export default function Command() {
  return <PullRequestsList />;
}
