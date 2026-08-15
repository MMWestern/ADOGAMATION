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
  extractFunction(planSrc, "renumberOutlineChapters"),
  extractFunction(planSrc, "initOutlineFromSegments"),
  extractFunction(planSrc, "syncOutlineToSegments"),
  extractVar(clientSrc, "_outlineSaveChain"),
  extractFunction(clientSrc, "snapshotOutlineChapterStates"),
  extractFunction(clientSrc, "savePlanOutline"),
  extractFunction(clientSrc, "schedulePlanOutlineSave"),
  extractFunction(clientSrc, "buildWritingWorkspaceTextFromSections"),
  extractFunction(clientSrc, "reconcileLegacyKeysIfNeeded"),
  extractFunction(clientSrc, "chapterDisplayLabel"),
].join("\n\n");

let passed = 0;
let failed = 0;

function log(name, ok, detail) {
  if (ok) passed++;
  else failed++;
  console.log((ok ? "PASS" : "FAIL") + ": " + name + (detail && !ok ? " -- " + detail : ""));
}

function buildSandbox() {
  const calls = { executePlanOutlineSave: [], schedule: [], callAppsScriptJson: [], setStatus: [] };
  const appState = {
    _outlineLoadState: {},
    _syntheticOutlineFor: "",
    _legacyKeyWarning: "",
    writingWorkspace: {
      outline: { acts: [], brainstorming: "", characterArcs: "", worldBuilding: "" },
      segments: [],
      outlineSnapshot: "",
      savedOutlineChapterStates: {},
      savedSegmentTexts: {},
      scope: "",
      draftText: "",
      version: 0,
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
    flushCurrentWorkspaceEdits: () => {},
    renderWritingChapterList: () => {},
    renderWritingWorkspaceScopeOptions: () => {},
    renderWritingWorkspaceEditor: () => {},
    renderPlanOutline: () => {},
    callAppsScriptJson: (fn, args) => { calls.callAppsScriptJson.push([fn, args]); return Promise.resolve({ ok: true }); },
    setStatus: (msg, mode) => { calls.setStatus.push([msg, mode]); },
    escapeHtml: (s) => String(s),
  };
  const fn = new Function(
    "appState",
    "getSelectedProject",
    "saveManager",
    "updateAllPlanChapterDots",
    "refreshWritingWorkspaceSaveState",
    "executePlanOutlineSave",
    "flushCurrentWorkspaceEdits",
    "renderWritingChapterList",
    "renderWritingWorkspaceScopeOptions",
    "renderWritingWorkspaceEditor",
    "renderPlanOutline",
    "callAppsScriptJson",
    "setStatus",
    "escapeHtml",
    code + "\nreturn { initOutlineFromSegments, savePlanOutline, schedulePlanOutlineSave, getPlanOutline, renumberOutlineChapters, syncOutlineToSegments, reconcileLegacyKeysIfNeeded, chapterDisplayLabel };"
  );
  sandbox.api = fn(
    appState,
    sandbox.getSelectedProject,
    sandbox.saveManager,
    sandbox.updateAllPlanChapterDots,
    sandbox.refreshWritingWorkspaceSaveState,
    sandbox.executePlanOutlineSave,
    sandbox.flushCurrentWorkspaceEdits,
    sandbox.renderWritingChapterList,
    sandbox.renderWritingWorkspaceScopeOptions,
    sandbox.renderWritingWorkspaceEditor,
    sandbox.renderPlanOutline,
    sandbox.callAppsScriptJson,
    sandbox.setStatus,
    sandbox.escapeHtml
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

  console.log("\n== renumberOutlineChapters (Phase 2d) ==");

  s = buildSandbox();
  s.appState.writingWorkspace.outline.acts = [{
    id: "a1", sortOrder: 0, children: [
      { id: "ol-1", sortOrder: 0, title: "Chapter 5: The Beginning" },
      { id: "ol-2", sortOrder: 1, title: "My Custom Title" }
    ]
  }];
  s.api.renumberOutlineChapters();
  log("renumber: sortOrder updated", s.appState.writingWorkspace.outline.acts[0].children[0].sortOrder === 0 && s.appState.writingWorkspace.outline.acts[0].children[1].sortOrder === 1);
  log("renumber: title NOT changed", s.appState.writingWorkspace.outline.acts[0].children[0].title === "Chapter 5: The Beginning");
  log("renumber: custom title preserved", s.appState.writingWorkspace.outline.acts[0].children[1].title === "My Custom Title");

  console.log("\n== syncOutlineToSegments (Phase 2b) ==");

  s = buildSandbox();
  s.appState.writingWorkspace.outline.acts = [{
    id: "a1", sortOrder: 0, children: [
      { id: "ol-1", sortOrder: 0, title: "Chapter 1" },
      { id: "ol-2", sortOrder: 1, title: "Chapter 2" }
    ]
  }];
  s.appState.writingWorkspace.segments = [
    seg("ol-1", "Chapter 1", 0),
    seg("ol-2", "Chapter 2", 1),
    seg("old-ch-3", "Chapter 3", 2)
  ];
  s.api.syncOutlineToSegments();
  var syncedSegs = s.appState.writingWorkspace.segments;
  log("sync: outline chapters present", syncedSegs.length === 3 && syncedSegs[0].key === "ol-1" && syncedSegs[1].key === "ol-2");
  log("sync: unknown segment preserved", syncedSegs[2].key === "old-ch-3" && syncedSegs[2].title === "Chapter 3");
  log("sync: unknown segment text preserved", syncedSegs[2].text === "<div>body</div>");

  s = buildSandbox();
  s.appState.writingWorkspace.outline.acts = [{
    id: "a1", sortOrder: 0, children: [
      { id: "ol-1", sortOrder: 0, title: "Chapter 1" }
    ]
  }];
  s.appState.writingWorkspace.segments = [seg("ol-1", "Chapter 1", 0)];
  s.api.syncOutlineToSegments();
  log("sync: no unknown segments, length unchanged", s.appState.writingWorkspace.segments.length === 1);

  s = buildSandbox();
  s.appState.writingWorkspace.outline.acts = [{
    id: "a1", sortOrder: 0, children: [
      { id: "ol-1", sortOrder: 0, title: "Chapter 1" }
    ]
  }];
  s.appState.writingWorkspace.segments = [seg("ol-1", "Chapter 1", 0), seg("extra-1", "Extra", 1)];
  s.appState.writingWorkspace.scope = "extra-1";
  s.api.syncOutlineToSegments();
  log("sync: scope preserved for unknown segment", s.appState.writingWorkspace.scope === "extra-1");

  console.log("\n== reconcileLegacyKeysIfNeeded (Phase 2c) ==");

  s = buildSandbox();
  s.appState.writingWorkspace.outline.acts = [{
    id: "a1", sortOrder: 0, children: [
      { id: "ol-1724", sortOrder: 0, title: "Chapter 1" },
      { id: "ol-1725", sortOrder: 1, title: "Chapter 2" }
    ]
  }];
  s.appState.writingWorkspace.segments = [
    seg("chapter-1", "Chapter 1", 0),
    seg("chapter-2", "Chapter 2", 1)
  ];
  s.appState.writingWorkspace.savedSegmentTexts = {
    "chapter-1": { text: "t1", title: "Chapter 1" },
    "chapter-2": { text: "t2", title: "Chapter 2" }
  };
  s.api.reconcileLegacyKeysIfNeeded({ project_id: 12345 });
  log("reconcile: keys remapped to ol-*", s.appState.writingWorkspace.segments[0].key === "ol-1724" && s.appState.writingWorkspace.segments[1].key === "ol-1725");
  log("reconcile: savedSegmentTexts remapped", !!s.appState.writingWorkspace.savedSegmentTexts["ol-1724"] && !!s.appState.writingWorkspace.savedSegmentTexts["ol-1725"]);
  log("reconcile: old savedSegmentTexts removed", !s.appState.writingWorkspace.savedSegmentTexts["chapter-1"]);
  log("reconcile: draftText updated", s.appState.writingWorkspace.draftText.length > 0);
  log("reconcile: rename calls sent (draft+notes+fixes)", s.calls.callAppsScriptJson.length === 6);
  log("reconcile: warning cleared", s.appState._legacyKeyWarning === "");
  log("reconcile: status ok", s.calls.setStatus.length === 1 && s.calls.setStatus[0][1] === "ok");

  s = buildSandbox();
  s.appState.writingWorkspace.outline.acts = [{
    id: "a1", sortOrder: 0, children: [
      { id: "ol-1", sortOrder: 0, title: "Chapter 1" },
      { id: "ol-2", sortOrder: 1, title: "Chapter 2" },
      { id: "ol-3", sortOrder: 2, title: "Chapter 3" }
    ]
  }];
  s.appState.writingWorkspace.segments = [
    seg("chapter-1", "Chapter 1", 0),
    seg("chapter-2", "Chapter 2", 1)
  ];
  s.api.reconcileLegacyKeysIfNeeded({ project_id: 12345 });
  log("reconcile mismatch: keys NOT remapped", s.appState.writingWorkspace.segments[0].key === "chapter-1");
  log("reconcile mismatch: no rename calls", s.calls.callAppsScriptJson.length === 0);
  log("reconcile mismatch: warning set", s.appState._legacyKeyWarning.indexOf("mismatch") !== -1);

  s = buildSandbox();
  s.appState.writingWorkspace.outline.acts = [{
    id: "a1", sortOrder: 0, children: [
      { id: "ol-1", sortOrder: 0, title: "Chapter 1" }
    ]
  }];
  s.appState.writingWorkspace.segments = [seg("ol-1", "Chapter 1", 0)];
  s.api.reconcileLegacyKeysIfNeeded({ project_id: 12345 });
  log("reconcile: no-op when keys already ol-*", s.calls.callAppsScriptJson.length === 0);

  console.log("\n== chapterDisplayLabel (Phase 2d) ==");

  log("display: plain chapter number", s.api.chapterDisplayLabel(0, "Chapter 1") === "CHAPTER 1");
  log("display: chapter with subtitle", s.api.chapterDisplayLabel(2, "Chapter 5: The Finale") === "CHAPTER 3 - The Finale");
  log("display: chapter with dash subtitle", s.api.chapterDisplayLabel(0, "Chapter 3 - Intro") === "CHAPTER 1 - Intro");
  log("display: custom title no prefix", s.api.chapterDisplayLabel(1, "My Title") === "CHAPTER 2 - My Title");
  log("display: empty title", s.api.chapterDisplayLabel(0, "") === "CHAPTER 1");

  console.log("\n" + passed + " passed, " + failed + " failed");
  if (failed > 0) process.exit(1);
}

main().catch(function (err) {
  console.error("Harness crashed:", err);
  process.exit(1);
});
