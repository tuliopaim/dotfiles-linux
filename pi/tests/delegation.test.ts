import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import {
  applyDelegationEvent,
  createDelegationDetails,
  getActiveSubagentPresetName,
  getDelegationConfig,
  runProcess,
  SCOUT,
  setSubagentPreset,
} from "../agent/extensions/shared/delegation.ts";

const sleeper = ["-e", "setInterval(() => {}, 1000)"];

test("subagent presets resolve from settings, environment, then session override", () => {
  const agentDir = mkdtempSync(join(tmpdir(), "pi-subagent-presets-"));
  const previousAgentDir = process.env.PI_CODING_AGENT_DIR;
  const previousPreset = process.env.PI_SUBAGENT_PRESET;

  try {
    process.env.PI_CODING_AGENT_DIR = agentDir;
    delete process.env.PI_SUBAGENT_PRESET;
    writeFileSync(join(agentDir, "settings.json"), JSON.stringify({
      subagents: {
        preset: "personal",
        presets: {
          personal: { scout: { model: "personal/scout", thinking: "low" } },
          copilot: { scout: { model: "github-copilot/scout", thinking: "medium" } },
        },
      },
    }));

    setSubagentPreset(undefined);
    assert.equal(getActiveSubagentPresetName(), "personal");
    assert.equal(getDelegationConfig("scout", SCOUT).model, "personal/scout");

    process.env.PI_SUBAGENT_PRESET = "copilot";
    assert.equal(getDelegationConfig("scout", SCOUT).model, "github-copilot/scout");

    setSubagentPreset("personal");
    assert.equal(getDelegationConfig("scout", SCOUT).model, "personal/scout");
    assert.throws(() => getDelegationConfig("review", SCOUT), /no valid "review" configuration/);
  } finally {
    setSubagentPreset(undefined);
    if (previousAgentDir === undefined) delete process.env.PI_CODING_AGENT_DIR;
    else process.env.PI_CODING_AGENT_DIR = previousAgentDir;
    if (previousPreset === undefined) delete process.env.PI_SUBAGENT_PRESET;
    else process.env.PI_SUBAGENT_PRESET = previousPreset;
    rmSync(agentDir, { recursive: true, force: true });
  }
});

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
