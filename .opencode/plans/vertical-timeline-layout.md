# Vertical Timeline Layout

Shipped design reference for the SCE portrait timeline.

## Layout model

The grid is state-major: each state is one full-width row, and columns
run left to right as States, Chapters, Scenes, then one column per layer.

```
States        | Chapters       | Scenes        | Layer 1   | Layer 2
--------------+----------------+---------------+-----------+----------
State 1       | Ch1            | Sc1           | [block]   | [block]
              | [+ Ch]         | Sc2           | [block]   |
              | Ch2            | Sc3           |           |
              | [+ Ch]         | [+ Sc]        |           |
              | Ch3            | Sc4           |           |
--------------+----------------+---------------+-----------+----------
State 2       | Ch4            | Sc5           | [block]   |
              |                | Sc6           |           |
```

Chapters and scenes stack vertically inside their column. A scene slot
holds the blocks anchored to that scene, so several blocks can sit in
one row and can differ per layer.

## Constants

Defined at the top of `scripts/sce-timeline.html`:

| Constant | Value | Meaning |
|----------|-------|---------|
| `SLOT_H` | 30 | Height of a scene slot in px |
| `GAP` | 2 | Gap between slots |
| `ADD_H` | 18 | Height of a `+` add row |

Row height is derived from the scene count in that state, not stored.

## Invariants

- Chapter order within a state is `sort_order`; `start_state` places the
  chapter on a row. Both are resequenced on move or reorder.
- A block points at either a `scene_id` or a `layer_id`. Scene-anchored
  blocks render inside the scene's slot; layer-anchored blocks render in
  the `.sce-layer-unscoped` band at the bottom of the state row.
- Column widths live in `--sce-col-*` custom properties and are persisted.
- Layers with `is_locked` set reject block moves.

## Data loading

Chapter and scene rows are read from Supabase into
`_sceState.sceneCache` by `loadSCEChaptersAndScenes()`. Render functions
read from that cache and never mutate it.

Every structural mutation writes to the database, then re-runs the
loader and re-renders. Do not hand-patch `_sceState` after a write; the
loader is the single source of truth.

## Undo and replay

`scripts/sce-core.html` owns the undo stack. Snapshots capture scenes
plus block anchors, so restoring a deleted chapter also restores its
scenes and re-points their blocks.

Undo records are moved between the redo and undo stacks *before* the
replay runs, and `_sceState.replayBusy` is held for the whole async
replay via an explicit `done` callback. Callers that can be reached
while a replay is in flight should start with `sceMutationBlocked()`.

## Files

| File | Role |
|------|------|
| `Index.html` | Timeline shell, header, toolbar, stats |
| `Styles.html` | Grid, tints, separators, resizers |
| `scripts/sce-timeline.html` | Row/slot geometry and rendering |
| `scripts/sce-core.html` | State, cache, loader, undo/replay |
| `scripts/sce-blocks.html` | Block placement and drag |
| `scripts/sce-connections.html` | Connection overlay |
| `scripts/sce-inspector.html` | Chapter/scene/block editing |

## Known gaps

- The stats bar estimates total words from a user-set average words per
  chapter; it does not read actual scene word counts.
- Connection lines have not been visually verified in portrait mode.
- Mutation guards are applied at individual entry points, not centrally.
  The header `+ Ch` path in `wireSCEToolbar()` and connection field
  updates are not currently guarded.
