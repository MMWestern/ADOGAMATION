# Silent Pixel — Application Outline

## Purpose

Silent Pixel is an author management platform for indie publishers. It manages the full lifecycle of a book series — from planning and writing through publishing and marketing — with an integrated world-building Codex system.

---

## Architecture

Single-page web application (HTML + vanilla JS) backed by Supabase (PostgreSQL + Storage). All modules share a single global `appState` object. Navigation uses a two-level tab system:

```
Hub Tabs (top):    HOME | STUDIO | HANDBOOK | INBOX | SETTINGS
Studio Sub-Tab:    PROJECTS | CHAT | PLAN | WRITING | CODEX | PUBLISHING | MARKETING | RESOURCES
```

### Central Project Selection

`selectProject()` is the propagation function. When a project is selected, every active module refreshes its data from the shared `appState`. This is the key integration point — any new management system must hook into this chain.

### Auto-Save System

A centralised `saveManager` provides debounced auto-save for workspace drafts (1.8s), project details (0.7s), plan outlines (3s), resources (2s), series knowledge (2s), and codex entries (1s).

---

## Module Map

### HOME
Read-only dashboard. Displays stats cards (total books, in progress, due soon, published), focus items, upcoming milestones, recent activity, and quick actions. All data comes from `appState.projects` — no direct Supabase reads.

### PROJECTS
The core data module. Manages book/series records. All other modules read from `appState.projects` which this module owns. Selecting a project triggers cross-module refresh.

**Supabase tables:** `projects` (CRUD), `series` (CRUD), `documents` (R)

### PLAN
Outline builder. Creates a hierarchical structure of acts → chapters → scenes. **Bidirectionally synced with WRITING** — adding/removing outline chapters rebuilds the writing workspace chapter list, and editing chapter titles in WRITING updates the outline. Scenes can be tagged with Codex entries (characters, locations, objects).

**Supabase tables:** `projects.outline` (R/W), `document_sections` (R/W)

### WRITING
The main writing workspace. A simple contenteditable editor for chapter text. Has a sidebar with chapter list and Codex panel. Reads Codex entries from the shared cache for the sidebar. Chapter sections are persisted as `document_sections` rows.

**Supabase tables:** `document_sections` (R/W — doc_type: `draft`, `notes`, `fixes`), `projects.outline` (R/W)

### CODEX
World-building knowledge base. Two systems coexist:

**Legacy system** (being migrated): Per-type tables — `series_characters`, `series_locations`, `series_objects`, `series_lore`, `series_subplots`, `series_other`, `series_continuity_entries` with associated link tables.

**New Codex engine**: Generic `codex_entities` table with `entity_type_id` pointing to `codex_entity_types`. Supports characters, locations, organisations, families, items, lore, quests, journals, continuity notes, maps, magic systems. Entity-to-entity relationships via `codex_connections`. Tagging via `codex_tags` + `codex_entity_tags`. Chronology via `codex_calendars`/`codex_events`/`codex_timelines`. Mentions tracking, content assets, AI suggestions, continuity findings, and vector embeddings.

**Supabase tables:** See [Codex Engine Tables](#codex-engine-tables-new) and [Legacy Codex Tables](#legacy-codex-tables-being-replaced) below.

### CHAT
AI chat assistant. Context can be set to specific outline nodes (acts/chapters/scenes), Codex categories, or full novel text. Sessions stored as `document_sections` with `doc_type="chat_session"`.

**Supabase tables:** `document_sections` (R/W — doc_type: `chat_session`)

### PUBLISHING
Publishing pipeline. Shows projects filtered by status (Publish Ready, Published, Complete, Editing). Displays a shared timeline with schedule milestones. Clicking a project calls `selectProject()` to propagate to other modules.

**Supabase tables:** `projects` (R — schedule_milestones, publish_date)

### MARKETING
Campaign management. Shares the same timeline, milestones, and campaign data as PUBLISHING. Campaigns are stored in `projects.campaigns` JSON column.

**Supabase tables:** `projects` (R/W — campaigns)

### RESOURCES
Standalone reference documents (general markdown). Has its own auto-save timer. Also contains a Series Knowledge panel that writes to the same `documents` table the CODEX reads from.

**Supabase tables:** `general_resources` (CRUD), `documents` (R/W — doc_type: `series_knowledge_registry`)

### HANDBOOK
Internal company handbook. Entries stored in `handbook_entries` table. Contenteditable editor with formatting toolbar and font/spacing preferences persisted to localStorage.

**Supabase tables:** `handbook_entries` (CRUD)

---

## Supabase Tables

### Core Tables

| Table | Purpose | Key Columns | Read By | Written By |
|---|---|---|---|---|
| `projects` | Book records in a series | `id`, `series_id` (FK), `title`, `book_number`, `status`, `priority`, `next_step`, `short_summary`, `outline` (JSONB), `schedule_milestones` (JSONB), `campaigns` (JSONB), `publish_date`, `pen_name`, `genre`, `format`, `project_image_url` | ALL modules | PROJECTS, PUBLISHING, MARKETING |
| `series` | Groups projects into series | `id`, `name`, `summary`, `series_image_url` | PROJECTS, CODEX, RESOURCES | PROJECTS |
| `documents` | Markdown documents per project/series | `id`, `project_id`, `series_id`, `doc_type`, `title`, `markdown_content`, `word_count` | WRITING, PLAN, CODEX, RESOURCES, CHAT | WRITING, CODEX, RESOURCES |
| `document_sections` | Subdivisions of documents | `project_id`, `doc_type`, `section_key`, `title`, `markdown_content`, `word_count`, `sort_order` | WRITING, PLAN, CHAT | WRITING, PLAN, CHAT |
| `general_resources` | Standalone reference docs | `id`, `title`, `category`, `markdown_content`, `word_count`, `sort_order` | RESOURCES | RESOURCES |
| `image_assets` | Uploaded images with crop metadata | `id`, `category`, `crop_data` | IMAGE PICKER | IMAGE PICKER |
| `handbook_entries` | Company handbook | `id`, `doc_id`, `title`, `department`, `section`, `entry_type`, `status`, `content`, `tags`, `related_entries`, `version`, `author` | HANDBOOK | HANDBOOK |
| `book_creator_pockets` | Categorized text snippets | `id`, `category`, `pocket_key`, `label`, `content_text`, `source_type`, `is_active` | BOOK CREATOR | — (read-only) |

**`documents` doc_type values:** `draft` (chapter text), `notes` (chapter notes), `fixes` (chapter fixes), `chat_session` (chat messages), `series_knowledge_registry` (knowledge base)

**`document_sections` upsert conflict key:** `project_id, doc_type, section_key`

### Codex Engine Tables (new)

| Table | Purpose | Key Columns | Relationships |
|---|---|---|---|
| `codex_entity_types` | Entity type taxonomy | `id`, `key`, `name_singular`, `name_plural`, `icon`, `field_schema`, `display_settings`, `is_system_type`, `is_enabled` | — |
| `codex_entities` | Any codex entry | `id`, `series_id` (FK→series), `entity_type_id` (FK→codex_entity_types), `name`, `slug`, `aliases`, `summary`, `description`, `image_url`, `color`, `scope`, `status`, `canon_status`, `custom_data` (JSONB), `deleted_at` | FK to series, entity_types |
| `codex_entity_projects` | Entity ↔ project links | `entity_id` (FK→codex_entities), `project_id` (FK→projects), `notes` | Many-to-many: entities ↔ projects |
| `codex_connections` | Entity ↔ entity relationships | `id`, `series_id`, `source_entity_id`, `target_entity_id`, `relationship_type_id` (FK→codex_relationship_types), `label`, `is_secret`, `deleted_at` | FK to entities (×2), relationship_types |
| `codex_relationship_types` | Relationship type definitions | `id`, `key`, `forward_label`, `inverse_label`, `is_directional`, `allowed_source_types`, `allowed_target_types` | — |
| `codex_tags` | Tag definitions per series | `id`, `series_id`, `name`, `slug` | FK to series |
| `codex_entity_tags` | Entity ↔ tag links | `entity_id` (FK→codex_entities), `tag_id` (FK→codex_tags) | Many-to-many: entities ↔ tags |
| `codex_mentions` | Where entities appear in documents | `id`, `series_id`, `entity_id`, `project_id`, `document_id`, `section_id`, `source_type`, `matched_text`, `confidence` | FK to entities, projects |
| `codex_content_assets` | Marketing/reader-facing content | `id`, `series_id`, `entity_id`, `asset_type`, `title`, `content`, `status`, `audience`, `spoiler_level` | FK to entities |
| `codex_continuity_findings` | Continuity issues | `id`, `series_id`, `finding_type`, `severity`, `status`, `title`, `description`, `evidence` | FK to series |
| `codex_ai_suggestions` | AI-generated suggestions | `id`, `series_id`, `suggestion_type`, `target_entity_id`, `suggested_payload` (JSONB), `status`, `provider`, `model` | FK to entities |
| `codex_embeddings` | Vector embeddings for search | `id`, `series_id`, `entity_id`, `source_type`, `content_text`, `embedding` | FK to entities |
| `codex_calendars` | In-world calendar systems | `id`, `series_id`, `name`, `calendar_config` (JSONB) | FK to series |
| `codex_events` | Chronological events | `id`, `series_id`, `calendar_id` (FK→codex_calendars), `title`, `display_date`, `start_sort_key`, `end_sort_key` | FK to calendars |
| `codex_timelines` | Named event groupings | `id`, `series_id`, `name`, `visibility` | FK to series |
| `codex_entity_revisions` | Version history (schema ready, not yet queried from JS) | `id`, `entity_id`, `revision_number`, `snapshot` (JSONB) | FK to entities |
| `codex_event_entities` | Event ↔ entity links (schema ready, not yet queried from JS) | `event_id`, `entity_id`, `role` | FK to events, entities |
| `codex_timeline_events` | Timeline ↔ event links (schema ready, not yet queried from JS) | `timeline_id`, `event_id`, `sort_order` | FK to timelines, events |

### Legacy Codex Tables (being replaced)

These are still actively read/written but marked for migration to the new engine:

| Table | New Engine Equivalent |
|---|---|
| `series_characters` + `series_character_books` + `series_character_relationships` | `codex_entities` (type=character) + `codex_entity_projects` + `codex_connections` |
| `series_locations` + `series_location_books` | `codex_entities` (type=location) + `codex_entity_projects` |
| `series_objects` + `series_object_books` + link tables | `codex_entities` (type=item) + `codex_entity_projects` |
| `series_lore` + `series_lore_books` | `codex_entities` (type=lore) + `codex_entity_projects` |
| `series_subplots` + `series_subplot_books` | `codex_entities` (type=quest) + `codex_entity_projects` |
| `series_other` + `series_other_books` | `codex_entities` (type=*) |
| `series_continuity_entries` + link tables | `codex_entities` (type=continuity_note) + `codex_connections` |

---

## selectProject() Propagation Chain

When a project is selected, the following cascade occurs:

```
selectProject(rowNumber)
  ├── appState.selectedRowNumber = rowNumber
  ├── syncSeriesFilterToSelectedProject(project)
  ├── fillDetailForm(project)                         [PROJECTS detail panel]
  ├── populateChatInfoPanel(project)                  [CHAT sidebar info]
  ├── appState.chats = _loadChatsFromStorage()        [CHAT]
  ├── renderChatList() + renderChatMessages()         [CHAT]
  ├── _loadChatsFromSupabase()                        [CHAT → Supabase]
  ├── preloadProjectDocs(project)                     [doc cache warming]
  ├── preloadReferencePanelSelections(project)        [doc cache warming]
  │
  ├── IF activeMainTab === "resources":
  │     ├── renderSeriesKnowledgePanel(project)       [RESOURCES]
  │     └── loadSeriesKnowledgeForSelectedProject()   [CODEX/RESOURCES]
  │
  ├── IF activeMainTab === "codex":
  │     ├── populateCodexInfoPanel(project)           [CODEX]
  │     ├── loadSeriesKnowledgeForSelectedProject()   [CODEX]
  │     └── renderCodexTree() + renderCodexDashboard()
  │
  ├── IF activeMainTab === "workspace" AND different project:
  │     └── openWritingWorkspace()                    [WRITING]
  │
  ├── IF different project:
  │     ├── flushCurrentWorkspaceEdits()              [WRITING — save pending]
  │     ├── Reset appState.writingWorkspace.*         [WRITING/PLAN]
  │     ├── IF activeMainTab === "workspace":
  │     │     └── loadWritingWorkspaceDraft()         [WRITING → Supabase]
  │     ├── IF activeMainTab === "plan":
  │     │     └── loadPlanData() → setPlanSubTab()   [PLAN → Supabase]
  │     └── ELSE:
  │           └── loadPlanData()                      [PLAN — preload]
  │
  └── renderProjectsTable()                           [PROJECTS]
```

---

## Key Data Flows

### PLAN ↔ WRITING (Bidirectional)

```
PLAN: addPlanChapter() / deletePlanNode() / drag-drop reorder
  → syncOutlineToSegments()
    → appState.writingWorkspace.segments = nextSegments
    → renderWritingChapterList() + renderWritingWorkspaceScopeOptions()

WRITING: Chapter title blur
  → syncSegmentTitleToOutline(scope, newTitle)
  → renderPlanOutline()
  → schedulePlanOutlineSave()

WRITING: saveWritingWorkspaceDraft()
  → Promise.all([saveDraftSections, savePlanOutline()])
    → document_sections (draft) + projects.outline
```

### CODEX → WRITING (Read)

```
WRITING sidebar "codex" tab:
  → getWritingCodexEntries(project)
    → IF USE_NEW_CODEX_ENGINE: codexCache.entitiesBySeries[seriesId]
    → ELSE: skCache.characters/locations/objects/lore/continuity[seriesId]
  → renderWritingCodexList(project)

WRITING codex modal (click entry):
  → openWritingCodexModal(key)
    → Loads entity data from codexCache or skCache
    → Displays details, research, relations, mentions, tracking tabs
    → scheduleCodexAutoSave() on edits
```

### CODEX → PLAN (Read)

```
PLAN: renderPlanOutline()
  → getCodexEntitiesForType_(seriesId, "characters")
  → getCodexEntitiesForType_(seriesId, "locations")
  → ... (7 types total)
  → getPlanSceneCodexTags(scene, characters, locations, ...)
    → Renders coloured tags on each scene

PLAN: Scene POV selector
  → _getSceneTaggedCharacters(scene, characters)
    → Reads from codex character data
```

### PUBLISHING ↔ MARKETING (Shared)

```
Both tabs:
  → Read appState.projects[].schedule_milestones
  → Read appState.projects[].campaigns
  → Share appState.timelineFilterSeries / timelineFilterProject
  → Share renderTimeline() function
  → persistTimelineFilter() writes to same localStorage key
```

### CHAT ← PLAN + CODEX + WRITING (Read)

```
CHAT context builder:
  → type="full-novel": reads appState.writingWorkspace.segments
  → type="full-outline": reads getPlanOutline()
  → type="acts": reads outline.acts
  → type="chapters": reads outline.acts[].children
  → type="scenes": reads outline.acts[].children[].children
  → type="codex": reads codex category labels
```

### RESOURCES ↔ CODEX (Indirect via series knowledge)

```
RESOURCES: Series Knowledge panel
  → saveSupabaseSeriesKnowledgeJsonFromClient(seriesId, payload)
    → documents table (doc_type="series_knowledge_registry")
  → Updates appState.seriesKnowledgeById[seriesId]

CODEX: Series Knowledge tab
  → Reads appState.seriesKnowledgeById[seriesId]
  → Same documents table (doc_type="series_knowledge_registry")
```

---

## Save Manager Integration

| Area | Debounce | Save Target |
|---|---|---|
| `workspace` | 1800ms | `saveWritingWorkspaceDraft()` → document_sections (draft) + projects.outline |
| `projectDetails` | 700ms | `saveSelectedProject()` → projects table |
| `planOutline` | 3000ms | `savePlanOutline()` → projects.outline |
| `resources` | 2000ms | `saveResourceEditor()` → general_resources |
| `seriesKnowledge` | 2000ms | Series knowledge save → documents |
| `writingCodex` | 1000ms | Codex entity save → codex_entities |

Config stored in localStorage: `writing_dashboard_auto_save_v1`

---

## localStorage Keys

| Key | Module | Purpose |
|---|---|---|
| `writing_dashboard_projects_cache_supabase_v2` | PROJECTS | Offline project cache |
| `writing_dashboard_dark_mode_v1` | GLOBAL | Dark mode preference |
| `writing_dashboard_ai_settings_v1` | SETTINGS | AI provider config |
| `writing_dashboard_auto_save_v1` | SAVE MANAGER | Auto-save config |
| `writing_dashboard_timeline_filter_v1` | PUBLISHING/MARKETING | Timeline filter state |
| `adogamation_activeHubTab` | GLOBAL | Last active hub tab |
| `planOutlineTemplates` | PLAN | Saved outline templates |
| `resourceLastSelectedId` | RESOURCES | Last selected resource |
| `workspace_backup_<projectId>` | WRITING | Offline draft backup |
| `chat_sessions_<projectId>` | CHAT | Chat session storage |
| `PROJECT_INSPECTOR_OPTIONS` | PROJECTS | Custom dropdown options |
| `handbook-font-prefs` | HANDBOOK | Font/spacing preferences |

---

## Integration Points for a New Management System

1. **Hook into `selectProject()`** — add your module's init function to the propagation chain so it refreshes when the project changes.

2. **Read from `appState.projects`** — project metadata is already loaded and cached. No additional fetch needed.

3. **Choose a storage strategy:**
   - **`documents` table with a new `doc_type`** — simplest for structured markdown content. Use `document_sections` for sub-sections.
   - **New dedicated table** — if the data has complex relationships or needs its own schema.
   - **`projects` table JSON column** — for small metadata that belongs to the project (like `campaigns`, `schedule_milestones`).

4. **Register with `saveManager`** — if the module has editable content, register a debounced auto-save area.

5. **Read from Codex if needed** — if the module needs world-building data, read from `codex_entities`/`codex_connections` via the shared `codexCache`.

6. **Add a main tab button** in `Index.html` and a content container, then add the tab to `switchMainTab()` in `Client.html`.
