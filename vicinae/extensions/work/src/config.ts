export const JIRA_SITE = "https://emsmc1.atlassian.net";
export const GITHUB_ORG = "EMS-Management-Consultants";
/** Jira projects whose keys are recognized in typed text and PR titles. */
export const PROJECTS = ["EMSVC", "AM", "SOL", "DE", "DBA", "DEVOPS2"];
/** Project used when a ticket is typed as a bare number, like `539`. */
export const DEFAULT_PROJECT = "EMSVC";

export interface Board {
  /** Matches the no-view command name in package.json. */
  command: string;
  title: string;
  subtitle: string;
  project: string;
  id: number;
  keywords: string[];
}

export interface Dashboard {
  /** Matches the no-view command name in package.json. */
  command: string;
  title: string;
  url: string;
  keywords: string[];
}

export interface Repo {
  name: string;
  title: string;
  keywords: string[];
}

export const BOARDS: Board[] = [
  {
    command: "e2-board",
    title: "E2 Board",
    subtitle: "EMSmart 2.0 · Combined Board",
    project: "AM",
    id: 70,
    keywords: ["e2", "am", "emsmart", "sprint"],
  },
  {
    command: "emservices-board",
    title: "Services Board",
    subtitle: "EMSmart 2.0 · Services Board",
    project: "AM",
    id: 3417,
    keywords: ["emsvc", "services", "sprint"],
  },
];

/** Grafana folders. Tabs on a dashboard's sub-pages count as the same page. */
export const DASHBOARDS: Dashboard[] = [
  {
    command: "emservices-grafana-prod",
    title: "EMServices Prod",
    url: "https://grafana.emsbilling.com/dashboards/f/bew3f487lam80d/emservices",
    keywords: ["emsvc", "services", "prod", "production"],
  },
  {
    command: "emservices-grafana-nonprod",
    title: "EMServices Non-prod",
    url: "https://grafana.stage-ac.emsbilling.com/dashboards/f/dep92ss1k9340b/?orgId=1",
    keywords: ["emsvc", "services", "nonprod", "non-prod", "stage", "staging"],
  },
];

export const REPOS: Repo[] = [
  { name: "EMSmart2.0", title: "EMSmart 2.0", keywords: ["e2", "ems2", "backend"] },
  { name: "EMSmart2.0-Client-Application", title: "EMSmart 2.0 Client", keywords: ["e2", "client", "front"] },
  { name: "Emsmart2.0-Common", title: "EMSmart 2.0 Common", keywords: ["e2", "common"] },
  { name: "EMS.EOB.835Converter", title: "EOB 835 Converter", keywords: ["835", "eob"] },
  { name: "EMServices-BillingRules", title: "EMServices Billing Rules", keywords: ["billing", "rules", "emsvc"] },
  { name: "EMS-IdentityVerification", title: "Identity Verification", keywords: ["identity", "tlo"] },
];

export function boardUrl(board: Board): string {
  return `${JIRA_SITE}/jira/software/c/projects/${board.project}/boards/${board.id}`;
}

export function issueUrl(key: string): string {
  return `${JIRA_SITE}/browse/${key}`;
}

export function repoUrl(repo: string): string {
  return `https://github.com/${GITHUB_ORG}/${repo}`;
}
