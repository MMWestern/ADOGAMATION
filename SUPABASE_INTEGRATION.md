# Supabase Integration — Adogamation Press Dashboard

## Overview

A vanilla JS single-page app (no framework) that uses Supabase for auth, database, and file storage. Previously backed by Google Apps Script + Google Drive; Supabase is the direct backend. The app uses a `supabaseRunner` Proxy to dispatch calls to Supabase implementations, falling back to `google.script.run` for legacy methods.

---

## Architecture

```
Client.html (SPA entry)
  ├── api/env.js          (Vercel serverless — injects Supabase credentials)
  ├── scripts/auth.html   (Auth flow)
  ├── scripts/el-cache.html (Global DOM element cache)
  ├── scripts/supabase-runner.html (Proxy dispatch + project mapper)
  ├── scripts/supabase-crud.html  (Core CRUD: projects, documents, series)
  ├── scripts/data-operations.html (Domain CRUD: images, resources, codex)
  ├── scripts/constants.html (Doc types, style presets, table configs)
  └── ... (UI, bindings, save-manager, etc.)
```

### Client Initialization

```js
// Client.html:13-17
const SUPABASE_URL = window.__SUPABASE_URL__ || "";
const SUPABASE_ANON_KEY = window.__SUPABASE_ANON_KEY__ || "";
const sbClient = (SUPABASE_URL && SUPABASE_ANON_KEY && typeof window.supabase !== "undefined")
  ? window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY)
  : null;
```

Credentials are injected at build time (`build.js`) or via Vercel serverless endpoint (`api/env.js`). Uses the Supabase JS CDN library (`window.supabase.createClient`).

---

## Database Schema (PostgreSQL)

### Core Tables

#### `projects`
| Column | Type | Notes |
|---|---|---|
| id | BIGSERIAL PK | |
| series_id | BIGINT FK → series(id) | |
| legacy_project_id | TEXT | |
| legacy_workspace_url | TEXT | |
| title | TEXT | |
| book_number | TEXT | |
| pen_name | TEXT | |
| genre | TEXT | |
| format | TEXT | |
| status | TEXT | |
| priority | TEXT | |
| next_step | TEXT | |
| short_summary | TEXT | |
| project_image_url | TEXT | |
| schedule_template | TEXT | |
| marketing_template | TEXT | |
| publish_date | TEXT | |
| publish_ready_date | TEXT | |
| schedule_milestones | JSONB | |
| campaigns | JSONB | |
| outline | JSONB | Project outline tree (acts → chapters → scenes) |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |

#### `series`
| Column | Type |
|---|---|
| id | BIGSERIAL PK |
| name | TEXT |
| summary | TEXT |
| series_image_url | TEXT |
| legacy_doc_urls | JSONB |

#### `documents`
| Column | Type | Notes |
|---|---|---|
| id | BIGSERIAL PK | |
| project_id | BIGINT FK | Nullable (null for series-scoped docs) |
| series_id | BIGINT FK | Nullable |
| doc_type | TEXT | See doc types below |
| title | TEXT | |
| markdown_content | TEXT | |
| legacy_google_doc_url | TEXT | For backward compat |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |

Unique constraint: `(project_id, doc_type)` and `(series_id, doc_type)`

#### `document_sections`
| Column | Type |
|---|---|
| id | BIGSERIAL PK |
| project_id | BIGINT FK |
| doc_type | TEXT |
| section_key | TEXT |
| title | TEXT |
| markdown_content | TEXT |
| word_count | INTEGER |
| sort_order | INTEGER |
| created_at | TIMESTAMPTZ |
| updated_at | TIMESTAMPTZ |

Unique constraint: `(project_id, doc_type, section_key)`

#### `image_assets`
| Column | Type |
|---|---|
| id | BIGSERIAL PK |
| storage_path | TEXT |
| thumbnail_path | TEXT |
| file_name | TEXT |
| mime_type | TEXT |
| generator_settings | JSONB |
| created_at | TIMESTAMPTZ |

#### `general_resources`
| Column | Type |
|---|---|
| id | BIGSERIAL PK |
| title | TEXT |
| category | TEXT |
| markdown_content | TEXT |
| word_count | INTEGER |
| sort_order | INTEGER |
| created_at | TIMESTAMPTZ |
| updated_at | TIMESTAMPTZ |

#### `book_creator_pockets`
| Column | Type |
|---|---|
| id | BIGSERIAL PK |
| project_id | BIGINT |
| config | JSONB |

### Series Knowledge / Codex Tables

#### `series_characters`
| Column | Type |
|---|---|
| id | BIGSERIAL PK |
| series_id | BIGINT FK → series(id) ON DELETE CASCADE |
| name | TEXT |
| type | TEXT |
| image_url | TEXT |
| description | TEXT |
| backstory | TEXT |
| significance | TEXT |
| notable_events | TEXT |
| sort_order | INTEGER |
| color | VARCHAR(7) | Hex color (#rrggbb) |
| scope | TEXT | 'book' or 'series' |
| created_at | TIMESTAMPTZ |

#### `series_character_books`
Junction: character ↔ project (book assignment)
| Column | Type |
|---|---|
| id | BIGSERIAL PK |
| character_id | BIGINT FK → series_characters(id) ON DELETE CASCADE |
| project_id | BIGINT |
| notes | TEXT |

#### `series_character_relationships`
| Column | Type |
|---|---|
| id | BIGSERIAL PK |
| character_id | BIGINT FK → series_characters(id) ON DELETE CASCADE |
| related_character_id | BIGINT |
| relationship_type | TEXT |

#### `series_locations`
Same structure as `series_characters` (name, description, sort_order, color, scope, etc.)

#### `series_location_books`
Same structure as `series_character_books`

#### `series_continuity_entries`
| Column | Type |
|---|---|
| id | BIGSERIAL PK |
| series_id | BIGINT FK → series(id) ON DELETE CASCADE |
| title | TEXT |
| type | TEXT |
| image_url | TEXT |
| description | TEXT |
| sort_order | INTEGER |
| scope | TEXT |
| color | VARCHAR(7) |
| created_at | TIMESTAMPTZ |

#### `series_continuity_character_links`
| Column | Type |
|---|---|
| id | BIGSERIAL PK |
| continuity_entry_id | BIGINT FK → series_continuity_entries(id) ON DELETE CASCADE |
| character_id | BIGINT |

#### `series_continuity_location_links`
| Column | Type |
|---|---|
| id | BIGSERIAL PK |
| continuity_entry_id | BIGINT FK → series_continuity_entries(id) ON DELETE CASCADE |
| location_id | BIGINT |

#### `series_continuity_project_links`
| Column | Type |
|---|---|
| id | BIGSERIAL PK |
| continuity_entry_id | BIGINT FK → series_continuity_entries(id) ON DELETE CASCADE |
| project_id | BIGINT |

#### Object Tables (mirror characters/locations)
- `series_objects` — same columns as `series_characters`
- `series_object_books` — junction: object ↔ project
- `series_object_character_links` — junction: object ↔ character
- `series_object_location_links` — junction: object ↔ location
- `series_object_lore_links` — junction: object ↔ lore

#### `series_lore`
| Column | Type |
|---|---|
| id | BIGSERIAL PK |
| series_id | BIGINT FK → series(id) ON DELETE CASCADE |
| name | TEXT |
| image_url | TEXT |
| description | TEXT |
| sort_order | INTEGER |
| color | VARCHAR(7) |
| scope | TEXT |
| created_at | TIMESTAMPTZ |

#### `series_lore_books`
Junction: lore ↔ project

#### `series_subplots`
Same structure as `series_lore`

#### `series_subplot_books`
Junction: subplot ↔ project

#### `series_other`
Same structure as `series_lore`

#### `series_other_books`
Junction: other ↔ project

---

## Document Types

Defined in `scripts/constants.html` (`SUPABASE_PROJECT_MARKDOWN_DOCS`):

| Key (field name) | docType | Scope | Label |
|---|---|---|---|
| draft_doc_url | draft | project | Draft |
| dev_edit_doc_url | dev_edit | project | Development Edit |
| line_edit_doc_url | line_edit | project | Line Edit |
| copy_edit_doc_url | copy_edit | project | Copy Edit |
| outline_doc_url | outline | project | Outline |
| outline_template_doc_url | outline_template | project | Outline Template |
| brainstorm_doc_url | brainstorm | project | Brainstorm |
| notes_doc_url | notes | project | Notes |
| characters_doc_url | characters | project | Characters |
| world_build_doc_url | world_build | project | World Build |
| concept_doc_url | concept | project | Concept |
| series_outline_doc_url | series_outline | series | Series Outline |
| series_brainstorm_doc_url | series_brainstorm | series | Series Brainstorm |
| series_characters_doc_url | series_characters | series | Series Characters |
| series_world_build_doc_url | series_world_build | series | Series World Build |
| series_notes_doc_url | series_notes | series | Series Notes |

---

## Authentication

**File:** `scripts/auth.html`

- Login: `sbClient.auth.signInWithPassword({ email, password })`
- Session resume: `sbClient.auth.getSession()`
- Reactive: `sbClient.auth.onAuthStateChange()` — shows/hides login overlay
- No sign-up flow in the app; users are pre-created in Supabase
- Logout: `sbClient.auth.signOut()`

---

## Row Level Security (RLS)

All tables have a single uniform policy:

```sql
CREATE POLICY "Authenticated full access" ON <table>
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
```

**No per-user or per-row isolation** — any authenticated user can read/write any row.

Storage bucket `project-images` uses the same pattern:
```sql
CREATE POLICY "Authenticated storage access" ON storage.objects
  FOR ALL USING (bucket_id = 'project-images' AND auth.uid() IS NOT NULL);
```

---

## API Call Pattern: `supabaseRunner` Proxy

**File:** `scripts/supabase-runner.html`

Methods are registered with `_sbDefine(name, impl)` and called through the `supabaseRunner` Proxy:

```js
// Registration
_sbDefine('saveProjectJsonFromClient', function(payloadJson) {
  return sbClient.from('projects').update(record).eq('id', payload.rowNumber)
    .then(function(res) { return JSON.stringify({ ok: true }); });
});

// Calling — chainable like google.script.run
supabaseRunner
  .withSuccessHandler(function(data) { ... })
  .withFailureHandler(function(err) { ... })
  .saveProjectJsonFromClient(JSON.stringify(payload));
```

If a method is not registered in `_sbImpl`, the Proxy falls back to `google.script.run` for legacy compatibility.

### Core CRUD Patterns

**Projects:**
- List: `sbClient.from('projects').select(columns).limit(5000).order('id')` — maps via `mapSupabaseProjectToClient_()`
- Update: `sbClient.from('projects').update(record).eq('id', id)`
- Create: `sbClient.from('projects').insert({...}).select('id').single()`

**Documents:**
- Get single: `.from('documents').select('*').eq('project_id', id).eq('doc_type', type).single()`
- Upsert: `.from('documents').upsert(payload, { onConflict: 'project_id,doc_type' })`
- Section list: `.from('document_sections').select('*').eq('project_id', id).eq('doc_type', type).order('sort_order')`
- Section upsert: `.from('document_sections').upsert(rows, { onConflict: 'project_id,doc_type,section_key' })`

**Codex entities** (characters, locations, continuity, objects, lore, subplots, other):
- List by series: `.from('series_<type>').select('*').eq('series_id', id).order('sort_order')`
- Get single with joins: fetches parent + link tables separately, assembles on client
- Save: upsert parent + delete all links + reinsert links
- Delete: cascade — delete links first, then parent

**Resources:**
- List: `.from('general_resources').select('id,title,category,word_count,...').order(...)`
- CRUD: standard select/insert/update/delete by id

---

## File Storage (Supabase Storage)

**Bucket:** `project-images`

**Upload flow** (client-side):
1. Image is resized to 1600px max (webp) + 420px thumbnail (webp)
2. Both uploaded to `project-images` bucket:
   - `originals/{timestamp}-{random}-{name}.webp`
   - `thumbnails/{timestamp}-{random}-{name}-thumb.webp`
3. Metadata recorded in `image_assets` table

**Public URL construction:**
```js
var baseUrl = 'https://bmssizjfkowberhhpyff.supabase.co/storage/v1/object/public/project-images/';
var url = storagePath ? baseUrl + storagePath : legacyDriveUrl;
```

**Delete:** removes storage objects + deletes `image_assets` row + clears `project_image_url` references.

---

## Real-time Subscriptions

**Not used.** The app uses request-response CRUD with a debounced auto-save manager (`scripts/save-manager.html`). No Supabase channels, no `.subscribe()`, no real-time.

---

## Migration SQL Files

All migrations are in `/migrations/` and should be run in order via Supabase SQL Editor:

1. **`enable_rls.sql`** — Enables RLS + creates policies on all core tables and storage
2. **`add_project_outline.sql`** — Adds `outline JSONB` column to `projects`
3. **`add_codex_color.sql`** — Adds `color VARCHAR(7)` to characters, locations, continuity
4. **`add_new_codex_types.sql`** — Creates objects, lore, subplots, other tables + link tables
5. **`enable_rls_new_types.sql`** — Enables RLS on new codex tables
6. **`fix_continuity_schema.sql`** — Adds sort_order/scope/color to continuity + creates link tables
