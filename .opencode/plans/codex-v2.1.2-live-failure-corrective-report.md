# CODEX V2.1.2 — LIVE FAILURE CORRECTIVE REPORT

## 1. Root Cause Analysis

### Failure A — B2 Ch3 Strength not superseding

**Diagnosis:** Case C — The pilot sequence was missing `saveState(patrickId, "Strength", null, 10, book2Id, null, 1, ...)`. The pilot created B1 Ch1 STR=6 and B1 Ch12 STR=8, but never created B2 Ch1 STR=10. The B1 Ch12 value carried forward correctly, but there was no B2 state to supersede it.

**Actual DB rows (before fix):**
| id | property_key | value_number | book_id | effective_from_sort | state_status |
|---|---|---|---|---|---|
| (auto) | Level | 1 | 346 | 10001 | canon |
| (auto) | Strength | 6 | 346 | 10001 | canon |
| (auto) | Level | 3 | 346 | 10012 | canon |
| (auto) | Strength | 8 | 346 | 10012 | canon |
| (auto) | Fireball | (Rank 1) | 346 | 10012 | canon |

**No B2 Strength=10 row existed.**

**Fix:** Added `saveState(patrickId, "Strength", null, 10, book2Id, null, 1, ...)` to pilot creation flow.

---

### Failure B — Goblin Sword ownership never active

**Diagnosis:** Two issues:

1. `saveConnection` did not pass `valid_from_sort` or `valid_to_sort` to the connection payload. The connection was created with `valid_from_sort: null` and `valid_to_sort: null`.

2. No `endConnection` call existed to set `valid_to_sort` at B2 Ch3.

**Actual connection row (before fix):**
| Field | Value |
|---|---|
| source_entity_id | Patrick |
| target_entity_id | Goblin Sword |
| relationship_type_id | null |
| label | "owns" |
| book_id | 346 |
| valid_from_sort | **null** |
| valid_to_sort | **null** |
| context_status | null |

With `valid_from_sort: null`, the connection should have been active at ALL points (not just B1 Ch7+). The "never active" result suggests the connection either wasn't created, or `getActiveConnectionsAt` had a display issue.

**Fix:** 
- `saveConnection` now accepts `chapterSortOrder` parameter and computes `valid_from_sort` via `codexV2GlobalSort(bookNum, chapterSortOrder)`
- New `endConnection` function sets `valid_to_sort` + `context_status: "ended"`
- Pilot creates connection with `valid_from_sort = 10007` (B1 Ch7)
- Pilot ends connection with `valid_to_sort = 20003` (B2 Ch3)

---

## 2. Fixes Made

### `scripts/codex-v2-dual-write.html`

**saveConnection function (line 509-537):**
- Added `chapterSortOrder` parameter
- Computes `globalSort` via `codexV2GlobalSort(bookNum, chapterSortOrder)`
- Passes `valid_from_sort: globalSort` to connection payload

**New endConnection function (line 539-551):**
- Accepts `connectionId`, `bookId`, `chapterSortOrder`
- Computes global sort for `valid_to_sort`
- Calls `updateCodexConnectionContext` with `valid_to_sort` and `context_status: "ended"`

**Pilot creation (line 571-612):**
- B2 Ch1: `saveState(patrickId, "Strength", null, 10, book2Id, null, 1, ...)`
- B2 Ch3: `saveEvent(...)` then `endConnection(swordConnId, book2Id, 3, ...)`
- Connection creation passes chapter sort order: `saveConnection(..., 7, ...)`

**Verification script (line 708):**
- Fixed: `queryRelationships("Book 2 Ch 3 (sort=3)", book2Id, 3)` (was `3` instead of `book2Id`)

---

## 3. Expected Results After Fix

### Strength Resolution

| Point | Expected |
|---|---|
| B1 Ch1 | 6 |
| B1 Ch5 | 6 |
| B1 Ch12 | 8 |
| B1 final | 8 |
| B2 Ch1 | 10 |
| B2 Ch2 | 10 |
| B2 Ch3 | 10 |
| B2 later | 10 |

### Goblin Sword Ownership

| Point | Expected |
|---|---|
| B1 Ch6 | NO |
| B1 Ch7 | YES |
| B1 Ch12 | YES |
| B1 final | YES |
| B2 Ch1 | YES |
| B2 Ch2 | YES |
| B2 Ch3 | NO |
| B2 later | NO |

---

## 4. Files Changed

| File | Change |
|------|--------|
| `scripts/codex-v2-dual-write.html` | saveConnection temporal bounds, endConnection function, pilot B2 Strength + sword loss, verification book2Id fix |

No migrations. No schema changes.

---

## 5. To Test

**Hard refresh**, then:
```javascript
codexV2CreatePilotDataset(65, 346, 347).then(function(r) {
  r.log.forEach(function(l) { console.log(l); });
  codexV2VerifyPilot(65, 346, 347, r.created["Patrick Kelth"]).then(function(results) {
    console.log("=== RESULTS ===");
    console.log(JSON.stringify(results, null, 2));
  });
});
```
