# CODEX V2 — POST-IMPLEMENTATION AUDIT

## 1. Executive Summary

### What Was Implemented

The Master Codex v2 implementation added an additive layer to the existing Codex system, introducing five new database tables, extended connection context, schema-driven entity fields, dual-write capabilities, and new UI tabs for Appearances, State/Progression, and Details.

### What Was Partially Implemented

- **Dual-write**: Only fires on entity save and connection save. Does not fire on all property changes (e.g., status, canon_status changes are not individually tracked as state records).
- **Book/chapter context on connections**: The UI only exposes book-level context, not chapter-level.
- **Schema-driven fields**: Only 11 entity types have seeded field definitions. The remaining 38 entity types have no custom fields defined.

### What Was Not Implemented

- **Chapter-level appearance tracking**: The `chapter_id` column exists but no UI exposes chapter selection for appearances.
- **Temporal relationship queries**: The `valid_from_sort`/`valid_to_sort` columns exist but no UI queries relationships by narrative point.
- **State history UI**: The State tab shows current state but does not display historical changes over time.
- **Inventory/Equipment convenience view**: No specialized LitRPG inventory view.
- **Relationship metadata editing**: The connection edit form only exposes book context, not the full metadata (notes, status, etc.).
- **Feature flag UI toggle**: `CODEX_V2_DUAL_WRITE` is hardcoded to `true` with no user-facing toggle.
- **Backfill for state/events**: Only appearances were backfilled. State and progression events were not backfilled from existing data.

### Differences from Specification

| Spec Requirement | Implementation Difference |
|-----------------|--------------------------|
| Chapter-level context | Column exists but UI only supports book-level |
| Temporal relationship queries | Columns exist but no query UI |
| State history visualization | Only flat list, no timeline view |
| Relationship metadata | Only book_id exposed in edit form |
| Feature flag toggle | Hardcoded, no UI toggle |
| State backfill | Not implemented |

### Legacy Functionality Changed

**No existing functionality was changed or removed.** All changes were additive. The existing entity detail page, relationships panel, codex tree, and preset system continue to work unchanged.

---

## 2. Database Changes

### New Tables

| Table | Purpose | Rows (Seed Data) |
|-------|---------|------------------|
| `codex_entity_appearances` | Track where entities appear in books/chapters | 0 (backfill available) |
| `codex_entity_state` | Time-aware state/progression layer | 0 |
| `codex_progression_events` | Change history (what changed, when, why) | 0 |
| `codex_entity_field_definitions` | Schema-driven field definitions per entity type | 75 (seeded) |
| `codex_entity_field_values` | Actual field values for entities | 0 |

### Modified Tables

| Table | Columns Added | Purpose |
|-------|---------------|---------|
| `codex_connections` | `book_id` | Book-level relationship context |
| `codex_connections` | `chapter_id` | Chapter-level relationship context |
| `codex_connections` | `valid_from_sort` | Narrative ordering anchor (start) |
| `codex_connections` | `valid_to_sort` | Narrative ordering anchor (end) |
| `codex_connections` | `context_status` | Relationship status (active/ended/planned) |
| `codex_connections` | `notes` | Human notes |
| `codex_connections` | `created_source` | Provenance (manual/import/AI/migration) |

### New Indexes

**`codex_entity_appearances`:**
- `idx_codex_entity_appearances_entity` (entity_id)
- `idx_codex_entity_appearances_series` (series_id)
- `idx_codex_entity_appearances_book` (book_id)
- `idx_codex_entity_appearances_chapter` (chapter_id)
- `idx_codex_entity_appearances_type` (appearance_type)
- `idx_codex_entity_appearances_entity_book` (entity_id, book_id) — composite

**`codex_entity_state`:**
- `idx_codex_entity_state_subject` (subject_entity_id)
- `idx_codex_entity_state_property_entity` (property_entity_id)
- `idx_codex_entity_state_series` (series_id)
- `idx_codex_entity_state_book` (book_id)
- `idx_codex_entity_state_chapter` (chapter_id)
- `idx_codex_entity_state_effective` (effective_from_sort)
- `idx_codex_entity_state_status` (state_status)
- `idx_codex_entity_state_subject_book_chapter` (subject_entity_id, book_id, effective_from_sort) — composite
- `idx_codex_entity_state_subject_series` (subject_entity_id, series_id, effective_from_sort) — composite

**`codex_progression_events`:**
- `idx_codex_progression_events_subject` (subject_entity_id)
- `idx_codex_progression_events_series` (series_id)
- `idx_codex_progression_events_book` (book_id)
- `idx_codex_progression_events_chapter` (chapter_id)
- `idx_codex_progression_events_type` (event_type)
- `idx_codex_progression_events_canon` (canon_status)
- `idx_codex_progression_events_source` (source_entity_id)
- `idx_codex_progression_events_subject_series` (subject_entity_id, series_id, created_at) — composite

**`codex_entity_field_definitions`:**
- `idx_codex_entity_field_defs_type` (entity_type_key)
- `idx_codex_entity_field_defs_group` (entity_type_key, group_name) — composite

**`codex_entity_field_values`:**
- `idx_codex_entity_field_values_entity` (entity_id)
- `idx_codex_entity_field_values_def` (field_definition_id)
- `idx_codex_entity_field_values_linked` (linked_entity_id)
- `idx_codex_entity_field_values_canon` (canon_status)
- `idx_codex_entity_field_values_entity_def` (entity_id, field_definition_id) — composite

**`codex_connections` (new):**
- `idx_codex_connections_book_id` (book_id)
- `idx_codex_connections_chapter_id` (chapter_id)
- `idx_codex_connections_valid_from` (valid_from_sort)
- `idx_codex_connections_context_status` (context_status)

**Total: 30 new indexes**

### Foreign Keys

| Table | Column | References | On Delete |
|-------|--------|------------|-----------|
| `codex_entity_appearances` | entity_id | codex_entities(id) | CASCADE |
| `codex_entity_appearances` | series_id | series(id) | CASCADE |
| `codex_entity_appearances` | book_id | projects(id) | CASCADE |
| `codex_entity_appearances` | chapter_id | document_sections(id) | SET NULL |
| `codex_entity_state` | subject_entity_id | codex_entities(id) | CASCADE |
| `codex_entity_state` | property_entity_id | codex_entities(id) | SET NULL |
| `codex_entity_state` | series_id | series(id) | CASCADE |
| `codex_entity_state` | book_id | projects(id) | SET NULL |
| `codex_entity_state` | chapter_id | document_sections(id) | SET NULL |
| `codex_progression_events` | subject_entity_id | codex_entities(id) | CASCADE |
| `codex_progression_events` | property_entity_id | codex_entities(id) | SET NULL |
| `codex_progression_events` | series_id | series(id) | CASCADE |
| `codex_progression_events` | book_id | projects(id) | SET NULL |
| `codex_progression_events` | chapter_id | document_sections(id) | SET NULL |
| `codex_progression_events` | source_entity_id | codex_entities(id) | SET NULL |
| `codex_entity_field_definitions` | relationship_type_id | codex_relationship_types(id) | SET NULL |
| `codex_entity_field_values` | entity_id | codex_entities(id) | CASCADE |
| `codex_entity_field_values` | field_definition_id | codex_entity_field_definitions(id) | CASCADE |
| `codex_entity_field_values` | linked_entity_id | codex_entities(id) | SET NULL |
| `codex_connections` (new) | book_id | projects(id) | SET NULL |
| `codex_connections` (new) | chapter_id | document_sections(id) | SET NULL |

**Total: 21 new foreign keys**

### Constraints

| Table | Constraint | Type | Definition |
|-------|------------|------|------------|
| `codex_entity_field_definitions` | unique_entity_type_field | UNIQUE | (entity_type_key, field_key) |
| `codex_entity_field_values` | unique_entity_field | UNIQUE | (entity_id, field_definition_id) |

### Triggers

| Table | Trigger | Function | Purpose |
|-------|---------|----------|---------|
| `codex_entity_appearances` | trg_codex_entity_appearances_updated_at | Auto-update updated_at | Timestamp tracking |
| `codex_entity_state` | trg_codex_entity_state_updated_at | Auto-update updated_at | Timestamp tracking |
| `codex_entity_field_definitions` | trg_codex_entity_field_definitions_updated_at | Auto-update updated_at | Timestamp tracking |
| `codex_entity_field_values` | trg_codex_entity_field_values_updated_at | Auto-update updated_at | Timestamp tracking |

### RLS Policies

All 5 new tables have:
```sql
ALTER TABLE <table> ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON <table>
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
```

This matches the existing pattern used by all 19 previous codex tables.

### Migrations

| File | Purpose |
|------|---------|
| `20260905_phase0_inventory.sql` | Pre-migration snapshot queries |
| `20260905_extend_codex_connections_context.sql` | Add 7 columns + 4 indexes to connections |
| `20260905_create_codex_entity_appearances.sql` | New table + 6 indexes + trigger + RLS |
| `20260905_create_codex_entity_state.sql` | New table + 9 indexes + trigger + RLS |
| `20260905_create_codex_progression_events.sql` | New table + 8 indexes + RLS |
| `20260905_create_codex_entity_field_definitions.sql` | New table + 2 indexes + trigger + RLS |
| `20260905_create_codex_entity_field_values.sql` | New table + 5 indexes + trigger + RLS |
| `20260905_seed_entity_field_definitions.sql` | Seed 75 field definitions for 11 entity types |
| `20260905_phase4_backfill_appearances.sql` | Backfill appearances from entity_projects |
| `20260905_phase6_deprecation_audit.sql` | Audit queries for entity type usage |

---

## 3. Existing Database Impact

### Tables Left Untouched

All 19 existing codex tables remain unchanged:
- `codex_entity_types`
- `codex_entities`
- `codex_entity_projects`
- `codex_relationship_types`
- `codex_tags`
- `codex_entity_tags`
- `codex_entity_revisions`
- `codex_calendars`
- `codex_events`
- `codex_event_entities`
- `codex_timelines`
- `codex_timeline_events`
- `codex_content_assets`
- `codex_embeddings`
- `codex_mentions`
- `codex_ai_suggestions`
- `codex_continuity_findings`
- `codex_format_presets`

### Tables Modified

- `codex_connections` — 7 nullable columns added, 4 indexes added. **No existing data affected.**

### Data Migrated

- **Appearances backfill**: Available via SQL script or UI button. Creates `codex_entity_appearances` records from existing `codex_entity_projects` links.
- **No other data migrated.** State, events, and field values start empty.

### Data Transformed

None. All existing data remains in its original form.

### Deprecated Structures

None deprecated. The `relationship` entity type, `equipment` entity type, and other overlaps remain active. Deprecation audit tools are available but no deprecation actions were taken.

### Potentially Destructive Changes

**None.** All changes are additive. The `IF NOT EXISTS` clauses ensure idempotent migrations.

### Existing Codex Data Integrity

**Confirmed intact.** The implementation:
- Only adds new nullable columns to `codex_connections`
- Only creates new tables (no modifications to existing tables)
- Uses `ON DELETE CASCADE` / `ON DELETE SET NULL` for referential integrity
- Does not modify, move, or transform any existing data

---

## 4. Entity System

### Entity Types

**No changes to entity types.** All 49 entity types remain as seeded in previous migrations. No types were added, removed, or modified.

### Entity Definitions

The `codex_entity_types` table was not modified. Entity type definitions (key, name_singular, name_plural, icon, etc.) remain unchanged.

### Entity-Specific Fields

**NEW**: Schema-driven field definitions via `codex_entity_field_definitions` table. Field definitions are seeded for 11 entity types:

| Entity Type | Fields Defined | Groups |
|-------------|----------------|--------|
| character | 12 | Identity, Physical, Personality, Psychology |
| location | 6 | Geography, Demographics, Politics, Features, Economy |
| organisation | 6 | Identity, History, Structure, Motivation, Power |
| item | 6 | Physical, Properties, Magical, Lore |
| magic_system | 6 | Fundamentals, Mechanics, Classification, Related |
| species | 6 | Biology, Society, Powers |
| religion | 6 | Core, Beliefs, Practices, Structure, Related, Calendar |
| government | 6 | Structure, Leadership, Legal, Power, Economy, Diplomacy |
| creature | 6 | Biology, Powers, Interaction |
| quest | 6 | Details, Constraints, Challenges, Impact |
| lore | 5 | Context, Connections, Significance |
| story_thread | 3 | Classification, Dynamics |

**Total: 75 field definitions seeded**

### Custom Sections

**Unchanged.** The existing `CODEX_DETAIL_SECTIONS` system (Physical Description, Personality Summary, Traits, etc.) continues to work via `custom_data.sections` on `codex_entities`.

### Presets

**Unchanged.** The preset system (all_types, standard_fantasy, litrpg, contemporary) continues to work. Presets only control visibility of entity types in the tree, not field definitions.

### Entity Scope

**Unchanged.** Entity scope (series/wiki/book) continues to work via `codex_entities.scope` and `codex_entity_projects`.

### Canon Status

**Unchanged.** The existing canon_status field on `codex_entities` (draft/provisional/canon/deprecated) continues to work. New v2 tables also use canon_status for state and events.

### Images/Assets

**Unchanged.** Entity images continue to work via `codex_entities.image_url`.

---

## 5. Relationship System

### codex_connections

**Extended** with 7 new nullable columns:
- `book_id` — Book-level context
- `chapter_id` — Chapter-level context
- `valid_from_sort` — Narrative ordering start
- `valid_to_sort` — Narrative ordering end
- `context_status` — active/ended/planned
- `notes` — Human notes
- `created_source` — manual/import/AI/migration

**All existing columns unchanged.** Existing connections continue to work with NULL values for new columns.

### Relationship Types

**Unchanged.** The `codex_relationship_types` table and its 14 seeded types remain as-is.

### Entity-to-Entity Relationships

**Unchanged.** The core relationship mechanism (source_entity_id → target_entity_id with relationship_type_id) continues to work.

### Book Context

**NEW**: Connections can now be associated with a specific book via `book_id`. The relationship edit form includes a book dropdown (filtered to current series).

### Chapter Context

**Schema ready, UI not implemented.** The `chapter_id` column exists but no UI exposes chapter selection for connections.

### Temporal Relationships

**Schema ready, UI not implemented.** The `valid_from_sort`/`valid_to_sort` columns exist but no UI or query logic uses them.

### Relationship Metadata

**Partial.** The `notes` and `context_status` columns exist but are not exposed in the relationship edit form. Only `book_id` is editable.

### Previous `relationship` Entity Type

**Not deprecated.** The `relationship` entity type remains active. The deprecation audit tool can measure its usage, but no action was taken.

---

## 6. Book & Chapter Integration

### Series

**Unchanged.** Entities remain linked to series via `codex_entities.series_id`.

### Books

**NEW**: Entity appearances in books tracked via `codex_entity_appearances.book_id` (references `projects.id`).

### Chapters

**Schema ready, UI not implemented.** The `chapter_id` column exists on appearances, state, and events tables (references `document_sections.id`), but no UI exposes chapter-level selection.

### Entity Appearances

**Implemented.** The `codex_entity_appearances` table tracks:
- Which entity appears
- In which book (required)
- In which chapter (optional, not yet in UI)
- Appearance type: appears, mentioned, POV, introduced, flashback, dies, returns, other
- Notes and source provenance

### Mentions

**Unchanged.** The existing `codex_mentions` table (text-matching in documents) continues to work independently of the new appearances system.

### Introductions

**Partially implemented.** The `appearance_type` field supports "introduced" as a value, but no UI specifically tracks introductions.

### POV Appearances

**Partially implemented.** The `appearance_type` field supports "pov" as a value, but no UI specifically tracks POV appearances.

### Book-Specific State

**Implemented.** The `codex_entity_state` table supports book_id and chapter_id context for state records.

---

## 7. State & Progression System

### How State is Stored

The `codex_entity_state` table stores:
- `subject_entity_id` — The entity (e.g., Patrick)
- `property_entity_id` — Optional definition entity (e.g., Strength stat)
- `property_key` — Optional scalar key (e.g., "class")
- `value_number` — Numeric value
- `value_text` — Text value
- `value_json` — Complex value
- `book_id` / `chapter_id` — Narrative context
- `effective_from_sort` / `effective_to_sort` — Temporal bounds
- `state_status` — draft/provisional/canon/deprecated

### Examples

**Character level:**
```
subject: Patrick, property_key: "level", value_number: 5, book: Book 2
```

**Stats:**
```
subject: Patrick, property_entity: Strength, value_number: 18, book: Book 1, chapter: Ch 10
```

**Skills:**
```
subject: Patrick, property_entity: Fireball, value_text: "Rank 4", book: Book 2, chapter: Ch 7
```

**Equipment:**
```
subject: Patrick, property_entity: Goblin Sword, value_text: "equipped_main_hand", book: Book 1
```

**Inventory:**
```
subject: Patrick, property_entity: Health Potion, value_number: 3, book: Book 1
```

**Achievements:**
```
subject: Patrick, property_key: "title", value_text: "Dragon Slayer", book: Book 2
```

**Resources:**
```
subject: Patrick, property_key: "gold", value_number: 423, book: Book 1, chapter: Ch 15
```

### Historical State Query

**Not fully implemented.** The schema supports querying state at a specific book/chapter via `effective_from_sort` and `effective_to_sort`, but no UI or query function implements this. The State tab currently shows a flat list of all state records for an entity.

---

## 8. LitRPG Implementation

### Definition vs Character-Specific State

**Schema supports separation, not yet populated.**

**Skill definition (entity):**
```
codex_entities: { name: "Fireball", entity_type_key: "skill_ability" }
```

**Character-specific state (state record):**
```
codex_entity_state: {
  subject_entity_id: Patrick,
  property_entity_id: Fireball,
  value_text: "Rank 4",
  book_id: Book 2,
  chapter_id: Ch 7
}
```

### Current Status

- The schema correctly separates definitions from character-specific state
- No LitRPG-specific state data has been created yet
- The dual-write system only creates generic `entity_updated` events, not specific stat/skill changes
- No specialized LitRPG UI exists (level-up animations, stat sheets, etc.)

---

## 9. UI Changes

### Codex Detail Panel

**3 new tabs added:**

| Tab | Content | Editable |
|-----|---------|----------|
| Appearances | List of books where entity appears | Read-only (backfill available) |
| State | List of state records and progression events | Read-only |
| Details | Schema-driven fields (text, number, select, textarea, checkbox) | Read-write with Save button |

### Relationships Panel

**Enhanced:**
- Connections now show book title when `book_id` is set
- Connection edit form includes book dropdown (filtered to current series)

### Progression

**Read-only display** of `codex_progression_events` in the State tab.

### Appearances

**Read-only display** of `codex_entity_appearances` with:
- Book title lookup from `appState.projects`
- Series name display
- "Backfill from Books" button to populate from existing entity_projects

### Book Selector

**Added to connection edit form.** Dropdown shows books from current series only.

### Chapter Selector

**Not implemented.** No UI exposes chapter selection.

### State History

**Basic implementation.** The State tab shows a flat list of all state records and events for an entity. No timeline visualization.

### Entity-Specific Panels

**Character**: Existing panels (Role, Archetype, Motivation) unchanged. New schema-driven fields in Details tab.
**Location**: Existing Parent Location panel unchanged. New schema-driven fields in Details tab.
**All other types**: Only schema-driven fields in Details tab (where defined).

---

## 10. Schema-Driven Entity Fields

### Implementation

**Implemented via `codex_entity_field_definitions` and `codex_entity_field_values` tables.**

Field definitions are stored in the database and rendered generically in the UI. Supported field types:
- `text` — Single-line input
- `long_text` — Textarea
- `number` — Numeric input
- `boolean` — Checkbox
- `select` — Dropdown (options from `options_json`)

### Examples

**Character:**
- Age (text, group: Identity)
- Gender (text, group: Identity)
- Height (text, group: Physical)
- Personality Traits (long_text, group: Personality)
- Fears (long_text, group: Psychology)

**Location:**
- Climate (text, group: Geography)
- Terrain (text, group: Geography)
- Population (text, group: Demographics)

**Species:**
- Lifespan (text, group: Biology)
- Habitat (text, group: Biology)
- Abilities (long_text, group: Powers)

**Religion:**
- Deity (text, group: Core)
- Tenets (long_text, group: Beliefs)
- Worship Practices (long_text, group: Practices)

**Magic System:**
- Source (text, group: Fundamentals)
- Cost/Limitation (long_text, group: Fundamentals)
- Rules (long_text, group: Mechanics)

**Item:**
- Material (text, group: Physical)
- Rarity (select: Common/Uncommon/Rare/Epic/Legendary/Unique)
- Powers (long_text, group: Magical)

### Adding New Entity Type Fields

**No frontend code changes required.** To add fields for a new entity type:
1. Insert rows into `codex_entity_field_definitions` with the entity_type_key
2. The Details tab automatically renders fields for any entity type with definitions

---

## 11. Story & Continuity Features

### Story Threads

**Field definitions seeded.** Thread Type, Tension Level, Resolution Status fields available via schema-driven system.

### Mysteries

**No specific implementation.** The `mystery` entity type exists but has no custom field definitions.

### Foreshadowing

**No specific implementation.** The `foreshadowing` entity type exists but has no custom field definitions.

### Setups/Payoffs

**No specific implementation.** The `setup_payoff` entity type exists but has no custom field definitions.

### Open Threads

**Not implemented.** No dedicated tracking for open/unresolved threads.

### Continuity Notes

**Unchanged.** The existing `continuity_note` entity type and `codex_continuity_findings` table continue to work.

### Canon Evidence

**Not implemented.** No dedicated canon evidence tracking beyond the existing `canon_status` field.

### Timeline/State History

**Basic implementation.** State records and progression events are stored with book/chapter context, but no timeline visualization exists.

---

## 12. Migration & Backwards Compatibility

### Migration Sequence

1. **Phase 0**: Inventory script (manual SQL)
2. **Phase 1**: Additive schema (8 migration files, applied to Supabase)
3. **Phase 2**: Read-only UI tabs (code changes only)
4. **Phase 3**: Dual-write behind feature flag (code changes only)
5. **Phase 4**: Backfill appearances (SQL script + UI button)
6. **Phase 5**: Enhanced relationships (code changes only)
7. **Phase 6**: Deprecation audit (SQL script + JS function)

### Data Backfills

- **Appearances**: Backfill script available (`20260905_phase4_backfill_appearances.sql` or "Backfill from Books" button)
- **State/Events**: Not backfilled (start empty)

### Feature Flags

- `CODEX_V2_DUAL_WRITE = true` (hardcoded in `scripts/constants.html`)
- Controls whether dual-write functions execute
- No UI toggle

### Dual-Write Behavior

When `CODEX_V2_DUAL_WRITE` is true:
- Entity save → creates appearance records for project links + `entity_updated` event
- Connection save → populates `book_id` context if provided
- All dual-write is fire-and-forget with error logging

### Deprecated Features

**None.** All existing features remain active.

### Rollback Capability

**Full rollback possible.** Since all changes are additive:
1. Drop the 5 new tables
2. Remove the 7 new columns from `codex_connections`
3. Remove the code changes

No existing data would be affected.

---

## 13. Testing

### Tests Performed

| Test | Result |
|------|--------|
| Existing project loading | ✅ Pass |
| Entity creation/editing | ✅ Pass |
| Relationship creation | ✅ Pass |
| Book context on connections | ✅ Pass |
| Appearances tab display | ✅ Pass |
| State tab display | ✅ Pass |
| Details tab display | ✅ Pass |
| Details tab save | ✅ Pass |
| Backfill from Books button | ✅ Pass |
| Deprecation audit (JS) | ✅ Pass |
| Existing test suite (50 tests) | ✅ Pass |
| Build + syntax check | ✅ Pass |

### Test Failures

**Initial seed migration failure**: The `20260905_seed_entity_field_definitions.sql` had a column count mismatch error (Lore and Story Thread INSERTs had `options_json` values but the column list didn't include `options_json`). Fixed in commit `a2b587c`.

**Console access issue**: The `codexV2DeprecationAudit` function was not accessible from browser console due to script scope issues. Fixed by exposing functions on `window` object in commit `4e52a90`.

---

## 14. Known Issues

### Bugs

1. **Dual-write only fires on entity save, not on individual property changes.** If a user changes only the status or canon_status, a generic `entity_updated` event is created rather than a specific state change record.

2. **Details tab does not show field values for entity_link fields.** The `linked_entity_id` field type is defined in the schema but not rendered in the UI.

### Limitations

1. **Chapter-level context not exposed in UI.** The `chapter_id` columns exist on appearances, state, events, and connections, but no UI allows selecting a chapter.

2. **No temporal relationship queries.** The `valid_from_sort`/`valid_to_sort` columns exist but no UI queries relationships by narrative point.

3. **No state history visualization.** The State tab shows a flat list, not a timeline or chart.

4. **Only 11 of 49 entity types have field definitions.** The remaining 38 types show "No field definitions for this entity type" in the Details tab.

5. **No multi_select, entity_link, image, url, or rich_text field types rendered.** The schema supports these types but the UI only renders text, long_text, number, boolean, and select.

6. **No field validation.** Required fields are defined in the schema but not enforced in the UI.

7. **No field grouping in UI beyond group_name.** Fields are grouped by `group_name` but there's no collapsible sections or tab-based organization.

### Technical Debt

1. **Hardcoded feature flag.** `CODEX_V2_DUAL_WRITE` should be a user-facing toggle or environment variable.

2. **No error recovery for dual-write failures.** Dual-write is fire-and-forget; failures are logged but not retried.

3. **Backfill is not idempotent.** Running the backfill multiple times could create duplicate records (the SQL script handles this with `NOT EXISTS` check, but the JS function does not).

4. **No pagination for large datasets.** All queries use `.limit(500)` or `.limit(200)` which may not be sufficient for large series.

### Temporary Implementations

1. **Debug logging removed.** Temporary console.log statements were added during development and removed in commit `dd58835`.

### Unfinished Work

1. **Phase 7 (Optional cleanup)** not started. Deprecation audit tools exist but no deprecation actions were taken.

2. **No UI for creating/editing field definitions.** Field definitions can only be added via SQL migrations.

3. **No UI for managing appearances manually.** Users can only backfill from entity_projects; there's no manual "Add Appearance" form.

### Performance Concerns

1. **No caching for field definitions.** Each Details tab load queries `codex_entity_field_definitions` from Supabase.

2. **No caching for field values.** Each Details tab load queries `codex_entity_field_values` from Supabase.

3. **Dual-write adds 2-3 extra Supabase calls per entity save.** This could slow down saves for users with many project links.

### Migration Concerns

1. **Backfill requires manual trigger.** Users must either run the SQL script or click "Backfill from Books" to populate appearances.

2. **No migration for existing relationship entity data.** The `relationship` entity type remains active; no data was migrated to `codex_connections`.

---

## 15. Files Changed

### Application Files Modified

| File | Changes |
|------|---------|
| `scripts/constants.html` | Added `CODEX_V2_DUAL_WRITE = true` feature flag |
| `scripts/supabase-codex.html` | Added 18 new Supabase CRUD functions for v2 tables + `updateCodexConnectionContext` |
| `scripts/series-knowledge.html` | Added Appearances/State/Details tabs, enhanced relationships, backfill button, field editor |
| `Client.html` | Added `<?!= include('scripts/codex-v2-dual-write'); ?>` include |

### New Files

| File | Purpose |
|------|---------|
| `scripts/codex-v2-dual-write.html` | Dual-write helper functions (235 lines) |
| `.opencode/plans/codex-categories-audit.md` | Entity type audit document |
| `.opencode/plans/codex-v2-phase-0-1.md` | Phase 0-1 implementation plan |
| `.opencode/plans/codex-v2-post-implementation-audit.md` | This audit document |

### Database Migrations

| File | Lines | Purpose |
|------|-------|---------|
| `20260905_phase0_inventory.sql` | 94 | Pre-migration snapshot |
| `20260905_extend_codex_connections_context.sql` | 34 | Extend connections table |
| `20260905_create_codex_entity_appearances.sql` | 52 | New appearances table |
| `20260905_create_codex_entity_state.sql` | 72 | New state table |
| `20260905_create_codex_progression_events.sql` | 52 | New events table |
| `20260905_create_codex_entity_field_definitions.sql` | 54 | New field definitions table |
| `20260905_create_codex_entity_field_values.sql` | 58 | New field values table |
| `20260905_seed_entity_field_definitions.sql` | 125 | Seed 75 field definitions |
| `20260905_phase4_backfill_appearances.sql` | 40 | Backfill appearances |
| `20260905_phase6_deprecation_audit.sql` | 83 | Deprecation audit queries |

### Supabase Functions Added

| Function | Table | Operation |
|----------|-------|-----------|
| `listCodexEntityAppearances` | codex_entity_appearances | SELECT |
| `saveCodexEntityAppearance` | codex_entity_appearances | INSERT/UPDATE |
| `deleteCodexEntityAppearance` | codex_entity_appearances | DELETE |
| `listCodexEntityState` | codex_entity_state | SELECT |
| `saveCodexEntityState` | codex_entity_state | INSERT/UPDATE |
| `deleteCodexEntityState` | codex_entity_state | DELETE |
| `listCodexProgressionEvents` | codex_progression_events | SELECT |
| `saveCodexProgressionEvent` | codex_progression_events | INSERT/UPDATE |
| `deleteCodexProgressionEvent` | codex_progression_events | DELETE |
| `listCodexEntityFieldDefinitions` | codex_entity_field_definitions | SELECT |
| `saveCodexEntityFieldDefinition` | codex_entity_field_definitions | INSERT/UPDATE |
| `deleteCodexEntityFieldDefinition` | codex_entity_field_definitions | DELETE |
| `listCodexEntityFieldValues` | codex_entity_field_values | SELECT |
| `saveCodexEntityFieldValue` | codex_entity_field_values | INSERT/UPDATE |
| `deleteCodexEntityFieldValue` | codex_entity_field_values | DELETE |
| `updateCodexConnectionContext` | codex_connections | UPDATE |

---

## 16. Specification Compliance Matrix

| Requirement | Status | Implementation | Notes |
|-------------|--------|----------------|-------|
| Extend codex_connections with context/temporal fields | COMPLETE | 7 columns added | All nullable, backward compatible |
| Create codex_entity_appearances table | COMPLETE | New table with 6 indexes | Supports book/chapter tracking |
| Create codex_entity_state table | COMPLETE | New table with 9 indexes | Generic time-aware state layer |
| Create codex_progression_events table | COMPLETE | New table with 8 indexes | Change history tracking |
| Create codex_entity_field_definitions table | COMPLETE | New table with 2 indexes | Schema-driven fields |
| Create codex_entity_field_values table | COMPLETE | New table with 5 indexes | Field values for entities |
| Seed field definitions | PARTIAL | 75 definitions for 11 types | 38 types have no definitions |
| Backfill appearances from entity_projects | COMPLETE | SQL script + UI button | Only unambiguous data |
| Dual-write behind feature flag | COMPLETE | Fire-and-forget with error logging | Hardcoded flag |
| Appearances tab UI | COMPLETE | Read-only list with book titles | No manual add |
| State tab UI | PARTIAL | Flat list of state + events | No history visualization |
| Details tab UI | COMPLETE | Editable schema-driven fields | text/number/boolean/select only |
| Relationships with book context | PARTIAL | Book dropdown in edit form | No chapter, no metadata |
| Deprecation audit tools | COMPLETE | SQL script + JS function | No deprecation actions taken |
| Feature flag toggle | NOT IMPLEMENTED | Hardcoded true | No UI toggle |
| Chapter-level context | NOT IMPLEMENTED | Columns exist, no UI | Schema ready |
| Temporal relationship queries | NOT IMPLEMENTED | Columns exist, no UI | Schema ready |
| State history visualization | NOT IMPLEMENTED | Flat list only | No timeline view |
| Inventory/Equipment view | NOT IMPLEMENTED | — | No specialized view |
| Relationship metadata editing | NOT IMPLEMENTED | Only book_id exposed | Notes/status not editable |
| Entity_link field type | NOT IMPLEMENTED | Schema supports, no UI | linked_entity_id exists |
| Multi_select field type | NOT IMPLEMENTED | Schema supports, no UI | options_json exists |
| Rich_text field type | NOT IMPLEMENTED | Schema supports, no UI | — |
| Field validation (required) | NOT IMPLEMENTED | Schema defines, no enforcement | — |
| Backfill state/events | NOT IMPLEMENTED | Only appearances backfilled | — |

---

## 17. Final Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        UI LAYER                             │
├─────────────────────────────────────────────────────────────┤
│  Entity Detail Page                                         │
│  ├── Description Tab (existing)                             │
│  ├── Backstory Tab (existing)                               │
│  ├── History Tab (existing)                                 │
│  ├── Appearances Tab (NEW - reads codex_entity_appearances) │
│  ├── State Tab (NEW - reads codex_entity_state + events)    │
│  └── Details Tab (NEW - reads/writes field values)          │
│                                                             │
│  Relationships Panel (enhanced with book context)           │
│  Codex Tree (unchanged)                                     │
│  Preset Editor (unchanged)                                  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                     DUAL-WRITE LAYER                        │
├─────────────────────────────────────────────────────────────┤
│  codex-v2-dual-write.html                                   │
│  ├── codexV2RecordAppearance()                              │
│  ├── codexV2RecordState()                                   │
│  ├── codexV2RecordEvent()                                   │
│  ├── codexV2UpdateConnectionContext()                       │
│  ├── codexV2BackfillAppearances()                           │
│  └── codexV2DeprecationAudit()                              │
│                                                             │
│  Controlled by: CODEX_V2_DUAL_WRITE (hardcoded true)        │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                  SUPABASE CRUD LAYER                        │
├─────────────────────────────────────────────────────────────┤
│  16 new _sbDefine functions in supabase-codex.html          │
│  ├── Appearances: list/save/delete                          │
│  ├── State: list/save/delete                                │
│  ├── Events: list/save/delete                               │
│  ├── Field Definitions: list/save/delete                    │
│  ├── Field Values: list/save/delete                         │
│  └── Connection Context: update                             │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                     DATABASE LAYER                          │
├─────────────────────────────────────────────────────────────┤
│  EXISTING (unchanged):                                      │
│  ├── codex_entities (49 entity types)                       │
│  ├── codex_entity_projects (book assignments)               │
│  ├── codex_relationship_types (14 types)                    │
│  ├── codex_connections (+ 7 new columns)                    │
│  └── 15 other codex tables                                  │
│                                                             │
│  NEW:                                                       │
│  ├── codex_entity_appearances (book/chapter presence)       │
│  ├── codex_entity_state (time-aware state)                  │
│  ├── codex_progression_events (change history)              │
│  ├── codex_entity_field_definitions (75 seeded)             │
│  └── codex_entity_field_values (empty, user-populated)      │
│                                                             │
│  RLS: All tables use "Authenticated full access" policy     │
└─────────────────────────────────────────────────────────────┘
```

---

## Summary

The Master Codex v2 implementation successfully added an additive layer to the existing Codex system without breaking any existing functionality. The core data model (entities, connections, presets, scopes) remains unchanged, while new tables provide the foundation for appearances, state tracking, progression events, and schema-driven fields.

**Key achievements:**
- 5 new tables with 30 indexes and 21 foreign keys
- 16 new Supabase CRUD functions
- 3 new UI tabs (Appearances, State, Details)
- Schema-driven entity fields for 11 entity types
- Dual-write system with feature flag
- Backfill and deprecation audit tools
- Zero breaking changes to existing functionality

**Key gaps:**
- Chapter-level context not exposed in UI
- No temporal relationship queries
- No state history visualization
- Only 11/49 entity types have field definitions
- Limited field type rendering (text/number/boolean/select only)
- No feature flag UI toggle
