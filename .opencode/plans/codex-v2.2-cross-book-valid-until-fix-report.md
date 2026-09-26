# Codex v2.2 — Cross-Book "Valid Until" Relationship Authoring Fix

## Problem

The relationship creation form used a **single shared Book dropdown** for both "Valid From" and "Valid Until" sides. This prevented authors from creating relationships that begin in one book and end in another.

**Example failure:** Creating `Patrick owns Goblin Sword` from B1 Ch7 to B2 Ch3 was impossible through the normal UI because the end chapter selector was always populated from the start book.

## Root Cause

The form had:
```
Book:        [ Book 1 ▼ ]     ← single shared book
Valid From:  [ Chapter 7 ▼ ]
Valid Until: [ Chapter 3 ▼ ]  ← populated from Book 1, not Book 2
```

Both chapter dropdowns were loaded from the same book. Selecting Book 2's Chapter 3 was impossible because the form didn't know Book 2 existed for the "Valid Until" side.

## Fix

Replaced the single shared book dropdown with **two independent book+chapter selectors**:

```
Valid From                 Valid Until
Book:    [ Book 1 ▼ ]     Book:    [ Book 2 ▼ ]
Chapter: [ Chapter 7 ▼ ]  Chapter: [ Chapter 3 ▼ ]
```

Each book dropdown loads its own chapter list independently. Changing "Valid From Book" only reloads "Valid From Chapter" — the "Valid Until" side is unaffected.

## Files Changed

| File | Changes |
|------|---------|
| `Index.html` | Replaced single book dropdown + two chapter dropdowns with two independent book+chapter pairs, plus separate labels |
| `scripts/series-knowledge.html` | Updated create form wiring, save handler, edit form, and validation logic |

## Specific Changes

### 1. HTML Form (`Index.html:1571-1586`)

**Before:** One `codexRelPanelBook` select feeding two chapter selects.

**After:**
- `codexRelPanelFromBook` + `codexRelPanelFromChapter` (Valid From)
- `codexRelPanelToBook` + `codexRelPanelToChapter` (Valid Until)
- Context Status and Notes in a separate row

### 2. Create Form Wiring (`series-knowledge.html:2298-2374`)

**Before:** Single `bookSelect` change handler loaded both chapter dropdowns.

**After:** Two independent book change handlers:
- `fromBookSelect` change → loads `fromChapterSelect` only
- `toBookSelect` change → loads `toChapterSelect` only

Both populate from `codexV2LoadChapters(bookId)` filtered to the selected book.

### 3. Save Handler (`series-knowledge.html:2385-2437`)

**Before:** Used single `bookId` for both sides.

**After:** Reads `fromBookId` and `toBookId` independently, computes global sort for each:
```javascript
var fromBookNum = codexV2GetBookNumber(fromBookId);
var toBookNum = codexV2GetBookNumber(toBookId);
validFromSort = codexV2GlobalSort(fromBookNum, fromChapter.sort_order);
validToSort = codexV2GlobalSort(toBookNum, toChapter.sort_order);
```

### 4. Validation (`series-knowledge.html:2421-2424`)

Added temporal bounds validation:
```javascript
if (validFromSort != null && validToSort != null && validToSort <= validFromSort) {
  alert("Valid Until must be later than Valid From.");
  return;
}
```

### 5. Edit Form (`series-knowledge.html:2501-2632`)

**Before:** Single `codexRelEditBook` with both chapter dropdowns.

**After:** Two independent book selectors (`codexRelEditFromBook`, `codexRelEditToBook`) with their own chapter dropdowns. Pre-fills by looking up which book each `valid_from_sort`/`valid_to_sort` belongs to.

### 6. Edit Save Handler (`series-knowledge.html:2639-2668`)

Updated to compute global sort independently for each side using `fromBookId`/`toBookId`.

## Boundary Semantics (Unchanged)

```
active if:
  (valid_from_sort IS NULL OR valid_from_sort <= target_position)
  AND
  (valid_to_sort IS NULL OR valid_to_sort > target_position)
```

- Start = inclusive
- End = exclusive

For `valid_from = 10007, valid_to = 20003`:
- B1 Ch6 (10006) → NO
- B1 Ch7 (10007) → YES
- B2 Ch2 (20002) → YES
- B2 Ch3 (20003) → NO

## Unbounded Relationships Preserved

- **Valid From empty:** `valid_from_sort = NULL` → always active from beginning
- **Valid Until empty:** `valid_to_sort = NULL` → never ends (open-ended)
- **Both empty:** `NULL/NULL` → unbounded permanent relationship

## Cross-Book Validation

Each side validates its chapter belongs to its own book:
- Valid From chapter must belong to Valid From book
- Valid Until chapter must belong to Valid Until book

Changing either book clears/revalidates the chapter dropdown.

## What Was NOT Changed

- `getActiveConnectionsAt` boundary semantics
- State/progression engine
- Cross-book state carry-forward
- Relationship History panel behavior
- Location hierarchy
- Global narrative position formula
- Relationship type architecture
