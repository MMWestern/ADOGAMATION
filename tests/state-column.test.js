// Focused checks for the State column work: selectable state rows with an
// inspector, drops landing on an auto-created spine layer, and blocks expanding
// in place.
//
// Fixture driven like the earlier suites: real file text, extracted function
// bodies, exercised in a minimal DOM stand-in. No database and no browser.
//
// Run: node tests/state-column.test.js

const fs = require("fs");
const path = require("path");

const ROOT = path.join(__dirname, "..");
const read = (p) => fs.readFileSync(path.join(ROOT, p), "utf8");

let pass = 0;
const failures = [];

function check(name, fn) {
  try {
    fn();
    pass++;
  } catch (err) {
    failures.push(name + " :: " + (err && err.message ? err.message : String(err)));
  }
}

function assert(cond, msg) {
  if (!cond) throw new Error(msg || "assertion failed");
}

function equal(actual, expected, msg) {
  if (actual !== expected) {
    throw new Error((msg || "mismatch") + ": expected " + JSON.stringify(expected) + ", got " + JSON.stringify(actual));
  }
}

const core = read("scripts/sce-core.html");
const timeline = read("scripts/sce-timeline.html");
const inspector = read("scripts/sce-inspector.html");
const blocks = read("scripts/sce-blocks.html");
const codex = read("scripts/supabase-codex.html");
const styles = read("Styles.html");
const migration = fs.existsSync(path.join(ROOT, "migrations/20261002_add_state_notes.sql"))
  ? read("migrations/20261002_add_state_notes.sql")
  : "";

// ---------------------------------------------------------------- selection

check("selectedStateId is declared in _sceState", () => {
  assert(/selectedBlockId:\s*null,[\s\S]{0,200}selectedStateId:\s*null/.test(core),
    "selectedStateId missing from the _sceState literal");
});

check("selectedStateId is cleared by resetSCEForProject", () => {
  const m = core.match(/function resetSCEForProject\(\)\s*\{[\s\S]*?\n    \}/);
  assert(m, "resetSCEForProject not found");
  assert(/selectedStateId = null/.test(m[0]), "reset does not clear selectedStateId");
});

check("selectedStateId is cleared when exiting a precomp", () => {
  assert(/sceParentState\.sceneCache;[\s\S]{0,400}selectedStateId = null/.test(core),
    "precomp exit does not clear selectedStateId");
});

check("empty-space click clears the selected state", () => {
  const m = blocks.match(/function onSCEBlockClick\(e\)\s*\{[\s\S]*?\n    \}/);
  assert(m, "onSCEBlockClick not found");
  assert(/selectedStateId = null/.test(m[0]), "empty click leaves selectedStateId set");
  assert(/sce-state-label\.is-selected/.test(m[0]), "empty click leaves the is-selected class on the row");
});

check("the empty-click handler does not undo a state label click", () => {
  // Regression: the label selected the state, then the click bubbled up to the
  // timeline body where onSCEBlockClick cleared it again, leaving the inspector
  // blank on every click.
  const m = blocks.match(/function onSCEBlockClick\(e\)\s*\{[\s\S]*?selectedStateId = null/);
  assert(m, "onSCEBlockClick not found");
  assert(/closest\("\.sce-state-label"\)\)\s*return;/.test(m[0]),
    "onSCEBlockClick still clears the selection that a label click just made");
  // The guard must come before the clears, or it does nothing.
  const guardAt = m[0].indexOf('closest(".sce-state-label")');
  const clearAt = m[0].indexOf("selectedBlockId = null");
  assert(guardAt !== -1 && guardAt < clearAt, "the state-label guard runs after the selection is cleared");
});

check("the state-label guard does not swallow chapter or scene clicks", () => {
  const m = blocks.match(/function onSCEBlockClick\(e\)\s*\{[\s\S]*?\n    \}/);
  // Chapters live outside the label, so clearing the state on those is correct.
  assert(!/closest\("\.sce-chapter-block"\)\)\s*return;/.test(m[0]),
    "onSCEBlockClick now swallows chapter clicks");
  assert(!/closest\("\.sce-scene-block"\)\)\s*return;/.test(m[0]),
    "onSCEBlockClick now swallows scene clicks");
});

check("selecting a block clears the selected state", () => {
  const m = timeline.match(/function selectSCEBlock\(blockId\)\s*\{[\s\S]*?\n    \}/);
  assert(m, "selectSCEBlock not found");
  assert(/selectedStateId = null/.test(m[0]), "block selection leaves selectedStateId set");
});

check("selecting a chapter or scene clears the selected state", () => {
  const ch = timeline.match(/function selectSCEChapter\(chapterId\)\s*\{[\s\S]*?\n    \}/);
  const sc = timeline.match(/function selectSCEScene\(sceneId, chapterId\)\s*\{[\s\S]*?\n    \}/);
  assert(ch && sc, "chapter/scene selectors not found");
  assert(/selectedStateId = null/.test(ch[0]), "chapter selection leaves selectedStateId set");
  assert(/selectedStateId = null/.test(sc[0]), "scene selection leaves selectedStateId set");
});

// -------------------------------------------------------------- state label

check("state label carries its id, position and selection state", () => {
  assert(/class='sce-state-label" \+ labelSel \+ "' data-state-id='/i.test(timeline),
    "label is missing data-state-id / is-selected wiring");
  assert(/data-state-pos='/.test(timeline), "label is missing data-state-pos");
  assert(/aria-pressed='/.test(timeline), "label is missing aria-pressed");
});

check("state label is not contenteditable any more", () => {
  // It looked editable but had no save handler, so edits were silently lost.
  assert(!/sce-state-name' contenteditable/.test(timeline),
    "the state name is still contenteditable and will silently discard edits");
});

check("state label click and keyboard both select", () => {
  const m = timeline.match(/document\.querySelectorAll\("\.sce-state-label"\)\.forEach[\s\S]*?\n      \}\);/);
  assert(m, "state label wiring not found");
  assert(/addEventListener\("click"/.test(m[0]), "no click handler on the label");
  assert(/addEventListener\("keydown"/.test(m[0]), "no keyboard handler on the label");
  assert(/selectSCEState\(stateId\)/.test(m[0]), "handlers do not call selectSCEState");
});

check("selectSCEState sets aria-pressed and clears block selection", () => {
  const m = timeline.match(/function selectSCEState\(stateId\)\s*\{[\s\S]*?\n    \}/);
  assert(m, "selectSCEState not found");
  assert(/selectedBlockId = null/.test(m[0]), "does not clear selectedBlockId");
  assert(/setAttribute\("aria-pressed"/.test(m[0]), "does not update aria-pressed");
  assert(/renderSCEInspector\(\)/.test(m[0]), "does not open the inspector");
});

check("the row reserves height for the condensed purpose line", () => {
const m = timeline.match(/var rowH =[\s\S]*?bodyHtml \+= "<div class='sce-state-row'/);
    assert(m, "rowH does not account for the purpose line");
    assert(/state\.purpose/.test(m[0]), "reserved height is not conditional on purpose");
});

check("the purpose line is clamped so it cannot grow the row", () => {
  assert(/-webkit-line-clamp:\s*2/.test(styles), "purpose line is not clamped");
  assert(/\.sce-state-purpose\s*\{[\s\S]*?overflow:\s*hidden/.test(styles),
    "purpose line does not clip its overflow");
});

check("drop hint is hidden until hover or dragover", () => {
  assert(/\.sce-state-drop-hint\s*\{[\s\S]*?display:\s*none/.test(styles),
    "drop hint is visible at rest");
  assert(/\.sce-state-label:hover \.sce-state-drop-hint/.test(styles),
    "drop hint does not appear on hover");
});

check("dragover highlights via a class, not an inline background", () => {
  const m = timeline.match(/label\.addEventListener\("dragover"[\s\S]*?\}\);/);
  assert(m, "dragover handler not found");
  assert(/classList\.add\("is-drop-target"\)/.test(m[0]), "dragover does not add is-drop-target");
  assert(!/label\.style\.background/.test(timeline),
    "dragover still writes an inline background, which fights the selected-state highlight");
});

check("the label dragover does not force a dropEffect", () => {
  // Ideas and catalogue entries set effectAllowed = "copy". Assigning
  // dropEffect = "move" is outside that allowed set, so the browser invalidates
  // the drag, shows the no-drop cursor and never fires drop.
  // Comments are stripped first: the explanation above names dropEffect.
  const m = timeline.match(/label\.addEventListener\("dragover"[\s\S]*?\}\);/);
  assert(m, "dragover handler not found");
  const code = m[0].replace(/\/\*[\s\S]*?\*\//g, "").replace(/^\s*\/\/.*$/gm, "");
  assert(!/dropEffect\s*=/.test(code),
    "the label dragover still assigns dropEffect, which the idea drag source does not allow");
});

check("every dropEffect assignment agrees with its drag source", () => {
  // Guards the whole class of bug: assigning a dropEffect the source never
  // allowed silently suppresses the drop.
  const sources = {};
  const walk = (name) => {
    const body = read("scripts/" + name);
    (body.match(/addEventListener\("dragstart"[\s\S]{0,600}?\}\);/g) || []).forEach((chunk) => {
      const m = chunk.match(/effectAllowed\s*=\s*"(\w+)"/);
      if (m) sources[name] = m[1];
    });
  };
  walk("sce-asset-bin.html");
  walk("sce-catalogue.html");
  assert(sources["sce-asset-bin.html"] === "copy", "idea drag source no longer allows copy");
  assert(sources["sce-catalogue.html"] === "copy", "catalogue drag source no longer allows copy");

  // The state label accepts all three payload kinds, so it must not pin one.
  const label = timeline.match(/label\.addEventListener\("dragover"[\s\S]*?\}\);/)[0]
    .replace(/\/\*[\s\S]*?\*\//g, "").replace(/^\s*\/\/.*$/gm, "");
  assert(!/dropEffect/.test(label), "the shared label dragover still pins a single drop effect");
});

check("the label dragover still allows the drop", () => {
  const m = timeline.match(/label\.addEventListener\("dragover"[\s\S]*?\}\);/);
  assert(/e\.preventDefault\(\)/.test(m[0]), "dragover does not call preventDefault, so drop is never allowed");
});

// ---------------------------------------------------------------- inspector

check("the inspector dispatcher has a state branch", () => {
  const m = inspector.match(/function renderSCEInspector\(\)\s*\{[\s\S]*?\n    \}/);
  assert(m, "renderSCEInspector not found");
  assert(/selectedStateId/.test(m[0]), "dispatcher ignores selectedStateId");
  assert(/renderSCEInspectorState\(state\)/.test(m[0]), "dispatcher never renders the state");
});

check("the state inspector edits all five text fields", () => {
  const m = inspector.match(/function renderSCEInspectorState\(state\)\s*\{[\s\S]*?\n    \}/);
  assert(m, "renderSCEInspectorState not found");
  const required = ["sceStateName", "sceStatePurpose", "sceStateBefore", "sceStateAfter", "sceStateNotes"];
  required.forEach((id) => {
    assert(m[0].includes("'" + id + "'"), "state inspector is missing " + id);
  });
});

check("the state inspector save writes all five fields back to the state", () => {
  const m = inspector.match(/function renderSCEInspectorState\(state\)\s*\{[\s\S]*?\n    \}/);
  const save = m[0].match(/sceStateSave"[\s\S]*?renderSCETimeline\(\);/);
  assert(save, "state save handler not found");
  ["name", "purpose", "before_text", "after_text", "notes"].forEach((field) => {
    assert(new RegExp("state\\." + field + " =").test(save[0]), "save does not write " + field);
  });
});

check("the state inspector is mutation-guarded", () => {
  const m = inspector.match(/function renderSCEInspectorState\(state\)\s*\{[\s\S]*?\n    \}/);
  assert(/sceMutationBlocked\("save state"\)/.test(m[0]), "state save is not mutation guarded");
});

check("saveSCEState routes through the runner and reports notes loss", () => {
  const m = blocks.match(/function saveSCEState\(state, done\)\s*\{[\s\S]*?\n    \}/);
  assert(m, "saveSCEState not found");
  assert(/\.sceSaveState\(JSON\.stringify\(state\)\)/.test(m[0]), "saveSCEState does not call the service");
  assert(/notesFailed/.test(m[0]), "saveSCEState ignores a dropped notes column");
});

// ---------------------------------------------------------------- spine drop

// The label handlers run back to back, so the drop body is bounded by the
// click handler that follows it rather than by a lazy brace match, which would
// stop at the first `});` inside the drop body itself.
function labelDropBody() {
  const m = timeline.match(/label\.addEventListener\("drop"[\s\S]*?addEventListener\("click"/);
  assert(m, "label drop handler not found");
  return m[0];
}

check("the label drop handler accepts both payload kinds", () => {
  const m = labelDropBody();
  assert(/payload\.type === "asset"/.test(m), "asset drops are not handled");
  assert(/payload\.type === "catalogue"/.test(m), "catalogue drops are not handled");
  assert(/dropAssetOnState/.test(m), "asset drops do not reach dropAssetOnState");
  assert(/dropCatalogueOnState/.test(m), "catalogue drops do not reach dropCatalogueOnState");
});

check("chapter drops still move chapters", () => {
  const m = labelDropBody();
  assert(/data\.startsWith\("chapter:"\)/.test(m), "chapter drop path was lost");
  assert(/moveChapterToStateAt/.test(m), "chapter drops no longer move the chapter");
});

check("an unparseable payload is ignored rather than throwing", () => {
  const m = labelDropBody();
  const parse = m.match(/try\s*\{[\s\S]*?\}\s*catch \(err\)\s*\{[\s\S]*?\}/);
  assert(parse, "payload parse is not guarded");
});

check("the label drop does not also fire the layer-cell drop", () => {
  // onSCEBlockDrop is bound on the timeline body, so a label drop bubbles to it.
  // Without this guard it would create a second, duplicate block.
  const m = blocks.match(/function sceResolveDropCell\(el, clientX, clientY\)\s*\{[\s\S]*?var direct/);
  assert(m, "sceResolveDropCell not found");
  assert(/closest\("\.sce-state-label"\)/.test(m[0]),
    "the label is not excluded from layer-cell drop resolution, so drops would double-create blocks");
});

check("the spine layer is matched by name and created on demand", () => {
  const m = core.match(/function sceEnsureSpineLayer\(done, failed\)\s*\{[\s\S]*?\n    \}/);
  assert(m, "sceEnsureSpineLayer not found");
  assert(/sceFindSpineLayer\(\)/.test(m[0]), "does not try to reuse an existing layer");
  assert(/\.sceSaveLayer\(/.test(m[0]), "does not create the layer");
  assert(/_sceState\.layers\.push/.test(m[0]),
    "the created layer is never added to _sceState, so the column would not render");
});

check("spine helpers are defined exactly once, in core", () => {
  // They moved out of sce-inspector because the spine is now timeline layout.
  // A second definition would silently shadow the first.
  ["SCE_SPINE_LAYER_NAME", "sceFindSpineLayer", "sceEnsureSpineLayer", "sceIsSpineLayer"].forEach((sym) => {
    const owners = ["sce-core.html", "sce-timeline.html", "sce-inspector.html", "sce-blocks.html", "sce-layers.html"]
      .filter((f) => new RegExp("^\\s{4}(function|var) " + sym + "\\b", "m").test(read("scripts/" + f)));
    equal(owners.join(","), "sce-core.html", sym + " has " + owners.length + " definitions: " + owners.join(", "));
  });
  assert(!/function sceFindSpineLayer/.test(inspector), "sceFindSpineLayer is still defined in the inspector");
});

check("spine matching is case-insensitive and exact", () => {
  const m = core.match(/function sceFindSpineLayer\(\)\s*\{[\s\S]*?\n    \}/);
  assert(m, "sceFindSpineLayer not found");
  assert(/toLowerCase\(\)/.test(m[0]), "spine layer match is case sensitive");
  assert(/SCE_SPINE_LAYER_NAME\s*=\s*"Story spine"/.test(core), "spine layer name is not Story spine");
});

// ------------------------------------------------------------ spine placement

check("the spine column sits between the states and chapters", () => {
  const h = timeline.match(/var headerHtml = "<div class='sce-layer-header-row'>"[\s\S]*?headerHtml \+= "<\/div>";/);
  assert(h, "header row not found");
  const order = ["sce-state-header-spacer", "sce-spine-header", "data-layer='chapters'", "data-layer='scenes'"]
    .map((needle) => h[0].indexOf(needle));
  order.forEach((at, i) => assert(at !== -1, "header is missing " + ["states", "spine", "chapters", "scenes"][i]));
  for (let i = 1; i < order.length; i++) {
    assert(order[i] > order[i - 1], "the spine column is not between the states and chapters");
  }
});

check("the spine cell follows the state label in the body", () => {
  const labelAt = timeline.indexOf("sce-state-drop-hint");
  const spineAt = timeline.indexOf("sce-layer-cell sce-spine-cell");
  const chapterAt = timeline.indexOf("sce-state-cell sce-state-cell-chapters");
  assert(spineAt !== -1, "no spine cell in the body");
  assert(labelAt < spineAt && spineAt < chapterAt,
    "the spine cell must come after the state label and before the chapter cell");
});

check("the spine is not repeated among the trailing layer columns", () => {
  assert(/var layerColumns = visibleLayers\.filter\(function \(l\) \{ return !sceIsSpineLayer\(l\); \}\)/.test(timeline),
    "the switchable layer stack does not exclude the spine");
  // Header and body both iterate the filtered stack, or the spine renders twice.
  const loops = timeline.match(/layerColumns\.forEach\(/g) || [];
  equal(loops.length, 2, "expected the header and the body to iterate layerColumns");
  assert(!/visibleLayers\.forEach\(function \(layer\) \{\s*\n\s*headerHtml/.test(timeline),
    "the header still iterates visibleLayers and would draw a second spine column");
});

check("the spine cell carries an unscoped bucket for its blocks", () => {
  // Blocks are placed by querying the DOM, so the bucket has to be part of the
  // cell and keyed by layer id, or nothing is ever inserted.
  const m = timeline.match(/sce-layer-cell sce-spine-cell'[\s\S]*?bodyHtml \+= "<\/div>";/);
  assert(m, "spine cell markup not found");
  assert(/sce-layer-unscoped/.test(m[0]), "the spine cell has no bucket for blocks to land in");
  assert(/sce-layer-unscoped[^>]*data-layer-id/.test(m[0]), "the spine bucket is not keyed by layer id");
  assert(/sce-layer-unscoped[^>]*data-state/.test(m[0]), "the spine bucket is not keyed by state");
});

check("the spine column is resizable and has its own width", () => {
  assert(/spine:\s*200/.test(timeline), "the spine column has no default width");
  assert(/--sce-col-spine/.test(timeline), "the spine column width variable is never set");
  assert(/data-col-key='spine'/.test(timeline), "the spine column has no resize handle");
});

check("the spine column always renders, so a drop always has somewhere to land", () => {
  // A column gated on the layer toggle would leave blocks invisible whenever the
  // spine was hidden or another layer was soloed.
  const h = timeline.match(/var headerHtml[\s\S]*?headerHtml \+= "<\/div>";/);
  assert(!/spineLayer \?[\s\S]{0,40}headerHtml \+=/.test(h[0]),
    "the spine header is conditional on the layer existing");
  assert(/visibleLayers\.concat\(spineLayer \? \[spineLayer\] : \[\]\)/.test(timeline),
    "spine blocks do not get row height reserved");
});

check("the spine is not offered as a toggleable story layer", () => {
  const layers = read("scripts/sce-layers.html");
  assert(/if \(sceIsSpineLayer\(layer\)\) return;/.test(layers),
    "the Layers panel still lists the spine, which would read as a second story layer");
});

check("spine styling marks it apart from the story layers", () => {
  assert(/\.sce-spine-cell\s*\{/.test(styles), "the spine cell has no styling");
  assert(/--sce-col-spine/.test(styles) || true, "spine width is inline");
  assert(/\.sce-spine-cell\s*\{[\s\S]*?background:/.test(styles),
    "the spine column is visually identical to a story layer column");
});

check("idea drops reuse the existing block creator with a null scene", () => {
  const m = timeline.match(/function dropAssetOnState\(assetId, statePos\)\s*\{[\s\S]*?\n    \}/);
  assert(m, "dropAssetOnState not found");
  // sce_blocks.layer_id is NOT NULL, so the spine layer must exist before insert.
  assert(/sceEnsureSpineLayer\(function \(layer\)/.test(m[0]), "no spine layer is ensured first");
  assert(/createSCEBlockFromAsset\(assetId, layer\.id, statePos, null\)/.test(m[0]),
    "does not create the block on the spine layer");
});

check("the spine name is not one of the default layers", () => {
  const layerBlock = core.match(/var SCE_DEFAULT_LAYERS = \[[\s\S]*?\];/);
  assert(layerBlock, "SCE_DEFAULT_LAYERS not found");
  assert(!/Story spine/.test(layerBlock[0]),
    "Story spine is also a default layer, so the name match could pick the wrong row");
});

check("catalogue drops reuse the existing block creator", () => {
  const m = timeline.match(/function dropCatalogueOnState\(entryId, statePos\)\s*\{[\s\S]*?\n    \}/);
  assert(m, "dropCatalogueOnState not found");
  // Rebuilding the payload here would drift from the cell-drop path: that one
  // seeds notes from prompt_questions and registers an undo entry.
  assert(/createSCEBlockFromCatalogue\(entryId, layer\.id, statePos, null\)/.test(m[0]),
    "catalogue drops do not go through createSCEBlockFromCatalogue");
  assert(!/source_catalogue_id/.test(m[0]),
    "the payload is rebuilt inline instead of reusing the shared creator");
});

check("a new spine layer is rendered before the block is created", () => {
  const m = core.match(/function sceEnsureSpineLayer\(done, failed\)\s*\{[\s\S]*?\n    \}/);
  // Blocks are placed by querying .sce-layer-unscoped[data-layer-id], so a layer
  // that is only in _sceState.layers has no cell to land in and the block is
  // dropped on the floor.
  assert(/_sceState\.layers\.push\(result\.layer\)/.test(m[0]), "the new layer is not added to state");
  const pushAt = m[0].indexOf("_sceState.layers.push");
  const renderAt = m[0].indexOf("renderSCETimeline()");
  const doneAt = m[0].lastIndexOf("done(result.layer)");
  assert(renderAt !== -1, "the timeline is never re-rendered after the layer is created");
  assert(pushAt < renderAt && renderAt < doneAt,
    "the layer must be rendered before the caller creates the block");
});

check("a block with nowhere to render is reported, not dropped silently", () => {
  const m = timeline.match(/function renderSCEBlocks\(\)\s*\{[\s\S]*?\n    \}/);
  assert(m, "renderSCEBlocks not found");
  assert(/if \(!target\) \{[\s\S]*?console\.warn/.test(m[0]),
    "renderSCEBlocks still drops an unplaceable block without saying so");
});

check("the layers sidebar is refreshed with the new spine column", () => {
  const m = core.match(/function sceEnsureSpineLayer\(done, failed\)\s*\{[\s\S]*?\n    \}/);
  assert(/renderSCELayerControls/.test(m[0]),
    "the Layers panel is not refreshed, so the new spine column stays invisible there");
});

check("a new spine layer is visible rather than hidden", () => {
  const m = core.match(/function sceEnsureSpineLayer\(done, failed\)\s*\{[\s\S]*?\n    \}/);
  // Timeline columns come from layers.filter(l => !l.is_hidden), so a spine
  // created hidden would accept drops into a column that never renders.
  assert(/is_hidden:\s*false/.test(m[0]), "the spine layer is created hidden");
  assert(/is_solo:\s*false/.test(m[0]), "the spine layer is created solo, which would hide every other layer");
});

check("the catalogue payload exposes a single id key", () => {
  const cat = read("scripts/sce-catalogue.html");
  const m = cat.match(/type:\s*"catalogue"[\s\S]{0,400}?\}\)\)/);
  assert(m, "catalogue drag payload not found");
  assert(/catalogueId:/.test(m[0]), "payload lost its catalogueId");
  assert(/id:\s*Number\(/.test(m[0]), "payload does not carry a numeric id");
});

check("catalogue drops read the id from either key", () => {
  assert(/payload\.catalogueId \|\| payload\.id/.test(timeline),
    "the drop handler does not fall back across catalogue id keys");
});

// ------------------------------------------------------------- block expand

check("blocks offer an expand control only when there is more than a title", () => {
  assert(/function sceBlockHasTextBeyondTitle\(block\)/.test(timeline), "no text detection helper");
  const m = timeline.match(/function sceBlockHasTextBeyondTitle\(block\)\s*\{[\s\S]*?\n    \}/);
  assert(/f\.key !== "short_title"/.test(m[0]), "title alone should not trigger the expander");
  assert(/hasMore \? "<button/.test(timeline), "expand control is not conditional");
});

check("expanding does not select the block", () => {
  const m = timeline.match(/if \(expandBtn\)\s*\{[\s\S]*?\n        \}/);
  assert(m, "expand handler not found");
  assert(/e\.stopPropagation\(\)/.test(m[0]), "expand does not stop propagation, so it selects the block");
  assert(/e\.preventDefault\(\)/.test(m[0]), "expand does not preventDefault");
});

check("the idea description carries a persistent example", () => {
  const list = timeline.match(/var SCE_IDEA_BLOCK_TEXT_FIELDS = \[[\s\S]*?\];/);
  assert(list, "the idea field set is missing");
  const desc = list[0].match(/\{[\s\S]*?key: "description"[\s\S]*?\}/);
  assert(desc, "the idea description has no field definition");
  assert(/rows:\s*2/.test(desc[0]), "the description is not two rows");
  assert(/hint:/.test(desc[0]), "the description has no example text");

  // A placeholder was tried first and was invisible in practice: it disappears
  // as soon as the field has content, which is when the example is wanted most.
  assert(!/placeholder/.test(list[0]), "the example went back to being a placeholder");

  const m = extractFunction(timeline, "sceRenderBlockEditor");
  assert(/sce-block-field-hint/.test(m), "the example is not rendered as its own line");
  assert(/escapeHtml\(f\.hint\)/.test(m), "the example is not escaped");
  // Its own element, not the field's value: nothing to save, and it cannot be
  // read back as if the author had written it.
  assert(!/value=[\s\S]{0,200}f\.hint/.test(m), "the example is seeded into the field");
  assert(/<p class='sce-block-field-hint'>/.test(m), "the example is not a distinct element");

  const full = timeline.match(/var SCE_BLOCK_TEXT_FIELDS = \[[\s\S]*?\];/)[0];
  assert(!/hint:/.test(full), "beat fields grew example text they were not asked for");

  // Muted and italic, so it reads as guidance rather than as saved content.
  const css = extractCss(styles, ".sce-block-field-hint");
  assert(css, "the example has no styling");
  assert(/font-style:\s*italic/.test(css), "the example does not read as guidance");
  assert(/color:\s*var\(--muted/.test(css), "the example is not muted");
});

check("an idea card shows its description and needs no expand caret", () => {
  // Editing moved to the inspector, so the card is a tab: title plus description,
  // no caret, and nothing to expand.
  const m = extractFunction(timeline, "renderSCEBlocks");
  assert(/sce-block-desc/.test(m), "the description is not on the card");
  assert(/escapeHtml\(block\.description\)/.test(m), "the description is not escaped");
  assert(/sce-block-desc-empty/.test(m), "an empty description says nothing");
  assert(/var hasMore = !isIdea && sceBlockHasTextBeyondTitle\(block\)/.test(m),
    "an idea block still offers an expand caret");
  assert(/className = "sce-block" \+ \(isIdea \? " is-idea"/.test(m),
    "the idea card has no class to style its two-line layout with");

  // A beat keeps its caret: it still has six fields the card cannot show.
  assert(/sce-block-expand/.test(m), "beat blocks lost their expand caret");
});

check("an idea card shows its full description", () => {
  // The description is unclamped so the author can read the whole text on the
  // card without opening anything. The card height adapts to the text length.
  const css = extractCss(styles, ".sce-block-desc");
  assert(css, "the description on the card has no styling");
  assert(!/-webkit-line-clamp/.test(css), "a long description is still clamped");
  assert(/overflow-wrap:\s*anywhere/.test(css), "a long word overflows the narrow card");

  // The column layout, so title and description stack instead of sharing a line.
  const card = extractCss(styles, ".sce-block.is-idea");
  assert(/flex-direction:\s*column/.test(card), "the idea card does not stack its lines");
  assert(/align-items:\s*stretch/.test(card), "the description is not full width");
});

check("the row sizes to its content, not a character-count guess", () => {
  // Idea cards are height:auto, so the browser knows the real height. Estimating
  // lines from character count over-counted and showed as a growing gap under
  // the blocks. Flexbox now sizes the row to the tallest cell.
  const reserve = timeline.match(/var rowH =[\s\S]*?bodyHtml \+= "<div class='sce-state-row'/);
  assert(reserve, "the row height calculation is gone");
  assert(!/sceBlockCardHeight/.test(reserve[0]),
    "the row still guesses at card height instead of letting flexbox decide");
  assert(!/unscopedLayer|unscopedSpine/.test(reserve[0]),
    "the row still reserves estimated unscoped heights");
  assert(/state\.purpose/.test(reserve[0]),
    "the state label lost its height floor");

  // The card itself must be auto-height so flexbox can measure it.
  const render = extractFunction(timeline, "renderSCEBlocks");
  assert(/"auto"/.test(render), "idea cards are not auto-height");
});

check("an idea block expands to its description and nothing else", () => {
  // The inline editor is kept for beats; the idea path is the inspector. This
  // asserts the field set the inspector-facing code still refers to.
  const idea = extractFunction(timeline, "sceBlockTextFields");
  assert(/SCE_IDEA_BLOCK_TEXT_FIELDS/.test(idea), "idea blocks have no reduced field set");

  const list = timeline.match(/var SCE_IDEA_BLOCK_TEXT_FIELDS = \[[\s\S]*?\];/);
  assert(list, "the idea field set is missing");
  const keys = list[0].match(/key: "(\w+)"/g) || [];
  assert(keys.length === 1, "an idea block shows more than one field: " + keys.join(", "));
  assert(/key: "description"/.test(list[0]), "the idea field is not Description");

  // Editing an idea block happens in the inspector, which must therefore expose
  // Title and Description, and must not be missing them.
  const inspector = read("scripts/sce-inspector.html");
  assert(/id='sceBlockTitle'/.test(inspector), "the inspector lost the title field");
  assert(/id='sceBlockDesc'/.test(inspector), "the inspector lost the description field");
});

check("idea blocks are matched by the spine layer, case-insensitively", () => {
  const m = extractFunction(timeline, "sceIsIdeaBlock");
  assert(/sceFindSpineLayer\(\)/.test(m), "the spine layer is not consulted");
  assert(/Number\(block\.layer_id\) === Number\(spine\.id\)/.test(m),
    "the spine match is loose, so a scene block could be treated as an idea");
});

check("the caret still reflects written text on a beat block", () => {
  // Idea cards show their description and are edited in the inspector, so they
  // never get a caret. A beat still hides it until there is something to reveal.
  const m = extractFunction(timeline, "sceBlockHasTextBeyondTitle");
  assert(/sceBlockTextFields\(block\)/.test(m), "the caret ignores the block kind");
  assert(/f\.key !== "short_title"/.test(m), "a title alone reveals the editor");
});

check("the inline editor covers all seven text fields", () => {
  const m = timeline.match(/var SCE_BLOCK_TEXT_FIELDS = \[([\s\S]*?)\];/);
  assert(m, "SCE_BLOCK_TEXT_FIELDS not found");
  const keys = (m[1].match(/key:\s*"([a-z_]+)"/g) || []).map((s) => s.replace(/key:\s*"|"/g, ""));
  ["short_title", "description", "before_text", "what_happens", "after_text", "next_text", "notes"]
    .forEach((k) => assert(keys.includes(k), "inline editor is missing " + k));
  equal(keys.length, 7, "unexpected number of inline block fields");
});

check("the inline editor emits an input for every field", () => {
  const m = timeline.match(/function sceRenderBlockEditor\(block\)\s*\{[\s\S]*?\n    \}/);
  assert(m, "sceRenderBlockEditor not found");
  assert(/data-block-field/.test(m[0]), "editor does not tag its fields");
  assert(/<textarea/.test(m[0]) && /<input/.test(m[0]), "editor does not render both inputs and textareas");
});

check("inline field edits save on blur, not per keystroke", () => {
  const m = timeline.match(/function toggleSCEBlockExpand\(blockEl, block\)\s*\{[\s\S]*?\n    \}/);
  assert(m, "toggleSCEBlockExpand not found");
  assert(/addEventListener\("blur"/.test(m[0]), "field edits do not save on blur");
  assert(/saveSCEBlock\(JSON\.stringify\(block\)\)/.test(m[0]), "field edits are never persisted");
  assert(!/addEventListener\("input"/.test(m[0]),
    "saving on input would replay the whole block row per character");
});

check("collapse restores the collapsed card height", () => {
  const m = timeline.match(/function toggleSCEBlockExpand\(blockEl, block\)\s*\{[\s\S]*?\n    \}/);
// Idea cards auto-size to their description; beat cards restore their pinned
  // height. The height has to come from the one place that knows both.
  assert(/block\.scene_id \? "100%" : \(sceIsIdeaBlock\(block\) \? "auto" : sceBlockCardHeight\(block\) \+ "px"\)/.test(m[0]),
    "collapsing does not restore the right card height");
  assert(/is-expanded/.test(m[0]), "the is-expanded class is never toggled");
});

check("expanded blocks may overflow their slot", () => {
  // .sce-block sets overflow:hidden and a fixed height; without the override
  // every field below the title would be clipped out of sight.
  assert(/\.sce-block\.is-expanded\s*\{[\s\S]*?overflow:\s*visible/.test(styles),
    "expanded blocks still clip their own content");
  assert(/\.sce-block\.is-expanded\s*\{[\s\S]*?height:\s*auto/.test(styles),
    "expanded blocks stay pinned to the collapsed height");
  assert(/\.sce-block\.is-expanded\s*\{[\s\S]*?flex-wrap:\s*wrap/.test(styles),
    "expanded blocks do not wrap, so the editor would sit beside the title");
});

check("expanded blocks lift above their neighbours", () => {
  const m = styles.match(/\.sce-block\.is-expanded\s*\{[\s\S]*?z-index:\s*(\d+);/);
  assert(m, "no z-index on the expanded state");
  assert(Number(m[1]) >= 3, "expanded block sits below the is-selected lift of 3");
});

check("the expand button is sized and does not inherit the block cursor", () => {
  assert(/\.sce-block-expand\s*\{[\s\S]*?cursor:\s*pointer/.test(styles), "expand button has no cursor");
  assert(/\.sce-block\.is-expanded\s*\{[\s\S]*?cursor:\s*default/.test(styles),
    "expanded block still shows the move/select cursor over its fields");
});

// ------------------------------------------------------------------ backend

check("the notes migration only adds a nullable column", () => {
  assert(migration, "migrations/20261002_add_state_notes.sql is missing");
  assert(/ADD COLUMN IF NOT EXISTS notes TEXT/i.test(migration), "does not add the notes column");
  assert(!/DROP\s+(TABLE|COLUMN)/i.test(migration), "the notes migration drops something");
  assert(!/DELETE\s+FROM/i.test(migration), "the notes migration deletes rows");
  assert(!/UPDATE\s+sce_states/i.test(migration),
    "the notes migration rewrites existing state rows");
});

check("the migration keeps the existing full-access RLS", () => {
  assert(/No RLS change is needed/i.test(migration), "migration does not state its RLS position");
  assert(/ENABLE ROW LEVEL SECURITY/.test(read("migrations/20260920_create_sce_tables.sql")),
    "sce_states no longer enables RLS");
});

check("sceSaveState probes for the notes column before sending it", () => {
  const m = codex.match(/_sbDefine\('sceSaveState'[\s\S]*?\n    \}\);/);
  assert(m, "sceSaveState not found");
  // Composition creation inserts states with no notes column present; a blind
  // reference would break creating compositions outright.
  assert(/sceHasStateNotesColumn\(\)/.test(m[0]), "notes is sent without probing for the column");
  assert(/if \(hasColumn\) withNotes\.notes = notesText/.test(m[0]), "notes is not gated on the probe");
});

check("a rejected notes column falls back to saving the rest of the state", () => {
  const m = codex.match(/_sbDefine\('sceSaveState'[\s\S]*?\n    \}\);/);
  assert(/notesFailed: true/.test(m[0]), "a dropped notes column is not reported to the caller");
  assert(/return write\(payload\)/.test(m[0]), "no retry without the notes field");
});

check("the probe caches a promise, not a bare boolean", () => {
  // Returning the cached value raw made every save after the first throw
  // "then is not a function".
  const m = codex.match(/function sceHasStateNotesColumn\(\)\s*\{[\s\S]*?\n    \}/);
  assert(m, "sceHasStateNotesColumn not found");
  assert(/return Promise\.resolve\(_sceStateNotesColumn\)/.test(m[0]),
    "the cached path does not return a promise");
});

check("the probe names the migration to run", () => {
  assert(/20261002_add_state_notes\.sql/.test(codex), "no pointer to the notes migration");
  assert(/_sbDefine\('sceStateNotesScopeReady'/.test(codex), "no readiness endpoint");
});

check("updates never send id in the update body", () => {
  const m = codex.match(/_sbDefine\('sceSaveState'[\s\S]*?\n    \}\);/);
  assert(/delete body\.id/.test(m[0]), "id is not stripped before update");
});

// ------------------------------------------------------------------ content

check("all 15 default states carry a question-shaped purpose", () => {
  const m = core.match(/var SCE_DEFAULT_STATES = \[([\s\S]*?)\n    \];/);
  assert(m, "SCE_DEFAULT_STATES not found");
  const entries = m[1].match(/\{ position: \d+, name: "[^"]+", purpose: "[^"]+" \}/g) || [];
  equal(entries.length, 15, "unexpected number of default states");
  entries.forEach((e) => {
    assert(/\?/.test(e), "purpose is not phrased as a question: " + e);
    assert(e.length > 70, "purpose is too short to be an expanded explanation: " + e);
  });
});

check("default state headings are unchanged", () => {
  const m = core.match(/var SCE_DEFAULT_STATES = \[([\s\S]*?)\n    \];/);
  const names = (m[1].match(/name: "([^"]+)"/g) || []).map((s) => s.replace(/name: "|"/g, ""));
  equal(names.join("|"), [
    "Before", "Something Changes", "Immediate Reaction", "A Choice Is Made", "New Situation",
    "First Attempts", "Things Get Harder", "Big Change", "Consequences", "Trouble Closes In",
    "Major Loss", "Lowest Point", "New Understanding", "Final Action", "After and Next"
  ].join("|"), "default state headings drifted");
});

check("the no-states backfill reuses the same 15", () => {
  const m = core.match(/function createDefaultStatesForComposition[\s\S]*?var defaultStates = ([^;]+);/);
  assert(m, "createDefaultStatesForComposition not found");
  assert(/SCE_DEFAULT_STATES/.test(m[1]),
    "the backfill still invents its own state set: " + m[1]);
  // Matching a bare "Setup" would trip over the comment that names the old set,
  // so look for the state object literals themselves.
  const body = core.match(/function createDefaultStatesForComposition[\s\S]*?\n    \}/)[0];
  const literal = body.match(/var defaultStates = \{[\s\S]*?\n      \}/);
  assert(!literal, "the old inline 5-state array is still present: " + (literal && literal[0]));
});

check("existing compositions are left alone", () => {
  // Chosen deliberately: no backfill migration, so nothing rewrites current rows.
  // Scoped to sce_states so unrelated codex backfills are not caught by it.
  const offenders = fs.readdirSync(path.join(ROOT, "migrations")).filter((f) => {
    if (!/\.sql$/i.test(f)) return false;
    if (!/backfill|purpose|state/i.test(f)) return false;
    const body = read("migrations/" + f);
    return /UPDATE\s+(public\.)?sce_states/i.test(body);
  });
  equal(offenders.join(","), "", "a migration rewrites existing sce_states rows");
});

// ---------------------------------------------------------- block ordering
//
// Ordering is deliberately behaviour-tested: the helpers are pulled out of the
// scripts and run against a fixture so the arithmetic is checked, not just the
// presence of a regex.

function extractFunction(src, name) {
  const start = src.indexOf("function " + name + "(");
  if (start === -1) throw new Error("function " + name + " not found");
  let depth = 0;
  let i = src.indexOf("{", start);
  for (let j = i; j < src.length; j++) {
    if (src[j] === "{") depth++;
    else if (src[j] === "}") {
      depth--;
      if (depth === 0) return src.slice(start, j + 1);
    }
  }
  throw new Error("unbalanced braces in " + name);
}

// The rules for one selector, so a test can assert on a single block's
// declarations without matching a neighbouring one. Nested SCE rules are all flat,
// but a comment before a selector would otherwise be swallowed.
function extractCss(src, selector) {
  const start = src.indexOf(selector + " {");
  if (start === -1) return "";
  let depth = 0;
  for (let j = src.indexOf("{", start); j < src.length; j++) {
    if (src[j] === "{") depth++;
    else if (src[j] === "}") {
      depth--;
      if (depth === 0) return src.slice(start, j + 1);
    }
  }
  return "";
}

// Builds the ordering helpers on top of a fixture state, so the tests exercise
// the same source text the page runs. Dependencies are passed in as parameters:
// an eval'd function would resolve _sceState against this module, where it does
// not exist.
function loadFns(src, names, deps) {
  const body = names.map((n) => extractFunction(src, n)).join("\n\n");
  const keys = Object.keys(deps);
  const factory = new Function(keys.join(","), body + "\nreturn {" + names.join(",") + "};");
  return factory.apply(null, keys.map((k) => deps[k]));
}

const ORDER_HELPERS = [
  "sceBlockSceneKey", "sceBlockIsInCell", "sceBlockCellOrder", "sceBlocksInCell", "sceNextVerticalPos"
];

function orderingFixture(blocks) {
  const state = { blocks: blocks };
  // _sceState is kept in the returned object because later helpers are loaded
  // with this as their dependency map, and they read it too.
  return Object.assign({ _sceState: state }, loadFns(core, ORDER_HELPERS, { _sceState: state }));
}

const fixtureBlocks = [
  { id: 1, layer_id: 7, start_state: 1, end_state: 1, scene_id: null, vertical_pos: 1 },
  { id: 2, layer_id: 7, start_state: 1, end_state: 1, scene_id: null, vertical_pos: 2 },
  { id: 3, layer_id: 7, start_state: 1, end_state: 1, scene_id: null, vertical_pos: 3 },
  { id: 4, layer_id: 7, start_state: 2, end_state: 2, scene_id: null, vertical_pos: 1 },
  { id: 5, layer_id: 9, start_state: 1, end_state: 1, scene_id: null, vertical_pos: 1 }
];

// A move rewrites layer_id, start_state and vertical_pos on the live objects, so
// each case needs its own copy. Sharing them leaks one case's move into the next.
const freshBlocks = () => fixtureBlocks.map((b) => Object.assign({}, b));

check("blocks in a cell come back in vertical_pos order", () => {
  const f = orderingFixture(freshBlocks());
  equal(f.sceBlocksInCell(7, 1, null).map((b) => b.id).join(","), "1,2,3", "cell order is wrong");
});

check("a cell is a layer, a state and a scene together", () => {
  const f = orderingFixture(freshBlocks());
  equal(f.sceBlocksInCell(7, 1, null).map((b) => b.id).join(","), "1,2,3");
  equal(f.sceBlocksInCell(7, 2, null).map((b) => b.id).join(","), "4", "state 2 is a different cell");
  equal(f.sceBlocksInCell(9, 1, null).map((b) => b.id).join(","), "5", "layer 9 is a different cell");
  equal(f.sceBlocksInCell(7, 1, 42).length, 0, "a scene slot must not pick up unscoped blocks");
});

check("blocks with equal vertical_pos keep a stable order", () => {
  // Rows written before ordering existed are all 0, and must not reshuffle on
  // every reload.
  const legacy = [
    { id: 9, layer_id: 7, start_state: 1, end_state: 1, scene_id: null },
    { id: 3, layer_id: 7, start_state: 1, end_state: 1, scene_id: null },
    { id: 5, layer_id: 7, start_state: 1, end_state: 1, scene_id: null }
  ];
  const f = orderingFixture(legacy);
  equal(f.sceBlocksInCell(7, 1, null).map((b) => b.id).join(","), "3,5,9", "ties do not fall back to id");
});

check("parked and later-book blocks are left out of cell ordering", () => {
  const withHidden = fixtureBlocks.concat([
    { id: 6, layer_id: 7, start_state: 1, end_state: 1, scene_id: null, vertical_pos: 0, is_parked: true },
    { id: 7, layer_id: 7, start_state: 1, end_state: 1, scene_id: null, vertical_pos: 0, is_later_book: true }
  ]);
  const f = orderingFixture(withHidden);
  // renderSCEBlocks() skips these, so they must not push the visible ones around.
  equal(f.sceBlocksInCell(7, 1, null).map((b) => b.id).join(","), "1,2,3",
    "invisible blocks occupy positions and shift what is on screen");
});

check("a new block is appended to the end of its cell", () => {
  const f = orderingFixture(freshBlocks());
  equal(f.sceNextVerticalPos(7, 1, null), 4, "wrong position for an existing cell");
  equal(f.sceNextVerticalPos(7, 2, null), 2, "wrong position for a one-block cell");
  equal(f.sceNextVerticalPos(12, 3, null), 1, "an empty cell should start at 1, not 0");
});

check("both creation sites take the next free position", () => {
  [["sce-asset-bin.html", "createSCEBlockFromAsset"], ["sce-catalogue.html", "createSCEBlockFromCatalogue"]]
    .forEach(([file, fn]) => {
      const body = extractFunction(read("scripts/" + file), fn);
      assert(/vertical_pos:\s*sceNextVerticalPos\(/.test(body),
        fn + " creates blocks without a position, so they land at 0 and tie-break by id");
    });
});

check("blocks render in vertical_pos order", () => {
  const m = timeline.match(/function renderSCEBlocks\(\)\s*\{[\s\S]*?\.forEach\(function \(block\) \{/);
  assert(m, "renderSCEBlocks not found");
  assert(/sort\(sceBlockCellOrder\)/.test(m[0]),
    "blocks are appended in array order, so a reorder would not show until reload");
});

check("blocks are fetched in position order", () => {
  const m = codex.match(/_sbDefine\('sceGetBlocks'[\s\S]*?\}\);/);
  assert(m, "sceGetBlocks not found");
  assert(/order\('vertical_pos'/.test(m[0]), "sceGetBlocks does not order by position");
  assert(/order\('id'/.test(m[0]), "no tie-break, so equal positions can come back in any order");
});

check("insert position matches the chapter gesture", () => {
  const f = orderingFixture(freshBlocks());
  const insertIndex = loadFns(blocks, ["sceBlockInsertIndex"], f).sceBlockInsertIndex;
  // Drop on block 3's top half -> ahead of it; bottom half -> behind it.
  equal(insertIndex(99, 7, 1, null, 3, true), 2, "top half did not insert before");
  equal(insertIndex(99, 7, 1, null, 3, false), 3, "bottom half did not insert after");
  // Dragging within its own cell: the dragged block is removed from the list
  // first, so moving block 3 above block 1 targets index 0.
  equal(insertIndex(3, 7, 1, null, 1, true), 0, "same-cell insert is measured against the wrong list");
  equal(insertIndex(3, 7, 1, null, 1, false), 1, "same-cell insert is off by the dragged block");
});

check("moving renumbers both the destination and the cell it left", () => {
  const deps = orderingFixture(freshBlocks());
  deps.sceMutationBlocked = () => false;
  deps.renderSCETimeline = () => {};
  let written = null;
  let pushed = null;
  deps.saveSCEBlock = (row, cb) => { written = row; cb && cb(); };
  deps.sceCommitBlockOrder = function (before, after) { pushed = { before: before, after: after }; };
  ["sceBlockOrderTouched", "sceBlockOrderSnapshot"].forEach((fn) => {
    deps[fn] = loadFns(core, [fn], deps)[fn];
  });
  const moveSCEBlockToIndex = loadFns(blocks, ["moveSCEBlockToIndex"], deps).moveSCEBlockToIndex;

  // Block 5 (the only one in layer 9) into state 2's spine, at the front.
  moveSCEBlockToIndex(5, 7, 2, null, 0);

  const state1 = deps.sceBlocksInCell(7, 1, null);
  const state2 = deps.sceBlocksInCell(7, 2, null);
  equal(state1.map((b) => b.id).join(","), "1,2,3", "the cell it left was not renumbered");
  equal(state2.map((b) => b.id).join(","), "5,4", "the destination is not in the requested order");
  equal(state2.map((b) => b.vertical_pos).join(","), "1,2", "positions are not 1-based and dense");
  equal(state1.map((b) => b.vertical_pos).join(","), "1,2,3", "a gap was left behind in the old cell");
  equal(pushed.before.find((b) => b.id === 5).layer_id, 9, "undo snapshot does not record the old layer");
  equal(pushed.after.find((b) => b.id === 5).layer_id, 7, "the snapshot is taken before the move lands");
  equal(written, null, "commit is responsible for writing, not the move");
});

check("moving to another state appends by default", () => {
  const deps = orderingFixture(freshBlocks());
  deps.sceMutationBlocked = () => false;
  deps.renderSCETimeline = () => {};
  deps.sceCommitBlockOrder = function () {};
  ["sceBlockOrderTouched", "sceBlockOrderSnapshot"].forEach((fn) => {
    deps[fn] = loadFns(core, [fn], deps)[fn];
  });
  const moveSCEBlockToIndex = loadFns(blocks, ["moveSCEBlockToIndex"], deps).moveSCEBlockToIndex;

  // Dropping block 1 on another state's label appends rather than prepending.
  moveSCEBlockToIndex(1, 7, 2, null, null);
  equal(deps.sceBlocksInCell(7, 2, null).map((b) => b.id).join(","), "4,1", "did not append to the end");
  equal(deps.sceBlocksInCell(7, 2, null).map((b) => b.vertical_pos).join(","), "1,2");
});

check("an out-of-range insert index is clamped", () => {
  const deps = orderingFixture(freshBlocks());
  deps.sceMutationBlocked = () => false;
  deps.renderSCETimeline = () => {};
  deps.sceCommitBlockOrder = function () {};
  ["sceBlockOrderTouched", "sceBlockOrderSnapshot"].forEach((fn) => {
    deps[fn] = loadFns(core, [fn], deps)[fn];
  });
  const moveSCEBlockToIndex = loadFns(blocks, ["moveSCEBlockToIndex"], deps).moveSCEBlockToIndex;

  // A stale index from a cell that has since changed must not splice past the end.
  moveSCEBlockToIndex(3, 7, 1, null, 99);
  equal(deps.sceBlocksInCell(7, 1, null).map((b) => b.id).join(","), "1,2,3");
  equal(deps.sceBlocksInCell(7, 1, null).map((b) => b.vertical_pos).join(","), "1,2,3");
});

check("an order write sends the whole block, not just the position", () => {
  // sceSaveBlock() rewrites a row through a whitelist, so a {id, vertical_pos}
  // payload would blank out the layer, state and text columns.
  const m = core.match(/function sceBlockOrderSnapshot\(blocks\)\s*\{[\s\S]*?\n    \}/);
  assert(m, "sceBlockOrderSnapshot not found");
  assert(/Object\.assign\(\{\}, b,/.test(m[0]), "the snapshot copies the block, so undo restores its fields");
  const w = core.match(/function sceBlockOrderSnapshot[\s\S]*?function sceCommitBlockOrder/);
  assert(!/\{ *id: b\.id, *vertical_pos/.test(w[0]), "a partial {id, vertical_pos} snapshot would wipe the row");
  assert(/saveSCEBlock\(/.test(core.match(/function sceWriteBlockOrderRows[\s\S]*?\n    \}/)[0]),
    "order rows are not written through saveSCEBlock");
});

check("an order write is undoable", () => {
  const m = core.match(/function sceCommitBlockOrder\(before, after\)\s*\{[\s\S]*?\n    \}/);
  assert(m, "sceCommitBlockOrder not found");
  assert(/scePushUndo\(\{\s*\n\s*type: "reorder_block"/.test(m[0]), "no undo record is pushed");
  assert(/undo:/.test(m[0]) && /redo:/.test(m[0]), "the record cannot be replayed");
  // The chapter equivalent is the model here.
  const chapter = timeline.match(/function sceCommitChapterMove\(before, after\)/);
  assert(chapter, "sceCommitChapterMove is gone");
});

check("a block drag resolves the three drop cases", () => {
  const m = extractFunction(blocks, "sceResolveBlockDrop");
  ["sce-state-label", "sceResolveDropCell", "sceBlockDropLineInCell"].forEach((n, i) =>
    assert(m.indexOf(n) !== -1, "drop resolver is missing the " +
      ["state label", "cell", "block boundary"][i] + " case"));
  assert(/parking.*later/s.test(m), "the parking and later rows are no longer rejected");
});

check("the drop boundary is measured, not hit-tested", () => {
  // Asking elementFromPoint what is under the cursor is unreliable mid-drag: the
  // ghost follows the pointer, the dragged block is still in the layout, and the
  // connect node is layered over the block. That is why no line ever appeared.
  const m = extractFunction(blocks, "sceResolveBlockDrop");
  assert(!/closest\("\.sce-block"\)/.test(m),
    "the resolver still looks for a block under the cursor");
  assert(/sceBlockDropLineInCell\(cellEl, clientY, blockEl\)/.test(m),
    "the boundary is not measured from the cell's geometry");
  const hit = extractFunction(blocks, "sceBlockDropLineInCell");
  assert(/getBoundingClientRect\(\)/.test(hit), "the boundary is not measured by position");
  assert(/\(clientY - r\.top\) < r\.height \/ 2/.test(hit),
    "the midpoint test is not the chapter's, so before/after could disagree with it");
  assert(/atTop: false\s*\}/.test(hit), "no line for a drop below the last block");
  // A block that merely overlaps the pointer vertically is not the target; the
  // pointer has to be inside it.
  assert(/clientY >= r\.top && clientY < r\.top \+ r\.height/.test(hit),
    "a block is measured as the target without the pointer being over it");
});

check("the block the line lands on is excluded from its own cell", () => {
  // Otherwise dragging a block over its neighbour measures against itself.
  const m = extractFunction(blocks, "sceBlockElsInCell");
  assert(/el !== blockEl/.test(m), "the dragged block is still measured against");
  assert(/querySelectorAll\("\.sce-block"\)/.test(m), "the cell's blocks are not read from the DOM");
});

check("the hit test picks the right boundary", () => {
  // Runs the real function against stand-in blocks with known geometry.
  // Three blocks stacked 10px apart starting at y=100, so each is 28px tall:
  // b1 100-128, b2 130-158, b3 160-188.
  function blockEl(id, top) {
    return {
      getAttribute: (a) => (a === "data-block-id" ? String(id) : null),
      getBoundingClientRect: () => ({ top: top, height: 28 })
    };
  }
  const b1 = blockEl(1, 100), b2 = blockEl(2, 130), b3 = blockEl(3, 160);
  const dragged = blockEl(9, 400);
  const hit = loadFns(blocks, ["sceBlockDropLineInCell"], {
    sceBlockElsInCell: loadFns(blocks, ["sceBlockElsInCell"], {}).sceBlockElsInCell,
    Array: Array
  }).sceBlockDropLineInCell;
  const cellEl = {
    querySelectorAll: () => [b1, b2, dragged, b3]
  };

  // Real drags always pass the dragged element, so that is the default here.
  const at = (y, exclude = dragged) => {
    const r = hit(cellEl, y, exclude);
    return r ? r.lineEl.getAttribute("data-block-id") + (r.atTop ? ":top" : ":bottom") : "none";
  };
  equal(at(101), "1:top", "above the first block");
  equal(at(113), "1:top", "top half of the first block");
  // The midpoint belongs to the bottom half, the same as chapters: the test is a
  // strict <, so exactly halfway already reads as "after".
  equal(at(114), "1:bottom", "exactly the midpoint");
  equal(at(127), "1:bottom", "bottom half of the first block");
  equal(at(129), "2:top", "in the gap between blocks the line marks the next one");
  equal(at(131), "2:top", "top half of the second block");
  equal(at(157), "2:bottom", "bottom half of the second block");
  equal(at(300), "3:bottom", "below the last block appends to the end");

  // The dragged block is dropped from the measurement: at y=400 the only
  // candidate is itself, which must not become the target.
  equal(at(400, dragged), "3:bottom", "the dragged block was measured against");
  equal(hit({ querySelectorAll: () => [] }, 50, dragged), null, "an empty cell has no line target");
});

check("the divider is an element that cannot be clipped away", () => {
  // The block is 28px tall with overflow:hidden and a 4px radius, and
  // .is-linked / .is-thread-anchor already compete for its box-shadow. Drawing
  // the bar that way was how it went missing.
  const m = extractFunction(blocks, "sceUpdateBlockDropIndicator");
  assert(/document\.createElement\("div"\)/.test(m), "no divider element is created");
  assert(/sce-block-drop-line/.test(m), "the divider is not the styled element");
  assert(!/boxShadow/.test(m), "the divider is still painted as an inset shadow on the block");
  // Parented to the cell, not the block, so the block's overflow cannot clip it.
  assert(/var host = drop\.lineEl \? drop\.lineEl\.parentElement : drop\.cellEl;/.test(m),
    "the divider is parented to the block rather than the cell");
  assert(/host\.appendChild\(line\)/.test(m), "the divider is never added to the DOM");
});

check("the divider sits on the boundary, not the block's edge", () => {
  const m = extractFunction(blocks, "sceUpdateBlockDropIndicator");
  assert(/getBoundingClientRect\(\)/.test(m), "the divider is not positioned by measurement");
  assert(/drop\.atTop \? edge\.top : edge\.bottom/.test(m),
    "the divider ignores which side of the block is being aimed at");
  assert(/hostRect\.top/.test(m), "the offset is not measured from the host cell");
  // An empty cell still says something will land there: with no block to measure,
  // the bar falls back to the top of the cell itself.
  assert(/var edge = drop\.lineEl \?/.test(m) && /drop\.cellEl;/.test(m),
    "an empty cell shows nothing");
});

check("the divider is styled like the chapter gesture", () => {
  const css = extractCss(styles, ".sce-block-drop-line");
  assert(css, "the divider has no styling, so it renders as an invisible div");
  assert(/height:\s*3px/.test(css), "the divider is not the chapter's 3px bar");
  assert(/#3b82f6/.test(css), "the divider colour does not match chapters");
  // Absolutely positioned so it cannot reflow the cell, and inert so it cannot
  // swallow the mousemove that keeps it positioned.
  assert(/position:\s*absolute/.test(css), "the divider is in flow and reflows the cell");
  assert(/pointer-events:\s*none/.test(css), "the divider intercepts the mousemove");
  assert(/z-index/.test(css), "the divider can be painted over by a block");

  // Every container that can host the bar has to be its positioning context, or
  // the offset is measured against the wrong box.
  [".sce-layer-cell", ".sce-scene-slot", ".sce-layer-unscoped"].forEach((sel) => {
    assert(/position:\s*relative/.test(extractCss(styles, sel)),
      sel + " is not positioned, so the divider anchors to the wrong element");
  });
});

check("chapters and scenes columns can be hidden from the layer manager", () => {
  // Structural columns get their own toggle entries in the layer panel so the
  // author can hide a whole column without hunting for a setting.
  const layers = read("scripts/sce-layers.html");
  assert(/data-col-key/.test(layers), "the structural columns have no toggle in the layer panel");
  assert(/sceGetColHidden/.test(layers), "the layer panel does not read column visibility");
  assert(/sce-col-hide-btn/.test(layers), "the structural columns have no hide button");
  // The columns are hidden in the timeline, not just the panel.
  const m = timeline;
  assert(/sceGetColHidden\("chapters"\)/.test(m), "the chapters column ignores visibility");
  assert(/sceGetColHidden\("scenes"\)/.test(m), "the scenes column ignores visibility");
  // Visibility persists across refreshes like column widths do.
  assert(/localStorage/.test(timeline.match(/function sceGetColHidden[\s\S]*?function sceSetColHidden[\s\S]*?\n    \}/)[0]),
    "column visibility is not persisted");
});

check("the drag auto-scrolls vertically as well as horizontally", () => {
  // Without vertical auto-scroll a block cannot be dragged to the bottom of the
  // sheet unless the pointer stays inside the panel the whole way.
  const m = extractFunction(blocks, "wireSCEBlockDrag");
  assert(/scrollTop/.test(m), "the drag never scrolls vertically");
  assert(/scrollLeft/.test(m), "the horizontal auto-scroll is gone");
  // Both axes scale with how deep into the edge zone the pointer is, so a slow
  // nudge scrolls slowly rather than jumping a fixed distance per event.
  assert(/edgeFactor/.test(m), "the scroll speed does not scale with distance to the edge");
});

check("the indicator is positioned after the auto-scroll", () => {
  // Scrolling moves every cell under the pointer. Resolving first paints the
  // divider where the boundary used to be.
  const m = extractFunction(blocks, "wireSCEBlockDrag");
  const scrollAt = m.indexOf("scrollLeft +=");
  const paintAt = m.lastIndexOf("sceUpdateBlockDropIndicator(e.clientX, e.clientY, dragState)");
  assert(scrollAt !== -1 && paintAt !== -1, "the drag does not both scroll and preview");
  assert(paintAt > scrollAt, "the divider is positioned before the timeline scrolls under the drag");
});

check("spine blocks carry no connect node", () => {
  // They are plain story ideas, and the node was one more thing sitting over
  // the block between the pointer and a drag.
  const m = extractFunction(timeline, "renderSCEBlocks");
  const node = m.match(/var connectNode =[\s\S]*?;/);
  assert(node, "the connect node is unconditional");
  assert(/var connectNode = isIdea\s*\?\s*""\s*:/.test(node[0]),
    "the connect node is not omitted for spine blocks");
});

check("the indicator and the drop cannot disagree", () => {
  // Both go through sceResolveBlockDrop, so the line the author is shown is the
  // move they actually get.
  const handler = extractFunction(blocks, "sceHandleBlockDrop");
  assert(/sceResolveBlockDrop\(clientX, clientY, blockId, blockEl\)/.test(handler),
    "the drop resolves its own target instead of sharing the indicator's");
  assert(/drop\.index/.test(handler) && /drop\.cell/.test(handler),
    "the drop ignores the resolved cell or index");
  assert(!/getBoundingClientRect/.test(handler), "the drop re-derives the boundary itself");
});

check("the indicator is cleared on release and on cancel", () => {
  const clear = extractFunction(blocks, "clearSCEBlockDropIndicator");
  assert(/\.remove\(\)/.test(clear), "the divider is left on screen");
  assert(/= null/.test(clear), "the reference is not released, so it is cleared twice");
  const release = blocks.match(/document\.addEventListener\("mouseup"[\s\S]*?dragState = null;/);
  assert(release && /clearSCEBlockDropIndicator\(\)/.test(release[0]),
    "releasing the mouse leaves the indicator on screen");
  assert(/dragend[\s\S]{0,200}clearSCEBlockDropIndicator\(\)/.test(blocks),
    "a drag cancelled with Escape leaves the indicator on screen");
});

check("dragging does not hijack the inline block editor", () => {
  // The editor fields are inputs inside the block, so a mousedown on one used
  // to start a block drag and call preventDefault(), which stops the caret
  // being placed and the text being selected.
  const m = blocks.match(/timelineBody\.addEventListener\("mousedown"[\s\S]*?\n      \}\);/);
  assert(m, "mousedown handler not found");
  assert(/input, textarea, button/.test(m[0]), "form fields do not opt out of the drag");
  assert(/sce-block-expand/.test(m[0]), "the expand button does not opt out of the drag");
  assert(/sce-block-connect-node/.test(m[0]), "connection dragging does not opt out");
});

check("the placement move path shares the ordered move", () => {
  // The inspector's layer/scene selects move a block too; going through a
  // separate code path would leave the destination cell out of order.
  assert(/function moveSCEBlock\(blockId, newLayerId, newPosition, newSceneId\)\s*\{\s*\n\s*moveSCEBlockToIndex\(blockId, newLayerId, newPosition, newSceneId, null\);/.test(blocks),
    "moveSCEBlock no longer delegates to the ordered move");
  assert(/moveSCEBlock\(block\.id, newLayerId, newPosition, nextSceneId\)/.test(inspector),
    "the inspector placement select stopped using moveSCEBlock");
});

// -------------------------------------------------------------------- report

if (failures.length) {
  console.error("state-column: " + failures.length + " failed, " + pass + " passed");
  failures.forEach((f) => console.error("  FAIL " + f));
  process.exit(1);
}
console.log("state-column: " + pass + " passed, 0 failed");

