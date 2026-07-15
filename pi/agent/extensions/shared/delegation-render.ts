import { getMarkdownTheme, type ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Container, Markdown, Spacer, Text } from "@earendil-works/pi-tui";
import type { DelegationConfig, DelegationDetails } from "./delegation.ts";

type Theme = ExtensionContext["ui"]["theme"];

function formatNumber(value: number) {
  if (value < 1_000) return String(value);
  if (value < 1_000_000) return `${Math.round(value / 1_000)}k`;
  return `${(value / 1_000_000).toFixed(1)}m`;
}

function usageLine(details: DelegationDetails) {
  const seconds = Math.round(details.elapsedMs / 1_000);
  const parts = [`${details.usage.turns} turns`, `↑${formatNumber(details.usage.input)}`, `↓${formatNumber(details.usage.output)}`];
  if (details.usage.cacheRead) parts.push(`R${formatNumber(details.usage.cacheRead)}`);
  if (details.usage.cost) parts.push(`$${details.usage.cost.toFixed(4)}`);
  parts.push(`${seconds}s`, `${details.model}:${details.thinking}`);
  return parts.join(" · ");
}

export function renderDelegationCall(config: DelegationConfig, task: string, expanded: boolean, theme: Theme) {
  let text = `${theme.fg("toolTitle", theme.bold(`${config.name} `))}${theme.fg("accent", `${config.model}:${config.thinking}`)}\n${theme.fg("dim", task)}`;
  if (expanded) text += `\n\n${theme.fg("muted", "Agent instructions:")}\n${theme.fg("dim", config.prompt)}`;
  return new Text(text, 0, 0);
}

export function renderDelegationResult(details: DelegationDetails | undefined, expanded: boolean, theme: Theme) {
  if (!details) return new Text(theme.fg("muted", "(no delegation details)"), 0, 0);
  const icon = details.status === "done" ? theme.fg("success", "✓") : theme.fg("warning", "⏳");
  const recent = expanded ? details.activities : details.activities.slice(-6);

  if (!expanded) {
    let text = `${icon} ${theme.fg("toolTitle", theme.bold(details.status === "done" ? "completed" : "running"))}`;
    for (const activity of recent) text += `\n${theme.fg("muted", "→ ")}${theme.fg("toolOutput", activity)}`;
    if (details.output) text += `\n${theme.fg("dim", details.output.split("\n").slice(-3).join("\n"))}`;
    text += `\n${theme.fg("dim", usageLine(details))}`;
    return new Text(text, 0, 0);
  }

  const container = new Container();
  container.addChild(new Text(`${icon} ${theme.fg("toolTitle", theme.bold(details.status))}`, 0, 0));
  container.addChild(new Spacer(1));
  container.addChild(new Text(theme.fg("muted", "── Task ──"), 0, 0));
  container.addChild(new Text(details.task, 0, 0));
  container.addChild(new Spacer(1));
  container.addChild(new Text(theme.fg("muted", "── Agent instructions ──"), 0, 0));
  container.addChild(new Text(theme.fg("dim", details.prompt), 0, 0));
  container.addChild(new Spacer(1));
  container.addChild(new Text(theme.fg("muted", "── Activity ──"), 0, 0));
  container.addChild(new Text(recent.length ? recent.map((item) => `→ ${item}`).join("\n") : "(waiting)", 0, 0));
  if (details.output) {
    container.addChild(new Spacer(1));
    container.addChild(new Text(theme.fg("muted", "── Output ──"), 0, 0));
    container.addChild(new Markdown(details.output, 0, 0, getMarkdownTheme()));
  }
  container.addChild(new Spacer(1));
  container.addChild(new Text(theme.fg("dim", usageLine(details)), 0, 0));
  return container;
}
