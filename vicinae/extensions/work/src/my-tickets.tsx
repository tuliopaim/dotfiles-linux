import { Action, ActionPanel, Color, Icon, List } from "@vicinae/api";
import { useState } from "react";
import { useCachedLoad } from "./cached";
import { OpenInEdge } from "./edge";
import { issueUrl } from "./config";
import { loadTickets, parseKey, Ticket } from "./tickets";

/** Sections come in this order: active work first, parked and not-started work last. */
const STATUS_ORDER = [
  "In Progress",
  "Code Review",
  "Dev: Testing",
  "Ready for QA",
  "UAT in Progress",
  "Approved for Release",
  "On Hold",
  "To Do",
  "Backlog",
];

/** Unlisted statuses go after the listed ones: in-progress ones first, then to-do, then by name. */
function compareStatus(a: Ticket, b: Ticket): number {
  const rank = (ticket: Ticket) => {
    const index = STATUS_ORDER.indexOf(ticket.status);
    return index !== -1 ? index : STATUS_ORDER.length + (ticket.category === "indeterminate" ? 0 : 1);
  };
  return rank(a) - rank(b) || a.status.localeCompare(b.status);
}

function groupByStatus(tickets: Ticket[]): [string, Ticket[]][] {
  const groups = new Map<string, Ticket[]>();
  for (const ticket of [...tickets].sort(compareStatus)) {
    const group = groups.get(ticket.status);
    if (group) group.push(ticket);
    else groups.set(ticket.status, [ticket]);
  }
  return [...groups];
}

function statusIcon(ticket: Ticket) {
  if (ticket.status === "Approved for Release") return { source: Icon.CheckCircle, tintColor: Color.Green };
  if (ticket.category === "indeterminate") return { source: Icon.CircleProgress50, tintColor: Color.Blue };
  return { source: Icon.Circle, tintColor: Color.SecondaryText };
}

function RefreshAction({ onRefresh }: { onRefresh: () => void }) {
  return (
    <Action
      title="Refresh"
      icon={Icon.ArrowClockwise}
      shortcut={{ modifiers: ["cmd"], key: "r" }}
      onAction={onRefresh}
    />
  );
}

function TicketActions({ ticketKey, onRefresh }: { ticketKey: string; onRefresh: () => void }) {
  return (
    <ActionPanel>
      <OpenInEdge title="Open in Jira" url={issueUrl(ticketKey)} />
      <Action.CopyToClipboard
        title="Copy Key"
        content={ticketKey}
        shortcut={{ modifiers: ["cmd", "shift"], key: "c" }}
      />
      <Action.CopyToClipboard
        title="Copy Link"
        content={issueUrl(ticketKey)}
        shortcut={{ modifiers: ["cmd", "opt"], key: "c" }}
      />
      <RefreshAction onRefresh={onRefresh} />
    </ActionPanel>
  );
}

export function TicketsList() {
  const [reloads, setReloads] = useState(0);
  const [searchText, setSearchText] = useState("");
  const { data, error, isLoading } = useCachedLoad("tickets", loadTickets, reloads);
  const refresh = () => setReloads((count) => count + 1);

  // A bare number like `21234` is also listed when any project has it, like AM-21234.
  const typedKey = parseKey(searchText);
  const bareNumber = /^\d+$/.test(searchText.trim()) ? `-${searchText.trim()}` : undefined;
  const showTypedKey =
    typedKey &&
    !data?.some((ticket) => ticket.key === typedKey || (bareNumber !== undefined && ticket.key.endsWith(bareNumber)));

  return (
    <List
      navigationTitle="My Tickets"
      isLoading={isLoading}
      filtering
      onSearchTextChange={setSearchText}
      searchBarPlaceholder="Filter your tickets, or type a key like EMSVC-540 or 540"
    >
      {showTypedKey && (
        <List.Section title="Open">
          <List.Item
            title={`Open ${typedKey}`}
            keywords={[searchText]}
            icon={Icon.Jira}
            actions={<TicketActions ticketKey={typedKey} onRefresh={refresh} />}
          />
        </List.Section>
      )}
      {error && !data && (
        <List.EmptyView
          icon={Icon.Warning}
          title="Could not load tickets"
          description={error}
          actions={
            <ActionPanel>
              <RefreshAction onRefresh={refresh} />
            </ActionPanel>
          }
        />
      )}
      {groupByStatus(data ?? []).map(([status, tickets]) => (
        <List.Section key={status} title={status} subtitle={String(tickets.length)}>
          {tickets.map((ticket) => (
            <List.Item
              key={ticket.key}
              title={ticket.summary}
              subtitle={ticket.key}
              keywords={[ticket.key, ticket.status, ticket.type]}
              icon={statusIcon(ticket)}
              accessories={[{ tag: ticket.type }]}
              actions={<TicketActions ticketKey={ticket.key} onRefresh={refresh} />}
            />
          ))}
        </List.Section>
      ))}
    </List>
  );
}

export default function Command() {
  return <TicketsList />;
}
