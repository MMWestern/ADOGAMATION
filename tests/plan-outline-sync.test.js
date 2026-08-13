"use strict";

const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const clientSrc = fs.readFileSync(path.join(ROOT, "Client.html"), "utf8");
const planSrc = fs.readFileSync(path.join(ROOT, "scripts", "plan-outline.html"), "utf8");

function extractFunction(src, name) {
  const marker = "function " + name + "(";
  const startIdx = src.indexOf(marker);
  if (startIdx === -1) throw new Error("function not found: " + name);
  const braceIdx = src.indexOf("{", startIdx);
  let depth = 0;
  let i = braceIdx;
  for (; i < src.length; i++) {
    if (src[i] === "{") depth++;
    else if (src[i] === "}") {
      depth--;
      if (depth === 0) break;
    }
  }
  return src.slice(startIdx, i + 1);
}

function extractVar(src, name) {
  const startIdx = src.indexOf("var " + name + " ");
  if (startIdx === -1) throw new Error("var not found: " + name);
  const endIdx = src.indexOf(";", startIdx);
  return src.slice(startIdx, endIdx + 1);
}

const code = [
  extractVar(planSrc, "_outlineIdCounter"),
  extractFunction(planSrc, "generateOutlineNodeId"),
  extractFunction(planSrc, "getPlanOutline"),
  extractFunction(planSrc, "initOutlineFromSegments"),
  extractVar(clientSrc, "_outlineSaveChain"),
  extractFunction(clientSrc, "snapshotOutlineChapterStates"),
  extractFunction(clientSrc, "savePlanOutline"),
  extractFunction(clientSrc, "schedulePlanOutlineSave"),
].join("\n\n");

let passed = 0;
let failed = 0;

function log(name, ok, detail) {
  if (ok) passed++;
  else failed++;
  console.log((ok ? "PASS" : "FAIL") + ": " + name + (detail && !ok ? " -- " + detail : ""));
}

function buildSandbox() {
  const calls = { executePlanOutlineSave: [], schedule: [] };
  const appState = {
    _outlineLoadState: {},
    _syntheticOutlineFor: "",
    writingWorkspace: {
      outline: { acts: [], brainstorming: "", characterArcs: "", worldBuilding: "" },
      segments: [],
      outlineSnapshot: "",
      savedOutlineChapterStates: {},
    },
  };
  const sandbox = {
    appState,
    calls,
    getSelectedProject: () => ({ project_id: 12345 }),
    saveManager: { schedule: (key, payload) => { calls.schedule.push([key, payload]); return true; } },
    updateAllPlanChapterDots: () => { calls.planDots = (calls.planDots || 0) + 1; },
    refreshWritingWorkspaceSaveState: () => { calls.saveState = (calls.saveState || 0) + 1; },
    executePlanOutlineSave: (projectId, snapshot) => { calls.executePlanOutlineSave.push([projectId, snapshot]); return Promise.resolve({ ok: true }); },
  };
  const fn = new Function(
    "appState",
    "getSelectedProject",
    "saveManager",
    "updateAllPlanChapterDots",
    "refreshWritingWorkspaceSaveState",
    "executePlanOutlineSave",
    code + "\nreturn { initOutlineFromSegments, savePlanOutline, schedulePlanOutlineSave, getPlanOutline };"
  );
  sandbox.api = fn(
    appState,
    sandbox.getSelectedProject,
    sandbox.saveManager,
    sandbox.updateAllPlanChapterDots,
    sandbox.refreshWritingWorkspaceSaveState,
    sandbox.executePlanOutlineSave
  );
  return sandbox;
}

function seg(key, title, sortOrder) {
  return { key: key, title: title, sortOrder: sortOrder, text: "<div>body</div>", wordCount: 10 };
}

function flatten(sandbox, segments) {
  sandbox.appState.writingWorkspace.segments = segments.slice();
  sandbox.api.initOutlineFromSegments();
  return sandbox.appState.writingWorkspace.outline;
}

async function main() {
  console.log("== initOutlineFromSegments ==");

  let s = buildSandbox();
  s.appState._outlineLoadState["12345"] = "loaded";
  let outline = flatten(s, [seg("k1", "A", 0), seg("k2", "B", 1)]);
  log("loaded state: no flatten (acts stay empty)", outline.acts.length === 0);
  log("loaded state: synthetic flag NOT set", s.appState._syntheticOutlineFor === "");

  s = buildSandbox();
  s.appState._outlineLoadState["12345"] = "empty";
  outline = flatten(s, [seg("k1", "A", 0), seg("k2", "B", 1)]);
  log("empty state: flattens into 1 act", outline.acts.length === 1 && outline.acts[0].title === "Act 1");
  log("empty state: chapters preserve segment keys", outline.acts[0].children.length === 2 && outline.acts[0].children[0].id === "k1" && outline.acts[0].children[1].id === "k2");
  log("empty state: synthetic flag set for project", s.appState._syntheticOutlineFor === "12345");

  const firstPassAct = s.appState.writingWorkspace.outline.acts[0];
  const firstPassIds = firstPassAct.children.map(function (c) { return c.id; });
  outline = flatten(s, [seg("k1", "A", 0), seg("k2", "B", 1)]);
  log("empty state + synthetic set: no re-flatten", s.appState.writingWorkspace.outline.acts[0] === firstPassAct);
  log("empty state + synthetic set: chapter ids stable", JSON.stringify(s.appState.writingWorkspace.outline.acts[0].children.map(function (c) { return c.id; })) === JSON.stringify(firstPassIds));

  s = buildSandbox();
  outline = flatten(s, [seg("k1", "A", 0)]);
  log("undefined state: no flatten", outline.acts.length === 0);

  s = buildSandbox();
  s.appState._outlineLoadState["12345"] = "empty";
  outline = flatten(s, []);
  log("empty state + no segments: no flatten", outline.acts.length === 0);

  s = buildSandbox();
  s.appState._outlineLoadState["12345"] = "empty";
  outline = flatten(s, [seg("k2", "B", 1), seg("k1", "A", 0)]);
  log("empty state: chapters sorted by sortOrder", outline.acts[0].children[0].id === "k1" && outline.acts[0].children[1].id === "k2");

  s = buildSandbox();
  s.appState._outlineLoadState["12345"] = "empty";
  outline = flatten(s, [seg("k1", "", 0)]);
  log("empty state: fallback chapter title", outline.acts[0].children[0].title === "Chapter 1");

  s = buildSandbox();
  s.appState._outlineLoadState["12345"] = "empty";
  outline = flatten(s, [seg("k2", "B", 1), seg("k1", "A", 0)]);
  s.appState._outlineLoadState["12345"] = "loaded";
  outline = flatten(s, [seg("k2", "B", 1), seg("k1", "A", 0), seg("k3", "C", 2)]);
  log("loaded after empty: no flatten, acts preserved", s.appState.writingWorkspace.outline.acts[0].children.length === 2);

  console.log("\n== savePlanOutline ==");

  s = buildSandbox();
  s.appState._syntheticOutlineFor = "12345";
  s.appState.writingWorkspace.outline.acts = [{ id: "a1", children: [{ id: "k1", title: "A" }] }];
  let result = s.api.savePlanOutline();
  await result;
  log("synthetic: resolves without DB write", s.calls.executePlanOutlineSave.length === 0);
  log("synthetic: outlineSnapshot synced", s.appState.writingWorkspace.outlineSnapshot === JSON.stringify(s.appState.writingWorkspace.outline));
  log("synthetic: chapter states snapshot saved", s.appState.writingWorkspace.savedOutlineChapterStates["k1"] === JSON.stringify(s.appState.writingWorkspace.outline.acts[0].children[0]));
  log("synthetic: plan dots refreshed", s.calls.planDots === 1);
  log("synthetic: save state refreshed", s.calls.saveState === 1);

  s = buildSandbox();
  s.appState.writingWorkspace.outlineSnapshot = JSON.stringify(s.appState.writingWorkspace.outline);
  result = s.api.savePlanOutline();
  await result;
  log("unchanged snapshot: no DB write", s.calls.executePlanOutlineSave.length === 0);

  s = buildSandbox();
  s.appState.writingWorkspace.outlineSnapshot = "{}";
  s.appState.writingWorkspace.outline.acts = [{ id: "a1", children: [{ id: "k1", title: "A" }] }];
  result = s.api.savePlanOutline();
  await result;
  log("changed snapshot: executes DB save", s.calls.executePlanOutlineSave.length === 1);
  log("changed snapshot: passes project id", s.calls.executePlanOutlineSave[0][0] === "12345");
  log("changed snapshot: passes serialized outline", JSON.parse(s.calls.executePlanOutlineSave[0][1]).acts.length === 1);

  console.log("\n== schedulePlanOutlineSave ==");

  s = buildSandbox();
  s.appState._syntheticOutlineFor = "12345";
  s.appState._outlineLoadState["12345"] = "empty";
  s.api.schedulePlanOutlineSave();
  log("synthetic: clears synthetic flag", s.appState._syntheticOutlineFor === "");
  log("synthetic: state promoted to loaded", s.appState._outlineLoadState["12345"] === "loaded");
  log("synthetic: save scheduled via saveManager", s.calls.schedule.length === 1 && s.calls.schedule[0][0] === "planOutline");

  console.log("\n" + passed + " passed, " + failed + " failed");
  if (failed > 0) process.exit(1);
}

main().catch(function (err) {
  console.error("Harness crashed:", err);
  process.exit(1);
});
