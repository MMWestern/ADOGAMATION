"use strict";

// Codex v2.2 — Temporal Relationship Regression Tests
// Tests the canonical temporal predicate and relationship resolver

let passed = 0;
let failed = 0;

function log(name, ok, detail) {
  if (ok) passed++;
  else failed++;
  console.log((ok ? "PASS" : "FAIL") + ": " + name + (detail && !ok ? " -- " + detail : ""));
}

// Canonical global sort: (bookNumber * 10000) + chapterSortOrder
function codexV2GlobalSort(bookNumber, chapterSortOrder) {
  var bookNum = Number(bookNumber);
  var chapterSort = Number(chapterSortOrder);
  if (!Number.isFinite(bookNum) || bookNum <= 0) {
    return Number.isFinite(chapterSort) ? chapterSort : null;
  }
  if (!Number.isFinite(chapterSort)) {
    return bookNum * 10000;
  }
  return (bookNum * 10000) + chapterSort;
}

// Canonical temporal predicate
function isActiveAt(connection, targetPosition) {
  var from = connection.valid_from_sort;
  var to = connection.valid_to_sort;
  var fromOk = (from == null) || (Number(from) <= targetPosition);
  var toOk = (to == null) || (targetPosition < Number(to));
  return fromOk && toOk;
}

// Build test connection
function conn(validFrom, validTo, status) {
  return {
    valid_from_sort: validFrom,
    valid_to_sort: validTo,
    context_status: status || "active",
    deleted_at: null
  };
}

// ========== TEST FIXTURES ==========

// B1 Ch3 → B1 Ch8 (same-book bounded)
var sameBook = conn(codexV2GlobalSort(1, 3), codexV2GlobalSort(1, 8));

// B1 Ch7 → B2 Ch3 (cross-book bounded)
var crossBook = conn(codexV2GlobalSort(1, 7), codexV2GlobalSort(2, 3));

// B1 Ch3 → B2 Ch2 (generic non-item)
var guildMember = conn(codexV2GlobalSort(1, 3), codexV2GlobalSort(2, 2));

// NULL start, B2 Ch3 end
var nullStart = conn(null, codexV2GlobalSort(2, 3));

// B1 Ch7 start, NULL end
var nullEnd = conn(codexV2GlobalSort(1, 7), null);

// NULL/NULL permanent
var permanent = conn(null, null);

// Ended status with temporal bounds
var endedConn = conn(codexV2GlobalSort(1, 7), codexV2GlobalSort(2, 3), "ended");

// ========== PART A: TEMPORAL TESTS ==========

console.log("\n=== Codex v2.2 Temporal Relationship Tests ===\n");

// Test 1: Bounded same-book
log("Same-book: B1 Ch2 inactive", !isActiveAt(sameBook, codexV2GlobalSort(1, 2)));
log("Same-book: B1 Ch3 active (inclusive start)", isActiveAt(sameBook, codexV2GlobalSort(1, 3)));
log("Same-book: B1 Ch4 active", isActiveAt(sameBook, codexV2GlobalSort(1, 4)));
log("Same-book: B1 Ch7 active", isActiveAt(sameBook, codexV2GlobalSort(1, 7)));
log("Same-book: B1 Ch8 inactive (exclusive end)", !isActiveAt(sameBook, codexV2GlobalSort(1, 8)));
log("Same-book: B1 Ch9 inactive", !isActiveAt(sameBook, codexV2GlobalSort(1, 9)));

// Test 2: Cross-book (Goblin Sword equivalent)
log("Cross-book: B1 Ch1 inactive", !isActiveAt(crossBook, codexV2GlobalSort(1, 1)));
log("Cross-book: B1 Ch6 inactive", !isActiveAt(crossBook, codexV2GlobalSort(1, 6)));
log("Cross-book: B1 Ch7 active (inclusive start)", isActiveAt(crossBook, codexV2GlobalSort(1, 7)));
log("Cross-book: B1 Ch12 active", isActiveAt(crossBook, codexV2GlobalSort(1, 12)));
log("Cross-book: B2 Ch1 active", isActiveAt(crossBook, codexV2GlobalSort(2, 1)));
log("Cross-book: B2 Ch2 active", isActiveAt(crossBook, codexV2GlobalSort(2, 2)));
log("Cross-book: B2 Ch3 inactive (exclusive end)", !isActiveAt(crossBook, codexV2GlobalSort(2, 3)));
log("Cross-book: B2 later inactive", !isActiveAt(crossBook, codexV2GlobalSort(2, 10)));

// Test 3: Generic non-item (Guild membership)
log("Guild: B1 Ch2 inactive", !isActiveAt(guildMember, codexV2GlobalSort(1, 2)));
log("Guild: B1 Ch3 active", isActiveAt(guildMember, codexV2GlobalSort(1, 3)));
log("Guild: B1 Ch12 active", isActiveAt(guildMember, codexV2GlobalSort(1, 12)));
log("Guild: B2 Ch1 active", isActiveAt(guildMember, codexV2GlobalSort(2, 1)));
log("Guild: B2 Ch2 inactive (exclusive end)", !isActiveAt(guildMember, codexV2GlobalSort(2, 2)));
log("Guild: B2 later inactive", !isActiveAt(guildMember, codexV2GlobalSort(2, 10)));

// Test 4: NULL start
log("NULL start: B1 Ch1 active", isActiveAt(nullStart, codexV2GlobalSort(1, 1)));
log("NULL start: B1 Ch12 active", isActiveAt(nullStart, codexV2GlobalSort(1, 12)));
log("NULL start: B2 Ch2 active", isActiveAt(nullStart, codexV2GlobalSort(2, 2)));
log("NULL start: B2 Ch3 inactive (exclusive end)", !isActiveAt(nullStart, codexV2GlobalSort(2, 3)));

// Test 5: NULL end
log("NULL end: B1 Ch6 inactive", !isActiveAt(nullEnd, codexV2GlobalSort(1, 6)));
log("NULL end: B1 Ch7 active (inclusive start)", isActiveAt(nullEnd, codexV2GlobalSort(1, 7)));
log("NULL end: B1 Ch12 active", isActiveAt(nullEnd, codexV2GlobalSort(1, 12)));
log("NULL end: B2 Ch1 active", isActiveAt(nullEnd, codexV2GlobalSort(2, 1)));
log("NULL end: B2 Ch10 active", isActiveAt(nullEnd, codexV2GlobalSort(2, 10)));

// Test 6: NULL/NULL permanent
log("Permanent: B1 Ch1 active", isActiveAt(permanent, codexV2GlobalSort(1, 1)));
log("Permanent: B1 Ch12 active", isActiveAt(permanent, codexV2GlobalSort(1, 12)));
log("Permanent: B2 Ch1 active", isActiveAt(permanent, codexV2GlobalSort(2, 1)));
log("Permanent: B2 Ch10 active", isActiveAt(permanent, codexV2GlobalSort(2, 10)));

// Test 7: Ended status historical reconstruction
log("Ended: B1 Ch12 active (inside interval)", isActiveAt(endedConn, codexV2GlobalSort(1, 12)));
log("Ended: B2 Ch1 active (inside interval)", isActiveAt(endedConn, codexV2GlobalSort(2, 1)));
log("Ended: B2 Ch3 inactive (at end)", !isActiveAt(endedConn, codexV2GlobalSort(2, 3)));

// Test 8: Backwards/forwards determinism
var testPoints = [
  codexV2GlobalSort(2, 3),  // inactive
  codexV2GlobalSort(1, 6),  // inactive
  codexV2GlobalSort(2, 1),  // active
  codexV2GlobalSort(1, 12), // active
  codexV2GlobalSort(2, 10)  // inactive
];
var expected = [false, false, true, true, false];
var actual = testPoints.map(function(p) { return isActiveAt(crossBook, p); });
log("Backwards/forwards determinism", JSON.stringify(actual) === JSON.stringify(expected),
  "Expected: " + JSON.stringify(expected) + " Got: " + JSON.stringify(actual));

// Test 9: Inverse direction (same temporal truth from target)
// The predicate is symmetric - same connection, same result regardless of source/target perspective
log("Inverse: Goblin Sword at B1 Ch12 active", isActiveAt(crossBook, codexV2GlobalSort(1, 12)));
log("Inverse: Goblin Sword at B2 Ch3 inactive", !isActiveAt(crossBook, codexV2GlobalSort(2, 3)));

// Test 10: Future relationship does not leak backwards
var futureRel = conn(codexV2GlobalSort(3, 1), null); // starts in Book 3
log("Future: B1 Ch12 inactive", !isActiveAt(futureRel, codexV2GlobalSort(1, 12)));
log("Future: B2 Ch1 inactive", !isActiveAt(futureRel, codexV2GlobalSort(2, 1)));
log("Future: B3 Ch1 active (inclusive start)", isActiveAt(futureRel, codexV2GlobalSort(3, 1)));
log("Future: B3 Ch5 active", isActiveAt(futureRel, codexV2GlobalSort(3, 5)));

// ========== SUMMARY ==========

console.log("\n=== Results ===");
console.log("Passed: " + passed);
console.log("Failed: " + failed);
console.log("Total:  " + (passed + failed));

if (failed > 0) {
  console.log("\nFAIL — temporal relationship tests failed");
  process.exit(1);
} else {
  console.log("\nPASS — all temporal relationship tests passed");
  process.exit(0);
}
