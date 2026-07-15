import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
  Editor,
  type EditorTheme,
  Key,
  matchesKey,
  Text,
  visibleWidth,
  wrapTextWithAnsi,
} from "@earendil-works/pi-tui";
import { Type } from "typebox";
import {
  ASK_USER_PARAMETER_DESCRIPTIONS,
  ASK_USER_PROMPT_GUIDELINES,
  ASK_USER_PROMPT_SNIPPET,
  ASK_USER_TOOL_DESCRIPTION,
  buildAskUserResultMessage,
} from "./shared/ask-user-prompt.ts";

const MIN_OPTIONS = 2;
const MAX_OPTIONS = 5;

const OptionSchema = Type.Object({
  label: Type.String({ description: ASK_USER_PARAMETER_DESCRIPTIONS.optionLabel }),
  description: Type.Optional(Type.String({ description: ASK_USER_PARAMETER_DESCRIPTIONS.optionDescription })),
});

const AskUserParams = Type.Object({
  question: Type.String({ description: ASK_USER_PARAMETER_DESCRIPTIONS.question }),
  options: Type.Array(OptionSchema, {
    minItems: MIN_OPTIONS,
    maxItems: MAX_OPTIONS,
    description: ASK_USER_PARAMETER_DESCRIPTIONS.options,
  }),
});

interface AskUserDetails {
  question: string;
  options: string[];
  answer: string | null;
  wasCustom: boolean;
  cancelled: boolean;
}

type SelectionResult = { answer: string; wasCustom: boolean; index?: number } | null;
type DisplayOption = { label: string; description?: string; isOther?: boolean };

export default function askUser(pi: ExtensionAPI) {
  pi.registerTool({
    name: "ask_user",
    label: "Ask User",
    description: ASK_USER_TOOL_DESCRIPTION,
    promptSnippet: ASK_USER_PROMPT_SNIPPET,
    promptGuidelines: ASK_USER_PROMPT_GUIDELINES,
    parameters: AskUserParams,
    executionMode: "sequential",

    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      const reply = (text: string, answer: string | null = null, wasCustom = false) => ({
        content: [{ type: "text" as const, text }],
        details: {
          question: params.question,
          options: params.options.map((option) => option.label),
          answer,
          wasCustom,
          cancelled: answer === null,
        } satisfies AskUserDetails,
      });

      if (params.options.length < MIN_OPTIONS || params.options.length > MAX_OPTIONS) {
        throw new Error(`ask_user requires ${MIN_OPTIONS}-${MAX_OPTIONS} options.`);
      }
      if (ctx.mode !== "tui") return reply(buildAskUserResultMessage({ kind: "no-ui" }));
      if (signal?.aborted) return reply(buildAskUserResultMessage({ kind: "cancelled" }));

      const options: DisplayOption[] = [
        ...params.options,
        { label: "Write my own answer…", isOther: true },
      ];

      const result = await ctx.ui.custom<SelectionResult>((tui, theme, _kb, done) => {
        let optionIndex = 0;
        let editMode = false;
        let settled = false;
        let cachedLines: string[] | undefined;

        const finish = (value: SelectionResult) => {
          if (settled) return;
          settled = true;
          signal?.removeEventListener("abort", cancel);
          done(value);
        };
        const cancel = () => finish(null);
        signal?.addEventListener("abort", cancel, { once: true });
        if (signal?.aborted) queueMicrotask(cancel);

        const editorTheme: EditorTheme = {
          borderColor: (text) => theme.fg("accent", text),
          selectList: {
            selectedPrefix: (text) => theme.fg("accent", text),
            selectedText: (text) => theme.fg("accent", text),
            description: (text) => theme.fg("muted", text),
            scrollInfo: (text) => theme.fg("dim", text),
            noMatch: (text) => theme.fg("warning", text),
          },
        };
        const editor = new Editor(tui, editorTheme);

        const refresh = () => {
          cachedLines = undefined;
          tui.requestRender();
        };
        const select = (index: number) => {
          const selected = options[index];
          if (selected.isOther) {
            optionIndex = index;
            editMode = true;
            refresh();
          } else {
            finish({ answer: selected.label, wasCustom: false, index: index + 1 });
          }
        };

        editor.onSubmit = (value) => {
          const answer = value.trim();
          if (answer) finish({ answer, wasCustom: true });
          else {
            editMode = false;
            editor.setText("");
            refresh();
          }
        };

        const addWrapped = (lines: string[], prefix: string, text: string, width: number) => {
          const prefixWidth = visibleWidth(prefix);
          const wrapped = wrapTextWithAnsi(text, Math.max(1, width - prefixWidth));
          for (let i = 0; i < wrapped.length; i++) {
            lines.push(`${i === 0 ? prefix : " ".repeat(prefixWidth)}${wrapped[i]}`);
          }
        };

        return {
          handleInput(data: string) {
            if (editMode) {
              if (matchesKey(data, Key.escape)) {
                editMode = false;
                editor.setText("");
                refresh();
              } else {
                editor.handleInput(data);
                refresh();
              }
              return;
            }
            if (matchesKey(data, Key.up)) optionIndex = (optionIndex - 1 + options.length) % options.length;
            else if (matchesKey(data, Key.down)) optionIndex = (optionIndex + 1) % options.length;
            else if (data.length === 1 && data >= "1" && data <= String(options.length)) return select(Number(data) - 1);
            else if (matchesKey(data, Key.enter)) return select(optionIndex);
            else if (matchesKey(data, Key.escape)) return finish(null);
            else return;
            refresh();
          },
          render(width: number) {
            if (cachedLines) return cachedLines;
            const lines: string[] = [theme.fg("accent", "─".repeat(width))];
            addWrapped(lines, " ", theme.fg("text", theme.bold(params.question)), width);
            lines.push("");

            options.forEach((option, index) => {
              const selected = index === optionIndex;
              const prefix = selected ? theme.fg("accent", " ❯ ") : "   ";
              const marker = option.isOther ? "✎" : `${index + 1}.`;
              addWrapped(lines, prefix, theme.fg(selected ? "accent" : option.isOther ? "muted" : "text", `${marker} ${option.label}`), width);
              if (option.description) addWrapped(lines, "      ", theme.fg("muted", option.description), width);
            });

            if (editMode) {
              lines.push("", theme.fg("muted", " Your answer:"));
              for (const line of editor.render(Math.max(1, width - 2))) lines.push(` ${line}`);
            }
            lines.push("");
            addWrapped(
              lines,
              " ",
              theme.fg("dim", editMode ? "Enter submit • Esc back" : `↑↓ or 1-${options.length} select • Enter confirm • Esc dismiss`),
              width,
            );
            lines.push(theme.fg("accent", "─".repeat(width)));
            cachedLines = lines;
            return lines;
          },
          invalidate() { cachedLines = undefined; },
          dispose() { signal?.removeEventListener("abort", cancel); },
        };
      });

      if (!result) return reply(buildAskUserResultMessage({ kind: "dismissed" }));
      if (result.wasCustom) {
        return reply(buildAskUserResultMessage({ kind: "custom", answer: result.answer }), result.answer, true);
      }
      return reply(
        buildAskUserResultMessage({ kind: "selected", answer: result.answer, index: result.index! }),
        result.answer,
      );
    },

    renderCall(args, theme) {
      let text = theme.fg("toolTitle", theme.bold("ask_user ")) + theme.fg("muted", String(args.question ?? ""));
      const options = Array.isArray(args.options) ? args.options as DisplayOption[] : [];
      if (options.length) text += `\n${theme.fg("dim", `  ${options.map((option, index) => `${index + 1}. ${option.label}`).join("  ")}`)}`;
      return new Text(text, 0, 0);
    },

    renderResult(result, _options, theme) {
      const details = result.details as AskUserDetails | undefined;
      if (!details) {
        const first = result.content[0];
        return new Text(first?.type === "text" ? first.text : "", 0, 0);
      }
      if (details.cancelled || details.answer === null) return new Text(theme.fg("warning", "✗ dismissed"), 0, 0);
      if (details.wasCustom) {
        return new Text(theme.fg("success", "✓ ") + theme.fg("muted", "(wrote) ") + theme.fg("accent", details.answer), 0, 0);
      }
      const index = details.options.indexOf(details.answer) + 1;
      return new Text(theme.fg("success", "✓ ") + theme.fg("accent", `${index}. ${details.answer}`), 0, 0);
    },
  });
}
