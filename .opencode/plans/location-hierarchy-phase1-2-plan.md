# Location Hierarchy — Phase 1+2 Plan

## Overview
Build structured location categories, migrate from connection-based hierarchy to a dedicated `parent_location_id` column, add an enhanced parent picker, and implement move/delete with child handling.

## Phase 1: Database Migration + Location Categories

### 1a. Migration: Add `parent_location_id` column

**File:** `migrations/20260917_add_parent_location_id.sql`

```sql
-- Add dedicated parent reference column to codex_entities
ALTER TABLE codex_entities
ADD COLUMN parent_location_id BIGINT REFERENCES codex_entities(id) ON DELETE SET NULL;

-- Index for efficient child queries
CREATE INDEX idx_codex_entities_parent_location ON codex_entities(parent_location_id)
WHERE parent_location_id IS NOT NULL;

-- Migrate existing located_in connections to the new column
-- (Only for active, non-deleted connections with relationship_type key = 'located_in')
UPDATE codex_entities e
SET parent_location_id = c.target_entity_id
FROM codex_connections c
JOIN codex_relationship_types rt ON c.relationship_type_id = rt.id
WHERE c.source_entity_id = e.id
  AND rt.key = 'located_in'
  AND c.deleted_at IS NULL
  AND c.context_status != 'ended'
  AND e.deleted_at IS NULL
  AND (SELECT key FROM codex_entity_types WHERE id = e.entity_type_id) = 'location';
```

**Run manually in Supabase SQL editor** (not via client-side).

### 1b. Supabase CRUD functions

**File:** `scripts/supabase-codex.html`

Add new functions:

- `saveCodexEntityLocation(seriesId, entityId, name, description, categoryId, parentLocationId, customData)` — saves entity + sets `parent_location_id` in one call
- `moveLocation(entityId, newParentId)` — validates no cycle, updates `parent_location_id`
- `getLocationChildren(seriesId, parentId)` — returns direct children by `parent_location_id`
- `getLocationAncestors(entityId)` — walks up the parent chain, returns breadcrumb array
- `searchLocations(seriesId, query)` — searches by name, returns with category and breadcrumb context

**Cycle prevention:** Before setting `parent_location_id`, walk up from `newParentId` to root. If `entityId` is found in the ancestor chain, reject the move.

### 1c. Location Categories

**File:** `scripts/constants.html`

Add location category definitions (configurable per preset):

```javascript
var LOCATION_CATEGORIES = [
  { id: "world",       name: "World",       icon: "\u{1F30D}", color: "#3b82f6" },
  { id: "continent",   name: "Continent",   icon: "\u{1F5FA}\uFE0F", color: "#22c55e" },
  { id: "country",     name: "Country",     icon: "\u{1F1E8}\u{1F1F3}", color: "#f59e0b" },
  { id: "region",      name: "Region",      icon: "\u{1F30F}", color: "#a855f7" },
  { id: "city",        name: "City",        icon: "\u{1F3D9}\uFE0F", color: "#ef4444" },
  { id: "town",        name: "Town",        icon: "\u{1F3E0}", color: "#f97316" },
  { id: "village",     name: "Village",     icon: "\u{1F3E1}", color: "#ec4899" },
  { id: "district",    name: "District",    icon: "\u{1F3D8}\uFE0F", color: "#6366f1" },
  { id: "street",      name: "Street",      icon: "\u{1F6E3}\uFE0F", color: "#14b8a6" },
  { id: "building",    name: "Building",    icon: "\u{1F3E2}", color: "#64748b" },
  { id: "landmark",    name: "Landmark",    icon: "\u{1F5FC}", color: "#eab308" },
  { id: "dungeon",     name: "Dungeon",     icon: "\u{1F47B}", color: "#7c3aed" },
  { id: "custom",      name: "Custom",      icon: "\u{1F4CD}", color: "#94a3b8" }
];
```

**Storage:** Category stored in `custom_data.location_category` as `{ id, name, icon, color }`.

### 1d. Location Detail Form Updates

**File:** `scripts/series-knowledge.html`

For locations specifically (`entityTypeKey === "location"`):

1. **Replace sub_type dropdown with category picker:**
   - Show a `<select>` or CascadeMenu with LOCATION_CATEGORIES
   - Display selected category with icon + color badge
   - Store in `custom_data.location_category`

2. **Replace parent dropdown with enhanced picker:**
   - Show current parent as a clickable breadcrumb: `Eldoria › Aranthia › Valoria › Northreach`
   - Clicking opens a searchable picker
   - Picker shows: `[Icon] Name · Category` for each result
   - Shows breadcrumb context below each result
   - Excludes current location and its descendants
   - "None (root)" option at top

3. **Show breadcrumb on detail page:**
   - Full path from root to current location
   - Each segment is clickable (navigates to that location)
   - Updates immediately after parent change

## Phase 2: Move + Delete/Archive

### 2a. Move Location

**File:** `scripts/series-knowledge.html`

Add "Move" button to location detail header:
1. Opens parent picker (excludes self + descendants)
2. Shows preview of new breadcrumb
3. Confirms if location has children (warns subtree will move)
4. Calls `moveLocation(entityId, newParentId)`
5. Updates breadcrumb and tree immediately

### 2b. Delete/Archive with Child Strategy

**File:** `scripts/series-knowledge.html`

Replace generic delete with location-specific delete modal:
- **Option 1: Archive subtree** (default, safest) — sets `status = 'archived'` on location and all descendants
- **Option 2: Move children to grandparent** — re-parents direct children to deleted location's parent
- **Option 3: Move children to...** — opens picker to choose new parent for children
- **Option 4: Delete subtree** — permanently deletes location and all descendants (with double confirmation)

## Files to Modify

| File | Changes |
|---|---|
| `scripts/constants.html` | Add `LOCATION_CATEGORIES` array |
| `scripts/supabase-codex.html` | Add location CRUD functions, cycle detection |
| `scripts/series-knowledge.html` | Category picker, parent picker, move, delete/archive |
| `scripts/codex-v2-dual-write.html` | Location breadcrumb helper, category helpers |
| `Index.html` | Location detail form updates (if needed) |
| `Styles.html` | Category badge styles, picker styles |
| `migrations/20260917_add_parent_location_id.sql` | Database migration |

## Test Plan

- [ ] Create root location (no parent)
- [ ] Create child location from parent
- [ ] Change parent location (valid move)
- [ ] Prevent move to self (cycle)
- [ ] Prevent move to descendant (cycle)
- [ ] Move location with subtree preserved
- [ ] Breadcrumb updates after move
- [ ] Delete parent — archive subtree
- [ ] Delete parent — move children to grandparent
- [ ] Delete parent — move children to chosen location
- [ ] Delete parent — delete subtree (destructive)
- [ ] Category picker shows all categories with icons
- [ ] Category badge displays correctly in tree and detail
- [ ] Parent picker excludes self and descendants
- [ ] Parent picker shows breadcrumb context
- [ ] Search works across locations
- [ ] Duplicate location names are distinguishable
