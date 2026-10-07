import { getPreferenceValues } from "@vicinae/api";
import { GITHUB_ORG } from "./config";
import { expandHome, resolveBin, run } from "./exec";

export type Checks = "SUCCESS" | "FAILURE" | "ERROR" | "PENDING" | "EXPECTED";
export type Review = "APPROVED" | "CHANGES_REQUESTED" | "REVIEW_REQUIRED";

export interface PullRequest {
  number: number;
  title: string;
  url: string;
  repo: string;
  isDraft: boolean;
  updatedAt: string;
  review?: Review;
  checks?: Checks;
}

interface Node {
  number: number;
  title: string;
  url: string;
  isDraft: boolean;
  updatedAt: string;
  reviewDecision: Review | null;
  repository: { name: string };
  commits: { nodes: { commit: { statusCheckRollup: { state: Checks } | null } }[] };
}

const QUERY = `query($q: String!) {
  search(query: $q, type: ISSUE, first: 50) {
    nodes {
      ... on PullRequest {
        number title url isDraft updatedAt reviewDecision
        repository { name }
        commits(last: 1) { nodes { commit { statusCheckRollup { state } } } }
      }
    }
  }
}`;

export async function loadPullRequests(): Promise<PullRequest[]> {
  const { ghBin, ghConfigDir } = getPreferenceValues<Preferences>();
  const bin = resolveBin("gh", ghBin);
  const q = `is:pr is:open author:@me org:${GITHUB_ORG} sort:updated-desc`;
  const output = await run(bin, ["api", "graphql", "-f", `query=${QUERY}`, "-f", `q=${q}`], {
    ...process.env,
    GH_CONFIG_DIR: expandHome(ghConfigDir ?? "~/.config/gh-ems"),
  });
  const nodes = (JSON.parse(output) as { data: { search: { nodes: Node[] } } }).data.search.nodes;
  return nodes.map((node) => ({
    number: node.number,
    title: node.title,
    url: node.url,
    repo: node.repository.name,
    isDraft: node.isDraft,
    updatedAt: node.updatedAt,
    review: node.reviewDecision ?? undefined,
    checks: node.commits.nodes[0]?.commit.statusCheckRollup?.state,
  }));
}
