import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "typebox";

export default function (pi: ExtensionAPI) {
  const apiKey = process.env.TAVILY_API_KEY;

  if (!apiKey) {
    console.warn("[tavily-search] TAVILY_API_KEY not set — search_web will fail at runtime");
  }

  pi.registerTool({
    name: "search_web",
    label: "Search the Web",
    description:
      "Search the web for current information on any topic. Use this when you need up-to-date facts, news, prices, weather, or anything that requires real-time data the model's training data may not cover.",
    parameters: Type.Object({
      query: Type.String({ description: "The search query (max ~400 chars, be specific)" }),
      max_results: Type.Optional(
        Type.Number({ description: "Max results to return (1-20, default 10)", minimum: 1, maximum: 20 }),
      ),
    }),
    async execute(_toolCallId, params, signal) {
      if (!apiKey) {
        throw new Error("TAVILY_API_KEY environment variable not set");
      }

      const maxResults = (params.max_results as number | undefined) ?? 10;

      const response = await fetch("https://api.tavily.com/search", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ api_key: apiKey, query: params.query, max_results: maxResults }),
        signal,
      });

      if (!response.ok) {
        throw new Error(`Tavily API error: ${response.status} ${response.statusText}`);
      }

      const data = (await response.json()) as {
        results: Array<{ url: string; title: string; content: string }>;
        answer?: string;
      };

      const lines = data.results.map((r, i) =>
        `[${i + 1}] ${r.title}\n   URL: ${r.url}\n   ${r.content.slice(0, 300)}…`,
      );

      const answer = data.answer ? `\n💡 AI Summary:\n${data.answer}\n` : "";

      return {
        content: [{ type: "text", text: `Web Search: "${params.query}"\n\n${lines.join("\n\n")}${answer}` }],
        details: { query: params.query, count: data.results.length },
      };
    },
  });
}