# Codex v2.3 & State Display — Session Report

**Date:** 6 September 2026
**Branch:** `feature/world-builder`
**Previous report:** `codex-v2.2-final-regression-and-legacy-write-audit-report.md`

---

## 1. Executive Summary

This session covered two major areas:

1. **Codex v2.3 implementation** — Character classification links, Starting Pack system, Starting State Editor, canonical property identity enforcement
2. **State display in writing mode** — Adding state/progression data to the "Selected Codex Entry" panel, with significant debugging around how state records are resolved and displayed

We also surfaced a **fundamental design question** about whether events should drive state changes (see Section 7).

---

## 2. Codex v2.3 — What Was Built

### Phase 1: Character Classification Entity Links
**Commit:** `836302b`

Created migration `20260907_seed_character_classification_fields.sql` to add entity_link field definitions for character and creature entity types:

| Field Key | Label | Type | Entity Type |
|-----------|-------|------|-------------|
| species | Species | entity_link | character, creature |
| culture | Culture | entity_link | character |
| family | Family / House | entity_link | character |
| profession | Profession | text | character |
| background | Background / Origin | text | character |
| organisation | Organisation | entity_link | character |
| progression_system | Progression System | entity_link | character |

Also added `applies_to` relationship type and `stat_set` entity type.

### Phase 2: Character Sub-type Cleanup
**Commit:** `836302b`

Hidden the universal "Sub-type" dropdown for characters (Role/Archetype already exists). Sub-type remains in `custom_data` for backward compatibility.

### Phase 4: Canonical Property Identity Enforcement
**Commit:** `836302b`

State resolver now prefers `property_entity_id` for deduplication when a canonical property entity exists. `property_key` used only as fallback.

### Phase 3+5: Starting Pack System & Starting State Editor
**Commit:** `73708a8`

**Data model:**
- Starting Pack = a `system_rule` entity with `custom_data.starting_pack: true`
- Pack contents = `codex_entity_state` records on the pack entity
- Pack applicability = `codex_connections` linking pack to Species/System/Class via `applies_to` relationship

**Functions added to `scripts/codex-v2-dual-write.html`:**
- `codexV2FindApplicablePacks(seriesId, entityId)` — finds packs via connections and entity_link field values
- `codexV2LoadPackValues(seriesId, packId)` — loads pack state values

**UI:**
- "Starting State" button on character detail page
- Shows applicable packs based on character's classifications
- "Apply All to Character" button with book/chapter selection
- Creates state records with `state_status: 'canon'`, `effective_from_sort` at selected chapter

### Bugs Fixed During v2.3
- `codexV2LoadPackValues` was passing `seriesId=0` instead of actual seriesId (`52db17e`)
- `findApplicablePacks` only checked `codex_connections`, not `codex_entity_field_values` (`5ebfa0e`)
- Starting State required book/chapter selection and set `effective_from_sort` correctly (`3de58f8`)

---

## 3. State Display — Multiple Entries & Entry Order

### The Problem
When a character has multiple state updates for the same property in the same chapter (e.g., strength = 10, then strength = 15, then strength = 20), the system needed a way to distinguish them.

### The Solution: Entry Order
Added `entry_order` field to state records:
- `entry_order = 1` (first update in chapter)
- `entry_order = 2` (second update)
- `entry_order = 3` (third update)

**Commits:** `ca43e1b`, `1d2e98a`, `36f3b69`

### State List Improvements
- Chapter section headers (blue highlighted) grouping state by book/chapter
- Ordering by narrative position → property name → entry_order
- "Delete All" button with double confirmation
- Preload chapters for all books with state records before rendering

**Commits:** `b0ad1df`, `3d14c31`, `1adee7c`, `fc0565f`, `59359da`

---

## 4. Writing Inspector — State Display in Selected Codex Entry Panel

### What Was Built
Added state/progression display to the "Selected Codex Entry" panel at the bottom of the right-hand column in writing mode.

**Commit:** `7544ad4`

**Changes:**
- `Index.html`: Added `#writingInspectorStateSection` (hidden by default) with `#writingInspectorStateList`
- `Client.html`: Added `loadWritingInspectorState()` and `renderWritingInspectorState()` functions
- `Styles.html`: Added `.writing-inspector-state-list` styles with scrollbar
- `scripts/el-cache.html`: Cached new DOM elements

### How It Works
1. When you select an entity pill in the writing outline, `updateWritingInspectorCodex()` is called
2. It extracts the entity ID from the entry key (format: `type::id`)
3. Calls `listCodexEntityState(seriesId, entityId)` via Supabase runner
4. Preloads chapters for all books in the results
5. Renders grouped by book/chapter with property names and values

### Bugs Found & Fixed

| Bug | Commit | Fix |
|-----|--------|-----|
| Response returns `states` not `rows` | `b6b1994` | Changed `result.rows` to `result.states` |
| Response is JSON string, not object | `b247d1f` | Added `JSON.parse(json)` |
| Property names showing as "property204" | `4690fa3` | Changed from `property_name` to `property_key` |
| Value field wrong | `4690fa3` | Changed from `property_value` to `value_number`/`value_text` |
| Multiple entries from chapter 1 carrying forward | `a6498e7` | Implemented "resolved state" logic |

---

## 5. The State Resolution Problem

### The Core Issue
When multiple state records exist for the same property across chapters, how should they be displayed?

**Example data:**
- Chapter 1: strength = 10, strength = 15, strength = 20 (3 entries, entry_order 1/2/3)
- Chapter 2: strength = 25 (1 entry)

### What the User Expected
- **Chapter 1:** Show ALL three entries (10, 15, 20) — the user can see the progression within the chapter
- **Chapter 2:** Show only strength = 25 — the final value from chapter 1 is superseded

### What Was Happening
All entries from chapter 1 were carrying forward to chapter 2, showing 4 entries instead of 1.

### Multiple Attempts to Fix

1. **First attempt** (`a6498e7`): Group by property, skip if value unchanged — broke because notes differed between entries
2. **Second attempt** (`60e8667`): Group by chapter+property, show all within chapter, carry forward final value — correct logic but applied to wrong panel
3. **Third attempt** (`97473d4`, `f61a82c`): View State At — sort by `effective_from_sort` descending then `entry_order` descending, keep first (latest)

### Current Status
- **Writing Inspector panel:** Shows resolved state correctly (carry forward final value)
- **View State At:** Shows latest entry per property (sorted by effective_from_sort DESC, entry_order DESC)
- **Remaining issue:** If `effective_from_sort` is NULL for all records, sorting doesn't help — all records have the same sort value

---

## 6. View State At — Current Behavior

### How It Works
1. User selects a book and chapter
2. System computes `chapterSortOrder = (bookNum × 10000) + chapterSortOrder`
3. Queries `getEntityStateAt(entityId, bookId, chapterSortOrder)`
4. Returns all records where `effective_from_sort <= chapterSortOrder OR effective_from_sort IS NULL`
5. Deduplicates by keeping only the latest entry per property_key

### The NULL effective_from_sort Problem
If state records have `effective_from_sort = NULL`:
- The query returns ALL records for any chapter (because NULL passes the filter)
- Sorting by `effective_from_sort` doesn't help (all are 0)
- The "latest" entry is arbitrary

**Possible fix:** Sort by `book_id` and `chapter_id` as fallback when `effective_from_sort` is NULL. This would need to be implemented.

---

## 7. Design Question: Events vs States

### The Question Raised
> "A state is an actual variable — should we be using events to increase variables?"

This is a fundamental design question about the data model.

### Current Model (Direct State)
- You manually create state records like `strength = 20` at chapter 1
- To "level up", you create another record `strength = 25` at chapter 7
- Events are separate — just notes about what happened
- **Simple, but manual**

### Alternative Model (Event-Driven)
- You define event types like "Training Session" with effects: `strength +5`
- The system auto-calculates current state by applying all events in order
- More structured and auditable — you can see WHY strength changed
- **More complex to build**

### Hybrid Approach
- Events can affect states, but you can also manually set states
- Most flexible but most complex

### Questions to Resolve
1. Should events AUTO-CALCULATE the resulting state?
2. Or should events just be LINKED to state changes for narrative context?
3. Should some states be "derived from events" while others are "manually set"?

**Status:** Open question — needs design decision before implementation.

---

## 8. Entity Type Auto-Creation Fix

### Problem
When saving a codex entity, if the entity type didn't exist, the system tried to create it — but caused duplicate key errors.

### Fix
`saveCodexEntity` now looks up existing types before creating.

**Commits:** `d84d106`, `bd1bdfe`

---

## 9. Earlier Session Work (Pre-v2.3)

These were completed before this session but are worth noting:

| Work | Commit | Status |
|------|--------|--------|
| Schedule Templates milestones fix | `d86c0e2` | Done — user confirmed working |
| Format Defaults dynamic list | `ec8bad5` | Done — user confirmed working |
| Codex Preset Select All/Deselect All | `b80d866` | Done — user confirmed working |

---

## 10. Files Changed This Session

| File | Changes |
|------|---------|
| `migrations/20260907_seed_character_classification_fields.sql` | NEW — character/creature classification entity_link fields |
| `scripts/series-knowledge.html` | Starting State editor, state list rendering, chapter label display, View State At deduplication |
| `scripts/supabase-codex.html` | `getEntityStateAt` no longer filters by book_id, includes draft states |
| `scripts/codex-v2-dual-write.html` | `codexV2FindApplicablePacks`, `codexV2LoadPackValues`, chapter helpers |
| `scripts/constants.html` | `CODEX_V2_DUAL_WRITE = true` |
| `Index.html` | Writing inspector state section, relationship form temporal selectors |
| `Client.html` | Writing inspector state loading and rendering |
| `Styles.html` | `.writing-inspector-state-list` styles |
| `scripts/el-cache.html` | Cached new DOM elements |
| `tests/temporal-relationship.test.js` | 43 temporal relationship tests |

---

## 11. Test Results

```
Plan-outline-sync tests: 50/50 PASS
Temporal-relationship tests: 43/43 PASS
Build: PASS
```

---

## 12. Open Items

### Design Decisions Needed
- [ ] Events vs States model — should events drive state changes?
- [ ] How to handle NULL `effective_from_sort` in View State At

### Known Limitations
- `saveSkConnection` legacy form creates NULL/NULL connections for any relationship type — documented as potentially unsafe
- No automated state/progression tests (manual only)
- View State At deduplication may not work correctly if all records have NULL `effective_from_sort`

### Deferred Work
- Complex inventory UI
- Formula execution
- Separate temporal location hierarchy
- Major UI redesign for relationship panel
- `saveSkConnection` temporal fields addition
- v2.3 Phase 6: Classification display (show linked classifications as clickable links on character overview)

---

## 13. Deployment History

| Commit | Description | Deployed |
|--------|-------------|----------|
| `836302b` | v2.3 Phase 1+2+4 | Yes |
| `73708a8` | v2.3 Phase 3+5 | Yes |
| `7544ad4` | Writing inspector state display | Yes |
| `b6b1994` | Fix states vs rows | Yes |
| `b247d1f` | Fix JSON parsing | Yes |
| `4690fa3` | Fix property_key display | Yes |
| `a6498e7` | Resolved state logic | Yes |
| `60e8667` | Within-chapter entries fix | Yes |
| `97473d4` | View State At dedup | Yes |
| `f61a82c` | View State At sort fix | Yes |
