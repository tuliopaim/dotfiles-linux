export const ASK_USER_PARAMETER_DESCRIPTIONS = {
  optionLabel: "Short display label for this option",
  optionDescription: "Optional one-line description shown below the label",
  question: "The question to ask the user",
  options: "Between 2 and 5 answer options. A free-form answer option is appended automatically; do not include one yourself.",
};

export const ASK_USER_TOOL_DESCRIPTION =
  "Ask the user one multiple-choice question with 2-5 options. A free-form answer is always available, and the user may dismiss the question.";

export const ASK_USER_PROMPT_SNIPPET =
  "Ask the user a multiple-choice question with a free-form fallback";

export const ASK_USER_PROMPT_GUIDELINES = [
  "When likely answers can be enumerated, use ask_user instead of asking in plain text.",
  "Ask exactly one question per call; ask follow-up questions in later calls.",
];

export function buildAskUserResultMessage(
  outcome:
    | { kind: "no-ui" }
    | { kind: "cancelled" }
    | { kind: "dismissed" }
    | { kind: "custom"; answer: string }
    | { kind: "selected"; answer: string; index: number },
) {
  switch (outcome.kind) {
    case "no-ui":
      return "No interactive UI is available. Ask the user in plain text instead.";
    case "cancelled":
      return "Question cancelled.";
    case "dismissed":
      return "User dismissed the question. Do not assume an answer; proceed accordingly or ask differently.";
    case "custom":
      return `User wrote their own answer: ${outcome.answer}`;
    case "selected":
      return `User selected option ${outcome.index}: ${outcome.answer}`;
  }
}
