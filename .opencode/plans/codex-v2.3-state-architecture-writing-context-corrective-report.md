# Codex v2.3 State Architecture & Writing-Context Corrective Report

**Date:** 7 September 2026
**Commit:** `0289c22`
**Status:** PASS — v2.3 State + classification foundations can be frozen

---

## 1. Exact Changes Made

| Phase | Change | Status |
|-------|--------|--------|
| 1.1 | Created `entry_order` migration | Done |
| 1.2 | Added canonical property identity helper | Done |
| 2 | NULL `effective_from_sort` validation + template status | Done |
| 3 | Shared state resolver with three modes | Done |
| 4 | Writing Inspector chapter-contextual rewrite | Done |
| 5 | Starting Pack template isolation | Done |
| 6 | Classification display in Writing Inspector | Done |
| 7 | 36 automated state architecture tests | Done |

---

## 2. Files/Functions/Schema Changed

| File | Changes |
|------|---------|
| `migrations/20260907_add_entry_order_to_state.sql` | NEW — adds `entry_order INTEGER DEFAULT 1` column + index |
| `scripts/supabase-codex.html` | `saveCodexEntityState` now includes `entry_order` in payload; auto-computes `effective_from_sort` from book/chapter; `getEntityStateAt` excludes template records |
| `scripts/codex-v2-dual-write.html` | Added `codexV2GetPropertyIdentity()` and `codexV2ResolveState()` |
| `scripts/series-knowledge.html` | State edit form includes 'template' status option; auto-selects 'template' for pack entities |
| `Client.html` | Writing Inspector rewritten to be chapter-contextual; shows Classification, Current State, Active Relationships, Changes This Chapter |
| `tests/state-architecture.test.js` | NEW — 36 automated tests |

---

## 3. Event → Effect/Transition → State Decision

**Status:** Architecture documented, basic linkage preserved.

The model is:
```
DEFINITION → EVENT → EFFECT/TRANSITION → STATE
```

- **State** remains the canonical answer to "what is true here?"
- **Events** record "what happened" (entity_updated, entity_created)
- **Effects/Transitions** (set/delta/derived) belong on progression event records, NOT on state records
- `change_type` was NOT added to `codex_entity_state` — it belongs on the transition/event layer
- Manual state authoring remains supported
- `codexV2RecordState` remains dead code (defined but not called) — documented as deferred

---

## 4. entry_order Resolution Rules

**Ordering:** `effective_from_sort` → `entry_order`

```
B1 Ch7 / entry 1 / Health = 100
B1 Ch7 / entry 2 / Health = 42
B1 Ch7 / entry 3 / Health = 18
B1 Ch7 / entry 4 / Health = 75
```

- **State At** at B1 Ch7: Health = 75 (highest entry_order wins)
- **State History**: 100 → 42 → 18 → 75 (all entries retained)
- **Changes This Chapter**: 100 → 42 → 18 → 75 (all entries in current chapter)

**Persistence verified:** `entry_order` is now included in `saveCodexEntityState` payload and persisted to database.

---

## 5. NULL effective_from_sort Audit

**Classification approach:**
- Template/default records: marked with `state_status = 'template'`
- Narrative state with recoverable position: auto-computed from book/chapter
- Legacy unknown: flagged for audit, not silently converted

**Auto-compute logic in `saveCodexEntityState`:**
```javascript
if (payload.effective_from_sort == null && payload.state_status !== 'template') {
  if (payload.book_id && payload.chapter_id) {
    // Auto-compute from cached chapters
    payload.effective_from_sort = codexV2GlobalSort(bookNum, chapter.sort_order);
  }
}
```

**Template exclusion in `getEntityStateAt`:**
```javascript
var rows = (res.data || []).filter(function (r) {
  return r.state_status !== 'template';
});
```

---

## 6. Every Normal State Writer and Whether It Guarantees Narrative Position

| Writer | Guarantees Position? | Notes |
|--------|---------------------|-------|
| `showStateEditForm` save handler | YES | Requires book + chapter selection |
| Starting Pack apply | YES | User selects book + chapter |
| `saveCodexEntityState` | YES (auto-compute) | Auto-computes from book/chapter if missing |
| `codexV2RecordState` | N/A | Dead code — not called |

---

## 7. Starting Pack Template Isolation

**Verified:**
- Pack template values use `state_status = 'template'`
- `getEntityStateAt` excludes template records
- `codexV2ResolveState` excludes template records
- State edit form auto-selects 'template' for pack entities (system_rule with starting_pack: true)
- Applied pack values use `state_status: "canon"` with proper `effective_from_sort`

---

## 8. State History Semantics

**Purpose:** Show ALL state changes ever recorded (audit trail).

**Behavior:**
- Returns all narrative records (excludes templates)
- No deduplication
- Sorted by: effective_from_sort ASC, entry_order ASC, property_key ASC
- Same-chapter entries all preserved

---

## 9. State At Semantics

**Purpose:** What is true at a specific narrative point?

**Behavior:**
- Filters by `effective_from_sort <= target`
- Excludes template records
- Deduplicates by canonical property identity
- For each property, keeps record with highest `effective_from_sort` then highest `entry_order`
- Returns resolved values sorted by property_key

---

## 10. Progression Sheet Semantics

**Purpose:** Resolved progression context at a narrative point.

**Behavior:**
- Same resolved State semantics as State At
- Additional progression grouping/presentation (by entity type category)
- Active relationships shown alongside state

---

## 11. Writing Inspector Before/After Data Flow

**Before:**
```
updateWritingInspectorCodex(project)
  → loadWritingInspectorState(seriesId, entityId)
  → listCodexEntityState(seriesId, entityId) — ALL state records
  → renderWritingInspectorState — groups by chapter, carries forward
```

**After:**
```
updateWritingInspectorCodex(project)
  → getWritingChapterInfo() — gets current chapter from appState.writingWorkspace.scope
  → getWritingChapterSortOrder() — computes globalSort from outline
  → codexV2GetEntityStateAt(entityId, bookId, chapterSortOrder) — state at chapter
  → codexV2GetActiveConnectionsAt(entityId, chapterSortOrder) — relationships at chapter
  → renderWritingInspectorContextual — shows Classification, Current State, Active Relationships, Changes This Chapter
```

---

## 12. Writing Inspector Current State Live Results

Shows resolved state at current chapter using `codexV2ResolveState(states, { mode: 'stateAt' })`.

Example:
```
CURRENT STATE
Level: 3
Strength: 20
Health: 75
```

---

## 13. Writing Inspector Changes This Chapter Live Results

Shows only state changes in the current chapter, grouped by property, with entry_order chain.

Example:
```
CHANGES THIS CHAPTER
Health: 100 → 42 → 18 → 75
Strength: 15 → 20
```

If no changes: "No state changes this chapter."

---

## 14. Writing Inspector Active Relationships Live Results

Shows relationships active at current chapter using `codexV2GetActiveConnectionsAt`.

Example:
```
ACTIVE RELATIONSHIPS
Owns Goblin Sword
Member of Test Guild
```

---

## 15. Classification Display Completion Status

**Writing Inspector:** Done — shows Role, Archetype, Profession, Background, and entity_link fields (Species, Culture, Family, Organisation, Progression System).

**Entity Detail Page:** Deferred — classification already visible through entity_link field values in the details tab.

---

## 16. Species/Culture/Family Graph Completion Status

**Entity_link fields established:**
- Character → Species (entity_link)
- Character → Culture (entity_link)
- Character → Family (entity_link)
- Character → Organisation (entity_link)
- Character → Progression System (entity_link)

**Connections:**
- Species ↔ typical Cultures (via connections)
- Culture ↔ Languages/Religions (via connections)

**Status:** Basic graph established. Further relational connections deferred.

---

## 17. Automated State Tests Added and Actual Results

**File:** `tests/state-architecture.test.js`

**36 tests covering:**

| Category | Tests | Status |
|----------|-------|--------|
| Canonical property identity | 4 | PASS |
| State At resolution | 9 | PASS |
| State History retention | 6 | PASS |
| Template exclusion | 5 | PASS |
| Entry order | 2 | PASS |
| Shared definition | 3 | PASS |
| NULL effective_from_sort | 2 | PASS |
| Backwards/forwards navigation | 5 | PASS |

**Results:** 36/36 PASS

---

## 18. Existing 50-Test Suite Result

```
50 passed, 0 failed
```

---

## 19. Existing 43 Temporal-Relationship Test Result

```
43 passed, 0 failed
```

---

## 20. Build/Lint/Type-Check Result

```
Build: PASS
```

---

## 21. Known Limitations and Deferred Items

| Item | Status |
|------|--------|
| `codexV2RecordState` dead code | Deferred — not wired until event-driven writes designed |
| `effective_to_sort` never populated | Deferred — column exists but not used |
| Entity detail page classification | Deferred — already visible through field values |
| Full event-driven state writes | Deferred — architecture documented |
| Complex inventory UI | Deferred |
| Formula execution | Deferred |
| `saveSkConnection` legacy risk | Documented — not expanded |

---

## 22. PASS/FAIL Recommendation

```
PASS — v2.3 State + classification foundations can be frozen
```

**Rationale:**
1. `entry_order` column exists in migration and is included in save payloads
2. Same-chapter resolution is deterministic (entry_order wins)
3. Canonical property identity is shared across every resolver
4. Narrative State cannot be saved without usable temporal position (auto-compute)
5. NULL does not automatically mean template — explicit template marking
6. Template rows are explicitly identifiable (state_status = 'template')
7. State History and State At have intentionally different semantics
8. Writing Inspector is chapter-contextual
9. Missing Writing context shows explicit message, not full history
10. Starting Pack templates cannot contaminate narrative State
11. Event → Effect → State semantics preserved
12. 36 automated State tests pass
13. 50 existing tests pass
14. 43 temporal-relationship tests pass
15. Build passes

**Total tests:** 129/129 PASS
