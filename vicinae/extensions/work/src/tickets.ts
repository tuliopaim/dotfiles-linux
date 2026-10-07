import { getPreferenceValues } from "@vicinae/api";
import { DEFAULT_PROJECT, PROJECTS } from "./config";
import { resolveBin, run } from "./exec";

export interface Ticket {
  key: string;
  summary: string;
  status: string;
  /** Jira status category: `new`, `indeterminate` or `done`. */
  category: string;
  type: string;
}

interface SearchItem {
  key: string;
  fields: {
    summary: string;
    status: { name: string; statusCategory: { key: string } };
    issuetype: { name: string };
  };
}

const PROJECT = `(${PROJECTS.join("|")})`;
const TYPED_KEY = new RegExp(`^(?:${PROJECT}[-\\s]*)?(\\d+)$`, "i");
const KEY_IN_TEXT = new RegExp(`\\b${PROJECT}-(\\d+)\\b`, "i");

const JQL = "assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC";

export async function loadTickets(): Promise<Ticket[]> {
  const { acliBin } = getPreferenceValues<Preferences>();
  const bin = resolveBin("acli", acliBin);
  const args = ["jira", "workitem", "search", "--jql", JQL, "--fields", "key,summary,status,issuetype"];
  const output = await run(bin, [...args, "--limit", "100", "--json"], {
    ...process.env,
    ACLI_NO_DEPRECATION_WARNINGS: "1",
  });
  return (JSON.parse(output) as SearchItem[]).map((item) => ({
    key: item.key,
    summary: item.fields.summary.trim(),
    status: item.fields.status.name,
    category: item.fields.status.statusCategory.key,
    type: item.fields.issuetype.name,
  }));
}

/** Turns `emsvc-539`, `EMSVC 539`, `emsvc539` or `539` into `EMSVC-539`. */
export function parseKey(text: string): string | undefined {
  const match = text.trim().match(TYPED_KEY);
  if (!match) return undefined;
  return `${(match[1] ?? DEFAULT_PROJECT).toUpperCase()}-${match[2]}`;
}

/** Finds a key like `EMSVC-539` in a PR title. */
export function findKey(text: string): string | undefined {
  const match = text.match(KEY_IN_TEXT);
  return match ? `${match[1].toUpperCase()}-${match[2]}` : undefined;
}
