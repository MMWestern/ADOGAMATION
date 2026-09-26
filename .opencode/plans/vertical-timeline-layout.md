# Vertical Timeline Layout Plan

## Current Layout (Landscape)
```
         │ State 1  │ State 2  │ State 3  │ State 4
─────────┼──────────┼──────────┼──────────┼──────────
Chapters │ Ch1 Ch2  │ Ch3      │ Ch4 Ch5  │ Ch6
Scenes   │ Sc1 Sc2  │ Sc3      │ Sc4 Sc5  │ 
Layer 1  │ [Bl][Bl] │ [Bl]     │ [Bl]     │ [Bl]
Layer 2  │ [Bl]     │ [Bl]     │ [Bl]     │ [Bl]
```

## New Layout (Portrait)
```
         │ Chapters │ Scenes   │ Layer 1  │ Layer 2
─────────┼──────────┼──────────┼──────────┼──────────
State 1  │ Ch1      │ Sc1      │ [Bl]     │ [Bl]
         │          │ Sc2      │ [Bl]     │ 
         │ Ch2      │ Sc3      │ [Bl]     │ 
         │ Ch3      │ Sc4      │ [Bl]     │ 
─────────┼──────────┼──────────┼──────────┼──────────
State 2  │ Ch4      │ Sc5      │ [Bl]     │ [Bl]
         │          │ Sc6      │ [Bl]     │ 
         │ Ch5      │ Sc7      │          │ 
─────────┼──────────┼──────────┼──────────┼──────────
State 3  │ Ch6      │ Sc8      │ [Bl]     │ 
```

## Design Decisions

1. **Block spanning**: Blocks span full height of all state rows they cover
2. **Row height**: Variable, expands to fit content (chapters/scenes)
3. **Sticky headers**: State labels (left) and layer names (top) are sticky
4. **Column widths**: Fixed widths (resizable later)
5. **Chapter/scene layout**: Both stack vertically within their columns

## Column Structure

| Column | Width | Content |
|--------|-------|---------|
| State | 120px | State name/number (sticky left) |
| Chapters | 150px | Chapter blocks stacked vertically |
| Scenes | 150px | Scene blocks stacked vertically |
| Layer 1 | 200px | Layer blocks stacked vertically |
| Layer 2 | 200px | Layer blocks stacked vertically |

## Implementation Steps

### Phase 1: HTML Structure
- [ ] Update `Index.html` timeline container structure
- [ ] Create new header row with layer names
- [ ] Create state row template with layer cells

### Phase 2: CSS Changes
- [ ] Add sticky positioning for state labels (left) and layer names (top)
- [ ] Update `.sce-timeline` to handle portrait layout
- [ ] Add `.sce-state-row` styles for vertical stacking
- [ ] Update `.sce-layer-cell` to be rows within state groups
- [ ] Add vertical block spanning styles

### Phase 3: JavaScript - Timeline Rendering
- [ ] Rewrite `renderSCETimeline()`:
  - Build header with layer names (Chapters, Scenes, + user layers)
  - Build state rows with layer cells
  - Calculate row heights based on chapter/scene count
- [ ] Update `renderSCEChapterBlocks()`:
  - Stack chapters vertically within state rows
  - Update drag-and-drop for vertical reordering
- [ ] Update `renderSCESceneBlocks()`:
  - Stack scenes vertically within scene column
  - Update drag-and-drop for vertical reordering

### Phase 4: JavaScript - Block Positioning
- [ ] Update `renderSCEBlocks()`:
  - Blocks span vertically across state rows
  - Calculate `top` and `height` based on state positions
  - Handle variable row heights
- [ ] Update block resize:
  - Top/bottom handles instead of left/right
  - Resize spans multiple states vertically

### Phase 5: JavaScript - Connections
- [ ] Update `renderSCEConnections()`:
  - Route connections vertically between state rows
  - Update SVG path calculations

### Phase 6: JavaScript - Drag and Drop
- [ ] Update block drag:
  - Move between states = move between rows
  - Update drop zone calculations
- [ ] Update chapter/scene drag:
  - Vertical reordering within state
  - Move between states (different rows)

### Phase 7: Polish
- [ ] Add description toggle option (show/hide scene descriptions)
- [ ] Test all interactions (drag, resize, reorder, connections)
- [ ] Verify sticky headers work correctly
- [ ] Test with large datasets (many states, chapters, scenes)

## Files to Modify

1. **`Index.html`** - Timeline container structure
2. **`Styles.html`** - New CSS for portrait layout
3. **`scripts/sce-timeline.html`** - Timeline rendering logic
4. **`scripts/sce-blocks.html`** - Block positioning and resize
5. **`scripts/sce-connections.html`** - Connection routing
6. **`scripts/sce-inspector.html`** - Update inspector for new layout

## Estimated Complexity

- **High**: Block spanning across variable-height rows
- **Medium**: Connection routing in portrait mode
- **Medium**: Drag-and-drop with vertical reordering
- **Low**: Basic layout structure and styling