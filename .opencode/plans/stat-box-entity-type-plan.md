# Stat Box Entity Type System — Implementation Plan

**Date:** 9 September 2026
**Status:** PLAN — awaiting approval

---

## Overview

Upgrade the stat box display system from hardcoded property key names to dynamic entity type-based rendering. This makes the system flexible — any stat/resource entity automatically gets the correct visual treatment without code changes.

---

## Current System (Hardcoded)

```javascript
// Hardcoded maps in codex-v2-dual-write.html
var codexV2StatDefs = {
  strength: { abbr: "STR", cls: "stat-str" },
  intelligence: { abbr: "INT", cls: "stat-int" },
  // ... only recognizes these specific names
};
```

**Problems:**
- New stats require code changes
- Custom stat names (e.g., "Power", "Luck") won't get stat boxes
- No hover info or descriptions

---

## New System (Entity Type Based)

### How It Works

1. State record has `property_entity_id` → look up entity
2. Entity has `entity_type_key` (stat, resource, level, etc.)
3. Use entity type to determine display style
4. Generate abbreviation from entity name (3-letter, uppercase)
5. Show hover tooltip with full name + description

### Categorization Logic

```
State Record
  ↓
Has property_entity_id?
  ├─ YES → Look up entity → Get entity_type_key
  │         ├─ stat → Stat box (red/blue/green/etc.)
  │         ├─ resource → Resource box (HP/MP style)
  │         ├─ level → Level box (larger, purple)
  │         └─ other → Plain list
  │
  └─ NO → Fall back to hardcoded property_key maps
           (backward compatibility for legacy data)
```

---

## Implementation Details

### 1. Update `codexV2CategorizeState` Function

**File:** `scripts/codex-v2-dual-write.html`

**Current signature:**
```javascript
function codexV2CategorizeState(resolved)
```

**New signature:**
```javascript
function codexV2CategorizeState(resolved, entities)
```

**Logic:**
```javascript
function codexV2CategorizeState(resolved, entities) {
  var level = [];
  var stats = [];
  var resources = [];
  var other = [];
  var entityMap = {};
  
  // Build entity lookup map
  (entities || []).forEach(function (e) {
    entityMap[Number(e.id)] = e;
  });

  (resolved || []).forEach(function (s) {
    var key = (s.property_key || "").toLowerCase();
    var value = s.value_number != null ? String(s.value_number) : (s.value_text || "—");
    var entry = { key: key, value: value, propKey: s.property_key || "property" };

    // Try entity type-based categorization first
    if (s.property_entity_id && entityMap[Number(s.property_entity_id)]) {
      var entity = entityMap[Number(s.property_entity_id)];
      var typeKey = (entity.codex_entity_types || {}).key || "";
      var entityName = entity.name || s.property_key || "Unknown";

      if (typeKey === "stat" || typeKey === "stat_set") {
        entry.abbr = generateAbbreviation(entityName);
        entry.cls = getStatColorClass(entityName);
        entry.fullName = entityName;
        entry.description = entity.description || "";
        stats.push(entry);
        return;
      } else if (typeKey === "resource") {
        entry.abbr = generateAbbreviation(entityName);
        entry.cls = getResourceColorClass(entityName);
        entry.fullName = entityName;
        entry.description = entity.description || "";
        resources.push(entry);
        return;
      } else if (typeKey === "level" || key === "level" || key === "level_up") {
        entry.abbr = "LVL";
        entry.cls = "stat-lvl";
        entry.fullName = entityName;
        entry.description = entity.description || "";
        level.push(entry);
        return;
      }
    }

    // Fallback to hardcoded maps (backward compatibility)
    if (codexV2LevelDefs[key]) {
      entry.abbr = codexV2LevelDefs[key].abbr;
      entry.cls = codexV2LevelDefs[key].cls;
      level.push(entry);
    } else if (codexV2StatDefs[key]) {
      entry.abbr = codexV2StatDefs[key].abbr;
      entry.cls = codexV2StatDefs[key].cls;
      stats.push(entry);
    } else if (codexV2ResourceDefs[key]) {
      entry.abbr = codexV2ResourceDefs[key].abbr;
      entry.cls = codexV2ResourceDefs[key].cls;
      resources.push(entry);
    } else {
      other.push(entry);
    }
  });

  return { level: level, stats: stats, resources: resources, other: other };
}
```

### 2. Add Helper Functions

**File:** `scripts/codex-v2-dual-write.html`

```javascript
/**
 * Generate 3-letter abbreviation from entity name.
 * "Strength" → "STR"
 * "Intelligence" → "INT"
 * "Health" → "HEA"
 */
function generateAbbreviation(name) {
  var s = String(name || "").trim();
  if (s.length <= 3) return s.toUpperCase();
  return s.substring(0, 3).toUpperCase();
}

/**
 * Get stat color class based on entity name.
 * Uses consistent colors for known stats, random for others.
 */
function getStatColorClass(name) {
  var s = String(name || "").trim().toLowerCase();
  var knownColors = {
    strength: "stat-str",
    intelligence: "stat-int",
    dexterity: "stat-dex",
    constitution: "stat-con",
    charisma: "stat-cha",
    wisdom: "stat-wis"
  };
  if (knownColors[s]) return knownColors[s];
  // For unknown stats, assign color based on name hash
  var hash = 0;
  for (var i = 0; i < s.length; i++) hash += s.charCodeAt(i);
  var colorIndex = hash % 6;
  return ["stat-str", "stat-int", "stat-dex", "stat-con", "stat-cha", "stat-wis"][colorIndex];
}

/**
 * Get resource color class based on entity name.
 */
function getResourceColorClass(name) {
  var s = String(name || "").trim().toLowerCase();
  var knownColors = {
    health: "res-health",
    mana: "res-mana",
    stamina: "res-stamina",
    xp: "res-xp",
    experience: "res-xp"
  };
  if (knownColors[s]) return knownColors[s];
  return "res-default";
}
```

### 3. Update `codexV2RenderStatBoxes` for Hover Tooltips

**File:** `scripts/codex-v2-dual-write.html`

Update rendering to include `title` attribute for hover tooltip:

```javascript
function codexV2RenderStatBoxes(categorized) {
  var html = "";
  
  // Level box
  if (categorized.level && categorized.level.length) {
    html += "<div class='stat-box-group' style='margin-bottom:6px;'>";
    categorized.level.forEach(function (l) {
      var tooltip = l.fullName ? l.fullName + (l.description ? ": " + l.description : "") : "";
      html += "<div class='stat-box stat-box-level " + l.cls + "' title='" + escapeHtml(tooltip) + "'>" +
        "<div class='stat-box-abbr'>" + escapeHtml(l.abbr) + "</div>" +
        "<div class='stat-box-value'>" + escapeHtml(l.value) + "</div>" +
        "</div>";
    });
    html += "</div>";
  }
  
  // Stats row
  if (categorized.stats.length) {
    html += "<div class='stat-box-group'>";
    categorized.stats.forEach(function (s) {
      var tooltip = s.fullName ? s.fullName + (s.description ? ": " + s.description : "") : "";
      html += "<div class='stat-box " + s.cls + "' title='" + escapeHtml(tooltip) + "'>" +
        "<div class='stat-box-abbr'>" + escapeHtml(s.abbr) + "</div>" +
        "<div class='stat-box-value'>" + escapeHtml(s.value) + "</div>" +
        "</div>";
    });
    html += "</div>";
  }
  
  // Resources row
  if (categorized.resources.length) {
    if (categorized.stats.length) html += "<div style='height:4px;'></div>";
    html += "<div class='stat-box-group'>";
    categorized.resources.forEach(function (r) {
      var tooltip = r.fullName ? r.fullName + (r.description ? ": " + r.description : "") : "";
      html += "<div class='stat-box " + r.cls + "' title='" + escapeHtml(tooltip) + "'>" +
        "<div class='stat-box-abbr'>" + escapeHtml(r.abbr) + "</div>" +
        "<div class='stat-box-value'>" + escapeHtml(r.value) + "</div>" +
        "</div>";
    });
    html += "</div>";
  }
  
  return html;
}
```

### 4. Update All Callers to Pass Entities

**Files to update:**
- `Client.html` — Writing Inspector
- `scripts/series-knowledge.html` — View State At, Progression Sheet

Each caller already has access to the entities array from `codexCache.entitiesBySeries[seriesId]`. Just need to pass it to `codexV2CategorizeState`.

**Example (Writing Inspector):**
```javascript
var entities = (typeof codexCache !== "undefined" && codexCache.entitiesBySeries && codexCache.entitiesBySeries[seriesId]) ? codexCache.entitiesBySeries[seriesId] : [];
var categorized = codexV2CategorizeState(resolved, entities);
```

### 5. Simplify Stat Entity Creation (Future Enhancement)

**Current stat entity form has too many fields.**

**Proposed simplification:**
- **Name** (required) — e.g., "Strength"
- **Description** (optional) — tooltip text
- **Color** (optional) — custom color override
- **Initial Value** (optional) — default value at Chapter 1
- **Abbreviation** (auto-generated) — 3-letter, editable

**Fields to hide/remove from stat entities:**
- Sub-type (not needed for stats)
- Role/Archetype (not needed for stats)
- Motivation/Arc (not needed for stats)
- Backstory (not needed for stats)

This is a separate UI task — can be done after the display system is updated.

---

## Files Changed

| File | Changes |
|------|---------|
| `scripts/codex-v2-dual-write.html` | Update `codexV2CategorizeState`, add `generateAbbreviation`, `getStatColorClass`, `getResourceColorClass`, update `codexV2RenderStatBoxes` |
| `Client.html` | Pass entities to `codexV2CategorizeState` |
| `scripts/series-knowledge.html` | Pass entities to `codexV2CategorizeState` in View State At and Progression Sheet |

---

## Backward Compatibility

- State records WITH `property_entity_id` → use entity type for categorization
- State records WITHOUT `property_entity_id` → fall back to hardcoded property_key maps
- Existing data continues to work without changes

---

## Testing

1. **Existing tests** — all 129 tests should still pass
2. **Manual verification:**
   - Create a new stat entity with custom name (e.g., "Luck")
   - Add state record for Patrick with that stat
   - Verify it appears as a stat box with "LUC" abbreviation
   - Hover shows "Luck" tooltip
3. **Backward compatibility:**
   - Verify existing stat records (without entity ID) still display correctly

---

## Questions Resolved

1. **Abbreviation:** 3-letter, auto-generated from entity name
2. **Colors:** Fixed for known stats, auto-assigned for custom stats
3. **Hover:** Show full name + description
4. **Custom fields:** Abbreviation and color can be added to entity custom_data later

---

## Future Enhancements (Not This Pass)

- Add `custom_data.abbr` and `custom_data.color` fields to stat entities
- Random color assignment on entity creation
- Simplified stat entity creation form
- Stat entity settings panel for customizing display
