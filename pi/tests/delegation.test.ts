import assert from "node:assert/strict";
import test from "node:test";
import {
  applyDelegationEvent,
  createDelegationDetails,
  runProcess,
  SCOUT,
} from "../agent/extensions/shared/delegation.ts";

const sleeper = ["-e", "setInterval(() => {}, 1000)"];

test("runProcess times out and terminates the child", async () => {
  await assert.rejects(
    runProcess(process.execPath, sleeper, { cwd: process.cwd(), timeoutMs: 50 }),
    /Timed out after/,
  );
});

test("runProcess propagates external abort", async () => {
  const controller = new AbortController();
  setTimeout(() => controller.abort(), 50);
  await assert.rejects(
    runProcess(process.execPath, sleeper, { cwd: process.cwd(), timeoutMs: 5_000, signal: controller.signal }),
    /aborted/,
  );
});

test("JSON events build live activity, output, and usage", () => {
  const details = createDelegationDetails(SCOUT, "find the entry point");
  applyDelegationEvent(details, {
    type: "tool_execution_start",
    toolName: "grep",
    args: { pattern: "main", path: "src" },
  });
  applyDelegationEvent(details, {
    type: "message_update",
    assistantMessageEvent: { type: "text_delta", delta: "Found it" },
  });
  applyDelegationEvent(details, {
    type: "message_end",
    message: {
      role: "assistant",
      content: [{ type: "text", text: "Found it." }],
      usage: { input: 100, output: 20, cacheRead: 50, cacheWrite: 0, totalTokens: 170, cost: { total: 0.001 } },
    },
  });

  assert.deepEqual(details.activities, ["grep /main/ in src"]);
  assert.equal(details.output, "Found it.");
  assert.deepEqual(details.usage, {
    turns: 1,
    input: 100,
    output: 20,
    cacheRead: 50,
    cacheWrite: 0,
    cost: 0.001,
    contextTokens: 170,
  });
});
