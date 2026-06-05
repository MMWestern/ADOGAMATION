# Session Handover

## Current State

Branch: `opencode/silent-pixel`
Dev server: port 3000, serves from project root with recursive include processing
Feature flag: `USE_NEW_CODEX_ENGINE = true` in `scripts/constants.html`
All 14 phases of the CODEX engine rebuild are complete.

## What Was Done This Session

### CODEX Engine Rebuild — All 14 Phases

**Phase 0-2 (Schema & Service Layer):**
- Audited 21 prototype tables, 38 `_sbDefine` methods, 158 DOM element IDs
- Created 7 migrations: `codex_entity_types` (9 seeds), `codex_entities`, `codex_entity_projects`, `codex_relationship_types` (14 seeds), `codex_connections`, `codex_tags`, `codex_entity_tags`, `codex_entity_revisions`
- Service layer (`scripts/supabase-codex.html`): 30+ `_sbDefine` methods
- View models (`scripts/codex-view-models.html`): mappers, `pluralMap`, `CODEX_GROUP_TO_TYPE_KEY`

**Phase 3-4 (Tab & Read Switch):**
- KNOWLEDGE tab renamed to CODEX in Index.html, Client.html, el-cache.html, bind-events.html, Styles.html
- Read switching: `getWritingCodexEntries()` routes through new engine
- `codexCache` stores `entitiesBySeries`, `entityDetails`, `entityTypesByKey`
- Dev server `processIncludes` fixed to recursive

**Phase 5-6 (Save Switch & Plan Integration):**
- `saveWritingCodexModal()` routes through `saveCodexEntity` when flag is on
- `mapLegacySavePayloadToCodex_()` converts legacy payload
- Plan outline codex tag rendering, tag modal, POV popup use `getCodexEntitiesForType_()`

**Phase 7 (Connections):**
- Connections sub-tab with add/list/save/delete via `loadSkConnections`, `renderSkConnectionList`, `saveSkConnection`, `deleteSkConnection`

**Phase 8 (Calendars & Events):**
- Timelines sub-tab with calendar and event CRUD
- Migration files: codex_chronology, codex_mentions, codex_content_assets, codex_ai_and_continuity

**Phase 9 (Mentions):**
- Mentions sub-tab button, pane, form, element cache IDs, event bindings
- Fixed `listCodexMentions` requiring entity_id — added `listCodexMentionsBySeries`

**Phase 10 (Content Assets):**
- Assets sub-tab with form fields (title, type, content, audience, spoiler_level, entity, status)
- Full CRUD: `loadSkAssets`, `renderSkAssetList`, `saveSkAsset`, `editSkAsset`, `deleteSkAsset`

**Phase 11 (AI Brainstorming):**
- AI sub-tab with type/entity/prompt form, generate button, suggestion list with detail view
- `loadSkAiSuggestions`, `generateSkAiSuggestion`, `reviewSkAiSuggestion`
- Model resolution via `collectAISettingsFormData()` + `getSelectedAIModel()`
- AI provider badge (green/red, polls 5s while AI tab visible, clickable to open AI Settings)
- UI polish: badge on same line as generate button, fixed button width, removed extra `</div>`, spinner with `.is-visible` class

**Phase 12 (Semantic Retrieval):**
- `codex_embeddings` table migration
- `callEditorEmbedding()` with OpenRouter/LM Studio/Ollama support
- `cosineSimilarity` helper + `searchCodexEmbeddings` (client-side cosine similarity)
- Generate Embeddings + Semantic Search UI in AI tab
- `generateSkEmbeddings()` batch-processes entities, `searchSkSemantic()` embeds query + searches

**Phase 13 (Continuity Scanning):**
- `scanSkContinuity()` — sends all entity descriptions to AI for contradiction analysis
- `loadSkContinuityFindings()` / `renderSkContinuityFindings()` — findings list with severity/status badges
- `resolveSkContinuityFinding()` — Resolve/Dismiss buttons
- `autoFixSkContinuityFinding()` — AI generates fix suggestion, saved to AI tab for adopt/dismiss
- Deduplication against existing findings by title
- Findings load on Continuity tab activation via `setSkSubTab()`

**Phase 14 (Prototype Table Retirement):**
- Guarded 7 legacy loads behind `USE_NEW_CODEX_ENGINE` in `loadSkEntities()`
- Updated continuity pickers (`renderSkContinuityCharPicks`, `renderSkContinuityLocPicks`, `renderSkContinuityDetail`) to read from `codexCache` when flag is on
- Migration to drop 16 prototype tables: `series_characters`, `series_character_books`, `series_character_relationships`, `series_locations`, `series_location_books`, `series_objects`, `series_object_books`, `series_object_character_links`, `series_object_location_links`, `series_object_lore_links`, `series_lore`, `series_lore_books`, `series_subplots`, `series_subplot_books`, `series_other`, `series_other_books`

### Key Files Changed
- `scripts/supabase-codex.html` — 200+ lines added (mentions, assets, AI, embeddings, continuity findings methods)
- `scripts/series-knowledge.html` — grew from ~1,050 to ~2,704 lines (all sub-tab CRUD, AI, semantic search, continuity scanning)
- `scripts/markdown-utils.html` — added `callEditorEmbedding()`
- `scripts/codex-view-models.html` — new file with mappers, pluralMap, entity type helpers
- `scripts/el-cache.html` — ~140 new element IDs
- `scripts/bind-events.html` — ~30 new event bindings
- `Index.html` — CODEX tab pane with all sub-tab content (connections, timelines, mentions, assets, AI, semantic search + continuity findings)
- `Styles.html` — AI badge, spinner, section dividers, severity badge variants, tiny buttons
- `migrations/` — 8 new migration files

### Migration Files (run in Supabase SQL editor)
1. `20260605_create_codex_chronology.sql` — calendars, events, timelines
2. `20260605_create_codex_mentions.sql` — mentions
3. `20260605_create_codex_content_assets.sql` — content assets
4. `20260605_create_codex_ai_and_continuity.sql` — AI suggestions, continuity findings
5. `20260605_create_codex_embeddings.sql` — embeddings for semantic search
6. `20260605_drop_prototype_tables.sql` — drops 16 unused prototype tables

### Known Issues
- Continuity tab manual entries still use prototype `series_continuity_entries` table (kept for backwards compatibility)
- Semantic search requires embedding-compatible model in LM Studio (e.g. `nomic-embed-text-v1.5`) or OpenRouter
- Most entities have no descriptions — AI features (scan, semantic search) need descriptive content to work well
- Old CODEX tab sub-tabs (Characters, Locations, Objects, etc.) show empty states after prototype tables are dropped — use WRITING tab's CODEX sidebar instead
- SERIES button in top-right of info panels (Plan + Writing) opens the series books modal
- Series modal shifted left (flex-start + 320px padding)

### Documentation Created
- `SUPABASE_INTEGRATION.md` — Full Supabase schema, migrations, auth, CRUD patterns, RLS, storage

## Key Architecture Points

- **SPA**: Vanilla JS single-page app, all HTML in one `Client.html` + `Index.html` + `Styles.html`
- **Supabase**: Direct client-side calls via `supabaseRunner` Proxy (`scripts/supabase-runner.html`)
  - Methods registered with `_sbDefine(name, impl)` in `scripts/supabase-crud.html` and `scripts/data-operations.html`
  - Proxy falls back to `google.script.run` for legacy methods
- **Element cache**: `scripts/el-cache.html` maps `el.propertyName` to `document.getElementById("propertyName")` — always add new element IDs here
- **Auth**: `scripts/auth.html` — email/password, no sign-up flow
- **Outline data**: Stored as `projects.outline` JSONB column (acts → chapters → scenes with POV, codex tags, etc.)
- **Plan outline**: Rendered by `renderPlanOutline()` in `scripts/plan-outline.html`
- **Writing workspace**: Rendered by `renderWritingWorkspaceEditor()` in `Client.html`
- **Codex (series knowledge)**: Stored in `series_*` tables (characters, locations, objects, lore, subplots, other, continuity_entries)

## Next Steps / Known Issues
- The `upgrade/worldbuilding` branch is ready for the worldbuilding integration
- The user is working with ChatGPT to design a worldbuilding app that will integrate

## Running Locally
```
npm install
npm run dev
```
Starts at `http://localhost:3031`
