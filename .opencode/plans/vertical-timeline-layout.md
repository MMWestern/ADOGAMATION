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

## Block placement

A block's row is derived, not stored. Nothing reads a block's own
`start_state` to place a scene-anchored block:

- `renderSCEBlocks()` looks the block up by
  `.sce-scene-slot[data-scene-id][data-layer-id]`, so `scene_id` + `layer_id`
  are sufficient.
- A chapter renders only in the row equal to its own `start_state`, and a
  scene lives in its chapter's group. A scene therefore inherits its row from
  the chapter, which is what `sceSceneStartState(sceneId)` returns.
- The block inspector edits placement with a Chapter select and a Scene select
  that it filters, not with state numbers. A scene change routes through
  `moveSCEBlock()` so it stays undoable exactly like a drag.
- Blocks with no scene stay in the `.sce-layer-unscoped` band, and for those
  `start_state` is still load-bearing as the row selector. That is the one
  remaining reason the column exists on `sce_blocks`.
- `end_state` is retained only for unscoped blocks, where it encodes a span
  (`span = end_state - start_state`) that a move must preserve. Scene-anchored
  blocks always have `end_state === start_state`, so they do not span rows.

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

## Connections

A connection is a bracket on the right-hand side of its layer column. The
path leaves the source block's right edge, runs down a vertical lane just
past the rightmost of the two blocks, and re-enters the target's right edge.
Both ends are on the right because a block's connect dot only exists there.

This is deliberately a single shape. The previous renderer picked between four
hand-rolled branches (same column, going left, adjacent column, far away) by
comparing rectangles, which is what allowed a connection to leave its column
and cross the rest of the timeline. Connections are now same-column only, so
one shape covers every case:

- `sceSameColumn()` compares `layer_id` on the two blocks.
- `wireSCEConnectNodes()` only highlights same-column blocks as valid drop
  targets and shows `.sce-block-connect-rejected` on the rest, so the rule is
  taught during the drag. A cross-column drop flashes "Connections stay
  within one column" and creates nothing.
- The corner radius is clamped to half the vertical gap. Without that clamp a
  gap under 12px (blocks in neighbouring states) made the vertical leg run
  backwards through itself.

Lines sit at `0.5` opacity. Selecting a block walks the connection graph in
both directions and lights the whole reachable thread at `1.0`, adding
`.is-linked` to the partner blocks. The anchor block keeps the brighter
`.is-selected` outline and is excluded from `.is-linked`.

## Known gaps

- The stats bar estimates total words from a user-set average words per
  chapter; it does not read actual scene word counts.
- Connection lines have not been visually verified in portrait mode.
- Mutation guards are applied at individual entry points, not centrally.
- Connections created before the same-column rule are still drawn with the
  new shape. Any that cross columns need deleting and recreating within one
  column; the renderer intentionally does not delete data on its own.
