# Codex v2.3 — Implementation Plan

## Current State Summary

| Concept | Current Storage | Gap |
|---------|----------------|-----|
| Subtype | `custom_data.sub_type` + `custom_data.role_archetype` | Overloaded for narrative role |
| Role | `custom_data.role_archetype` | Works but mixed with subtype |
| Archetype | `custom_data.archetype` | Works |
| Motivation/Arc | `custom_data.motivation_arc` | Works |
| Species | Entity type exists, NO link from Character | Missing entity_link |
| Profession | Does not exist | Missing entirely |
| Background | Does not exist | Missing entirely |
| Culture | Entity type exists, connection-only | No entity_link field |
| Family/House | Entity type exists, connection-only | No entity_link field |
| Organisation | Entity type exists, temporal connections | Works |
| Class/Path | Via `codex_entity_state` | Works |
| Progression System | Via `codex_entity_field_values` (system field) | Works |
| Starting Packs | Does not exist | Missing entirely |
| Canonical property identity | `property_entity_id` on state table | Works but not enforced in UI |

---

## Phase 1: Character Classification Entity Links

**Goal:** Add entity_link field definitions so Characters can link to Species, Culture, Family, etc.

### Migration: `migrations/20260907_seed_character_classification_fields.sql`

Seed entity_link field definitions for `character` entity type:

| Field Key | Label | Type | Group | Options (entity_type_key) |
|-----------|-------|------|-------|--------------------------|
| species | Species | entity_link | Identity | species |
| culture | Culture | entity_link | Identity | culture |
| family | Family / House | entity_link | Identity | family |
| profession | Profession | text | Identity | — |
| background | Background / Origin | text | Identity | — |
| organisation | Organisation | entity_link | Identity | organisation |
| progression_system | Progression System | entity_link | Links | system_rule |

Also seed for `creature` entity type:
| species | Species | entity_link | Identity | species |

### UI Impact
- Details tab already renders `entity_link` fields as dropdowns
- Character/Creature detail will show new fields automatically
- No UI code changes needed for basic functionality

---

## Phase 2: Retire Character Subtype as Narrative Role

**Goal:** Stop using `custom_data.sub_type` for narrative role. Role field already exists.

### Changes
1. **No DB migration** — keep `sub_type` in `custom_data` for backward compatibility
2. **UI change:** In `showCodexEntityDetail`, when `entityTypeKey === "character"`:
   - Hide the universal "Sub-type" dropdown
   - Role dropdown already exists and works
3. **Sidebar grouping:** `renderSubTypeGroups` currently groups by `sub_type || role_archetype`. Change to group by `role_archetype` only for characters.

### Files Changed
- `scripts/series-knowledge.html`: Hide sub-type field for characters, update sidebar grouping

---

## Phase 3: Starting Pack System

**Goal:** Define reusable starting packs that suggest initial values based on classifications.

### Data Model
Use existing tables — no new tables needed:

1. **Starting Pack = a `system_rule` entity** with `custom_data.starting_pack: true`
2. **Pack contents = `codex_entity_state` records** on the pack entity itself (not on characters)
3. **Pack applicability = `codex_connections`** linking pack to Species/System/Class/etc.

### Example Structure
```
Entity: "Human Baseline" (type: system_rule, custom_data: {starting_pack: true})
  State: {property: "Strength", value: 5}
  State: {property: "Dexterity", value: 5}
  State: {property: "Constitution", value: 5}
  Connection: linked to Species "Human" via "applies_to" relationship
```

### UI: Starting State Editor
Add to character detail page (after Progression Sheet tab):
- Detect applicable packs from character's Species/System/Class connections
- Show proposed values from pack state records
- Allow author to edit before saving
- Save creates `codex_entity_state` records on the character

---

## Phase 4: Canonical Property Identity Enforcement

**Goal:** Ensure State editor always uses `property_entity_id` when a canonical property exists.

### Changes
1. **State editor:** When a property entity is selected from the dropdown, always set `property_entity_id` AND `property_key`
2. **State resolver:** Prefer `property_entity_id` for identity; use `property_key` only as fallback
3. **Duplicate prevention:** Before creating a new state record, check if one exists with same `subject_entity_id` + `property_entity_id` + `effective_from_sort`

### Files Changed
- `scripts/series-knowledge.html`: State editor save handler
- `scripts/supabase-codex.html`: State resolver deduplication

---

## Phase 5: Starting State Editor UI

**Goal:** Provide a bulk authoring interface for character starting state.

### UI Location
Add a "Starting State" button/tab to character detail page that:
1. Shows applicable packs (from Species/System/Class connections)
2. Shows proposed values in an editable grid
3. Allows author to override any value
4. Saves all values as `codex_entity_state` records with `effective_from_sort` at selected chapter

### Implementation
- New function `loadStartingStateEditor(seriesId, entityId)` in `scripts/series-knowledge.html`
- Reads pack state records from `codex_entity_state` where `subject_entity_id = packId`
- Merges with character's existing state
- Renders editable grid
- Save creates/updates `codex_entity_state` records on the character

---

## Phase 6: Classification Display

**Goal:** Show linked classifications on Character/Creature overview.

### Changes
- Add a "Classifications" section to the entity detail header or a dedicated tab
- Show: Species, Role, Profession, Culture, Family, Organisation, Class, System
- Each is a link to the canonical entity

### Implementation
- Read from `codex_entity_field_values` (entity_link fields) and `codex_connections`
- Render as a simple list with entity links

---

## Implementation Order

1. **Phase 1:** Seed classification entity_link fields (migration only)
2. **Phase 2:** Retire subtype for characters (UI change)
3. **Phase 4:** Canonical property identity enforcement (State editor fix)
4. **Phase 3:** Starting Pack system (data model + UI)
5. **Phase 5:** Starting State Editor UI
6. **Phase 6:** Classification display

---

## Files to Change

| File | Changes |
|------|---------|
| `migrations/20260907_seed_character_classification_fields.sql` | NEW — entity_link fields for Species, Culture, Family, etc. |
| `scripts/series-knowledge.html` | State editor fixes, Starting State editor, classification display, subtype hiding |
| `scripts/supabase-codex.html` | State resolver deduplication |
| `scripts/codex-v2-dual-write.html` | Starting pack helper functions |

## What NOT to Change
- Temporal relationship architecture
- State/progression engine
- Relationship History panel
- Active Relationships view
- Global narrative position formula
- Location hierarchy
- Existing entity types
- Existing connections
