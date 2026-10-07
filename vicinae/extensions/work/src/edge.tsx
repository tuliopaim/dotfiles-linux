import { Action, closeMainWindow, open } from "@vicinae/api";
import { BOARDS, boardUrl, DASHBOARDS } from "./config";
import { run } from "./exec";

/** Work links open in Edge rather than the default browser. */
const EDGE = "com.microsoft.edgemac";
/** Past this, give up on finding the tab and open a new one. */
const FOCUS_TIMEOUT_MS = 3000;

/**
 * Switches to an Edge tab already showing the URL and prints `found`, or prints `missing`.
 * A tab on a sub-page also counts (`/pull/117/changes` for `/pull/117`) unless the second argument is `exact`.
 * Query strings are ignored, so a board with `?selectedIssue=...` still matches.
 */
const FOCUS_TAB_SCRIPT = `
function run(argv) {
  const normalize = (url) => url.replace(/[?#].*$/, "").replace(/\\/+$/, "");
  const target = normalize(argv[0]);
  const exact = argv[1] === "exact";
  const matches = (url) => normalize(url) === target || (!exact && normalize(url).startsWith(target + "/"));
  const edge = Application("Microsoft Edge");
  if (!edge.running()) return "missing";
  for (const window of edge.windows()) {
    const index = window.tabs.url().findIndex(matches);
    if (index !== -1) {
      window.activeTabIndex = index + 1;
      window.minimized = false;
      window.index = 1;
      edge.activate();
      return "found";
    }
  }
  return "missing";
}`;

async function focusExistingTab(url: string, exact: boolean): Promise<boolean> {
  try {
    const args = ["-l", "JavaScript", "-e", FOCUS_TAB_SCRIPT, url, exact ? "exact" : ""];
    return (await run("/usr/bin/osascript", args, process.env, FOCUS_TIMEOUT_MS)).trim() === "found";
  } catch {
    // Vicinae isn't allowed to control Edge, or Edge didn't answer in time: open a new tab instead.
    return false;
  }
}

export async function openInEdge(url: string, exact = false): Promise<void> {
  if (!(await focusExistingTab(url, exact))) {
    await open(url, EDGE);
  }
  await closeMainWindow({ clearRootSearch: true });
}

export async function openBoard(command: string): Promise<void> {
  const board = BOARDS.find((candidate) => candidate.command === command);
  if (!board) throw new Error(`No board configured for ${command}`);
  await openInEdge(boardUrl(board), true);
}

export async function openDashboard(command: string): Promise<void> {
  const dashboard = DASHBOARDS.find((candidate) => candidate.command === command);
  if (!dashboard) throw new Error(`No dashboard configured for ${command}`);
  await openInEdge(dashboard.url);
}

/**
 * Same as `Action.OpenInBrowser`, but always in Edge, switching to the page's tab if it's already open.
 * Set `exact` when tabs on sub-pages shouldn't count: a repo root would match every PR tab,
 * and a board would match its Backlog or Reports tab.
 */
export function OpenInEdge({ url, exact = false, ...props }: Action.OpenInBrowser.Props & { exact?: boolean }) {
  return <Action {...props} onAction={() => openInEdge(url, exact)} />;
}
