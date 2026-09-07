/**
 * Codex v2.3 State Architecture Tests
 *
 * Tests the state resolution logic, canonical property identity,
 * entry_order handling, template exclusion, and the three state views.
 *
 * Run: node tests/state-architecture.test.js
 */

// Minimal test harness
let passed = 0;
let failed = 0;
function assert(condition, label) {
  if (condition) {
    console.log("PASS:", label);
    passed++;
  } else {
    console.error("FAIL:", label);
    failed++;
  }
}

// Import helpers (extract from the source files)
// Since these are browser functions, we need to define minimal versions for testing

/**
 * Canonical property identity helper
 * Uses property_entity_id when available, falls back to normalized property_key
 */
function codexV2GetPropertyIdentity(row) {
  if (row && row.property_entity_id) {
    return "entity:" + String(row.property_entity_id);
  }
  return "key:" + String((row && row.property_key) || "").trim().toLowerCase();
}

/**
 * Shared state resolver
 * Modes: 'history', 'stateAt', 'progression'
 */
function codexV2ResolveState(rows, options) {
  var mode = (options && options.mode) || 'stateAt';
  var safeRows = Array.isArray(rows) ? rows : [];

  // Exclude template records from narrative queries
  var narrative = safeRows.filter(function (r) {
    return r.state_status !== 'template';
  });

  if (mode === 'history') {
    return narrative.sort(function (a, b) {
      var sortA = Number(a.effective_from_sort || 0);
      var sortB = Number(b.effective_from_sort || 0);
      if (sortA !== sortB) return sortA - sortB;
      var orderA = Number(a.entry_order || 1);
      var orderB = Number(b.entry_order || 1);
      if (orderA !== orderB) return orderA - orderB;
      return String(a.property_key || "").localeCompare(String(b.property_key || ""));
    });
  }

  // stateAt / progression: deduplicate by canonical property identity
  var groups = {};
  narrative.forEach(function (row) {
    var identity = codexV2GetPropertyIdentity(row);
    if (!groups[identity]) groups[identity] = [];
    groups[identity].push(row);
  });

  var resolved = [];
  Object.keys(groups).forEach(function (identity) {
    var group = groups[identity];
    group.sort(function (a, b) {
      var sortA = Number(a.effective_from_sort || 0);
      var sortB = Number(b.effective_from_sort || 0);
      if (sortA !== sortB) return sortB - sortA;
      var orderA = Number(a.entry_order || 1);
      var orderB = Number(b.entry_order || 1);
      return orderB - orderA;
    });
    resolved.push(group[0]);
  });

  resolved.sort(function (a, b) {
    return String(a.property_key || "").localeCompare(String(b.property_key || ""));
  });

  return resolved;
}

// ============================================================
// TEST SUITE
// ============================================================

console.log("=== Codex v2.3 State Architecture Tests ===\n");

// --- Canonical Property Identity ---

console.log("--- Canonical Property Identity ---");

// Same property_entity_id + different property_key = one resolved property
var row1 = { property_entity_id: "str-uuid", property_key: "strength", value_number: 10 };
var row2 = { property_entity_id: "str-uuid", property_key: "Strength", value_number: 15 };
assert(
  codexV2GetPropertyIdentity(row1) === codexV2GetPropertyIdentity(row2),
  "Same property_entity_id + different property_key = one identity"
);

// Different property_entity_id + same display name = different properties
var row3 = { property_entity_id: "str-uuid-1", property_key: "Strength", value_number: 10 };
var row4 = { property_entity_id: "str-uuid-2", property_key: "Strength", value_number: 15 };
assert(
  codexV2GetPropertyIdentity(row3) !== codexV2GetPropertyIdentity(row4),
  "Different property_entity_id + same display name = different identity"
);

// No property_entity_id = fallback to normalized property_key
var row5 = { property_entity_id: null, property_key: "Mood", value_text: "Happy" };
var row6 = { property_entity_id: null, property_key: "mood", value_text: "Sad" };
assert(
  codexV2GetPropertyIdentity(row5) === codexV2GetPropertyIdentity(row6),
  "No property_entity_id + same normalized key = one identity"
);

// No property_entity_id + different key = different properties
var row7 = { property_entity_id: null, property_key: "Mood", value_text: "Happy" };
var row8 = { property_entity_id: null, property_key: "Health", value_number: 100 };
assert(
  codexV2GetPropertyIdentity(row7) !== codexV2GetPropertyIdentity(row8),
  "No property_entity_id + different key = different identity"
);

// --- State Resolution: State At ---

console.log("\n--- State Resolution: State At ---");

// Same property across multiple chapters - latest wins
var states1 = [
  { property_key: "Strength", value_number: 10, effective_from_sort: 10001, entry_order: 1 },
  { property_key: "Strength", value_number: 15, effective_from_sort: 10007, entry_order: 1 },
  { property_key: "Strength", value_number: 20, effective_from_sort: 10012, entry_order: 1 }
];
var resolved1 = codexV2ResolveState(states1, { mode: 'stateAt' });
assert(resolved1.length === 1, "State At: one property = one resolved entry");
assert(resolved1[0].value_number === 20, "State At: latest value wins");

// Multiple same-property entries in same chapter - highest entry_order wins
var states2 = [
  { property_key: "Health", value_number: 100, effective_from_sort: 10007, entry_order: 1 },
  { property_key: "Health", value_number: 42, effective_from_sort: 10007, entry_order: 2 },
  { property_key: "Health", value_number: 18, effective_from_sort: 10007, entry_order: 3 },
  { property_key: "Health", value_number: 75, effective_from_sort: 10007, entry_order: 4 }
];
var resolved2 = codexV2ResolveState(states2, { mode: 'stateAt' });
assert(resolved2.length === 1, "State At: same-chapter entries = one resolved");
assert(resolved2[0].value_number === 75, "State At: highest entry_order wins");
assert(resolved2[0].entry_order === 4, "State At: entry_order preserved");

// Cross-book carry-forward
var states3 = [
  { property_key: "Strength", value_number: 20, effective_from_sort: 10012, entry_order: 1 },
  { property_key: "Level", value_number: 3, effective_from_sort: 10012, entry_order: 1 }
];
var resolved3 = codexV2ResolveState(states3, { mode: 'stateAt' });
assert(resolved3.length === 2, "Cross-book: both properties present");
assert(resolved3.find(function (r) { return r.property_key === "Strength"; }).value_number === 20, "Cross-book: Strength carried forward");

// Future state does not leak backwards
var states4 = [
  { property_key: "Strength", value_number: 20, effective_from_sort: 10012, entry_order: 1 },
  { property_key: "Strength", value_number: 30, effective_from_sort: 20003, entry_order: 1 }
];
// Query at B1 Ch12 should return 20, not 30
var atB1Ch12 = states4.filter(function (s) { return s.effective_from_sort <= 10012; });
var resolved4 = codexV2ResolveState(atB1Ch12, { mode: 'stateAt' });
assert(resolved4[0].value_number === 20, "Future no-leak: B1 Ch12 sees Strength 20");

// Query at B2 Ch3 should return 30
var atB2Ch3 = states4.filter(function (s) { return s.effective_from_sort <= 20003; });
var resolved5 = codexV2ResolveState(atB2Ch3, { mode: 'stateAt' });
assert(resolved5[0].value_number === 30, "Future no-leak: B2 Ch3 sees Strength 30");

// --- State Resolution: History ---

console.log("\n--- State Resolution: History ---");

// History retains all entries
var states5 = [
  { property_key: "Strength", value_number: 10, effective_from_sort: 10001, entry_order: 1 },
  { property_key: "Strength", value_number: 15, effective_from_sort: 10007, entry_order: 1 },
  { property_key: "Strength", value_number: 20, effective_from_sort: 10012, entry_order: 1 }
];
var history = codexV2ResolveState(states5, { mode: 'history' });
assert(history.length === 3, "History: all entries retained");
assert(history[0].value_number === 10, "History: first entry preserved");
assert(history[2].value_number === 20, "History: last entry preserved");

// History retains same-chapter entries
var states6 = [
  { property_key: "Health", value_number: 100, effective_from_sort: 10007, entry_order: 1 },
  { property_key: "Health", value_number: 42, effective_from_sort: 10007, entry_order: 2 },
  { property_key: "Health", value_number: 18, effective_from_sort: 10007, entry_order: 3 }
];
var history2 = codexV2ResolveState(states6, { mode: 'history' });
assert(history2.length === 3, "History: same-chapter entries all retained");
assert(history2[0].value_number === 100, "History: entry_order 1 first");
assert(history2[2].value_number === 18, "History: entry_order 3 last");

// --- Template Exclusion ---

console.log("\n--- Template Exclusion ---");

// Template records excluded from narrative State At
var states7 = [
  { property_key: "Strength", value_number: 5, effective_from_sort: null, entry_order: 1, state_status: "template" },
  { property_key: "Strength", value_number: 20, effective_from_sort: 10001, entry_order: 1, state_status: "canon" }
];
var resolved6 = codexV2ResolveState(states7, { mode: 'stateAt' });
assert(resolved6.length === 1, "Template exclusion: only narrative state in State At");
assert(resolved6[0].state_status === "canon", "Template exclusion: canon record returned");
assert(resolved6[0].value_number === 20, "Template exclusion: canon value used");

// Template records excluded from Progression
var resolved7 = codexV2ResolveState(states7, { mode: 'progression' });
assert(resolved7.length === 1, "Template exclusion: only narrative state in Progression");

// Template records excluded from History
var history3 = codexV2ResolveState(states7, { mode: 'history' });
assert(history3.length === 1, "Template exclusion: only narrative state in History");

// --- Entry Order ---

console.log("\n--- Entry Order ---");

// Entry order determines resolution within same chapter
var states8 = [
  { property_key: "Mana", value_number: 50, effective_from_sort: 10007, entry_order: 1 },
  { property_key: "Mana", value_number: 40, effective_from_sort: 10007, entry_order: 2 },
  { property_key: "Mana", value_number: 30, effective_from_sort: 10007, entry_order: 3 }
];
var resolved8 = codexV2ResolveState(states8, { mode: 'stateAt' });
assert(resolved8[0].entry_order === 3, "Entry order: highest entry_order wins");
assert(resolved8[0].value_number === 30, "Entry order: correct value selected");

// --- Two Characters Share Definition ---

console.log("\n--- Two Characters Share Definition ---");

// Patrick and Alice share Strength definition but have independent state
var patrickStates = [
  { property_entity_id: "str-uuid", property_key: "Strength", value_number: 20, effective_from_sort: 10001, entry_order: 1 }
];
var aliceStates = [
  { property_entity_id: "str-uuid", property_key: "Strength", value_number: 15, effective_from_sort: 10001, entry_order: 1 }
];
var patrickResolved = codexV2ResolveState(patrickStates, { mode: 'stateAt' });
var aliceResolved = codexV2ResolveState(aliceStates, { mode: 'stateAt' });
assert(patrickResolved[0].value_number === 20, "Shared definition: Patrick has Strength 20");
assert(aliceResolved[0].value_number === 15, "Shared definition: Alice has Strength 15");
assert(
  codexV2GetPropertyIdentity(patrickResolved[0]) === codexV2GetPropertyIdentity(aliceResolved[0]),
  "Shared definition: same canonical identity"
);

// --- NULL effective_from_sort ---

console.log("\n--- NULL effective_from_sort ---");

// NULL effective_from_sort records are included (they may be legacy data)
var states9 = [
  { property_key: "Strength", value_number: 10, effective_from_sort: null, entry_order: 1, state_status: "canon" },
  { property_key: "Strength", value_number: 20, effective_from_sort: 10001, entry_order: 1, state_status: "canon" }
];
var resolved9 = codexV2ResolveState(states9, { mode: 'stateAt' });
assert(resolved9.length === 1, "NULL effective_from_sort: one resolved entry");
// The record with effective_from_sort: 10001 should win over NULL (treated as 0)
assert(resolved9[0].effective_from_sort === 10001, "NULL effective_from_sort: positioned record wins");

// --- Backwards/Forwards Navigation ---

console.log("\n--- Backwards/Forwards Navigation ---");

var allStates = [
  { property_key: "Strength", value_number: 10, effective_from_sort: 10001, entry_order: 1 },
  { property_key: "Strength", value_number: 15, effective_from_sort: 10001, entry_order: 2 },
  { property_key: "Strength", value_number: 20, effective_from_sort: 10001, entry_order: 3 },
  { property_key: "Strength", value_number: 25, effective_from_sort: 10002, entry_order: 1 },
  { property_key: "Strength", value_number: 30, effective_from_sort: 20003, entry_order: 1 }
];

// Navigate: B2 Ch3 -> B1 Ch1 -> B2 Ch1 -> B1 Ch2 -> B2 Ch3
function getStateAt(states, sort) {
  var filtered = states.filter(function (s) { return s.effective_from_sort <= sort; });
  return codexV2ResolveState(filtered, { mode: 'stateAt' })[0];
}

var at_B2_Ch3 = getStateAt(allStates, 20003);
var at_B1_Ch1 = getStateAt(allStates, 10001);
var at_B2_Ch1 = getStateAt(allStates, 20001);
var at_B1_Ch2 = getStateAt(allStates, 10002);
var back_B2_Ch3 = getStateAt(allStates, 20003);

assert(at_B2_Ch3.value_number === 30, "Nav: B2 Ch3 = 30");
assert(at_B1_Ch1.value_number === 20, "Nav: B1 Ch1 = 20 (highest entry_order)");
assert(at_B2_Ch1.value_number === 25, "Nav: B2 Ch1 = 25 (carried from B1 Ch2)");
assert(at_B1_Ch2.value_number === 25, "Nav: B1 Ch2 = 25");
assert(back_B2_Ch3.value_number === 30, "Nav: back to B2 Ch3 = 30 (no stale cache)");

// --- Results ---

console.log("\n=== Results ===");
console.log("Passed:", passed);
console.log("Failed:", failed);
console.log("Total:", passed + failed);

if (failed > 0) {
  console.error("\nFAIL — " + failed + " test(s) failed");
  process.exit(1);
} else {
  console.log("\nPASS — all state architecture tests passed");
  process.exit(0);
}
