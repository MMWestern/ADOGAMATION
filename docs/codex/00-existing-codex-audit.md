# Existing Codex Audit

**Date:** 2026-06-04
**Branch:** `upgrade/worldbuilding` (from `main` at `opencode/silent-pixel`)
**Purpose:** Document every existing Codex integration point before the generic engine rebuild

---

## 1. Prototype Database Tables

### 1.1 Table Inventory

| Table | Migration File | RLS | Columns |
|-------|---------------|-----|---------|
| `series_characters` | original + `add_codex_color.sql` | `enable_rls.sql` | id, series_id, name, role_archetype, archetype, image_url, description, motivation_arc, backstory, sort_order, color, scope, created_at |
| `series_character_books` | original | `enable_rls.sql` | id, character_id, project_id, notes |
| `series_character_relationships` | original | `enable_rls.sql` | id, series_id, character_id_a, character_id_b, relationship_type, description |
| `series_locations` | original + `add_codex_color.sql` | `enable_rls.sql` | id, series_id, name, type, image_url, description, significance, notable_events, sort_order, color, scope, created_at |
| `series_location_books` | original | `enable_rls.sql` | id, location_id, project_id, notes |
| `series_continuity_entries` | original + `add_codex_color.sql` + `fix_continuity_schema.sql` | `enable_rls.sql` | id, series_id, title, image_url, description, severity, resolved, sort_order, scope, color, created_at |
| `series_continuity_character_links` | `fix_continuity_schema.sql` | `fix_continuity_schema.sql` | id, continuity_entry_id, character_id |
| `series_continuity_location_links` | `fix_continuity_schema.sql` | `fix_continuity_schema.sql` | id, continuity_entry_id, location_id |
| `series_continuity_project_links` | `fix_continuity_schema.sql` | `fix_continuity_schema.sql` | id, continuity_entry_id, project_id |
| `series_objects` | `add_new_codex_types.sql` | `enable_rls_new_types.sql` | id, series_id, name, type, image_url, description, significance, notable_events, sort_order, color, scope, created_at |
| `series_object_books` | `add_new_codex_types.sql` | `enable_rls_new_types.sql` | id, object_id, project_id, notes |
| `series_object_character_links` | `add_new_codex_types.sql` | `enable_rls_new_types.sql` | id, object_id, character_id |
| `series_object_location_links` | `add_new_codex_types.sql` | `enable_rls_new_types.sql` | id, object_id, location_id |
| `series_object_lore_links` | `add_new_codex_types.sql` | `enable_rls_new_types.sql` | id, object_id, lore_id |
| `series_lore` | `add_new_codex_types.sql` | `enable_rls_new_types.sql` | id, series_id, name, image_url, description, sort_order, color, scope, created_at |
| `series_lore_books` | `add_new_codex_types.sql` | `enable_rls_new_types.sql` | id, lore_id, project_id, notes |
| `series_subplots` | `add_new_codex_types.sql` | `enable_rls_new_types.sql` | id, series_id, name, image_url, description, sort_order, color, scope, created_at |
| `series_subplot_books` | `add_new_codex_types.sql` | `enable_rls_new_types.sql` | id, subplot_id, project_id, notes |
| `series_other` | `add_new_codex_types.sql` | `enable_rls_new_types.sql` | id, series_id, name, image_url, description, sort_order, color, scope, created_at |
| `series_other_books` | `add_new_codex_types.sql` | `enable_rls_new_types.sql` | id, other_id, project_id, notes |

**Total: 21 tables** (7 entity tables, 7 book-link tables, 5 cross-entity link tables, 1 relationship table, 1 legacy knowledge document)

### 1.2 Row Counts

**Row counts (confirmed 2026-06-04):**

| Table | Rows |
|-------|------|
| `series_characters` | 26 |
| `series_character_books` | 12 |
| `series_character_relationships` | 3 |
| `series_locations` | 2 |
| `series_location_books` | 0 |
| `series_continuity_entries` | 2 |
| `series_continuity_character_links` | 0 |
| `series_continuity_location_links` | 0 |
| `series_continuity_project_links` | 1 |
| `series_objects` | 1 |
| `series_object_books` | 1 |
| `series_object_character_links` | 0 |
| `series_object_location_links` | 0 |
| `series_object_lore_links` | 0 |
| `series_lore` | 2 |
| `series_lore_books` | 2 |
| `series_subplots` | 1 |
| `series_subplot_books` | 1 |
| `series_other` | 1 |
| `series_other_books` | 1 |

**Total: 57 rows across 20 tables.** Confirms handover note that prototype tables contain minimal data. The series lore textarea content lives in `documents` table as `doc_type = 'series_knowledge_registry'`.

### 1.3 RLS Policy

All tables use the same policy:
```sql
CREATE POLICY "Authenticated full access" ON <table>
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
```
This grants full CRUD to any authenticated user. No series-level isolation.

---

## 2. Supabase Service Layer (`_sbDefine` methods)

**File:** `scripts/data-operations.html`

### 2.1 Series Knowledge (Lore Textarea)

| Method | Line | Supabase Table | Direction |
|--------|------|----------------|-----------|
| `getSupabaseSeriesKnowledgeJsonFromClient` | 267 | `documents` (doc_type=series_knowledge_registry) | READ |
| `saveSupabaseSeriesKnowledgeJsonFromClient` | 293 | `documents` (doc_type=series_knowledge_registry) | WRITE |
| `getSupabaseSeriesProjectsBySeriesIdJsonFromClient` | 319 | `projects` | READ |

### 2.2 Characters

| Method | Line | Supabase Table | Direction |
|--------|------|----------------|-----------|
| `listSupabaseSeriesCharactersJsonFromClient` | 327 | `series_characters` | READ |
| `getSupabaseSeriesCharacterJsonFromClient` | 334 | `series_characters` + `series_character_books` + `series_character_relationships` | READ |
| `saveSupabaseSeriesCharacterJsonFromClient` | 347 | `series_characters` + `series_character_books` | WRITE |
| `deleteSupabaseSeriesCharacterJsonFromClient` | 386 | `series_characters` + `series_character_books` + `series_character_relationships` | DELETE |
| `saveSupabaseSeriesCharacterRelationshipJsonFromClient` | 396 | `series_character_relationships` | WRITE |
| `deleteSupabaseSeriesCharacterRelationshipJsonFromClient` | 409 | `series_character_relationships` | DELETE |
| `listSeriesCharacterBookLinksJsonFromClient` | 422 | `series_characters` + `series_character_books` | READ |

### 2.3 Locations

| Method | Line | Supabase Table | Direction |
|--------|------|----------------|-----------|
| `listSupabaseSeriesLocationsJsonFromClient` | 415 | `series_locations` | READ |
| `getSupabaseSeriesLocationJsonFromClient` | 500 | `series_locations` + `series_location_books` | READ |
| `saveSupabaseSeriesLocationJsonFromClient` | 512 | `series_locations` + `series_location_books` | WRITE |
| `deleteSupabaseSeriesLocationJsonFromClient` | 548 | `series_locations` + `series_location_books` | DELETE |
| `listSeriesLocationBookLinksJsonFromClient` | 435 | `series_locations` + `series_location_books` | READ |

### 2.4 Continuity

| Method | Line | Supabase Table | Direction |
|--------|------|----------------|-----------|
| `listSupabaseSeriesContinuityEntriesJsonFromClient` | 558 | `series_continuity_entries` | READ |
| `getSupabaseSeriesContinuityEntryJsonFromClient` | 565 | `series_continuity_entries` + 3 link tables | READ |
| `saveSupabaseSeriesContinuityEntryJsonFromClient` | 589 | `series_continuity_entries` + 3 link tables | WRITE |
| `deleteSupabaseSeriesContinuityEntryJsonFromClient` | 633 | `series_continuity_entries` + 3 link tables | DELETE |

### 2.5 Objects

| Method | Line | Supabase Table | Direction |
|--------|------|----------------|-----------|
| `listSupabaseSeriesObjectsJsonFromClient` | 646 | `series_objects` | READ |
| `getSupabaseSeriesObjectJsonFromClient` | 653 | `series_objects` + `series_object_books` + 3 link tables | READ |
| `saveSupabaseSeriesObjectJsonFromClient` | 673 | `series_objects` + `series_object_books` + 3 link tables | WRITE |
| `deleteSupabaseSeriesObjectJsonFromClient` | 724 | `series_objects` + all link tables | DELETE |
| `listSeriesObjectBookLinksJsonFromClient` | 448 | `series_objects` + `series_object_books` | READ |

### 2.6 Lore

| Method | Line | Supabase Table | Direction |
|--------|------|----------------|-----------|
| `listSupabaseSeriesLoreJsonFromClient` | 738 | `series_lore` | READ |
| `getSupabaseSeriesLoreJsonFromClient` | 745 | `series_lore` + `series_lore_books` | READ |
| `saveSupabaseSeriesLoreJsonFromClient` | 757 | `series_lore` + `series_lore_books` | WRITE |
| `deleteSupabaseSeriesLoreJsonFromClient` | 792 | `series_lore` + `series_lore_books` | DELETE |
| `listSeriesLoreBookLinksJsonFromClient` | 461 | `series_lore` + `series_lore_books` | READ |

### 2.7 Subplots

| Method | Line | Supabase Table | Direction |
|--------|------|----------------|-----------|
| `listSupabaseSeriesSubplotsJsonFromClient` | 803 | `series_subplots` | READ |
| `getSupabaseSeriesSubplotJsonFromClient` | 810 | `series_subplots` + `series_subplot_books` | READ |
| `saveSupabaseSeriesSubplotJsonFromClient` | 822 | `series_subplots` + `series_subplot_books` | WRITE |
| `deleteSupabaseSeriesSubplotJsonFromClient` | 857 | `series_subplots` + `series_subplot_books` | DELETE |
| `listSeriesSubplotBookLinksJsonFromClient` | 474 | `series_subplots` + `series_subplot_books` | READ |

### 2.8 Other

| Method | Line | Supabase Table | Direction |
|--------|------|----------------|-----------|
| `listSupabaseSeriesOtherJsonFromClient` | 868 | `series_other` | READ |
| `getSupabaseSeriesOtherJsonFromClient` | 875 | `series_other` + `series_other_books` | READ |
| `saveSupabaseSeriesOtherJsonFromClient` | 887 | `series_other` + `series_other_books` | WRITE |
| `deleteSupabaseSeriesOtherJsonFromClient` | 922 | `series_other` + `series_other_books` | DELETE |
| `listSeriesOtherBookLinksJsonFromClient` | 487 | `series_other` + `series_other_books` | READ |

**Total: 38 `_sbDefine` methods** related to codex/series knowledge

---

## 3. UI Integration Map

### 3.1 Knowledge Tab (Main Tab)

**File:** `Index.html:319` + `Index.html:565-615`

**Tab Button:**
```html
<button id="mainTabSeriesKnowledge" class="main-tab" type="button" data-main-tab="seriesknowledge">KNOWLEDGE</button>
```

**Tab Content:** `#mainTabContentSeriesknowledge` (lines 565-615)
- Series header with name/project display
- 4 sub-tabs: Lore, Characters, Locations, Continuity
- Lore textarea (`#resourceSeriesKnowledgeLore`)
- Entity lists (`#skCharacterList`, `#skLocationList`, `#skContinuityList`)
- Entity forms (`#skCharacterForm`, `#skLocationForm`, `#skContinuityForm`)
- Detail panels (`#skCharacterDetail`, `#skLocationDetail`, `#skContinuityDetail`)
- Status bar (`#resourceSeriesKnowledgeStatus`)

**Tab Switching Logic:** `Client.html:5056-5073`
```js
setMainTab("seriesknowledge") → shows #mainTabContentSeriesknowledge
                               → hides projectInspectorPanel
                               → shows seriesKnowledgeFormsPanel
                               → hides searchPanelContent
```

### 3.2 Writing Sidebar Codex (Left Panel)

**File:** `Client.html:2394-3407`

**DOM Elements** (from `scripts/el-cache.html:312-390`):
- `#writingCodexPanel` — outer container
- `#writingSidebarTabCodex` / `#writingSidebarTabChapters` — tab buttons
- `#writingCodexView` / `#writingChaptersView` — tab content
- `#writingCodexSearchInput` / `#writingCodexSearchClear` — search
- `#writingCodexFilterAll` / `#writingCodexFilterSeries` / `#writingCodexFilterBook` — scope filters
- `#writingCodexNewEntry` / `#writingCodexNewEntryDropdown` — new entry action
- `#writingCodexList` — entry list container
- Info panel: `#writingCodexInfoImage`, `#writingCodexInfoTitle`, `#writingCodexInfoSeries`, `#writingCodexInfoGenre`, `#writingCodexInfoAuthor`, `#writingCodexInfoWords`

**Key Functions:**
- `getWritingCodexEntries(project)` — `Client.html:2394` — assembles flat entry array from all `skCache.*` arrays
- `getWritingCodexEntryByKey(project, key)` — `Client.html:2509` — lookup by composite key
- `getWritingCodexCachedPayload(seriesId, type, id)` — `Client.html:2519` — reads from `skCache.*[seriesId]`
- `getWritingCodexCachedExtra(type, id)` — `Client.html:2547` — reads detail caches
- `renderWritingCodexList(project)` — `Client.html:3278` — renders grouped sidebar cards
- `updateWritingInspectorCodex(project)` — `Client.html:3415` — updates right inspector panel

**Data Flow:**
```
skCache.characters[seriesId]  ─┐
skCache.locations[seriesId]   ─┤
skCache.objects[seriesId]     ─┤
skCache.lore[seriesId]        ─┼──→ getWritingCodexEntries() ──→ renderWritingCodexList()
skCache.subplots[seriesId]    ─┤                                       │
skCache.other[seriesId]       ─┤                                       ▼
skCache.continuity[seriesId]  ─┘                           grouped sidebar cards
```

**Entry Shape:**
```js
{
  key: "character::123",    // composite key: type::id
  type: "characters",       // category key
  title: "John Doe",
  body: "A brave warrior...",
  badge: "Warrior",
  color: "#ff0000",
  role: "Warrior",
  archetype: "Hero",
  scope: "book",
  bookLinks: [{ project_id: 456 }]
}
```

**Grouping:** `["characters", "locations", "objects", "continuity", "lore", "subplots", "other"]`

### 3.3 Writing Codex Modal (Quick Edit)

**File:** `Client.html:2565-3270`

**DOM Elements** (from `scripts/el-cache.html:335-390`):
- `#writingCodexModal` — modal container
- 5 tabs: Details, Research, Relations, Mentions, Tracking
- Title: `#writingCodexModalTitle`
- Badge/Role/Archetype: `#writingCodexModalBadgeInput`, `#writingCodexModalRoleSelect`, `#writingCodexModalArchetypeSelect`
- Scope: `#writingCodexModalScopeSelect`
- Severity (continuity): `#writingCodexModalSeveritySelect`
- Image: `#writingCodexModalImage`, `#writingCodexModalImageUrl`
- Color: `#writingCodexModalColorTrigger`
- Primary/Secondary/Tertiary textareas (mapped per type)
- Relations panel: `#writingCodexRelationsPanel`, `#writingCodexRelationsList`
- Research: `#writingCodexModalResearch`
- Mentions: `#writingCodexModalMentions`
- Tracking: `#writingCodexModalTracking`
- Save button: `#writingCodexModalSaveButton`

**Key Functions:**
- `populateWritingCodexModal(entry, payload, extra)` — `Client.html:2729` — loads modal fields per type
- `setWritingCodexModalTab(tabKey)` — `Client.html:2674` — switches tabs
- `renderWritingCodexRelations(entry, extra)` — `Client.html:2605` — renders character relationships + object links
- `saveWritingCodexModal()` — `Client.html:3071` — builds type-specific payload, calls `_sbDefine` save
- `closeWritingCodexModal()` — `Client.html:2565` — resets modal state

**Save Dispatch** (`Client.html:3174-3186`):
```js
type → saverName mapping:
  "characters" → "saveSupabaseSeriesCharacterJsonFromClient"
  "locations"  → "saveSupabaseSeriesLocationJsonFromClient"
  "objects"    → "saveSupabaseSeriesObjectJsonFromClient"
  "lore"       → "saveSupabaseSeriesLoreJsonFromClient"
  "subplots"   → "saveSupabaseSeriesSubplotJsonFromClient"
  "other"      → "saveSupabaseSeriesOtherJsonFromClient"
  (default)    → "saveSupabaseSeriesContinuityEntryJsonFromClient"
```

### 3.4 Writing Inspector (Right Panel)

**File:** `Client.html:3415-3422`

**DOM Elements:**
- `#writingInspectorPanel` — container
- `#writingInspectorCodexTitle` — selected entry title
- `#writingInspectorCodexBody` — selected entry body

**Function:** `updateWritingInspectorCodex(project)` reads `getWritingCodexEntries()` and displays the selected entry.

### 3.5 Plan Tab Codex Tags

**File:** `scripts/plan-outline.html:726-968`

**DOM Elements** (from `scripts/el-cache.html:496-499`):
- `#planCodexTagModal` — modal for adding codex tags to scenes
- `#planCodexTagList` — searchable list of all codex entries
- `#planCodexTagSearch` — search input
- `#planCodexTagClose` — close button

**Key Functions:**
- `getPlanSceneCodexTags(scene, characters, locations, objects, lore, subplots, other, continuity, showRemove)` — `plan-outline.html:726` — renders codex tag chips for a scene
- `openPlanCodexTagModal(sceneId)` — `plan-outline.html:885` — opens modal to add tags
- `renderPlanCodexTagList(query)` — `plan-outline.html:901` — renders searchable entry list
- `_getSceneTaggedCharacters(scene, characters)` — `plan-outline.html:796` — extracts tagged characters for POV popup

**Scene Data Shape** (stored in `projects.outline` JSONB):
```js
scene = {
  id: "scene-uuid",
  text: "Scene description...",
  povType: "Third Person Limited",
  povCharacterId: "123",
  characterIds: [123, 456],          // legacy field
  codexEntries: [                     // new field
    { id: 123, type: "characters" },
    { id: 789, type: "locations" }
  ]
}
```

### 3.6 Writing Workspace Editor Integration

**File:** `Client.html:2376-2393` (filter binding)

Filters (All/Series/Book) toggle `appState.writingWorkspace.filter` and re-render the sidebar list.

---

## 4. In-Memory Cache (`skCache`)

**File:** `scripts/series-knowledge.html:1-14`

```js
var skCache = {
    characters: {},      // seriesId → [character rows]
    locations: {},       // seriesId → [location rows]
    continuity: {},      // seriesId → [continuity rows]
    objects: {},         // seriesId → [object rows]
    lore: {},            // seriesId → [lore rows]
    subplots: {},        // seriesId → [subplot rows]
    other: {},           // seriesId → [other rows]
    seriesProjects: {},  // seriesId → [project rows]
    characterDetails: {}, // characterId → { bookLinks, relationships }
    locationDetails: {},  // locationId → { bookLinks }
    continuityDetails: {}, // continuityEntryId → { linkedCharacterIds, linkedLocationIds, linkedProjectIds }
    objectDetails: {}     // objectId → { bookLinks, linkedCharacterIds, linkedLocationIds, linkedLoreIds }
};
```

**Population:** `loadSkEntities(seriesId)` in `series-knowledge.html:222-234` loads all 8 entity types in parallel.

**Consumers:**
1. Knowledge tab entity lists and forms (series-knowledge.html)
2. Writing sidebar codex list (Client.html `getWritingCodexEntries`)
3. Writing codex modal (Client.html `getWritingCodexCachedPayload/Extra`)
4. Plan outline codex tags (plan-outline.html `getPlanSceneCodexTags`)

---

## 5. Save Manager Integration

**File:** `scripts/save-manager.html`

Two codex-related save areas:
- `seriesKnowledge` — debounce: 0ms, enabled: true — saves the lore textarea
- `writingCodex` — debounce: 1000ms, enabled: true — saves quick-edit modal changes

These are included in the global area keys at lines 227 and 249:
```js
var areaKeys = ["workspace", "projectDetails", "planOutline", "resources", "seriesKnowledge", "writingCodex"];
```

---

## 6. Element Cache (All Codex-Related IDs)

**File:** `scripts/el-cache.html`

### 6.1 Knowledge Tab Elements

| Element ID | Line | Purpose |
|-----------|------|---------|
| `mainTabSeriesKnowledge` | 307 | Tab button |
| `mainTabContentSeriesknowledge` | 308 | Tab content container |
| `resourceSeriesKnowledgeSeriesName` | 422 | Series name display |
| `resourceSeriesKnowledgeProjectName` | 423 | Project name display |
| `resourceSeriesKnowledgeLore` | 424 | Lore textarea |
| `resourceSeriesKnowledgeSaveButton` | 425 | Save button |
| `resourceSeriesKnowledgeStatus` | 426 | Status bar |
| `seriesKnowledgeFormsPanel` | 411 | Forms panel container |
| `skSubTabLore` | 462 | Sub-tab button |
| `skSubTabCharacters` | 463 | Sub-tab button |
| `skSubTabLocations` | 464 | Sub-tab button |
| `skSubTabContinuity` | 465 | Sub-tab button |
| `skTabLore` | 466 | Sub-tab pane |
| `skTabCharacters` | 500 | Sub-tab pane |
| `skTabLocations` | 501 | Sub-tab pane |
| `skTabContinuity` | 502 | Sub-tab pane |

### 6.2 Character Elements (38 IDs)

| Element ID | Line |
|-----------|------|
| `skCharacterAddButton` | 503 |
| `skCharacterList` | 504 |
| `skCharacterForm` | 505 |
| `skCharacterId` | 506 |
| `skCharacterName` | 507 |
| `skCharacterNameDisplay` | 508 |
| `skCharacterRole` | 509 |
| `skCharacterRoleBadge` | 510 |
| `skCharacterArchetypeBadge` | 511 |
| `skCharacterArchetype` | 512 |
| `skCharacterColorPicker` | 513 |
| `skCharacterColorTrigger` | 514 |
| `skCharacterColorDropdown` | 515 |
| `skCharacterImageUrl` | 516 |
| `skCharacterImage` | 517 |
| `skCharacterImagePlaceholder` | 518 |
| `skCharacterDescription` | 519 |
| `skCharacterMotivation` | 520 |
| `skCharacterBackstory` | 521 |
| `skCharacterBookLinks` | 522 |
| `skCharacterRelationships` | 523 |
| `skCharacterRelOther` | 524 |
| `skCharacterRelType` | 525 |
| `skCharacterRelAddButton` | 526 |
| `skCharacterFormSaveButton` | 527 |
| `skCharacterFormCancelButton` | 528 |
| `skCharacterFormDeleteButton` | 529 |
| `skCharacterDetail` | 570 |

### 6.3 Location Elements (20 IDs)

| Element ID | Line |
|-----------|------|
| `skLocationAddButton` | 530 |
| `skLocationList` | 531 |
| `skLocationForm` | 532 |
| `skLocationId` | 533 |
| `skLocationName` | 534 |
| `skLocationNameDisplay` | 535 |
| `skLocationType` | 536 |
| `skLocationTypeBadge` | 537 |
| `skLocationImageUrl` | 538 |
| `skLocationImage` | 539 |
| `skLocationImagePlaceholder` | 540 |
| `skLocationDescription` | 541 |
| `skLocationSignificance` | 542 |
| `skLocationEvents` | 543 |
| `skLocationBookLinks` | 544 |
| `skLocationFormSaveButton` | 545 |
| `skLocationFormCancelButton` | 546 |
| `skLocationFormDeleteButton` | 547 |
| `skLocationDetail` | 571 |

### 6.4 Continuity Elements (22 IDs)

| Element ID | Line |
|-----------|------|
| `skContinuityAddButton` | 548 |
| `skContinuityList` | 549 |
| `skContinuityForm` | 550 |
| `skContinuityId` | 551 |
| `skContinuityTitle` | 552 |
| `skContinuityTitleDisplay` | 553 |
| `skContinuitySeverityBadge` | 554 |
| `skContinuityImageUrl` | 555 |
| `skContinuityImage` | 556 |
| `skContinuityImagePlaceholder` | 557 |
| `skContinuityDescription` | 558 |
| `skContinuitySeverity` | 559 |
| `skContinuityResolved` | 560 |
| `skContinuityCharPicks` | 561 |
| `skContinuityCharAdd` | 562 |
| `skContinuityLocPicks` | 563 |
| `skContinuityLocAdd` | 564 |
| `skContinuityProjectPicks` | 565 |
| `skContinuityProjectAdd` | 566 |
| `skContinuityFormSaveButton` | 567 |
| `skContinuityFormCancelButton` | 568 |
| `skContinuityFormDeleteButton` | 569 |
| `skContinuityDetail` | 572 |

### 6.5 Writing Sidebar Codex Elements (38 IDs)

| Element ID | Line |
|-----------|------|
| `writingCodexPanel` | 312 |
| `writingSidebarTabCodex` | 313 |
| `writingSidebarTabChapters` | 314 |
| `writingCodexView` | 315 |
| `writingChaptersView` | 316 |
| `writingCodexInfoImage` | 317 |
| `writingCodexInfoTitle` | 318 |
| `writingCodexInfoSeries` | 319 |
| `writingCodexSeriesButton` | 320 |
| `writingCodexInfoGenre` | 321 |
| `writingCodexInfoAuthor` | 322 |
| `writingCodexInfoWords` | 323 |
| `writingCodexSearchInput` | 324 |
| `writingCodexSearchClear` | 325 |
| `writingCodexFilterAll` | 328 |
| `writingCodexFilterSeries` | 329 |
| `writingCodexFilterBook` | 330 |
| `writingCodexNewEntry` | 331 |
| `writingCodexNewEntryDropdown` | 332 |
| `writingCodexList` | 333 |

### 6.6 Writing Codex Modal Elements (38 IDs)

| Element ID | Line |
|-----------|------|
| `writingCodexModal` | 335 |
| `writingCodexModalType` | 336 |
| `writingCodexTabDetails` | 337 |
| `writingCodexTabResearch` | 338 |
| `writingCodexTabRelations` | 339 |
| `writingCodexTabMentions` | 340 |
| `writingCodexTabTracking` | 341 |
| `writingCodexModalTitle` | 342 |
| `writingCodexModalBadgeWrap` | 343 |
| `writingCodexModalBadgeInput` | 344 |
| `writingCodexModalRolePill` | 345 |
| `writingCodexModalArchetypePill` | 346 |
| `writingCodexModalRoleSelect` | 347 |
| `writingCodexModalArchetypeSelect` | 348 |
| `writingCodexModalRoleArchetypeRow` | 349 |
| `writingCodexModalScopeSelect` | 350 |
| `writingCodexModalSeriesBanner` | 351 |
| `writingCodexModalSeveritySelect` | 352 |
| `writingCodexModalImage` | 353 |
| `writingCodexModalAvatarShell` | 354 |
| `writingCodexModalAvatarFallback` | 355 |
| `writingCodexModalMeta` | 356 |
| `writingCodexModalStatus` | 357 |
| `writingCodexModalForm` | 358 |
| `writingCodexModalPrimaryGroup` | 359 |
| `writingCodexModalPrimaryLabel` | 360 |
| `writingCodexModalPrimaryHelp` | 361 |
| `writingCodexModalPrimary` | 362 |
| `writingCodexModalSecondaryGroup` | 363 |
| `writingCodexModalSecondaryLabel` | 364 |
| `writingCodexModalSecondaryHelp` | 365 |
| `writingCodexModalSecondary` | 366 |
| `writingCodexModalSecondarySelect` | 367 |
| `writingCodexModalTertiaryGroup` | 368 |
| `writingCodexModalTertiaryLabel` | 369 |
| `writingCodexModalTertiaryHelp` | 370 |
| `writingCodexModalTertiary` | 371 |
| `writingCodexModalImageGroup` | 372 |
| `writingCodexModalImageUrl` | 373 |
| `writingCodexModalColor` | 374 |
| `writingCodexModalColorTrigger` | 375 |
| `writingCodexModalColorDropdown` | 376 |
| `writingCodexModalResolvedGroup` | 377 |
| `writingCodexModalResolved` | 378 |
| `writingCodexRelationsPanel` | 379 |
| `writingCodexRelationsEmpty` | 380 |
| `writingCodexRelationsList` | 381 |
| `writingCodexModalResearchPanel` | 382 |
| `writingCodexModalResearch` | 383 |
| `writingCodexModalMentionsPanel` | 384 |
| `writingCodexModalMentions` | 385 |
| `writingCodexModalTrackingPanel` | 386 |
| `writingCodexModalTracking` | 387 |
| `writingCodexModalWordCount` | 388 |
| `writingCodexModalCopyButton` | 389 |
| `writingCodexModalSaveButton` | 390 |

### 6.7 Plan Codex Tag Elements (4 IDs)

| Element ID | Line |
|-----------|------|
| `planCodexTagModal` | 496 |
| `planCodexTagList` | 497 |
| `planCodexTagSearch` | 498 |
| `planCodexTagClose` | 499 |

**Total: ~158 codex-related DOM element IDs**

---

## 7. Files Affected by Codex Integration

| File | Role | Codex-Related Lines (approx) |
|------|------|------------------------------|
| `Index.html` | Tab buttons, tab content HTML, DOM structure | 319, 565-615 |
| `Client.html` | Sidebar rendering, modal CRUD, inspector, tab switching, filters, save dispatch | 2376-3270, 3278-3407, 3415-3422, 3917-3979, 5056-5073, 5133-5135, 6373, 6502, 6552, 6494 |
| `scripts/series-knowledge.html` | skCache, entity CRUD, knowledge panel, auto-select | Entire file (1265 lines) |
| `scripts/data-operations.html` | `_sbDefine` CRUD methods for all 7 categories | 267-929 (~660 lines) |
| `scripts/plan-outline.html` | Codex tag rendering on scenes, tag modal, POV popup | 726-968 (~240 lines) |
| `scripts/el-cache.html` | Element cache for all codex DOM IDs | 307-308, 312-390, 411, 422-426, 462-466, 496-499, 500-572 |
| `scripts/save-manager.html` | Save areas: seriesKnowledge + writingCodex | 19-20, 52-58, 90-93, 227, 249 |
| `scripts/bind-events.html` | Tab binding | 2, 1228 |
| `Styles.html` | Knowledge tab styles | 3019 |

---

## 8. Data Flow Diagrams

### 8.1 Knowledge Tab Load Flow

```
User selects project
  → setMainTab("seriesknowledge")
  → renderSeriesKnowledgePanel(project)        [series-knowledge.html:114]
  → loadSeriesKnowledgeForSelectedProject()    [series-knowledge.html:146]
    → getSupabaseSeriesKnowledgeJsonFromClient [data-operations.html:267]
    → stores in appState.seriesKnowledgeById[seriesId]
    → loadSkEntities(seriesId)                 [series-knowledge.html:222]
      → loadSkCharacters(seriesId)             → listSupabaseSeriesCharactersJsonFromClient
      → loadSkLocations(seriesId)              → listSupabaseSeriesLocationsJsonFromClient
      → loadSkContinuityEntries(seriesId)      → listSupabaseSeriesContinuityEntriesJsonFromClient
      → loadSkObjects(seriesId)                → listSupabaseSeriesObjectsJsonFromClient
      → loadSkLore(seriesId)                   → listSupabaseSeriesLoreJsonFromClient
      → loadSkSubplots(seriesId)               → listSupabaseSeriesSubplotsJsonFromClient
      → loadSkOther(seriesId)                  → listSupabaseSeriesOtherJsonFromClient
      → loadSkSeriesProjects(seriesId)         → getSupabaseSeriesProjectsBySeriesIdJsonFromClient
    → populates skCache.*[seriesId]
    → renders entity lists
```

### 8.2 Writing Sidebar Codex Load Flow

```
User opens WRITING tab with a project selected
  → loadSeriesKnowledgeForSelectedProject() (already called during project select)
  → skCache is populated
  → renderWritingCodexList(project)            [Client.html:3278]
  → getWritingCodexEntries(project)            [Client.html:2394]
    → reads skCache.characters[seriesId]
    → reads skCache.locations[seriesId]
    → reads skCache.objects[seriesId]
    → reads skCache.lore[seriesId]
    → reads skCache.subplots[seriesId]
    → reads skCache.other[seriesId]
    → reads skCache.continuity[seriesId]
    → reads appState.seriesKnowledgeById[seriesId].lore (series lore entry)
  → returns flat entries array
  → groups by type, renders sidebar cards
```

### 8.3 Quick Edit Save Flow

```
User edits entry in modal → clicks Save
  → saveWritingCodexModal()                    [Client.html:3071]
  → builds type-specific payload
  → dispatches to appropriate _sbDefine save method
  → Supabase CRUD
  → reloads skCache for that type
  → re-renders sidebar list
  → re-renders plan outline (if PLAN tab active)
```

---

## 9. Backward Compatibility Requirements

The following must remain functional through any migration:

1. **Knowledge tab** — Lore textarea reads/writes to `documents` table (doc_type=series_knowledge_registry)
2. **Writing sidebar** — Compact entity cards with search, filters, grouping, color dots, badges
3. **Writing quick-edit modal** — All 5 tabs (Details, Research, Relations, Mentions, Tracking) + save
4. **Writing inspector** — Selected entry display in right panel
5. **Plan outline codex tags** — Scene-level codex entry tagging in outline JSONB
6. **Plan POV popup** — Character selection from scene-tagged characters
7. **Save manager** — Both `seriesKnowledge` and `writingCodex` autosave areas
8. **Image picker** — Entity images via `#writingCodexModalImageUrl`

---

## 10. Safe Tables (Do Not Touch)

These tables are **independent** from the Codex rebuild:

- `projects` — book metadata, outline JSONB, short_summary
- `series` — series name, summary, images
- `documents` — manuscript content, series_knowledge_registry
- `document_sections` — chapter sections
- `image_assets` — uploaded images
- `general_resources` — reference documents
- `book_creator_pockets` — book creator library

---

## 11. Migration Strategy Notes

1. **Prototype tables have little/no data** per handover — can be retired after verification
2. **No complex migration needed** — build new generic tables alongside, switch via feature flag
3. **`series_lore` is separate from the lore textarea** — textarea stores in `documents`, `series_lore` stores structured entries
4. **Book assignment pattern** is consistent: each category has a `*_books` junction table
5. **Cross-entity links exist only for**: characters↔continuity, locations↔continuity, objects↔characters/locations/lore
6. **No generic connection system** exists — each entity has hard-coded link tables

---

## 12. Decisions Requiring Review Before Phase 1

1. **Rename KNOWLEDGE → CODEX immediately?** (recommended yes — reduces double-editing)
2. **Keep prototype tables alive during transition?** (recommended yes — use feature flag to switch)
3. **Scope of Phase 1 core tables?** (8 tables: entity_types, entities, entity_projects, relationship_types, connections, tags, entity_tags, entity_revisions)
4. **New migration file naming convention?** (e.g., `[timestamp]_create_codex_core.sql`)
5. **Where to put `supabase-codex.html`?** (in `scripts/` alongside existing files)
6. **Feature flag location?** (in `scripts/constants.html`)
