# Codex v2.1 — Implementation Plan

## Overview

This plan implements the Codex v2.1 Progression System specification. The work is organized into 8 phases, each building on the previous. All changes remain additive — no destructive migrations.

---

## Phase 1: Seed Progression Field Definitions

**Goal:** Add schema-driven field definitions for stat, resource, skill_ability, class_path, and trait_perk entity types.

### 1.1 Create migration: `migrations/20260906_seed_progression_field_definitions.sql`

**Stat fields (entity_type_key: 'stat'):**
| Field Key | Label | Type | Group | Options |
|-----------|-------|------|-------|---------|
| abbreviation | Abbreviation | text | Identity | — |
| category | Category | select | Identity | Physical, Mental, Social, Magical, Derived, Other |
| value_type | Value Type | select | Identity | integer, decimal, percentage, boolean, text, rank, enum, calculated |
| default_value | Default Value | text | Defaults | — |
| min_value | Minimum Value | number | Bounds | — |
| max_value | Maximum Value | number | Bounds | — |
| stat_kind | Stat Kind | select | Classification | base, derived |
| formula | Formula | long_text | Derived | — |
| progression_method | Progression Method | long_text | Rules | — |
| display_order | Display Order | number | Display | — |
| player_visible | Player Visible | boolean | Display | — |
| description_rules | Description / Rules | long_text | Documentation | — |
| system | System | entity_link | Links | — |

**Resource fields (entity_type_key: 'resource'):**
| Field Key | Label | Type | Group | Options |
|-----------|-------|------|-------|---------|
| abbreviation | Abbreviation | text | Identity | — |
| category | Category | select | Identity | Health, Mana, Stamina, Experience, Energy, Currency, Other |
| value_type | Value Type | select | Identity | integer, decimal, percentage |
| default_value | Default Value | number | Defaults | — |
| min_value | Minimum Value | number | Bounds | — |
| max_value | Maximum Value | number | Bounds | — |
| max_formula | Maximum Formula | long_text | Rules | — |
| regeneration_rule | Regeneration Rule | long_text | Rules | — |
| depletion_rule | Depletion Rule | long_text | Rules | — |
| can_exceed_max | Can Exceed Maximum | boolean | Rules | — |
| player_visible | Player Visible | boolean | Display | — |
| display_order | Display Order | number | Display | — |
| system | System | entity_link | Links | — |

**Skill/Ability fields (entity_type_key: 'skill_ability'):**
| Field Key | Label | Type | Group | Options |
|-----------|-------|------|-------|---------|
| skill_type | Skill Type | select | Classification | Spell, Ability, Technique, Passive, Craft, Social, Other |
| rank_type | Rank Type | select | Classification | numeric, tier, named, boolean |
| min_rank | Minimum Rank | text | Bounds | — |
| max_rank | Maximum Rank | text | Bounds | — |
| governing_stat | Governing Stat | entity_link | Mechanics | — |
| cost_resource | Cost Resource | entity_link | Mechanics | — |
| cost | Cost | text | Mechanics | — |
| cooldown | Cooldown | text | Mechanics | — |
| progression_method | Progression Method | long_text | Rules | — |
| requirements | Requirements | long_text | Rules | — |
| player_visible | Player Visible | boolean | Display | — |
| system | System | entity_link | Links | — |

**Class/Path fields (entity_type_key: 'class_path'):**
| Field Key | Label | Type | Group | Options |
|-----------|-------|------|-------|---------|
| class_type | Class Type | select | Classification | Combat, Magic, Support, Hybrid, Crafting, Social, Other |
| tier | Tier | text | Progression | — |
| min_level | Minimum Level | number | Requirements | — |
| max_level | Maximum Level | number | Requirements | — |
| progression_method | Progression Method | long_text | Rules | — |
| requirements | Requirements | long_text | Rules | — |
| player_visible | Player Visible | boolean | Display | — |
| system | System | entity_link | Links | — |

**Trait/Perk fields (entity_type_key: 'trait_perk'):**
| Field Key | Label | Type | Group | Options |
|-----------|-------|------|-------|---------|
| trait_type | Trait Type | select | Classification | Racial, Class, Background, Achievement, Item, Quest, Other |
| rank_type | Rank Type | select | Classification | numeric, tier, named, boolean |
| max_rank | Maximum Rank | text | Bounds | — |
| stackable | Stackable | boolean | Rules | — |
| effect | Effect | long_text | Rules | — |
| requirements | Requirements | long_text | Rules | — |
| player_visible | Player Visible | boolean | Display | — |
| system | System | entity_link | Links | — |

### 1.2 Update `loadCodexFieldDefinitions` to render `entity_link` fields

In `scripts/series-knowledge.html`, add a case for `entity_link` field type:
- Render as a `<select>` dropdown populated with entities from the current series
- Filter by entity type if `options_json.entity_type_key` is specified
- Save to `linked_entity_id` on `codex_entity_field_values`
- Load existing `linked_entity_id` values and pre-select

### 1.3 Update `saveCodexFieldValues` to handle `linked_entity_id`

Currently only saves `value_text`, `value_number`, `value_boolean`. Add:
```javascript
if (fieldType === "entity_link") {
  payload.linked_entity_id = input.value ? Number(input.value) : null;
  payload.value_text = null; // Don't duplicate
}
```

---

## Phase 2: State Authoring UI

**Goal:** Make the State tab editable with add/edit/delete for state records and progression events.

### 2.1 Wire the "+ Add State" button

In `scripts/series-knowledge.html`, find the `loadCodexStateAndEvents` function and add click handler for `codexStateAddBtn`:

**Add State form fields:**
- Property Definition (entity_link to any entity, or freeform text for property_key)
- Value (text/number/boolean depending on context)
- Book (dropdown, filtered to current series)
- Chapter (dropdown, filtered to selected book)
- Effective From Sort (auto-populated from chapter)
- State Status (select: draft, provisional, canon, deprecated)
- Notes (textarea)

**Save calls:** `saveCodexEntityState(seriesId, payload)`

### 2.2 Wire the "+ Add Event" button

**Add Event form fields:**
- Event Type (select from spec list: level_up, stat_change, skill_unlock, skill_rank_change, class_acquired, class_change, trait_acquired, trait_lost, resource_change, item_acquired, item_lost, title_awarded, achievement_awarded, reputation_change, relationship_change, custom)
- Property Entity (entity_link)
- Old Value (JSON/text)
- New Value (JSON/text)
- Delta (number)
- Book (dropdown)
- Chapter (dropdown)
- Reason (text)
- Source Entity (entity_link — quest/achievement/item that caused change)
- Canon Status (select)
- Notes (textarea)

**Save calls:** `saveCodexProgressionEvent(seriesId, payload)`

### 2.3 Add edit/delete to existing state items

Modify the state list rendering to include:
- Edit button (pencil icon) — opens inline edit form with current values
- Delete button (×) — confirms and calls `deleteCodexEntityState(stateId)`

### 2.4 Add edit/delete to existing event items

Same pattern for events:
- Edit button — opens inline edit form
- Delete button — confirms and calls `deleteCodexProgressionEvent(eventId)`

### 2.5 Adapt value editor to definition's Value Type

When a property definition is selected, check its `value_type` field:
- `integer` / `decimal` / `percentage` → `<input type="number">`
- `boolean` → `<input type="checkbox">`
- `text` / `rank` / `enum` → `<input type="text">` or `<select>` if options defined
- `calculated` → read-only display

---

## Phase 3: Chapter-Level Context

**Goal:** Expose chapter selection in all v2 UIs.

### 3.1 Create chapter loading utility

Add function `loadChaptersForBook(projectId)` that:
- Queries `document_sections` where `project_id = projectId` and `doc_type = 'draft'`
- Returns array of `{id, title, sort_order}` sorted by `sort_order`
- Caches in `skCache.chapters[projectId]`

### 3.2 Add chapter dropdown to State form

When book is selected, populate chapter dropdown from `loadChaptersForBook(bookId)`.

### 3.3 Add chapter dropdown to Event form

Same pattern — chapter dropdown filtered by selected book.

### 3.4 Add chapter dropdown to Appearance form

When adding/editing an appearance, show chapter dropdown filtered by book.

### 3.5 Add chapter dropdown to Connection edit form

Enhance `showRelEditForm` to include chapter dropdown (already has book dropdown).

### 3.6 Resolve chapter titles in display

Replace raw `chapter_id` display with chapter title lookup:
- In Appearances tab: show "Chapter 5: The Battle" instead of "chapter 42"
- In State tab: show chapter title next to book title
- In Event tab: same

---

## Phase 4: Temporal Queries

**Goal:** Implement `getEntityStateAt(entity_id, book_id, chapter_id)` and temporal relationship queries.

### 4.1 Create Supabase function: `getEntityStateAt`

```sql
-- Returns the most recent state for each property_key/property_entity_id
-- at or before the specified narrative point
SELECT DISTINCT ON (COALESCE(property_key, property_entity_id::text))
  *
FROM codex_entity_state
WHERE subject_entity_id = :entity_id
  AND (book_id = :book_id OR book_id IS NULL)
  AND effective_from_sort <= :chapter_sort_order
  AND state_status IN ('provisional', 'canon')
ORDER BY COALESCE(property_key, property_entity_id::text), effective_from_sort DESC;
```

### 4.2 Create JavaScript wrapper: `codexV2GetEntityStateAt(seriesId, entityId, bookId, chapterId)`

- Loads chapter's `sort_order` from `document_sections`
- Calls the Supabase query
- Returns array of current state records at that narrative point

### 4.3 Create Supabase function: `getActiveConnectionsAt`

```sql
SELECT *
FROM codex_connections
WHERE (source_entity_id = :entity_id OR target_entity_id = :entity_id)
  AND deleted_at IS NULL
  AND (valid_from_sort IS NULL OR valid_from_sort <= :chapter_sort_order)
  AND (valid_to_sort IS NULL OR valid_to_sort > :chapter_sort_order);
```

### 4.4 Create JavaScript wrapper: `codexV2GetActiveConnectionsAt(seriesId, entityId, bookId, chapterId)`

- Loads chapter's `sort_order`
- Calls the Supabase query
- Returns array of active connections at that narrative point

### 4.5 Add temporal query test UI

In the State tab, add a "View State At..." button that lets user select book + chapter and displays the resolved state at that point.

---

## Phase 5: Entity-Link Field Support

**Goal:** Implement `entity_link` rendering in the Details tab.

### 5.1 Update `loadCodexFieldDefinitions` rendering

Add case for `entity_link`:
```javascript
if (fieldType === "entity_link") {
  // Get entity type filter from options_json
  var filterType = def.options_json && def.options_json.entity_type_key;
  // Build dropdown from codexCache.entitiesBySeries
  html += "<select class='codex-field-input' data-field-type='entity_link' data-linked-entity-id='" + (val ? val.linked_entity_id || '' : '') + "'>";
  html += "<option value=''>— None —</option>";
  // Group entities by type
  var entities = codexCache.entitiesBySeries[seriesId] || [];
  entities.forEach(function(e) {
    if (filterType && (e.codex_entity_types || {}).key !== filterType) return;
    var selected = val && val.linked_entity_id == e.id ? ' selected' : '';
    html += "<option value='" + e.id + "'" + selected + ">" + escapeHtml(e.name) + "</option>";
  });
  html += "</select>";
}
```

### 5.2 Update `saveCodexFieldValues` for entity_link

```javascript
if (fieldType === "entity_link") {
  payload.linked_entity_id = input.value ? Number(input.value) : null;
  payload.value_text = input.options[input.selectedIndex].text; // Store display name
}
```

### 5.3 Update value loading for entity_link

When loading field values, pre-select the linked entity in the dropdown using `val.linked_entity_id`.

---

## Phase 6: Appearances CRUD

**Goal:** Add manual add/edit/delete for appearances.

### 6.1 Wire "+ Add" button in Appearances tab

Add click handler for `codexAppearanceAddBtn`:

**Form fields:**
- Book (dropdown, filtered to current series)
- Chapter (dropdown, filtered to selected book)
- Appearance Type (select: appears, mentioned, pov, introduced, flashback, dies, returns, other)
- Notes (textarea)

**Save calls:** `saveCodexEntityAppearance(seriesId, payload)`

### 6.2 Add edit/delete to appearance items

Each appearance row gets:
- Edit button — opens inline edit form
- Delete button — confirms and calls `deleteCodexEntityAppearance(appearanceId)`

### 6.3 Make JS backfill idempotent

Modify `codexV2BackfillAppearances` to check for existing records before inserting:

```javascript
// Load existing appearances first
supabaseRunner.withSuccessHandler(function(existingJson) {
  var existing = JSON.parse(existingJson);
  var existingKeys = {};
  (existing.appearances || []).forEach(function(a) {
    existingKeys[a.entity_id + ':' + a.book_id] = true;
  });
  // Only insert if not exists
  entities.forEach(function(entity) {
    projectLinks.forEach(function(link) {
      var key = entityId + ':' + pid;
      if (existingKeys[key]) return; // Skip duplicate
      // ... insert ...
    });
  });
}).listCodexEntityAppearances(seriesId);
```

---

## Phase 7: Historical State Display

**Goal:** Add "View State At..." feature to show entity state at a specific narrative point.

### 7.1 Add "View State At..." button to State tab

Button opens a book + chapter selector. On selection, calls `codexV2GetEntityStateAt`.

### 7.2 Render historical state view

Display resolved state in a read-only panel:
- Property name
- Value (formatted by value_type)
- Source (which book/chapter set this value)
- Status (draft/provisional/canon)

### 7.3 Add "View Relationships At..." to Relationships panel

Similar feature: select book + chapter, show active relationships at that point.

---

## Phase 8: Patrick Pilot Test

**Goal:** Verify the complete workflow with a test dataset.

### 8.1 Create test data (manual or script)

**System: Uni-Verse**
- Create entity: "Uni-Verse System" (type: system_rule)

**Stats:**
- Strength (abbreviation: STR, category: Physical, value_type: integer, stat_kind: base)
- Dexterity (abbreviation: DEX, category: Physical, value_type: integer, stat_kind: base)
- Constitution (abbreviation: CON, category: Physical, value_type: integer, stat_kind: base)
- Intelligence (abbreviation: INT, category: Mental, value_type: integer, stat_kind: base)
- Charisma (abbreviation: CHA, category: Social, value_type: integer, stat_kind: base)

**Resources:**
- Health (category: Health, value_type: integer, max_formula: CON × 10)
- Mana (category: Mana, value_type: integer, max_formula: INT × 10)
- Experience (category: Experience, value_type: integer)

**Character:**
- Patrick Kelth (type: character)

**Class:**
- Beast Slayer (type: class_path, class_type: Combat)

**Skill:**
- Fireball (type: skill_ability, skill_type: Spell, governing_stat: Intelligence, cost_resource: Mana, cost: 12)

**Item:**
- Goblin Sword (type: item)

### 8.2 Record state changes

| Book | Chapter | Event |
|------|---------|-------|
| Book 1 | Ch 1 | Patrick: Level 1, STR 6, Fireball unavailable |
| Book 1 | Ch 7 | Patrick: Goblin Sword acquired |
| Book 1 | Ch 12 | Patrick: Level 3, STR 8, Fireball Rank 1 |
| Book 2 | Ch 3 | Patrick: Goblin Sword lost |

### 8.3 Verify historical queries

- `getEntityStateAt(Patrick, Book 1, Ch 1)` → Level 1, STR 6
- `getEntityStateAt(Patrick, Book 1, Ch 12)` → Level 3, STR 8, Fireball Rank 1
- `getEntityStateAt(Patrick, Book 2, Ch 3)` → Goblin Sword lost
- `getActiveConnectionsAt(Patrick, Book 1, Ch 7)` → OWNS Goblin Sword
- `getActiveConnectionsAt(Patrick, Book 2, Ch 3)` → Goblin Sword connection ended

---

## File Changes Summary

### New Migrations
| File | Purpose |
|------|---------|
| `migrations/20260906_seed_progression_field_definitions.sql` | Seed field definitions for stat, resource, skill_ability, class_path, trait_perk |

### Modified Files
| File | Changes |
|------|---------|
| `scripts/series-knowledge.html` | State authoring UI, chapter dropdowns, entity_link rendering, appearance CRUD, historical state view |
| `scripts/supabase-codex.html` | Add `getEntityStateAt` and `getActiveConnectionsAt` Supabase functions |
| `scripts/codex-v2-dual-write.html` | Make backfill idempotent, add chapter loading utility |

### No New Files Expected
All changes fit within existing file structure.

---

## Dependencies Between Phases

```
Phase 1 (Field Definitions)
    ↓
Phase 2 (State Authoring) ← requires Phase 1 for value_type-aware editors
    ↓
Phase 3 (Chapter Context) ← requires Phase 2 for chapter dropdowns in state forms
    ↓
Phase 4 (Temporal Queries) ← requires Phase 3 for chapter sort_order resolution
    ↓
Phase 5 (Entity-Link) ← independent, can parallel with Phase 2-4
    ↓
Phase 6 (Appearances CRUD) ← requires Phase 3 for chapter dropdowns
    ↓
Phase 7 (Historical Display) ← requires Phase 4 for temporal queries
    ↓
Phase 8 (Patrick Pilot) ← requires all previous phases
```

---

## Estimated Complexity

| Phase | Effort | Risk |
|-------|--------|------|
| Phase 1 | Low | Low — just SQL seeds + minor UI case |
| Phase 2 | High | Medium — new forms, value type adaptation |
| Phase 3 | Medium | Low — chapter loading + dropdown wiring |
| Phase 4 | High | Medium — SQL queries + JS wrappers |
| Phase 5 | Medium | Low — dropdown rendering |
| Phase 6 | Medium | Low — CRUD forms |
| Phase 7 | Medium | Medium — historical resolution UI |
| Phase 8 | Low | Low — manual testing |
