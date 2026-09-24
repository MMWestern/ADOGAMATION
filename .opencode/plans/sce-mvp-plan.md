# Story Composition Editor (SCE) — Full MVP Plan

## Overview
Build a visual story composition editor with drag-and-drop story blocks on a 15-state timeline, organized into layers. Full MVP includes: Asset Bin, Timeline, Layers, Blocks, Inspector, Autosave, Undo/Redo.

## Database Tables

### sce_compositions
| Column | Type | Notes |
|--------|------|-------|
| id | BIGSERIAL PK | |
| book_id | BIGINT FK → projects | |
| series_id | BIGINT FK → series | |
| name | TEXT | |
| structure_template | TEXT | default 'standard_15' |
| version | INT | default 1 |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |

### sce_states
| Column | Type | Notes |
|--------|------|-------|
| id | BIGSERIAL PK | |
| composition_id | BIGINT FK → sce_compositions | |
| position | INT | 1-15 |
| name | TEXT | editable title |
| purpose | TEXT | plain-language purpose |
| before_text | TEXT | "Before" |
| after_text | TEXT | "After" |
| created_at | TIMESTAMPTZ | |

### sce_layers
| Column | Type | Notes |
|--------|------|-------|
| id | BIGSERIAL PK | |
| composition_id | BIGINT FK → sce_compositions | |
| name | TEXT | |
| color | TEXT | hex color |
| position | INT | sort order |
| is_hidden | BOOLEAN | default false |
| is_solo | BOOLEAN | default false |
| is_locked | BOOLEAN | default false |
| is_default | BOOLEAN | true for built-in layers |
| created_at | TIMESTAMPTZ | |

### sce_assets
| Column | Type | Notes |
|--------|------|-------|
| id | BIGSERIAL PK | |
| series_id | BIGINT FK → series | |
| name | TEXT | |
| description | TEXT | |
| what_changes | TEXT | |
| what_produces | TEXT | |
| notes | TEXT | |
| created_at | TIMESTAMPTZ | |

### sce_blocks
| Column | Type | Notes |
|--------|------|-------|
| id | BIGSERIAL PK | |
| composition_id | BIGINT FK → sce_compositions | |
| asset_id | BIGINT FK → sce_assets | nullable |
| layer_id | BIGINT FK → sce_layers | |
| start_state | INT | 1-15 |
| end_state | INT | 1-15, >= start_state |
| vertical_pos | INT | for stacking within layer |
| short_title | TEXT | shown on timeline |
| description | TEXT | full description |
| before_text | TEXT | |
| what_happens | TEXT | |
| after_text | TEXT | |
| next_text | TEXT | |
| notes | TEXT | |
| is_detached | BOOLEAN | default false |
| is_parked | BOOLEAN | default false |
| is_later_book | BOOLEAN | default false |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |

### sce_connections
| Column | Type | Notes |
|--------|------|-------|
| id | BIGSERIAL PK | |
| source_block_id | BIGINT FK → sce_blocks | |
| target_block_id | BIGINT FK → sce_blocks | |
| connection_type | TEXT | causes/produces/sets_up/foreshadows/echoes/pays_off/complicates/requires/contradicts |
| notes | TEXT | |
| created_at | TIMESTAMPTZ | |

### sce_ladders (Phase 2)
| Column | Type | Notes |
|--------|------|-------|
| id | BIGSERIAL PK | |
| composition_id | BIGINT FK → sce_compositions | |
| name | TEXT | |
| layer_id | BIGINT FK → sce_layers | |
| color | TEXT | |
| description | TEXT | |

### sce_ladder_steps (Phase 2)
| Column | Type | Notes |
|--------|------|-------|
| id | BIGSERIAL PK | |
| ladder_id | BIGINT FK → sce_ladders | |
| block_id | BIGINT FK → sce_blocks | |
| sequence_position | INT | |
| step_type | TEXT | |

## UI Layout

```
┌──────────────────────────────────────────────────────────────┐
│  SCE — Story Composition Editor         [Undo] [Redo] [Save] │
├──────────┬────────────────────────────────────────┬──────────┤
│ ASSET BIN│  LAYERS + TIMELINE                     │ INSPECTOR│
│          │                                        │          │
│ Search.. │  [Main Story ▼👁🔒]                    │ Title    │
│          │  [Set Pieces ▼👁🔒]                    │ Desc     │
│ + Add    │  [Character  ▼👁🔒]                    │ Before   │
│          │  [Progression▼👁🔒]                    │ What     │
│ ▸ Idea1  │                                        │ After    │
│ ▸ Idea2  │  ┌─────┬─────┬─────┬─────┬─...─┬─────┐│ Next     │
│ ▸ Idea3  │  │ S1  │ S2  │ S3  │ S4  │     │ S15 ││ Layer    │
│ ▸ Idea4  │  │Befo │Some │Immed│Choic│     │After││ Asset    │
│          │  │re   │thing│Reac │e    │     │Next ││ Notes    │
│          │  ├─────┼─────┼─────┼─────┤─...─┼─────┤│          │
│          │  │████████████│     │     │     │     ││ [Save]   │
│          │  │block       │     │     │     │     ││ [Delete] │
│          │  ├─────┼─────┼─────┼─────┤─...─┼─────┤│          │
│          │  │     │     │█████│█████│     │     ││          │
│          │  └─────┴─────┴─────┴─────┴─...─┴─────┘│          │
│          │                                        │          │
│          │  [Parking]  [Later Books]               │          │
└──────────┴────────────────────────────────────────┴──────────┘
```

## Default Layers
1. Main Story — #3b82f6 (blue)
2. Set Pieces — #ef4444 (red)
3. LitRPG Progression — #22c55e (green)
4. Character — #a855f7 (purple)
5. Relationships — #ec4899 (pink)
6. Mystery and World — #f59e0b (amber)
7. Foreshadowing — #14b8a6 (teal)
8. Easter Eggs and Callbacks — #6366f1 (indigo)
9. Consequences — #f97316 (orange)

## Default 15 States
1. Before
2. Something changes
3. Immediate reaction
4. A choice is made
5. New situation
6. First attempts
7. Things get harder
8. Big change
9. Consequences
10. Trouble closes in
11. Major loss
12. Lowest point
13. New understanding
14. Final action
15. After and next

## Block Interaction
- **Drag from Asset Bin** → creates new block on timeline
- **Drag block** → moves between states and layers
- **Resize block edges** → spans multiple states
- **Click block** → selects and opens in Inspector
- **Double-click** → opens full editor
- **Right-click** → context menu (duplicate, delete, detach, park, connect)

## Autosave
- Debounced 2-second save on any change
- Saves composition metadata + all blocks + layer states
- Undo/redo via in-memory command stack (max 50 entries)

## Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `Index.html` | Modify | Add SCE tab + content panel |
| `scripts/el-cache.html` | Modify | Cache SCE elements |
| `scripts/bind-events.html` | Modify | Wire SCE tab click |
| `Client.html` | Modify | Add SCE to switchMainTab |
| `scripts/sce-core.html` | Create | Init, data load, autosave, undo/redo |
| `scripts/sce-timeline.html` | Create | Timeline rendering, state columns |
| `scripts/sce-blocks.html` | Create | Block rendering, drag/drop, resize |
| `scripts/sce-layers.html` | Create | Layer controls |
| `scripts/sce-asset-bin.html` | Create | Asset Bin panel |
| `scripts/sce-inspector.html` | Create | Inspector panel |
| `Styles.html` | Modify | SCE CSS |
| `migrations/20260920_create_sce_tables.sql` | Create | DB migration |
| `scripts/supabase-codex.html` | Modify | SCE Supabase CRUD |

## Implementation Order
1. DB migration + Supabase CRUD functions
2. Tab setup (button, panel, wiring, CSS)
3. Timeline rendering (15 state columns)
4. Layer controls (default layers, hide/solo/lock)
5. Asset Bin (CRUD, search)
6. Block rendering (place on timeline)
7. Block drag/drop (move between states/layers)
8. Block resize (span multiple states)
9. Inspector (edit block details)
10. Autosave + undo/redo
11. Parking / Later Books

## Acceptance Criteria
1. Create "Patrick's first city boss" in Asset Bin
2. Drag it to Set Pieces layer at State 8
3. Resize to span States 7-9
4. Add "boss reward" block to LitRPG layer
5. Connect boss victory to reward
6. Solo LitRPG layer to inspect progression
7. Solo Character layer to inspect arc
8. Move boss sequence to another state
9. Undo the move
10. Park an unused idea
