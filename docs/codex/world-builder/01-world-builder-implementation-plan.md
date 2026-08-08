# CODEX World Builder — Implementation Plan

**Branch:** `feature/world-builder`  
**Baseline:** `v1.0` (tagged on `main`)  
**Status:** Approved for implementation  
**Last updated:** 2026-08-08

---

## Table of Contents

1. [Verified Current-State Findings](#1-verified-current-state-findings)
2. [Approved Decisions](#2-approved-decisions)
3. [Stage 0: Verification and Plan](#3-stage-0-verification-and-plan)
4. [Stage 1: Safety and Existing Wiring](#4-stage-1-safety-and-existing-wiring)
5. [Stage 2: Manual World Framework](#5-stage-2-manual-world-framework)
6. [Stage 3: Build Sessions and Extract-Only Assistance](#6-stage-3-build-sessions-and-extract-only-assistance)
7. [Stage 4: Proposal Review and CODEX Promotion](#7-stage-4-proposal-review-and-codex-promotion)
8. [Stage 5: Deeper Assistance](#8-stage-5-deeper-assistance)
9. [Stage 6: Semantic and Long-Term Intelligence](#9-stage-6-semantic-and-long-term-intelligence)
10. [Data Model Summary](#10-data-model-summary)
11. [AI Contract](#11-ai-contract)
12. [Risks and Unresolved Decisions](#12-risks-and-unresolved-decisions)

---

## 1. Verified Current-State Findings

All findings verified against the codebase at `v1.0`.

### 1.1 Status Fields

| Field | Type | Default | CHECK Constraint | JS Enums |
|---|---|---|---|---|
| `status` | TEXT | `'active'` | None | None |
| `visibility` | TEXT | `'private'` | None | None |
| `canon_status` | TEXT | `'draft'` | None | None |
| `scope` | TEXT | `'series'` | None | None |
| `spoiler_level` | TEXT | `'author_only'` | None | None |

**Source:** `migrations/20260604_create_codex_entities.sql:16-24`, `scripts/supabase-codex.html:91-97`

### 1.2 Entity Types

11 entity types defined in `codex_entity_types` table. 9 visible in sidebar via `CODEX_GROUP_TO_TYPE_KEY`.

| Key | Label | Icon | Sidebar Group | Sort |
|---|---|---|---|---|
| `character` | Character | `user` | characters | 10 |
| `location` | Location | `map-pin` | locations | 20 |
| `organisation` | Organisation | `building` | *(not wired)* | 30 |
| `family` | Family | `users` | *(not wired)* | 40 |
| `item` | Item | `box` | objects | 50 |
| `map` | Map | `map` | maps | 55 |
| `lore` | Lore | `book-open` | lore | 60 |
| `magic_system` | Magic System | `zap` | magic_systems | 65 |
| `quest` | Quest | `compass` | subplots | 70 |
| `journal` | Journal | `feather` | other | 80 |
| `continuity_note` | Continuity Note | `alert-triangle` | continuity | 90 |

**Source:** `migrations/20260604_create_codex_entity_types.sql:22-31`, `scripts/codex-view-models.html:175-185`

### 1.3 `codex_entity_revisions`

Schema exists. **ZERO JavaScript references.** Completely unused.

```sql
CREATE TABLE codex_entity_revisions (
  id BIGSERIAL PRIMARY KEY,
  entity_id BIGINT NOT NULL REFERENCES codex_entities(id) ON DELETE CASCADE,
  revision_number INTEGER NOT NULL,
  snapshot JSONB NOT NULL,
  change_summary TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

**Source:** `migrations/20260604_create_codex_revisions.sql`

### 1.4 Event/Calendar/Timeline System

Full chronology system exists in dedicated tables:

| Table | Purpose |
|---|---|
| `codex_calendars` | Calendar definitions per series |
| `codex_events` | In-world events |
| `codex_event_entities` | Junction: events ↔ entities |
| `codex_timelines` | Named timelines per series |
| `codex_timeline_events` | Junction: timelines ↔ events |

Has CRUD service (`supabase-codex.html:265-347`) and basic UI (`series-knowledge.html:4190-4219`).

**Source:** `migrations/20260605_create_codex_chronology.sql`

### 1.5 Review Action

Read-only dashboard showing entity counts per type. No data storage. Clicking a type card filters to that type.

**Source:** `scripts/series-knowledge.html:3484-3545`

### 1.6 AI Tools

| Feature | Status | Source |
|---|---|---|
| AI Suggestions (brainstorming) | Wired | `series-knowledge.html:2643-2698` |
| Continuity Findings | Wired | `series-knowledge.html:4289` |
| Semantic Search | Wired (limited) | `series-knowledge.html:3080-3174` |
| Content Assets | Wired | `series-knowledge.html:2470-2537` |
| Editor AI Test | Wired | `Index.html:2438-2507` |
| Generation Engine | Wired | `generation-engine.html` |
| AI Provider Config | Wired | `Index.html:2143-2263` |

### 1.7 `custom_data.sections`

Identified by key from `CODEX_DETAIL_SECTIONS` array (15 section types). Ordered by array position. Rendered as tabs with textareas. Stored in `custom_data.sections` object.

**Source:** `scripts/series-knowledge.html:3547-3563`

### 1.8 Organisation and Family

DB schema supports them. `saveCodexEntity` handles any type uniformly. But UI doesn't expose them — no tree entries, no new-entry buttons.

**Source:** `scripts/supabase-codex.html:74-129`, `scripts/series-knowledge.html:3179-3208`

### 1.9 Entity Write Service

`saveCodexEntity` in `scripts/supabase-codex.html:74-129` is the single central function for all entity creates/updates. Stateless, pure data write. Safe for proposal acceptance.

### 1.10 Connections

Full CRUD. 14 seeded relationship types. No reverse button. Filters by entity or series.

**Source:** `scripts/supabase-codex.html:174-219`, `migrations/20260604_create_codex_relationships.sql:38-54`

### 1.11 Embeddings

Schema and CRUD exist. No stale detection. Full re-embed each time. Client-side cosine similarity.

**Source:** `scripts/supabase-codex.html:503-556`

### 1.12 Story Seed

Self-contained modal. No integration with any proposal/build session concept.

**Source:** `Index.html:3169-3254`

### 1.13 RLS Policies

All tables use "Authenticated full access" pattern — any authenticated user can access all rows. No series-level isolation.

**Source:** `migrations/20260604_enable_codex_rls.sql`

### 1.14 Save Manager

Per-area queue with `isSaving` lock. Debounce per area. No conflict resolution (last-write-wins). Offline queue with retry.

**Source:** `scripts/save-manager.html`

### 1.15 Right Panel

CODEX tab doesn't use the right panel. Can host a persistent assistant without conflicting.

**Source:** `Index.html:1198`

---

## 2. Approved Decisions

| Decision | Resolution |
|---|---|
| Status fields | Add CHECK constraints |
| Organisation/Family | Separate sidebar groups |
| Right-panel assistant | Persistent within CODEX tab only |
| Brainstorm sources | Rich text/markdown support |
| AI provider | Use same provider as existing AI tools |
| Pillar customization | Rename/reorder/hide from the start |
| Proposal auto-creation | Auto-create with option to turn off |
| Revision granularity | Field-level diffs via on-the-fly comparison of full snapshots |

---

## 3. Stage 0: Verification and Plan

**Status:** Complete (this document)

**Deliverables:**
- [x] Verified current-state findings
- [x] Component map
- [x] Data model proposal
- [x] Migration sequence
- [x] State and status model
- [x] Detailed UI flow
- [x] AI/API contract
- [x] Provenance and revision design
- [x] Integration map
- [x] Test plan
- [x] Risks and unresolved decisions

---

## 4. Stage 1: Safety and Existing Wiring

**Goal:** Wire up revision tracking, expose hidden types, clarify status values. No generative workflow.

### 4A: Wire `codex_entity_revisions`

**New service functions** in `scripts/supabase-codex.html`:
- `saveCodexRevision(entityId, revisionNumber, snapshot, changeSummary)`
- `listCodexRevisions(entityId)`

**Modify** `saveCodexEntity` (`scripts/supabase-codex.html:74`):
- Before update: fetch current entity, snapshot it, insert revision
- After update: return new revision number

**New migration** — add index:
```sql
CREATE INDEX IF NOT EXISTS idx_codex_revisions_entity_created
  ON codex_entity_revisions(entity_id, created_at DESC);
```

**UI:** Add "History" tab to entity detail page in `scripts/series-knowledge.html`:
- List of revisions with timestamps and change summaries
- Click revision → field-level diff (compare current vs. snapshot)
- "Restore" button on any revision

**Diff rendering function** (new):
```js
function computeEntityFieldDiff(oldSnapshot, newSnapshot) {
  // Compare top-level fields
  // Compare custom_data nested fields
  // Compare sections
  // Return array of { field, path, oldValue, newValue }
}
```

### 4B: Expose Organisation and Family

**Modify** `scripts/series-knowledge.html` (`CODEX_TREE_DEF`):
- Add `organisation` group (icon: `building`)
- Add `family` group (icon: `users`)

**Modify** `Index.html` (new-entry dropdown):
- Add "Organisation" and "Family" options

### 4C: Status Field CHECK Constraints

**New migration:**
```sql
ALTER TABLE codex_entities DROP CONSTRAINT IF EXISTS chk_codex_status;
ALTER TABLE codex_entities ADD CONSTRAINT chk_codex_status
  CHECK (status IN ('draft', 'active', 'archived'));

ALTER TABLE codex_entities DROP CONSTRAINT IF EXISTS chk_codex_canon_status;
ALTER TABLE codex_entities ADD CONSTRAINT chk_codex_canon_status
  CHECK (canon_status IN ('draft', 'provisional', 'canon', 'deprecated'));

ALTER TABLE codex_entities DROP CONSTRAINT IF EXISTS chk_codex_visibility;
ALTER TABLE codex_entities ADD CONSTRAINT chk_codex_visibility
  CHECK (visibility IN ('private', 'author_only', 'public'));

ALTER TABLE codex_entities DROP CONSTRAINT IF EXISTS chk_codex_spoiler;
ALTER TABLE codex_entities ADD CONSTRAINT chk_codex_spoiler
  CHECK (spoiler_level IN ('none', 'mild', 'major', 'secret'));
```

**New constants** in `scripts/constants.html`:
```js
var CODEX_STATUS_OPTIONS = ["draft", "active", "archived"];
var CODEX_CANON_STATUS_OPTIONS = ["draft", "provisional", "canon", "deprecated"];
var CODEX_VISIBILITY_OPTIONS = ["private", "author_only", "public"];
var CODEX_SPOILER_OPTIONS = ["none", "mild", "major", "secret"];
```

**UI:** Add dropdowns to entity detail page.

**Estimated scope:** ~4 files modified, ~2 new service functions, ~1 migration.

---

## 5. Stage 2: Manual World Framework

**Goal:** Add World Framework structure with pillars, brainstorm sources, and manual extraction. Fully functional with AI disabled.

### 5A: New Supabase Tables

**`world_frameworks`** — one per series:
```sql
CREATE TABLE world_frameworks (
  id BIGSERIAL PRIMARY KEY,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'active',
  settings JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX idx_world_frameworks_series ON world_frameworks(series_id);
ALTER TABLE world_frameworks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON world_frameworks
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
```

**`world_framework_pillars`** — pillar content per framework:
```sql
CREATE TABLE world_framework_pillars (
  id BIGSERIAL PRIMARY KEY,
  framework_id BIGINT NOT NULL REFERENCES world_frameworks(id) ON DELETE CASCADE,
  pillar_key TEXT NOT NULL,
  label TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  state TEXT NOT NULL DEFAULT 'empty',
  author_content TEXT NOT NULL DEFAULT '',
  ai_content TEXT NOT NULL DEFAULT '',
  locked_content TEXT NOT NULL DEFAULT '',
  is_visible BOOLEAN NOT NULL DEFAULT TRUE,
  is_custom BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX idx_pillars_framework_key ON world_framework_pillars(framework_id, pillar_key);
ALTER TABLE world_framework_pillars ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON world_framework_pillars
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
```

**`world_brainstorm_sources`** — rich text sources:
```sql
CREATE TABLE world_brainstorm_sources (
  id BIGSERIAL PRIMARY KEY,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  title TEXT NOT NULL DEFAULT '',
  content TEXT NOT NULL DEFAULT '',
  content_html TEXT NOT NULL DEFAULT '',
  source_type TEXT NOT NULL DEFAULT 'manual',
  status TEXT NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE world_brainstorm_sources ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON world_brainstorm_sources
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
```

**`world_framework_extractions`** — extracted fragments:
```sql
CREATE TABLE world_framework_extractions (
  id BIGSERIAL PRIMARY KEY,
  source_id BIGINT NOT NULL REFERENCES world_brainstorm_sources(id) ON DELETE CASCADE,
  pillar_key TEXT NOT NULL,
  fragment TEXT NOT NULL,
  author_action TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE world_framework_extractions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON world_framework_extractions
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
```

### 5B: Default Pillars with Customization

**New constant** in `scripts/constants.html`:
```js
var WORLD_FRAMEWORK_PILLARS = [
  { key: "core_concept", label: "Core Concept", sort_order: 10 },
  { key: "world_type", label: "World Type", sort_order: 20 },
  { key: "scale", label: "Scale", sort_order: 30 },
  { key: "time_era", label: "Time and Era", sort_order: 40 },
  { key: "change_point", label: "Change Point", sort_order: 50 },
  { key: "geography", label: "Geography", sort_order: 60 },
  { key: "people_cultures", label: "People and Cultures", sort_order: 70 },
  { key: "politics_power", label: "Politics and Power", sort_order: 80 },
  { key: "religion_belief", label: "Religion and Belief", sort_order: 90 },
  { key: "magic_system", label: "Magic or System", sort_order: 100 },
  { key: "technology", label: "Technology", sort_order: 110 },
  { key: "economy_resources", label: "Economy and Resources", sort_order: 120 },
  { key: "everyday_life", label: "Everyday Life", sort_order: 130 },
  { key: "history", label: "History", sort_order: 140 },
  { key: "conflict_pressure", label: "Conflict and Pressure", sort_order: 150 },
  { key: "themes_tone", label: "Themes and Tone", sort_order: 160 },
  { key: "story_scale", label: "Story Scale", sort_order: 170 },
  { key: "mysteries_secrets", label: "Mysteries and Secrets", sort_order: 180 },
  { key: "open_questions", label: "Open Questions", sort_order: 190 },
  { key: "boundaries", label: "Boundaries", sort_order: 200 }
];
```

**Pillar customization UI:**
- Drag to reorder
- Toggle visibility (hide/show)
- Rename label
- Add custom pillar
- Settings stored in `world_frameworks.settings`

### 5C: Service Functions

**New file: `scripts/world-builder.html`**
- `getWorldFramework(seriesId)` — fetch framework + pillars
- `saveWorldFramework(seriesId, settings)` — create/update framework
- `saveWorldPillar(frameworkId, pillarKey, data)` — update pillar
- `reorderWorldPillars(frameworkId, pillarKeys)` — update sort orders
- `listBrainstormSources(seriesId)` — fetch sources
- `saveBrainstormSource(seriesId, payload)` — create/update source (rich text)
- `deleteBrainstormSource(sourceId)` — soft delete
- `saveExtractions(sourceId, extractions)` — save extracted fragments
- `updateExtractionAction(extractionId, action)` — accept/reject/move

### 5D: UI — Mode Switch

**Modify** `Index.html` (CODEX center workspace):
- Add mode switch: `OVERVIEW | WORLD BUILDER | REVIEW`
- Overview = existing dashboard (extended with framework status)
- World Builder = new construction workspace
- Review = existing review + proposal queue

### 5E: UI — Pillar Grid

Center workspace shows a grid of pillar cards:
```
┌─────────────┬─────────────┬─────────────┐
│ Core Concept │ World Type  │   Scale     │
│ ● captured   │ ○ empty     │ ○ empty     │
├─────────────┼─────────────┼─────────────┤
│ Time and Era │ Change Point│ Geography   │
│ ○ empty      │ ○ empty     │ ○ empty     │
└─────────────┴─────────────┴─────────────┘
```

Click a pillar → opens detail view with:
- Author content (rich text editor)
- AI content area (read-only until Stage 3)
- Lock toggle
- State indicator
- Source fragments panel

### 5F: UI — Brainstorm Panel

Right panel (persistent within CODEX tab):
- List of saved brainstorm sources
- "Add Source" button (opens rich text editor)
- "Extract Structure" button (disabled until Stage 3)
- Source content viewer

**Estimated scope:** ~4 new migrations, ~1 new script file, ~3 existing files modified.

---

## 6. Stage 3: Build Sessions and Extract-Only Assistance

**Goal:** Add AI-powered extraction and guided questions. No direct entity creation yet.

### 6A: New Supabase Tables

**`world_build_sessions`:**
```sql
CREATE TABLE world_build_sessions (
  id BIGSERIAL PRIMARY KEY,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  pillar_key TEXT,
  assistance_mode TEXT NOT NULL DEFAULT 'organizer',
  creativity_level TEXT NOT NULL DEFAULT 'balanced',
  depth_level TEXT NOT NULL DEFAULT 'foundation',
  auto_create_proposals BOOLEAN NOT NULL DEFAULT TRUE,
  settings_snapshot JSONB NOT NULL DEFAULT '{}',
  status TEXT NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE world_build_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON world_build_sessions
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
```

**`world_build_messages`:**
```sql
CREATE TABLE world_build_messages (
  id BIGSERIAL PRIMARY KEY,
  session_id BIGINT NOT NULL REFERENCES world_build_sessions(id) ON DELETE CASCADE,
  role TEXT NOT NULL,
  content TEXT NOT NULL,
  message_type TEXT NOT NULL DEFAULT 'text',
  metadata JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE world_build_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON world_build_messages
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
```

### 6B: AI Modes and Settings

**New constants:**
```js
var WORLD_BUILDER_MODES = [
  { key: "organizer", label: "Organizer", description: "Restructure and summarize without adding new ideas" },
  { key: "interviewer", label: "Interviewer", description: "Ask focused questions and develop through answers" },
  { key: "collaborator", label: "Collaborator", description: "Offer clearly labeled possibilities" },
  { key: "challenger", label: "Challenger", description: "Locate assumptions, contradictions, weaknesses" },
  { key: "explorer", label: "Explorer", description: "Examine from inside the world" }
];

var WORLD_BUILDER_CREATIVITY = [
  { key: "conservative", label: "Conservative" },
  { key: "balanced", label: "Balanced" },
  { key: "unexpected", label: "Unexpected" },
  { key: "experimental", label: "Experimental" }
];

var WORLD_BUILDER_DEPTH = [
  { key: "foundation", label: "Foundation" },
  { key: "working_detail", label: "Working Detail" },
  { key: "deep_worldbuilding", label: "Deep Worldbuilding" }
];
```

### 6C: AI Contract

AI returns structured JSON (not prose). See [Section 11: AI Contract](#11-ai-contract).

### 6D: Right-Panel Assistant

**New panel** in `Index.html`:
```html
<div id="worldBuilderAssistant" class="world-builder-assistant" hidden>
  <div class="assistant-header">
    <span class="assistant-title">World Builder Assistant</span>
    <select class="assistant-mode-select"></select>
  </div>
  <div class="assistant-messages"></div>
  <div class="assistant-actions">
    <button data-action="ask_questions">Ask Me Questions</button>
    <button data-action="offer_possibilities">Offer Three Possibilities</button>
    <button data-action="explore_consequences">Explore Consequences</button>
    <button data-action="challenge">Challenge an Assumption</button>
    <button data-action="find_contradictions">Find Contradictions</button>
    <button data-action="leave_unresolved">Leave Unresolved</button>
  </div>
</div>
```

Visible only when CODEX tab is active AND World Builder mode is selected.

### 6E: Auto-Create Proposals

When `auto_create_proposals` is enabled:
- AI extraction results automatically create `world_proposals`
- User can toggle this off in session settings
- Even with auto-create, proposals still go through Review before promotion

**Estimated scope:** ~2 new migrations, ~1 new script file, AI contract definition.

---

## 7. Stage 4: Proposal Review and CODEX Promotion

**Goal:** Add proposal storage, review UI, and promotion to CODEX entities.

### 7A: New Supabase Table

**`world_proposals`:**
```sql
CREATE TABLE world_proposals (
  id BIGSERIAL PRIMARY KEY,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  session_id BIGINT REFERENCES world_build_sessions(id),
  proposal_type TEXT NOT NULL,
  target_entity_type TEXT,
  target_entity_id BIGINT,
  proposed_content JSONB NOT NULL DEFAULT '{}',
  summary TEXT NOT NULL DEFAULT '',
  source_passage TEXT,
  source_pillar_key TEXT,
  contradictions JSONB NOT NULL DEFAULT '[]',
  ai_assumptions JSONB NOT NULL DEFAULT '[]',
  suggested_connections JSONB NOT NULL DEFAULT '[]',
  review_status TEXT NOT NULL DEFAULT 'pending',
  reviewer_edits JSONB NOT NULL DEFAULT '{}',
  rejection_reason TEXT,
  do_not_suggest_again BOOLEAN NOT NULL DEFAULT FALSE,
  resulting_entity_id BIGINT,
  resulting_connection_id BIGINT,
  settings_snapshot JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE world_proposals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON world_proposals
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
```

### 7B: Proposal Types

```js
var PROPOSAL_TYPES = [
  { key: "create_entity", label: "Create Entity" },
  { key: "update_entity", label: "Update Entity" },
  { key: "create_connection", label: "Create Connection" },
  { key: "add_framework_statement", label: "Add Framework Statement" },
  { key: "add_world_rule", label: "Add World Rule" },
  { key: "add_event", label: "Add Event" },
  { key: "create_continuity_finding", label: "Create Continuity Finding" }
];
```

### 7C: Service Functions

- `listWorldProposals(seriesId, status)` — fetch proposals
- `saveWorldProposal(seriesId, payload)` — create/update proposal
- `acceptWorldProposal(proposalId, edits)` — promote to CODEX
- `rejectWorldProposal(proposalId, reason)` — reject with reason
- `archiveWorldProposal(proposalId)` — archive
- `markDoNotSuggest(proposalId)` — flag

### 7D: Review UI

**Modify** the Review mode switch:
- Show pending proposals as cards
- Each card shows: type, target entity type, summary, source, contradictions
- Actions: Accept (as provisional/canon), Edit & Accept, Reject, Archive, Do Not Suggest Again
- Accepting "create entity" → calls `saveCodexEntity`, records resulting entity ID
- Accepting "update entity" → shows field-level diff, calls `saveCodexEntity`, records revision

### 7E: Provenance

When a proposal is accepted:
- Resulting entity gets a revision (from Stage 1A)
- Revision's `change_summary` references the proposal ID
- Proposal's `resulting_entity_id` links back

**Estimated scope:** ~1 new migration, ~1 new script file, Review UI modifications.

---

## 8. Stage 5: Deeper Assistance

**Goal:** Add Collaborator, Challenger, Explorer modes and consequence analysis.

### 8A: Additional AI Actions

- "Offer Three Possibilities" — AI generates 3 options for a pillar
- "Explore Consequences" — AI examines ripple effects of a world rule
- "Challenge an Assumption" — AI identifies weaknesses
- "Find Contradictions" — AI scans all pillars for inconsistencies
- "Explore Everyday Effects" — AI examines how a world change affects daily life
- "Add Historical Layers" — AI suggests historical context
- "Suggest Connected Entities" — AI proposes entities that should exist

### 8B: Continuity/Ripple Findings

When a world rule or entity changes:
- AI identifies what else might be affected
- Creates proposals of type `create_continuity_finding`
- Findings appear in Review for author resolution

### 8C: Relevant Canon Retrieval

When developing a pillar:
- System fetches related CODEX entities
- Displays them in the right-panel assistant as context
- Uses existing `codex_embeddings` if available

**Estimated scope:** Enhanced AI prompts, consequence analysis logic, retrieval integration.

---

## 9. Stage 6: Semantic and Long-Term Intelligence

**Goal:** Integrate embeddings, deeper historical claims, cross-book impact.

### 9A: Embedding Integration

- Auto-embed new/updated entities (detect staleness via `updated_at` vs embedding `created_at`)
- Use embeddings for relevant-canon retrieval during Build Sessions
- Hybrid search: keyword + semantic

### 9B: Cross-Book Impact

- When a world entity changes, identify scenes/chapters that reference it
- Surface potential continuity issues across books

### 9C: Story Seed Integration

- Generate Story Seeds from accepted world material
- Link Story Seed output to a Build Session

**Estimated scope:** Embedding pipeline improvements, cross-reference analysis.

---

## 10. Data Model Summary

### New Tables (7 total)

| Table | Stage | Purpose |
|---|---|---|
| `world_frameworks` | 2 | One per series, stores settings |
| `world_framework_pillars` | 2 | Pillar content per framework |
| `world_brainstorm_sources` | 2 | Rich text brainstorm sources |
| `world_framework_extractions` | 2 | Extracted fragments from sources |
| `world_build_sessions` | 3 | AI-assisted development sessions |
| `world_build_messages` | 3 | Messages within a session |
| `world_proposals` | 4 | Reviewable proposals for CODEX promotion |

### Modified Tables

| Table | Stage | Change |
|---|---|---|
| `codex_entities` | 1 | Add CHECK constraints on status fields |
| `codex_entity_revisions` | 1 | Add index, wire into save flow |

### New Files

| File | Stage | Purpose |
|---|---|---|
| `scripts/world-builder.html` | 2 | World Builder service functions |
| `scripts/world-builder-ui.html` | 2 | World Builder UI rendering |
| `scripts/world-builder-ai.html` | 3 | AI contract and session management |
| `scripts/world-builder-proposals.html` | 4 | Proposal review and promotion |

### Modified Files

| File | Stage | Changes |
|---|---|---|
| `scripts/supabase-codex.html` | 1 | Add revision CRUD, modify saveCodexEntity |
| `scripts/series-knowledge.html` | 1, 2 | Add Organisation/Family to tree, revision UI, mode switch |
| `scripts/constants.html` | 1, 2, 3 | Add status enums, pillar defaults, AI modes |
| `Index.html` | 1, 2, 3 | New-entry dropdown, mode switch, assistant panel |
| `Styles.html` | 2, 3 | World Builder styles, assistant styles |
| `scripts/el-cache.html` | 2, 3 | Cache new DOM elements |
| `scripts/bind-events.html` | 2, 3 | Bind new event handlers |

---

## 11. AI Contract

### Request Schema

```json
{
  "action": "extract_structure",
  "series_id": 123,
  "pillar_key": "change_point",
  "mode": "organizer",
  "creativity": "balanced",
  "depth": "foundation",
  "context": {
    "source_text": "...",
    "existing_framework": { ... },
    "locked_statements": [ ... ],
    "existing_entities": [ ... ],
    "prohibited_concepts": [ ... ]
  }
}
```

### Response Schema

```json
{
  "extracted_statements": [
    {
      "text": "The System assigns practical skills to ordinary people",
      "pillar": "magic_system",
      "confidence": "explicit",
      "source_ref": "paragraph 2"
    }
  ],
  "tentative_statements": [
    {
      "text": "Skills may be assigned randomly or by some hidden logic",
      "pillar": "magic_system",
      "confidence": "inference",
      "reason": "Not explicitly stated but implied by 'unexpectedly useful'"
    }
  ],
  "open_questions": [
    {
      "question": "Does the System arrive publicly for everyone at once, or does society first learn about it through scattered individual incidents?",
      "pillar": "change_point",
      "reason": "The source does not specify the mechanism of arrival"
    }
  ],
  "contradictions": [
    {
      "statement_a": "Local cosy adventures",
      "statement_b": "Darker skills such as necromancy appear",
      "explanation": "Cosy tone may conflict with dark skill implications"
    }
  ],
  "assumptions": [
    {
      "text": "Assumed the System is a single entity or force",
      "reason": "Source uses 'A System' (singular)"
    }
  ],
  "framework_updates": [
    {
      "pillar": "core_concept",
      "content": "Contemporary world where a System assigns practical skills, with both cosy and dark implications",
      "action": "update"
    }
  ],
  "entity_proposals": [
    {
      "name": "The System",
      "type": "lore",
      "summary": "The mysterious force that assigns skills to people",
      "source_passage": "A System starts giving people skills",
      "pillar": "magic_system"
    }
  ],
  "connection_proposals": [],
  "continuity_findings": []
}
```

### Actions

| Action | Description |
|---|---|
| `extract_structure` | Analyze source text, extract into framework pillars |
| `ask_questions` | Generate focused questions for a pillar |
| `offer_possibilities` | Generate 3 options for a pillar |
| `explore_consequences` | Examine ripple effects of a world rule |
| `challenge_assumption` | Identify weaknesses in a pillar |
| `find_contradictions` | Scan all pillars for inconsistencies |
| `explore_everyday` | Examine daily life effects |
| `add_history` | Suggest historical layers |
| `suggest_entities` | Propose connected entities |

### Failure Handling

- AI failure does not lose raw brainstorm or answers
- Invalid output cannot write directly to canon
- Partially saved sessions can be resumed or safely abandoned
- All AI output goes through proposal review before promotion

---

## 12. Risks and Unresolved Decisions

### Resolved Decisions

| Decision | Resolution |
|---|---|
| Status field constraints | Add CHECK constraints |
| Organisation/Family | Separate sidebar groups |
| Right-panel assistant | Persistent within CODEX tab |
| Brainstorm storage | Rich text/markdown |
| AI provider | Same as existing AI tools |
| Pillar customization | From the start |
| Proposal auto-creation | Auto-create with toggle |
| Revision granularity | Field-level via snapshot comparison |

### Risks

| Risk | Mitigation |
|---|---|
| CHECK constraints break existing data | Verify all existing values comply before adding constraints |
| Rich text storage size | Use `TEXT` type, consider compression for large sources |
| AI response quality | Structured contract with fallback handling, human review required |
| Performance with many pillars | Lazy loading, virtual scrolling if needed |
| Concurrent edits | Save manager's `isSaving` lock per area, last-write-wins |

### Open Items

- [ ] Verify existing `status`/`canon_status`/`visibility`/`spoiler_level` values comply with CHECK constraints before migration
- [ ] Determine rich text editor library (or use existing `contenteditable` pattern)
- [ ] Define exact AI prompt templates for each action
- [ ] Design pillar drag-and-drop reorder UX
- [ ] Design proposal card layout and batch action UI

---

*End of implementation plan. Ready for Stage 1 implementation.*
