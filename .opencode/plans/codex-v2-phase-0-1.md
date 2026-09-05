# Master Codex v2 — Phase 0 & 1 Implementation Plan

## Phase 0: Backup and Inventory

### 0.1 Database Backup
- [ ] Create Supabase database snapshot (manual step in Supabase dashboard)
- [ ] Document current row counts for all 19 codex tables
- [ ] Export current schema definitions (table/column/index/RLS)

### 0.2 Code Inventory
- [ ] Document all code paths that write to `codex_connections`
- [ ] Document all code paths that write to `codex_entities`
- [ ] Document all code paths that use `relationship` entity type
- [ ] Document all code paths that use `equipment` entity type
- [ ] Document all code paths that use `quest` vs `story_thread`

### 0.3 Staging Validation
- [ ] Verify Patrick's Part-Time Universe data exists and is complete
- [ ] Record baseline entity/connection counts for Patrick's series
- [ ] Verify existing Codex pages work without errors

---

## Phase 1: Additive Schema Only

### 1.1 Extend `codex_connections` (ALTER TABLE)

**File:** `migrations/20260905_extend_codex_connections_context.sql`

Add nullable columns to existing `codex_connections` table:

```sql
ALTER TABLE codex_connections
  ADD COLUMN IF NOT EXISTS book_id BIGINT REFERENCES projects(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS chapter_id BIGINT REFERENCES document_sections(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS valid_from_sort NUMERIC,
  ADD COLUMN IF NOT EXISTS valid_to_sort NUMERIC,
  ADD COLUMN IF NOT EXISTS context_status TEXT DEFAULT 'active',
  ADD COLUMN IF NOT EXISTS notes TEXT,
  ADD COLUMN IF NOT EXISTS created_source TEXT DEFAULT 'manual';

-- Indexes for new query paths
CREATE INDEX IF NOT EXISTS idx_codex_connections_book_id ON codex_connections(book_id);
CREATE INDEX IF NOT EXISTS idx_codex_connections_chapter_id ON codex_connections(chapter_id);
CREATE INDEX IF NOT EXISTS idx_codex_connections_valid_from ON codex_connections(valid_from_sort);
CREATE INDEX IF NOT EXISTS idx_codex_connections_context_status ON codex_connections(context_status);
```

**Rationale:** The spec says to keep `codex_connections` as the universal graph edge. Adding `book_id` and `chapter_id` allows relationships to be scoped to specific narrative points without creating a separate table. `valid_from_sort` and `valid_to_sort` use `document_sections.sort_order` as the narrative ordering anchor.

**Impact:** Existing code is unaffected — all new columns are nullable. Existing connections continue to work with `book_id = NULL` and `chapter_id = NULL`.

### 1.2 Create `codex_entity_appearances` (NEW TABLE)

**File:** `migrations/20260905_create_codex_entity_appearances.sql`

```sql
CREATE TABLE IF NOT EXISTS codex_entity_appearances (
  id BIGSERIAL PRIMARY KEY,
  entity_id BIGINT NOT NULL REFERENCES codex_entities(id) ON DELETE CASCADE,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  book_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  chapter_id BIGINT REFERENCES document_sections(id) ON DELETE SET NULL,
  appearance_type TEXT NOT NULL DEFAULT 'appears',
  notes TEXT,
  source TEXT DEFAULT 'manual',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_codex_entity_appearances_entity ON codex_entity_appearances(entity_id);
CREATE INDEX IF NOT EXISTS idx_codex_entity_appearances_series ON codex_entity_appearances(series_id);
CREATE INDEX IF NOT EXISTS idx_codex_entity_appearances_book ON codex_entity_appearances(book_id);
CREATE INDEX IF NOT EXISTS idx_codex_entity_appearances_chapter ON codex_entity_appearances(chapter_id);

-- RLS (match existing pattern)
ALTER TABLE codex_entity_appearances ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON codex_entity_appearances
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
```

**Rationale:** Separates "where does this entity appear" from "what is this entity's scope". A character may be series-scoped but only appear in specific books/chapters. This is different from `codex_entity_projects` (which is scope/ownership) and `codex_mentions` (which is text-matching in documents).

**Appearance types:** `appears`, `mentioned`, `pov`, `introduced`, `flashback`, `dies`, `returns`, `other`

### 1.3 Create `codex_entity_state` (NEW TABLE)

**File:** `migrations/20260905_create_codex_entity_state.sql`

```sql
CREATE TABLE IF NOT EXISTS codex_entity_state (
  id BIGSERIAL PRIMARY KEY,
  subject_entity_id BIGINT NOT NULL REFERENCES codex_entities(id) ON DELETE CASCADE,
  property_entity_id BIGINT REFERENCES codex_entities(id) ON DELETE SET NULL,
  property_key TEXT,
  value_number NUMERIC,
  value_text TEXT,
  value_json JSONB,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  book_id BIGINT REFERENCES projects(id) ON DELETE SET NULL,
  chapter_id BIGINT REFERENCES document_sections(id) ON DELETE SET NULL,
  effective_from_sort NUMERIC,
  effective_to_sort NUMERIC,
  state_status TEXT DEFAULT 'draft',
  source_reference TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_codex_entity_state_subject ON codex_entity_state(subject_entity_id);
CREATE INDEX IF NOT EXISTS idx_codex_entity_state_property_entity ON codex_entity_state(property_entity_id);
CREATE INDEX IF NOT EXISTS idx_codex_entity_state_series ON codex_entity_state(series_id);
CREATE INDEX IF NOT EXISTS idx_codex_entity_state_book ON codex_entity_state(book_id);
CREATE INDEX IF NOT EXISTS idx_codex_entity_state_chapter ON codex_entity_state(chapter_id);
CREATE INDEX IF NOT EXISTS idx_codex_entity_state_effective ON codex_entity_state(effective_from_sort);
CREATE INDEX IF NOT EXISTS idx_codex_entity_state_status ON codex_entity_state(state_status);

-- RLS
ALTER TABLE codex_entity_state ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON codex_entity_state
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
```

**Rationale:** Generic time-aware state layer. Supports LitRPG numeric progression AND non-LitRPG narrative state. `property_entity_id` links to a stat/skill/item definition entity; `property_key` is a scalar fallback when no entity exists. `value_number` for numeric stats, `value_text` for text/enum, `value_json` for complex values.

**Example usage:**
- Patrick's Strength = 8 at Book 1 Ch 1: `{subject: Patrick, property_entity: Strength, value_number: 8, book: B1, chapter: Ch1}`
- Patrick's class = Mage from B2 Ch3: `{subject: Patrick, property_key: "class", value_text: "Mage", book: B2, chapter: Ch3}`

### 1.4 Create `codex_progression_events` (NEW TABLE)

**File:** `migrations/20260905_create_codex_progression_events.sql`

```sql
CREATE TABLE IF NOT EXISTS codex_progression_events (
  id BIGSERIAL PRIMARY KEY,
  subject_entity_id BIGINT NOT NULL REFERENCES codex_entities(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  property_entity_id BIGINT REFERENCES codex_entities(id) ON DELETE SET NULL,
  old_value JSONB,
  new_value JSONB,
  delta NUMERIC,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  book_id BIGINT REFERENCES projects(id) ON DELETE SET NULL,
  chapter_id BIGINT REFERENCES document_sections(id) ON DELETE SET NULL,
  reason TEXT,
  source_entity_id BIGINT REFERENCES codex_entities(id) ON DELETE SET NULL,
  canon_status TEXT DEFAULT 'draft',
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_codex_progression_events_subject ON codex_progression_events(subject_entity_id);
CREATE INDEX IF NOT EXISTS idx_codex_progression_events_series ON codex_progression_events(series_id);
CREATE INDEX IF NOT EXISTS idx_codex_progression_events_book ON codex_progression_events(book_id);
CREATE INDEX IF NOT EXISTS idx_codex_progression_events_chapter ON codex_progression_events(chapter_id);
CREATE INDEX IF NOT EXISTS idx_codex_progression_events_type ON codex_progression_events(event_type);
CREATE INDEX IF NOT EXISTS idx_codex_progression_events_canon ON codex_progression_events(canon_status);

-- RLS
ALTER TABLE codex_progression_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON codex_progression_events
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
```

**Rationale:** State tells us what is true. Events tell us what changed and why. Essential for LitRPG auditability and continuity checks.

**Event types:** `level_up`, `skill_unlock`, `stat_change`, `item_acquired`, `item_lost`, `title_awarded`, `class_change`, `reputation_change`, `custom`

### 1.5 Create `codex_entity_field_definitions` (NEW TABLE)

**File:** `migrations/20260905_create_codex_entity_field_definitions.sql`

```sql
CREATE TABLE IF NOT EXISTS codex_entity_field_definitions (
  id BIGSERIAL PRIMARY KEY,
  entity_type_key TEXT NOT NULL,
  field_key TEXT NOT NULL,
  label TEXT NOT NULL,
  field_type TEXT NOT NULL DEFAULT 'text',
  group_name TEXT,
  sort_order INTEGER DEFAULT 0,
  required BOOLEAN DEFAULT FALSE,
  options_json JSONB,
  relationship_type_id BIGINT REFERENCES codex_relationship_types(id) ON DELETE SET NULL,
  help_text TEXT,
  preset_visibility JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(entity_type_key, field_key)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_codex_entity_field_defs_type ON codex_entity_field_definitions(entity_type_key);

-- RLS
ALTER TABLE codex_entity_field_definitions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON codex_entity_field_definitions
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
```

**Rationale:** Schema-driven field definitions instead of hard-coding 47 entity type panels. Define fields in data, render generically.

**Field types:** `text`, `long_text`, `number`, `boolean`, `date`, `select`, `multi_select`, `entity_link`, `entity_multi_link`, `image`, `url`, `rich_text`, `json`

### 1.6 Create `codex_entity_field_values` (NEW TABLE)

**File:** `migrations/20260905_create_codex_entity_field_values.sql`

```sql
CREATE TABLE IF NOT EXISTS codex_entity_field_values (
  id BIGSERIAL PRIMARY KEY,
  entity_id BIGINT NOT NULL REFERENCES codex_entities(id) ON DELETE CASCADE,
  field_definition_id BIGINT NOT NULL REFERENCES codex_entity_field_definitions(id) ON DELETE CASCADE,
  value_text TEXT,
  value_number NUMERIC,
  value_boolean BOOLEAN,
  value_json JSONB,
  linked_entity_id BIGINT REFERENCES codex_entities(id) ON DELETE SET NULL,
  canon_status TEXT DEFAULT 'draft',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(entity_id, field_definition_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_codex_entity_field_values_entity ON codex_entity_field_values(entity_id);
CREATE INDEX IF NOT EXISTS idx_codex_entity_field_values_def ON codex_entity_field_values(field_definition_id);
CREATE INDEX IF NOT EXISTS idx_codex_entity_field_values_linked ON codex_entity_field_values(linked_entity_id);

-- RLS
ALTER TABLE codex_entity_field_values ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON codex_entity_field_values
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
```

### 1.7 Seed Initial Field Definitions

**File:** `migrations/20260905_seed_entity_field_definitions.sql`

Seed field definitions for the most common entity types (Character, Location, Organisation, Item, Magic System):

```sql
-- Character fields
INSERT INTO codex_entity_field_definitions (entity_type_key, field_key, label, field_type, group_name, sort_order, help_text) VALUES
  ('character', 'age', 'Age', 'text', 'Identity', 10, 'Character age or age range'),
  ('character', 'gender', 'Gender', 'text', 'Identity', 20, 'Gender identity'),
  ('character', 'height', 'Height', 'text', 'Physical', 30, 'Physical height'),
  ('character', 'build', 'Build', 'text', 'Physical', 40, 'Body type/build'),
  ('character', 'hair', 'Hair', 'text', 'Physical', 50, 'Hair color/style'),
  ('character', 'eyes', 'Eyes', 'text', 'Physical', 60, 'Eye color'),
  ('character', 'notable_features', 'Notable Features', 'long_text', 'Physical', 70, 'Distinctive physical features'),
  ('character', 'personality_traits', 'Personality Traits', 'long_text', 'Personality', 80, 'Key personality characteristics'),
  ('character', 'speech_patterns', 'Speech Patterns', 'long_text', 'Personality', 90, 'How the character speaks'),
  ('character', 'fears', 'Fears', 'long_text', 'Psychology', 100, 'What the character fears'),
  ('character', 'desires', 'Desires', 'long_text', 'Psychology', 110, 'What the character wants'),
  ('character', 'secrets', 'Secrets', 'long_text', 'Psychology', 120, 'What the character hides')
ON CONFLICT (entity_type_key, field_key) DO NOTHING;

-- Location fields
INSERT INTO codex_entity_field_definitions (entity_type_key, field_key, label, field_type, group_name, sort_order, help_text) VALUES
  ('location', 'climate', 'Climate', 'text', 'Geography', 10, 'Climate/weather patterns'),
  ('location', 'terrain', 'Terrain', 'text', 'Geography', 20, 'Land type/terrain'),
  ('location', 'population', 'Population', 'text', 'Demographics', 30, 'Population size/type'),
  ('location', 'government', 'Government', 'text', 'Politics', 40, 'Local government type'),
  ('location', 'notable_landmarks', 'Notable Landmarks', 'long_text', 'Features', 50, 'Key landmarks and features'),
  ('location', 'resources', 'Resources', 'long_text', 'Economy', 60, 'Natural resources/trade goods')
ON CONFLICT (entity_type_key, field_key) DO NOTHING;

-- Organisation fields
INSERT INTO codex_entity_field_definitions (entity_type_key, field_key, label, field_type, group_name, sort_order, help_text) VALUES
  ('organisation', 'org_type', 'Type', 'select', 'Identity', 10, 'Organisation type', '{"options":["Guild","Faction","Government","Military","Religious","Criminal","Academic","Commercial","Other"]}'),
  ('organisation', 'founded', 'Founded', 'text', 'History', 20, 'When/how it was founded'),
  ('organisation', 'headquarters', 'Headquarters', 'text', 'Structure', 30, 'Main base of operations'),
  ('organisation', 'membership_size', 'Membership Size', 'text', 'Structure', 40, 'Number of members'),
  ('organisation', 'goals', 'Goals', 'long_text', 'Motivation', 50, 'Primary objectives'),
  ('organisation', 'resources', 'Resources', 'long_text', 'Power', 60, 'Available resources/power')
ON CONFLICT (entity_type_key, field_key) DO NOTHING;

-- Item fields
INSERT INTO codex_entity_field_definitions (entity_type_key, field_key, label, field_type, group_name, sort_order, help_text) VALUES
  ('item', 'material', 'Material', 'text', 'Physical', 10, 'Primary material(s)'),
  ('item', 'weight', 'Weight', 'text', 'Physical', 20, 'Weight/mass'),
  ('item', 'dimensions', 'Dimensions', 'text', 'Physical', 30, 'Size/shape'),
  ('item', 'rarity', 'Rarity', 'select', 'Properties', 40, 'How rare this item is', '{"options":["Common","Uncommon","Rare","Epic","Legendary","Unique"]}'),
  ('item', 'powers', 'Powers/Abilities', 'long_text', 'Magical', 50, 'Magical properties or abilities'),
  ('item', 'history', 'Item History', 'long_text', 'Lore', 60, 'Origin and history of the item')
ON CONFLICT (entity_type_key, field_key) DO NOTHING;

-- Magic System fields
INSERT INTO codex_entity_field_definitions (entity_type_key, field_key, label, field_type, group_name, sort_order, help_text) VALUES
  ('magic_system', 'source', 'Source', 'text', 'Fundamentals', 10, 'Where magic comes from'),
  ('magic_system', 'cost', 'Cost/Limitation', 'long_text', 'Fundamentals', 20, 'What using magic costs'),
  ('magic_system', 'rules', 'Rules', 'long_text', 'Mechanics', 30, 'Core rules of the system'),
  ('magic_system', 'training', 'Training', 'long_text', 'Mechanics', 40, 'How magic is learned/trained'),
  ('magic_system', 'types', 'Types/Categories', 'long_text', 'Classification', 50, 'Different types of magic'),
  ('magic_system', 'artifacts', 'Notable Artifacts', 'long_text', 'Related', 60, 'Important magical items')
ON CONFLICT (entity_type_key, field_key) DO NOTHING;
```

### 1.8 Add RLS to New Tables

Already included in each CREATE TABLE migration above (matching existing pattern).

---

## Phase 1 Summary

**New tables:** 5
- `codex_entity_appearances`
- `codex_entity_state`
- `codex_progression_events`
- `codex_entity_field_definitions`
- `codex_entity_field_values`

**Modified tables:** 1
- `codex_connections` (add 6 nullable columns + 4 indexes)

**New indexes:** 17 total across all new/modified tables

**RLS:** All new tables use same "Authenticated full access" policy

**Breaking changes:** None — all changes are additive

---

## Phase 1 File List

| File | Purpose |
|------|---------|
| `migrations/20260905_extend_codex_connections_context.sql` | Add context/temporal columns to connections |
| `migrations/20260905_create_codex_entity_appearances.sql` | New appearances table |
| `migrations/20260905_create_codex_entity_state.sql` | New state table |
| `migrations/20260905_create_codex_progression_events.sql` | New events table |
| `migrations/20260905_create_codex_entity_field_definitions.sql` | New field definitions table |
| `migrations/20260905_create_codex_entity_field_values.sql` | New field values table |
| `migrations/20260905_seed_entity_field_definitions.sql` | Seed initial field definitions |

---

## Phase 1 Acceptance Criteria

1. All existing projects open without migration errors
2. Existing Codex counts match pre-migration counts
3. Existing Character and Location detail panels behave exactly as before
4. Existing `codex_connections` are readable and editable after new columns are added
5. New tables are created and accessible via Supabase client
6. RLS prevents cross-user/project access on every new table
7. Patrick's Part-Time Universe data is unchanged

---

## Next Phase Preview (Phase 2: Read-only v2 Views)

Phase 2 will build UI tabs that read from the new tables:
- **Appearances tab** on entity detail page
- **State/Progression tab** on entity detail page
- **Schema-driven fields** rendered from `codex_entity_field_definitions`
- **Enhanced connections** with book/chapter context

Phase 2 will NOT change any write paths — existing UI remains authoritative for writes.
