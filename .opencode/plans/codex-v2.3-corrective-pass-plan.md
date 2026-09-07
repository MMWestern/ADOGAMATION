# Codex v2.3 Corrective Pass — Implementation Plan

**Date:** 6 September 2026
**Based on:** `Codex_v2.3_State_Architecture_and_Writing_Context_Corrective_Pass.md`
**Status:** APPROVED with 4 amendments — implementation in progress

---

## Executive Summary

This plan addresses the corrective pass specification. The work is divided into 8 phases, ordered by priority and dependency. The high-priority items (Phases 1-4) stabilise the state architecture and rewrite the Writing Inspector. Medium-priority items (Phases 5-8) complete classification display, add automated tests, and verify acceptance criteria.

**Estimated scope:** Significant — touches every state-related save path, the Writing Inspector UI, and the temporal query layer.

---

## Current State Assessment

### What Works
- Temporal relationship engine (43 tests passing)
- Cross-book state persistence
- Starting Pack system (apply packs to characters)
- View State At (with known NULL effective_from_sort limitation)
- Progression Sheet
- State History tab

### Critical Findings from Codebase Investigation

#### Finding 1: `entry_order` Column Does NOT Exist in Database
**Severity:** CRITICAL

The `entry_order` column was never added to the database:
- No migration file in `migrations/` creates it
- `saveCodexEntityState` in `supabase-codex.html` silently DROPS the field from payloads (line 1154-1181)
- Callers in `series-knowledge.html` include `entry_order` in their JSON (lines 9544, 9866), but the gateway function never reads or forwards it
- All reads of `entry_order` from database results return `undefined`
- Sorting by `entry_order` in JavaScript is a no-op (comparing `undefined` values)

**Impact:** All same-chapter state ordering, deduplication in View State At, and Writing Inspector entry ordering are broken at the database level.

#### Finding 2: Writing Chapter Context Available via `appState.writingWorkspace.scope`
**Severity:** Informational

The writing workspace stores the current chapter in `appState.writingWorkspace.scope` (a string containing the `segment.key` / outline chapter `id`).

To compute `chapterSortOrder` for the current writing chapter:
```javascript
var scope = appState.writingWorkspace.scope;
var outline = appState.writingWorkspace.outline;
var chapterSortOrder = null;
(outline.acts || []).forEach(function (act) {
  (act.children || []).forEach(function (ch) {
    if (ch.id === scope) chapterSortOrder = ch.sortOrder;
  });
});
var bookNum = codexV2GetBookNumber(getSelectedProject().project_id);
var globalSort = codexV2GlobalSort(bookNum, chapterSortOrder);
```

**Key relationships:**
- `segment.key` === `outline chapter.id` (same string)
- `segment.sortOrder` = 1-based (for display)
- `outline chapter.sortOrder` = 0-based (for database queries)
- `appState.writingWorkspace.scope` = the selected chapter key

#### Finding 3: `state_status` Enum Needs 'template' Value
**Severity:** Medium

The existing `state_status` values are: `draft`, `provisional`, `canon`, `deprecated`. A new value `'template'` is needed for Starting Pack default values to distinguish them from narrative state.

### Key Gaps Identified
| Gap | Severity | Description |
|-----|----------|-------------|
| `entry_order` column missing | **CRITICAL** | Column doesn't exist, silently dropped from saves |
| `codexV2RecordState` is dead code | High | Defined but never called |
| NULL `effective_from_sort` | High | Records without chapter selection appear at ALL narrative points |
| Writing Inspector has no chapter awareness | High | Shows all state across all books/chapters |
| No state supersedence on save | Medium | Old records accumulate; resolution only at query time |
| Events not linked to state changes | Design gap | Generic `entity_updated` events only |

---

## Phase 1: Lock State/Event Architecture

### 1.1 CRITICAL: Add `entry_order` Column to Database

**Problem:** The `entry_order` column does NOT exist in the `codex_entity_state` table. All JavaScript code that reads, writes, or sorts by `entry_order` is broken — the column is silently dropped from save payloads and returns `undefined` from queries.

**Evidence:**
- No migration file in `migrations/` creates this column
- `saveCodexEntityState` (supabase-codex.html:1154-1181) does NOT read `parsed.entry_order` from the input JSON
- Callers in series-knowledge.html (lines 9544, 9866) include `entry_order` in their payloads, but it's silently dropped

**Actions:**

**Step 1: Create migration to add column**
```sql
-- migrations/20260907_add_entry_order_to_state.sql
ALTER TABLE codex_entity_state ADD COLUMN IF NOT EXISTS entry_order INTEGER DEFAULT 1;
CREATE INDEX IF NOT EXISTS idx_state_entry_order ON codex_entity_state(subject_entity_id, property_key, entry_order);
```

**Step 2: Fix `saveCodexEntityState` to include `entry_order` in payload**

Current code (supabase-codex.html ~line 1154-1181):
```javascript
var payload = {
  subject_entity_id: ...,
  property_entity_id: ...,
  property_key: ...,
  // entry_order is MISSING here
  ...
};
```

Add:
```javascript
entry_order: parsed.entry_order != null ? Number(parsed.entry_order) : 1,
```

**Step 3: Backfill existing records**
```sql
UPDATE codex_entity_state SET entry_order = 1 WHERE entry_order IS NULL;
```

**Files:**
- `migrations/20260907_add_entry_order_to_state.sql` — NEW
- `scripts/supabase-codex.html` — fix `saveCodexEntityState` payload

### 1.2 Document the Architecture Model

Create an architecture comment block in `scripts/supabase-codex.html` documenting:

```
DEFINITION -> EVENT -> EFFECT/TRANSITION -> STATE

- Definition: What is this property/concept? (Strength, Health, Human, Fireball)
- Event: What happened? (Patrick kills an Ogre, Training Session)
- Effect/Transition: What changed? (XP +500, Health -20, Strength 15 -> 20)
- State: What is now true? (XP = 1700, Health = 60, Strength = 20)

State change semantics:
- SET: Strength becomes 25; Rank becomes Apprentice
- DELTA: Strength +5; Health -20; XP +300
- DERIVED/CALCULATED: only where progression system defines it (deferred)

State must remain the canonical answer to "what is true here?".
Do NOT make State At replay every historical event to calculate current values.
```

**Files:**
- `scripts/supabase-codex.html` — add architecture comment at top

### 1.3 Fix `codexV2RecordState` to Actually Be Called

**Problem:** Function exists at `codex-v2-dual-write.html:79` but is never called.

**Decision needed:** Should this function be:
- **(A)** Wired into entity save paths so that editing character custom_data auto-creates state records? (e.g., changing role_archetype creates a state record)
- **(B)** Left as dead code until full event-driven writes are implemented?
- **(C)** Removed entirely?

**Recommendation:** Option (B) — leave as dead code for now, document it. Full event-driven writes are a future feature. The current model (manual state authoring) works.

**Files:**
- `scripts/codex-v2-dual-write.html` — add comment: "DEFERRED: Not wired until event-driven state writes are designed"

### 1.4 Define State Change Types in Save Payload

**Problem:** The save payload doesn't distinguish between SET, DELTA, and DERIVED state changes.

**Action:**
- Add `change_type` field to state save payload (default: 'set')
- Allowed values: `set`, `delta`, `derived`
- This is a documentation/future-proofing step — no immediate functional change

**Files:**
- `scripts/series-knowledge.html` — `showStateEditForm` save handler
- `scripts/supabase-codex.html` — `saveCodexEntityState` payload

---

## Phase 2: Fix NULL `effective_from_sort`

### 2.1 Audit Existing NULL Records

**Action:**
- Create a Supabase query to count NULL `effective_from_sort` records
- Classify each as: narrative_state, template/default, or legacy_unknown
- Document findings in the corrective report

**Query:**
```sql
SELECT
  CASE
    WHEN notes LIKE '%starting pack%' OR notes LIKE '%template%' THEN 'template'
    WHEN book_id IS NOT NULL AND chapter_id IS NOT NULL THEN 'narrative_with_chapter'
    WHEN book_id IS NOT NULL THEN 'narrative_book_only'
    ELSE 'legacy_unknown'
  END as classification,
  COUNT(*) as count
FROM codex_entity_state
WHERE effective_from_sort IS NULL
GROUP BY classification;
```

### 2.2 Backfill Narrative State Records

**For records with book_id AND chapter_id:**
- Compute `effective_from_sort = codexV2GlobalSort(bookNum, chapter.sort_order)`
- Update records

**For records with book_id only:**
- Flag for manual review — cannot safely infer chapter

**For template/legacy records:**
- Mark with `state_status = 'template'` or add `notes` prefix `[template]`
- Exclude from narrative state queries

**Migration:** `migrations/20260907_backfill_null_effective_from_sort.sql`

### 2.3 Add Validation to Save Paths

**Rule:** Normal narrative state MUST have a narrative position.

**Changes to `saveCodexEntityState`:**
```
if (!payload.effective_from_sort && payload.book_id && payload.chapter_id) {
  // Auto-compute from book/chapter
  effective_from_sort = codexV2GlobalSort(bookNum, chapter.sort_order)
}
if (!payload.effective_from_sort) {
  // Reject or warn — cannot save narrative state without position
  throw new Error('effective_from_sort required for narrative state')
}
```

**Exception:** Template/default records (from Starting Packs) may have NULL `effective_from_sort` but must be marked with `state_status = 'template'` or similar.

**Files:**
- `scripts/supabase-codex.html` — `saveCodexEntityState` validation
- `scripts/series-knowledge.html` — state edit form validation

### 2.4 Update `getEntityStateAt` to Exclude Templates

**Current query:** `state_status IN ('draft', 'provisional', 'canon')`

**Change:** Add `'template'` to excluded statuses, OR add a separate filter for `effective_from_sort IS NOT NULL OR state_status != 'template'`

**Files:**
- `scripts/supabase-codex.html` — `getEntityStateAt` query

---

## Phase 3: Formalise Three State Views

### 3.1 State History View

**Purpose:** Show ALL state changes ever recorded (audit trail).

**Current implementation:** `loadCodexStateAndEvents` in `series-knowledge.html`

**Changes:**
- Rename UI label to "State History" (currently "State")
- Ensure it shows ALL entries including multiple same-chapter entries
- Sort by: effective_from_sort ASC, property_key ASC, entry_order ASC
- No deduplication — this is the raw history

**Files:**
- `scripts/series-knowledge.html` — rename tab/label, verify sorting

### 3.2 State At View

**Purpose:** What is true at a specific narrative point?

**Current implementation:** View State At in `series-knowledge.html`

**Changes:**
- Deduplicate by: group by property_key, sort by effective_from_sort DESC, entry_order DESC, keep first
- Exclude template/default records
- For NULL effective_from_sort: exclude from narrative queries (they are templates)
- Add label: "State At [Book X, Chapter Y]"

**Files:**
- `scripts/series-knowledge.html` — View State At dedup logic

### 3.3 Progression Sheet View

**Purpose:** Resolved progression context at a narrative point.

**Current implementation:** `loadProgressionSheet` in `series-knowledge.html`

**Changes:**
- Same dedup logic as State At
- Default to "current state" (all records, no chapter filter) if no chapter selected
- When chapter selected, use State At semantics
- Show active relationships alongside state

**Files:**
- `scripts/series-knowledge.html` — Progression Sheet logic

### 3.4 Shared Helper Function

Create a shared resolver function used by all three views:

```javascript
function codexV2ResolveState(allRows, options) {
  // options: { mode: 'history'|'stateAt'|'progression', chapterSortOrder: number }
  // history: return all rows sorted by effective_from_sort, entry_order
  // stateAt: return deduplicated latest per property_key
  // progression: same as stateAt but with category grouping
}
```

**Files:**
- `scripts/codex-v2-dual-write.html` — new shared helper

---

## Phase 4: Writing Inspector Chapter-Contextual Rewrite

### 4.1 Get Current Writing Context

**Source:** `appState.writingWorkspace.scope` contains the chapter key (same as outline chapter `id`).

**To compute `chapterSortOrder`:**
```javascript
function getWritingChapterSortOrder() {
  var scope = String(appState.writingWorkspace.scope || "");
  if (!scope) return null;
  var outline = appState.writingWorkspace.outline;
  if (!outline) return null;
  var chapterSortOrder = null;
  (outline.acts || []).forEach(function (act) {
    (act.children || []).forEach(function (ch) {
      if (ch.id === scope) chapterSortOrder = ch.sortOrder;
    });
  });
  if (chapterSortOrder == null) return null;
  var project = getSelectedProject();
  var bookNum = codexV2GetBookNumber(project.project_id || project.id);
  return codexV2GlobalSort(bookNum, chapterSortOrder);
}

function getWritingChapterInfo() {
  var scope = String(appState.writingWorkspace.scope || "");
  var segments = Array.isArray(appState.writingWorkspace.segments) ? appState.writingWorkspace.segments : [];
  var segment = scope ? segments.find(function (s) { return s.key === scope; }) : null;
  if (!segment) return null;
  var project = getSelectedProject();
  return {
    key: segment.key,
    title: segment.title,
    bookId: project ? (project.project_id || project.id) : 0,
    bookNum: codexV2GetBookNumber(project ? (project.project_id || project.id) : 0),
    sortOrder: getWritingChapterSortOrder()
  };
}
```

**Files:**
- `Client.html` — add `getWritingChapterSortOrder()` and `getWritingChapterInfo()` helpers

### 4.2 Rewrite `loadWritingInspectorState`

**Current:** Calls `listCodexEntityState(seriesId, entityId)` — returns ALL state.

**New:** Call `getEntityStateAt(entityId, bookId, chapterSortOrder)` — returns state at current chapter.

```javascript
function loadWritingInspectorState(seriesId, entityId, stateList, stateSection) {
  var bookId = getCurrentWritingBookId();
  var chapterSortOrder = getCurrentWritingChapterSortOrder();

  if (bookId && chapterSortOrder) {
    // Chapter-contextual mode
    codexV2GetEntityStateAt(entityId, bookId, chapterSortOrder)
      .then(function(states) {
        renderWritingInspectorResolvedState(states, stateList);
      });
  } else {
    // Fallback: show all state (current behavior)
    // ... existing code ...
  }
}
```

**Files:**
- `Client.html` — `loadWritingInspectorState` rewrite

### 4.3 Rewrite `renderWritingInspectorState`

**Current:** Groups by chapter, carries forward values, shows all entries.

**New layout per corrective pass spec:**

```
PATRICK KELTH
Current at Book 1, Chapter 7

Classification
Species: Human
Role: Protagonist
Class: Beast Slayer

Current State
Level: 3
Strength: 20
Health: 75
Mana: 40

Active Relationships
Owns Goblin Sword
Member of Test Guild

Changes This Chapter
Strength 15 -> 20
Health 100 -> 42 -> 18 -> 75
```

**Implementation:**
1. **Classification section:** Read from entity_link field values
2. **Current State section:** Use resolved state (deduplicated, latest per property)
3. **Active Relationships section:** Call `codexV2GetActiveConnectionsAt`
4. **Changes This Chapter section:** Filter state records to only those in current chapter, sorted by entry_order

**Files:**
- `Client.html` — new `renderWritingInspectorContextual` function
- `Index.html` — update Writing Inspector HTML structure
- `Styles.html` — new styles for contextual layout

### 4.4 Show "Changes This Chapter" Only

**For Changes This Chapter:**
- Filter state records where `effective_from_sort` matches current chapter
- Group by property_key
- Show entry_order sequence: "Strength: 10 -> 15 -> 20"
- If no changes in chapter, show "No state changes this chapter" or omit section

**Files:**
- `Client.html` — Changes This Chapter logic

### 4.5 Active Relationships in Writing Inspector

**Add:** Call `codexV2GetActiveConnectionsAt(entityId, chapterSortOrder)` and display.

**Files:**
- `Client.html` — add Active Relationships section

---

## Phase 5: Starting Pack Template Isolation

### 5.1 Verify Pack Values Don't Leak Into Narrative Queries

**Test:** Create a Starting Pack with values, apply to character, verify:
- Pack template records (on pack entity) don't appear in character's State At
- Only materialized character state records appear

**Current behavior:** Pack state records have `subject_entity_id = packId`. Character state records have `subject_entity_id = characterId`. Queries filter by `subject_entity_id`, so they should not leak.

**Action:** Verify this is working correctly. Document in report.

### 5.2 Mark Pack Template Records

**Action:** When creating pack state records, set:
- `state_status = 'template'` (not 'canon')
- `notes = 'Pack template value'`

This ensures they are excluded from narrative queries.

**Files:**
- `scripts/series-knowledge.html` — Starting Pack creation logic

### 5.3 Verify No Duplicate Definitions

**Test:** Apply a pack that references "Strength" stat. Verify:
- No duplicate "Strength" entity is created
- Pack uses existing canonical Strength entity via `property_entity_id`

**Action:** Verify existing behavior. Document in report.

---

## Phase 6: Classification Display & World Graph

### 6.1 Classification Display on Character Overview

**Add:** "Classifications" section to character detail page showing:
- Species, Culture, Family/House, Role, Profession, Background, Class/Path, System
- Each as clickable link to Codex entry

**Implementation:**
- Read from `codex_entity_field_values` (entity_link fields)
- Read from `codex_connections` (for role, archetype)
- Render as list with entity links

**Files:**
- `scripts/series-knowledge.html` — character detail page
- `Index.html` — classification section HTML

### 6.2 Classification in Writing Inspector

**Add:** Compact classification summary in Writing Inspector:
```
Classification
Species: Human
Role: Protagonist
Class: Beast Slayer
```

**Files:**
- `Client.html` — Writing Inspector layout

### 6.3 World Classification Graph Verification

**Verify these connections work:**
- Character/Creature -> Species (entity_link)
- Character/Creature -> Culture (entity_link)
- Character -> Family/House (entity_link)
- Character -> Organisation (temporal connection)
- Species <-> typical Cultures (connection)
- Culture <-> Languages/Religions (connection)

**Action:** Document which connections exist and which are missing.

---

## Phase 7: Automated State Tests

### 7.1 New Test File: `tests/state-architecture.test.js`

**Tests to add:**

| Test | Description |
|------|-------------|
| Canonical property identity | `property_entity_id` preferred over `property_key` |
| Same property across chapters | Correct resolution at each chapter |
| Multiple same-property in chapter | `entry_order` determines latest |
| Latest same-chapter entry wins | State At uses highest `entry_order` |
| State History retains all entries | All same-chapter entries preserved |
| Cross-book carry-forward | State persists across books |
| Supersession | New value replaces old |
| Backwards/forwards reconstruction | Navigate B2→B1→B2→B1 correctly |
| Future state no-leak | Future changes don't appear in past |
| Starting Pack application | Creates canonical state on character |
| Pack isolation | Pack templates don't leak into narrative state |
| Two characters share definition | Independent state, same canonical property |
| NULL effective_from_sort rejected | Save validation prevents accidental NULL |
| Active relationships in context | Resolve alongside state |

**Files:**
- `tests/state-architecture.test.js` — NEW

### 7.2 Run All Tests

- `node tests/plan-outline-sync.test.js` — 50 tests
- `node tests/temporal-relationship.test.js` — 43 tests
- `node tests/state-architecture.test.js` — new tests

---

## Phase 8: Live Acceptance Matrix

### 8.1 Patrick Test Data

**Setup:**
```
Patrick Kelth (Character)
B1 Ch1 entry 1: Strength = 10
B1 Ch1 entry 2: Strength = 15
B1 Ch1 entry 3: Strength = 20
B1 Ch2 entry 1: Strength = 25
B2 Ch3 entry 1: Strength = 30
```

### 8.2 Acceptance Matrix

| Context | State At | Changes This Chapter |
|---------|----------|---------------------|
| B1 Ch1 | Strength 20 | 10, 15, 20 in entry order |
| B1 Ch2 | Strength 25 | 25 only |
| B1 later | Strength 25 | None unless changed |
| B2 Ch1 | Strength 25 | None |
| B2 Ch3 | Strength 30 | 30 only |

### 8.3 Navigation Test

Navigate backwards and forwards repeatedly:
```
B2 Ch3 -> B1 Ch1 -> B2 Ch1 -> B1 Ch2 -> B2 Ch3
```
Verify no stale cache or incorrect values.

### 8.4 Event/Transition Test (if implemented)

Create event with multiple effects:
```
Event: Patrick defeats Ogre
Position: B1 Ch7
Effects: XP +500, Health -20, Strength +2
```
Verify:
- Event is identifiable as cause
- Old/new/delta retained
- State rows materialized
- State At uses result without replaying event log

---

## Implementation Order

```
Phase 1: Lock Architecture (1.1, 1.2, 1.3, 1.4)
    ↓
Phase 2: Fix NULL effective_from_sort (2.1, 2.2, 2.3, 2.4)
    ↓
Phase 3: Three State Views (3.1, 3.2, 3.3, 3.4)
    ↓
Phase 4: Writing Inspector Rewrite (4.1, 4.2, 4.3, 4.4, 4.5)
    ↓
Phase 5: Pack Isolation (5.1, 5.2, 5.3)
    ↓
Phase 6: Classification Display (6.1, 6.2, 6.3)
    ↓
Phase 7: Automated Tests (7.1, 7.2)
    ↓
Phase 8: Acceptance Matrix (8.1, 8.2, 8.3, 8.4)
```

---

## Files Changed Summary

| File | Changes |
|------|---------|
| `migrations/20260907_add_entry_order_to_state.sql` | NEW — add entry_order column (if missing) |
| `migrations/20260907_backfill_null_effective_from_sort.sql` | NEW — backfill NULL records |
| `scripts/supabase-codex.html` | Architecture docs, save validation, getEntityStateAt template exclusion |
| `scripts/codex-v2-dual-write.html` | Shared state resolver, architecture docs, codexV2RecordState docs |
| `scripts/series-knowledge.html` | Three views, state edit form validation, classification display |
| `Client.html` | Writing Inspector chapter-contextual rewrite |
| `Index.html` | Writing Inspector HTML structure |
| `Styles.html` | New Writing Inspector styles |
| `tests/state-architecture.test.js` | NEW — automated state tests |

---

## Questions for Clarification

All questions resolved. Implementation can proceed.

**Answers received:**
1. **Writing chapter context:** `appState.writingWorkspace.scope` stores the chapter key. Outline has `sortOrder` for each chapter.
2. **`entry_order` column:** CRITICAL — column does NOT exist. Must create migration and fix save function.
3. **Template `state_status`:** Use `'template'` as a new allowed value.
4. **Event-driven writes:** Implement basic event-to-state linkage.
5. **Classification display:** Both entity detail page and Writing Inspector.

---

## Freeze Criteria Checklist

- [ ] `entry_order` column exists in database and is included in save payloads
- [ ] Canonical state-property identity is reliable
- [ ] Normal narrative State cannot be saved without usable narrative position
- [ ] Same-chapter ordering is deterministic
- [ ] State History and State At have intentionally different semantics
- [ ] Writing Inspector is chapter-contextual
- [ ] Starting Pack values cannot contaminate story-state resolution
- [ ] Classification data is visible while writing
- [ ] Automated State tests cover temporal resolver and Starting State
- [ ] Existing 50-test suite passes
- [ ] Existing 43 temporal-relationship tests pass
- [ ] Build passes
