# Codex v2.2 — Temporal Relationship Model: Findings & Changes

## What the Audit Found

The Codex v2.1.2 live testing revealed that the **temporal state system works correctly** (Strength, Level, Fireball carry forward across books), but the **temporal relationship system has a fundamental architectural issue**: the relationship panel shows ALL connections ever created, not just those active at the current narrative point.

This means if Patrick acquires a sword in B1 Ch7 and loses it in B2 Ch3, the relationship panel would show "owns sword" at every narrative point because it reads from a non-temporal cache.

---

## Root Causes Identified

### 1. Relationship Panel is a History View, Not Active-at-Point

The function `loadAndRenderEntityRelationships` (the main relationship panel in the right column) reads from `skCache.connections[seriesId]`, which is populated by `listCodexConnections` — a bulk loader that returns ALL non-deleted connections with no temporal filtering. Every connection ever created appears as "currently true."

### 2. `getActiveConnectionsAt` exists but is never used by the main UI

The temporal resolver function `getActiveConnectionsAt` correctly filters by `valid_from_sort` and `valid_to_sort`, but it's only used by the pilot verification script and admin tools — never by the main relationship panel.

### 3. Dual-write wrapper was silently dropping temporal fields

The `codexV2UpdateConnectionContext` wrapper function only forwarded `book_id`, `chapter_id`, `context_status`, and `notes` to the connection update. It silently dropped `valid_from_sort`, `valid_to_sort`, and `created_source` even though the caller had them in a `contextUpdates` object.

### 4. Boundary semantics were correct but underdocumented

The temporal resolver uses:
- `valid_from_sort <= target_position` (inclusive start)
- `valid_to_sort > target_position` (exclusive end, via `valid_to_sort <= target → exclude`)

This is correct: a connection with `valid_to_sort = 20003` is active at 20002 but not at 20003.

---

## What Was Changed

### 1. Relationship panel now shows temporal status badges

Every connection in the right-column panel now shows a colored badge indicating its temporal status:

- `ENDED` (red) — connection has `context_status === "ended"`
- `PLANNED` (amber) — connection has `context_status === "planned"`
- `TEMPORAL` (purple) — connection has temporal bounds but no explicit status
- No badge — unbounded connection (always active)

This preserves the history view (all connections visible) while making temporal state clear.

### 2. Dual-write wrapper forwards all temporal fields

`codexV2UpdateConnectionContext` now accepts a context object and forwards all fields:

- `book_id`
- `chapter_id`
- `valid_from_sort`
- `valid_to_sort`
- `context_status`
- `notes`
- `created_source`

### 3. Call site updated

The `saveCodexConnection` dual-write call now passes the full `contextUpdates` object instead of individual parameters.

---

## Architecture Decision

The implementation follows the spec's recommended approach:

```
HISTORY VIEW (loadAndRenderEntityRelationships)
= All connections ever recorded, with temporal status badges
= Answers: "What relationships have ever existed for this entity?"

ACTIVE-AT-POINT VIEW (getActiveConnectionsAt)
= Only connections active at a specific narrative position
= Answers: "What relationships are true at B2 Ch1?"
```

Both views coexist. The panel shows everything (useful for editing and history browsing); the temporal resolver returns only active connections (useful for continuity checking and progression sheets).

---

## Connection Consumer Audit Summary

The audit identified 33 consumers of `codex_connections`:

| Classification | Count | Description |
|---|---|---|
| **active-at-point** | 5 | Temporal-aware — uses `getActiveConnectionsAt` |
| **latest/current** | 14 | Non-temporal — reads from bulk cache |
| **write (temporal)** | 6 | Sends temporal fields on save |
| **write (non-temporal)** | 4 | Legacy write paths, no temporal fields |
| **structural** | 3 | Migrations and audit scripts |

### Key Consumers

| Consumer | Classification | Notes |
|---|---|---|
| `loadAndRenderEntityRelationships` | History view | Shows all connections with temporal badges |
| `getActiveConnectionsAt` | Active-at-point | Filters by `valid_from_sort`/`valid_to_sort` |
| `listCodexConnections` | Bulk loader | Returns all non-deleted connections |
| `saveEntityConnection` | Temporal write | Sends `valid_from_sort`, `valid_to_sort` |
| `saveSkConnection` | Non-temporal write | Legacy form, no temporal fields |
| `buildLocationParentMap` | Non-temporal | Acceptable for permanent relationships |

---

## What Remains

### Location hierarchy is non-temporal

The `located_in` relationship system (parent locations, breadcrumbs, location tree) remains non-temporal. This is acceptable for permanent geographic relationships but would need updating if locations change parents across books.

### `saveSkConnection` legacy form

The legacy connection creation form (old UI) does not send temporal fields. Connections created through this path will have `valid_from_sort = NULL` and `valid_to_sort = NULL`, making them appear "always active" in temporal queries.

### Relationship history UI

The current panel shows all connections with status badges. A future enhancement could split into:
- Active at selected point (filtered view)
- Relationship History (full view with temporal intervals)

This was not implemented to avoid a broader UI redesign.

---

## Boundary Semantics (Canonical Rule)

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

Example: `valid_from = B1 Ch7, valid_to = B2 Ch3`

| Point | Active? | Why |
|---|---|---|
| B1 Ch6 | NO | 10006 < 10007 (before start) |
| B1 Ch7 | YES | 10007 >= 10007 (at start, inclusive) |
| B2 Ch2 | YES | 20002 < 20003 (before end) |
| B2 Ch3 | NO | 20003 >= 20003 (at end, exclusive) |

---

## `context_status` Role

`context_status` is **metadata**, not temporal truth. The temporal bounds (`valid_from_sort`/`valid_to_sort`) are the authoritative answer for "was this active at point X?"

- A relationship marked `ended` may still have been active in earlier chapters
- A query for B1 Ch12 must not discard the sword merely because its `context_status` is `ended`
- `context_status` is useful for UI display and management, not for temporal queries
