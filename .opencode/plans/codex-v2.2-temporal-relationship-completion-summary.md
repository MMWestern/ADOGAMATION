# Codex v2.2 — Temporal Relationship Completion: Changes Summary

## Overview

This document outlines every fix, change, and adjustment made during the Codex v2.2 temporal relationship completion pass. The work was driven by the finding that while the temporal **state** system works correctly across books (Strength, Level, Fireball carry forward), the temporal **relationship** system had architectural issues where ended connections appeared as current.

---

## 1. Consumer Audit Results

A complete audit of all `codex_connections` consumers was performed. **33 consumers** were identified across the codebase:

### Classification Summary

| Classification | Count | Description |
|---|---|---|
| **active-at-point** | 5 | Uses `getActiveConnectionsAt` — filters by temporal bounds |
| **history** | 10 | Reads all non-deleted connections — correct for editing/audit |
| **write (temporal)** | 6 | Sends temporal fields on save |
| **write (non-temporal)** | 4 | Legacy write paths, no temporal fields |
| **structural** | 3 | Migrations and audit scripts |

### Critical Finding

The **relationship panel** (`loadAndRenderEntityRelationships`) was a history view masquerading as a current view. It showed ALL connections ever created, including ended ones, with no visual distinction.

---

## 2. Files Changed

| File | Changes |
|---|---|
| `scripts/series-knowledge.html` | Location hierarchy filtering, connection list badges, panel header, parent location selector, parent location save |
| `scripts/codex-v2-dual-write.html` | Dual-write wrapper now forwards all temporal fields |
| `scripts/supabase-codex.html` | Dual-write call site updated to pass context object |
| `Index.html` | Relationship panel header changed to "Relationship History" |
| `Client.html` | Location tree builder filters out ended connections |

---

## 3. Specific Fixes

### 3.1 Relationship Panel Header

**Before:** "Relationships"  
**After:** "Relationship History"

**Why:** The panel shows ALL connections ever recorded (history view), not just those active at the current narrative point. Making this explicit prevents users from assuming ended relationships are current.

**File:** `Index.html:1558`

---

### 3.2 Connection List Temporal Status Badges

**Before:** Connection cards showed only `source → label → target`  
**After:** Each card shows a colored status badge:
- `ENDED` (red) — `context_status === "ended"`
- `PLANNED` (amber) — `context_status === "planned"`
- `TEMPORAL` (purple) — has temporal bounds but no explicit status
- No badge — unbounded connection (always active)

**File:** `scripts/series-knowledge.html:1919-1934` (`renderSkConnectionList`)

---

### 3.3 Location Hierarchy Filtering

**Before:** `buildLocationParentMap` built parent map from ALL `located_in` connections, including ended ones. If a location was re-parented, both old and new parent entries existed, causing non-deterministic behavior.

**After:** Filters out connections where `context_status === "ended"` or `deleted_at` is set.

**Affected functions:**
- `buildLocationParentMap` (`scripts/series-knowledge.html:3977`)
- `buildLocationTreeEntries` (`Client.html:4303`)

---

### 3.4 Parent Location Selector

**Before:** `.find()` returned the first `located_in` connection, which could be a stale/ended one.

**After:** Filters to find only active connections (`!deleted_at && context_status !== "ended"`).

**File:** `scripts/series-knowledge.html:5484-5491`

---

### 3.5 Parent Location Save

**Before:** `saveParentLocationConnection` searched for existing `located_in` connection without filtering by temporal status, potentially finding an ended connection.

**After:** Filters to find only active connections.

**File:** `scripts/series-knowledge.html:2649-2657`

---

### 3.6 Dual-Write Wrapper

**Before:** `codexV2UpdateConnectionContext` accepted individual parameters `(connectionId, bookId, chapterId, status, notes)` and silently dropped `valid_from_sort`, `valid_to_sort`, and `created_source`.

**After:** Accepts a single `contextData` object and forwards all fields:
- `book_id`
- `chapter_id`
- `valid_from_sort`
- `valid_to_sort`
- `context_status`
- `notes`
- `created_source`

**File:** `scripts/codex-v2-dual-write.html:126-141`

---

### 3.7 Dual-Write Call Site

**Before:** Passed individual parameters to the wrapper:
```javascript
codexV2UpdateConnectionContext(savedId, contextUpdates.book_id, contextUpdates.chapter_id, contextUpdates.context_status, contextUpdates.notes);
```

**After:** Passes the full context object:
```javascript
codexV2UpdateConnectionContext(savedId, contextUpdates);
```

**File:** `scripts/supabase-codex.html:389-391`

---

## 4. Architectural Decisions

### 4.1 History vs Active-at-Point

The implementation follows the spec's distinction:

- **History view** (relationship panel) = all connections ever recorded, with temporal status badges
- **Active-at-point view** (`getActiveConnectionsAt`) = only connections active at a specific narrative position

Both coexist. The panel shows everything (useful for editing and history browsing); the temporal resolver returns only active connections (useful for continuity checking).

### 4.2 Location Hierarchy Remains Structural

Per the spec: "It is acceptable for located_in parent hierarchy/breadcrumbs to remain structural for now."

Location connections are created without temporal bounds (`valid_from_sort = NULL`, `valid_to_sort = NULL`), meaning they're always active. The filtering applied is only to exclude explicitly ended connections and deleted connections.

Future political control/occupation should use temporal relationships like `controlled_by`, `occupied_by`, or `governed_by`.

### 4.3 `context_status` is Metadata, Not Temporal Truth

`context_status` is useful for UI display and management, but the temporal bounds (`valid_from_sort`/`valid_to_sort`) are the authoritative answer for "was this active at point X?"

An `ENDED` relationship must still resolve as active when looking backwards to a point inside its interval.

---

## 5. Canonical Boundary Semantics

The temporal boundary rule is:

```
active if:
  (valid_from_sort IS NULL OR valid_from_sort <= target_position)
  AND
  (valid_to_sort IS NULL OR valid_to_sort > target_position)
```

This gives:
- **Start = inclusive** — active FROM the start position
- **End = exclusive** — inactive AT the end position

Example: `valid_from = B1 Ch7 (10007), valid_to = B2 Ch3 (20003)`

| Point | Sort | Active? | Why |
|---|---|---|---|
| B1 Ch6 | 10006 | NO | 10006 < 10007 (before start) |
| B1 Ch7 | 10007 | YES | 10007 >= 10007 (at start, inclusive) |
| B2 Ch2 | 20002 | YES | 20002 < 20003 (before end) |
| B2 Ch3 | 20003 | NO | 20003 >= 20003 (at end, exclusive) |

---

## 6. What Was NOT Changed

- **Location hierarchy temporal bounds** — intentionally structural, not temporal
- **Editing/audit consumers** — correctly need full history access
- **State/progression engine** — completely untouched
- **Cross-book state carry-forward** — confirmed working
- **Backwards narrative reconstruction** — confirmed working
- **Permanent/unbounded relationships** — still work (NULL/NULL = always active)

---

## 7. Remaining Work

### Not Yet Implemented
- Generic non-item temporal relationship test (e.g., Patrick → member of → Test Guild)
- Repeated intervals support (same source/type/target with multiple temporal periods)
- Automated temporal tests for the test suite
- Full live Goblin Sword acceptance matrix

### Known Limitations
- `saveSkConnection` (legacy form) creates NULL/NULL connections — acceptable for structural relationships
- Location hierarchy is non-temporal — acceptable per spec
- No "View active relationships at point" UI — panel shows history view only
- Relationship counts include all history, not just active

### Deferred (Out of Scope)
- Complex inventory UI
- Formula execution
- Separate temporal location hierarchy
- Major UI redesign for relationship panel
