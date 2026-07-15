import assert from "node:assert/strict";
import test from "node:test";
import { buildAskUserResultMessage } from "../agent/extensions/shared/ask-user-prompt.ts";

test("ask_user preserves selected and custom answers for the parent model", () => {
  assert.equal(
    buildAskUserResultMessage({ kind: "selected", answer: "Keep it", index: 2 }),
    "User selected option 2: Keep it",
  );
  assert.equal(
    buildAskUserResultMessage({ kind: "custom", answer: "Something else" }),
    "User wrote their own answer: Something else",
  );
});
