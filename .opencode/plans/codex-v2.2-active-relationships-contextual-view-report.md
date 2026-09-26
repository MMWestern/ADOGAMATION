# Codex v2.2 — Active Relationships Contextual View: Changes Summary

## What Was Added

### Active Relationships in "View State At..." (State Tab)

When you click "View State At..." and select a Book + Chapter, the results now show **two sections**:

1. **State** — Level, Strength, Fireball, Health, etc. at that narrative point
2. **Active Relationships** — grouped by label (Owns, Member of, Travels with, etc.)

Both resolve against the same selected Book + Chapter.

### Active Relationships in Progression Sheet (Character Tab)

The Progression Sheet now queries **both state and active relationships in parallel** and displays:

- Level
- Stats (grid)
- Resources (grid)
- Class
- Skills
- Traits
- Other
- **Active Relationships** (grouped by label, separated by a divider)

### Forward/Inverse Label Support

Active Relationships uses the correct directional label:

| Viewing | Relationship | Label Shown |
|---------|-------------|-------------|
| Patrick | owns → Goblin Sword | "Owns" |
| Goblin Sword | owned by → Patrick | "Owned by" |

Uses `codex_relationship_types.forward_label` and `inverse_label` where available, falls back to `label`.

### Grouping by Relationship Type

Active connections are grouped by their display label:

```
ACTIVE RELATIONSHIPS

Owns
— Goblin Sword
— Bronze Key

Member of
— Test Guild

Travels with
— Mira Vale
```

### Empty State Handling

- No active relationships: "No active relationships at this point."
- No state recorded: "No state recorded."
- Loading: "Loading..."

---

## What Was NOT Changed

- **Relationship History panel** — unchanged, still shows all historical connections with ENDED/PLANNED/TEMPORAL badges
- **Temporal boundary semantics** — unchanged (inclusive start, exclusive end)
- **State/progression engine** — unchanged
- **Cross-book state carry-forward** — unchanged
- **Location hierarchy** — unchanged (structural, not temporal)
- **Relationship type architecture** — unchanged

---

## How It Works

### Data Flow

```
User selects Book + Chapter
        ↓
Resolve global narrative position
  (book_number × 10000 + chapter_sort_order)
        ↓
Query in parallel:
  1. codexV2GetEntityStateAt(entityId, bookId, globalSort)
  2. codexV2GetActiveConnectionsAt(entityId, globalSort)
        ↓
Render both sections
```

### Temporal Predicate

Active relationships use:

```
(valid_from_sort IS NULL OR valid_from_sort <= target_position)
AND
(valid_to_sort IS NULL OR valid_to_sort > target_position)
```

- Start = inclusive
- End = exclusive
- NULL bounds = unbounded (always active/never ends)

### Files Changed

| File | Change |
|------|--------|
| `scripts/series-knowledge.html` | Added Active Relationships to View State At and Progression Sheet |

---

## How to Test

### View State At
1. Open Patrick → State tab → click "View State At..."
2. Select Book 1, Chapter 7 → Load
3. Should show: State (Level 1, STR 6) + Active Relationships (Owns: Goblin Sword)
4. Select Book 2, Chapter 3 → Load
5. Should show: State (Level 3, STR 10) + Active Relationships (empty — sword lost)

### Progression Sheet
1. Open Patrick → click "Progression Sheet" tab
2. Select Book 1, Chapter 12 → Load
3. Should show: Level 3, STR 8, Fireball Rank 1 + Active Relationships (Owns: Goblin Sword)
4. Select Book 2, Chapter 3 → Load
5. Should show: Level 3, STR 10, Fireball Rank 1 + Active Relationships (empty)

### Reverse Test
1. Open Goblin Sword → State tab → "View State At..."
2. Select Book 1, Chapter 12 → Load
3. Should show: Active Relationships (Owned by: Patrick Kelth)

---

## Architectural Principle

The Codex now clearly supports two distinct views:

| View | Question Answered | Source |
|------|------------------|--------|
| **Relationship History** (right panel) | "What relationships has this entity ever had?" | All non-deleted connections |
| **Active Relationships** (contextual) | "What relationships are true at this narrative point?" | `getActiveConnectionsAt()` |

Both coexist. History shows everything; Active shows only what's true at the selected Book + Chapter.
